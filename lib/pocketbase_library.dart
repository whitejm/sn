import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:crypto/crypto.dart';
import 'package:sn/qa_parser.dart';
import 'package:intl/intl.dart';

// RecordModel
//  String id;
//  String created;
//  String updated;
//  String collectionId;
//  String collectionName;

// RecordModels will get converted to/from these custom classes...
// - Notebooks
//   - Flashcards
//     - Reviews

// TODO Reviews... and add reviews to Flashcard

class Flashcard {
  final String question;
  String answer; // answers can be edited
  final String notebookId;
  String? id; // we get this from PB after flascards are parsed and push to PB
  final String sha512;
  String due;
  String reviewHistory;

  Flashcard({
    required this.question,
    required this.answer,
    required this.notebookId,
    required this.sha512,
    this.id,
    this.due = "",
    this.reviewHistory = "never reviewed before",
  });
}

class Notebook {
  final String id;
  final String name;
  final String content;
  // flashcard lists contain flashcards sha512(key) not the Flashcards themselves
  List<String> allFlashcards = [];
  List<String> newFlashcards = [];
  List<String> dueFlashcards = [];
  Notebook({
    required this.id,
    required this.content,
    required this.name,
  });
}

DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSSZZZZZ');

// utility functions...

Notebook recordModelToNotebook(RecordModel recordModelNotebook) {
  // TODO: throw execption if colllection name
  return Notebook(
      content: recordModelNotebook.getStringValue('content'),
      id: recordModelNotebook.id,
      name: recordModelNotebook.getStringValue('name'));
}

List<Notebook> recordModelsToNotebooks(List<RecordModel> recordModelNotebooks) {
  List<Notebook> notebooks = [];
  for (var recordModelNotebook in recordModelNotebooks) {
    notebooks.add(recordModelToNotebook(recordModelNotebook));
  }
  return notebooks;
}

/// Takes a list of notebooks and returns a Map were notebook.id is the key and notebook is the value
Map<String, Notebook> notebookListToMap(List<Notebook> notebooks) {
  return {for (var notebook in notebooks) notebook.id: notebook};
}

Map<String, RecordModel> recordModelListToMap(List<RecordModel> list,
    {keyString = 'id'}) {
  return {for (var record in list) record.getStringValue(keyString): record};
}

class PocketBaseLibraryNotifier extends ChangeNotifier {
  PocketBase pb;
  bool _isLoading = false;
  bool _errorOccurred = false;
  String _errorMessage = "";
  String _userId = ""; // TODO: find better way to do this
  Map<String, Notebook> _notebooks = {};
  Map<String, Flashcard> _flashcards = {};
  // Map<String, RecordModel> _flashcards = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get errorOccurred => _errorOccurred;
  String get errorMessage => _errorMessage;
  String get userId => _userId;
  Map<String, Notebook> get notebooks => _notebooks;
  Map<String, Flashcard> get flashcards => _flashcards;
  List<Notebook> get sortedNotebooks {
    List<Notebook> _sortedNotebooks = _notebooks.values.toList();
    _sortedNotebooks
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _sortedNotebooks;
  }

  // Constructor
  PocketBaseLibraryNotifier(this.pb);

  /// load all notebooks from pocketbase and parse their flaschards
  Future<void> loadNotebooks(String userId) async {
    _userId = userId;
    debugPrint('loadNotebooks for userId $userId');
    //debugPrintStack();
    _isLoading = true;
    notifyListeners();
    try {
      final recordModelNotebooks =
          await pb.collection('notebooks').getFullList();
      _notebooks =
          notebookListToMap(recordModelsToNotebooks(recordModelNotebooks));
      parseFlashcardsFromNotebooks();
      syncAllFlashcards();
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      _notebooks = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // add notebook
  Future<void> addNotebook(String name) async {
    debugPrint('addNotebook: ${name}');
    _isLoading = true;
    notifyListeners();
    try {
      final record = await pb
          .collection('notebooks')
          .create(body: {'name': name, 'userId': _userId});
      debugPrint('new notebook notebookId ${record.id}');
      _notebooks[record.id] = Notebook(content: "", id: record.id, name: name);
      debugPrint(_notebooks[record.id].toString());
      parseFlashcardsFromNotebook(record.id);
      syncNotebookFlashcards(record.id);
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      debugPrint(_errorMessage);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // update notebook
  Future<void> updateNotebook(
      String notebookId, String name, String content) async {
    debugPrint('updateNotebook: notebookId $notebookId, name $name');
    _isLoading = true;
    notifyListeners();
    try {
      final record = await pb
          .collection('notebooks')
          .update(notebookId, body: {'name': name, 'content': content});
      _notebooks.update(record.id,
          (value) => Notebook(content: content, id: record.id, name: name));
      parseFlashcardsFromNotebook(notebookId);
      syncNotebookFlashcards(notebookId);
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // delete notebook
  Future<void> deleteNotebook(String notebookId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await pb.collection('notebooks').delete(notebookId);
      _notebooks.remove(notebookId);
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Flashcards
  // 1. Parse flashcards from Notebook
  // 2. Get remaining data for flashcards from PB (id, due).
  //    Ignore old flashcards (flashcards that are in PB, but weren't parsed)
  // 3. Add new flashcards (flashcards that were parsed but weren't in PB) to PB
  //    (you can tell they are new because they'll have no id property)

  // TODO: handle flash card syncs on a per notebook bases...

  void parseFlashcardsFromNotebook(String notebookId) {
    debugPrint('parseFlashcardsFromNotebook notebookId: $notebookId');

    _notebooks[notebookId]?.allFlashcards = [];

    List<QA> qas = parseQAsFromMD(_notebooks[notebookId]?.content ?? "");

    // Step 3: Flashcard extraction
    for (var qa in qas) {
      final question = qa.question;
      final answer = qa.answer;
      // TODO: get pocketbase to take long id or do something better
      final sha =
          sha512.convert(utf8.encode(question)).toString().substring(0, 15);
      final flashcard = Flashcard(
          sha512: sha,
          question: question,
          answer: answer,
          notebookId: notebookId);
      _flashcards.update(sha, (value) => flashcard, ifAbsent: () => flashcard);
      _notebooks[notebookId]?.allFlashcards.add(sha);
    }
  }

  void parseFlashcardsFromNotebooks() {
    for (var notebookId in _notebooks.keys) {
      parseFlashcardsFromNotebook(notebookId);
    }
  }

  // TODO: handle sync on a single notebook

  void syncAllFlashcards() async {
    debugPrint('syncAllFlashcards');
    // TODO: try/catch, error handling
    for (var notebookId in _notebooks.keys) {
      syncNotebookFlashcards(notebookId);
    }
  }

  void syncNotebookFlashcards(String notebookId) async {
    debugPrint(
        'syncNotebookFlashcards: notebookId $notebookId (${_notebooks[notebookId]?.name})');
    // TODO: try/catch, error handling
    final pbFlashcardsList = await pb.collection('flashcards').getFullList(
        filter:
            'notebookId="$notebookId"'); //filter: 'notebookId = ${notebookId}'
    final pbFlashcardsMap =
        recordModelListToMap(pbFlashcardsList, keyString: 'sha512');
    _notebooks[notebookId]?.newFlashcards = [];
    List<Flashcard> dueFlashcards = [];
    for (var fcSha in _notebooks[notebookId]?.allFlashcards ?? []) {
      // handle flashcards already in PB
      if (pbFlashcardsMap.containsKey(fcSha)) {
        _flashcards[fcSha]!.due =
            pbFlashcardsMap[fcSha]?.getStringValue('due') ?? "";
        _flashcards[fcSha]!.id = pbFlashcardsMap[fcSha]!.id;
        _flashcards[fcSha]!.reviewHistory = await getReviewHistory(fcSha);
      }
      // handle flashcards from notebook not in PB yet
      else {
        try {
          final record = await pb.collection('flashcards').create(body: {
            'sha512': fcSha,
            'notebookId': notebookId,
            'userId': _userId
          });
          _flashcards[fcSha]!.id = record.id;
        } catch (error) {
          debugPrint(error.toString());
        }
      }
      // New Flashcards

      if (_flashcards[fcSha]?.due.isEmpty ?? true) {
        _notebooks[notebookId]?.newFlashcards.add(fcSha);
      } else {
        // Due flashcards
        DateTime dueDateTime = formatter.parse(_flashcards[fcSha]!.due, true);
        DateTime nowDateTime = DateTime.now();
        if (dueDateTime.isBefore(nowDateTime)) {
          dueFlashcards.add(_flashcards[fcSha]!);
          _notebooks[notebookId]!.dueFlashcards.add(fcSha);
        }
      }
    }
    // Due flashcards continued
    dueFlashcards.sort((a, b) =>
        formatter.parse(a.due, true).compareTo(formatter.parse(b.due, true)));
    notebooks[notebookId]!.dueFlashcards =
        dueFlashcards.map((fc) => fc.sha512).toList();
    notifyListeners();
  }

  void setDueDate(String fcSha, int days) async {
    // TODO, try/catch error handling, check for id...

    DateTime dueDateTime = DateTime.now().toUtc().add(Duration(days: days));
    String due = formatter.format(dueDateTime);
    String id = _flashcards[fcSha]?.id ?? "";
    debugPrint(
        'setDueDate flashcardId: $id sha: $fcSha dateTime: $due days: $days');
    await pb.collection('flashcards').update(id, body: {'due': due});
    // add review history
    await pb.collection('reviews').create(
        body: {'flashcardId': _flashcards[fcSha]?.id ?? "", 'userId': _userId});
    // TODO: could just update notebooks.dueFlashcards directly and call notifylisteners to save a call to backend
    syncNotebookFlashcards(_flashcards[fcSha]!.notebookId);
  }

  Future<String> getReviewHistory(String fcSha) async {
    try {
      // Error handling
      var reviews = await pb.collection('reviews').getFullList(
          filter: 'flashcardId="${_flashcards[fcSha]!.id}"', sort: "-created");

      if (reviews.length > 0) {
        // Convert the created time to a DateTime object
        DateTime lastReviewDate = DateTime.parse(reviews[0].created);

        // Calculate the difference between now and the last review
        Duration difference = DateTime.now().difference(lastReviewDate);

        // Determine the correct output based on the difference
        if (difference.inDays == 0) {
          return "You have reviewed this ${reviews.length} times. Last reviewed today";
        } else if (difference.inDays == 1) {
          return "You have reviewed this ${reviews.length} times. Last reviewed yesterday";
        } else {
          return "You have reviewed this ${reviews.length} times. Last reviewed ${difference.inDays} days ago";
        }
      } else {
        return "No review history found";
      }
    } catch (error) {
      // Handle errors appropriately
      return "Error fetching review history";
    }
  }
}
