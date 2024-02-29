import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:html/parser.dart';
import 'package:crypto/crypto.dart';

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

  Flashcard({
    required this.question,
    required this.answer,
    required this.notebookId,
    required this.sha512,
    this.id,
    this.due = "",
  });
}

class Notebook {
  final String id;
  final String name;
  final String content;
  List<Flashcard> flashcards =
      []; // flashcards are added after contents are parsed

  Notebook({
    required this.id,
    required this.content,
    required this.name,
  });
}

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
  Map<String, Notebook> get notebooks => _notebooks;
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
    // Step 1: Markdown to HTML conversion
    String html =
        markdown.markdownToHtml(_notebooks[notebookId]?.content ?? "");

    // Step 2: DOM parsing
    var document = parse(html);
    var allBlockquotes = document.querySelectorAll('blockquote');

    // Step 3: Flashcard extraction
    for (var bq in allBlockquotes) {
      var nestedBlockquote = bq.querySelector('blockquote');
      if (nestedBlockquote != null) {
        bq.querySelector('blockquote')?.remove();
        final question = bq.text.trim();
        final answer = nestedBlockquote.text.trim();
        // TODO: get pocketbase to take long id or do something better
        final sha =
            sha512.convert(utf8.encode(question)).toString().substring(0, 15);
        final flashcard = Flashcard(
            sha512: sha,
            question: question,
            answer: answer,
            notebookId: notebookId);
        _flashcards.update(sha, (value) => flashcard,
            ifAbsent: () => flashcard);
      }
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
    final pbFlashcardsList = await pb
        .collection('flashcards')
        .getFullList(); //filter: 'notebookId = ${notebookId}'
    final pbFlashcardsMap =
        recordModelListToMap(pbFlashcardsList, keyString: 'sha512');
    for (var fc in _flashcards.values) {
      // handle flashcards already in PB
      if (pbFlashcardsMap.containsKey(fc.sha512)) {
        _flashcards[fc.sha512]!.due =
            pbFlashcardsMap[fc.sha512]?.getStringValue('due') ?? "";
      }
      // handle flashcards from notebook not in PB yet
      else if (fc.notebookId == notebookId) {
        try {
          debugPrint('adding flashcard with notebookId of ${fc.notebookId}');
          final record = await pb.collection('flashcards').create(body: {
            'sha512': fc.sha512,
            'notebookId': fc.notebookId,
            'userId': _userId
          });
          _flashcards[fc.sha512]!.id = record.id;
        } catch (error) {
          debugPrint(error.toString());
        }
      }
    }
    notifyListeners();
  }
}
