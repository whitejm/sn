import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:html/parser.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:sn/pocketbase_auth.dart';

// RecordModel
//  String id;
//  String created;
//  String updated;
//  String collectionId;
//  String collectionName;

class Flashcard {
  final String question;
  final String answer;
  final String notebookId;
  final String id; //sha512
  String due;

  Flashcard({
    required this.question,
    required this.answer,
    required this.notebookId,
    required this.id,
    this.due = "",
  });
}

class PocketBaseLibraryNotifier extends ChangeNotifier {
  PocketBase pb;
  bool _isLoading = false;
  bool _errorOccurred = false;
  String _errorMessage = "";
  String _userId = ""; // TODO: find better way to do this
  Map<String, RecordModel> _notebooks = {};
  List<RecordModel> _sortedNotebooks = [];
  Map<String, Flashcard> _flashcards = {};
  // Map<String, RecordModel> _flashcards = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get errorOccurred => _errorOccurred;
  String get errorMessage => _errorMessage;
  Map<String, RecordModel> get notebooks => _notebooks;
  List<RecordModel> get sortedNotebooks => _sortedNotebooks;

  // Constructor
  PocketBaseLibraryNotifier(this.pb);

  Map<String, RecordModel> recordModelListToMap(List<RecordModel> list) {
    return {for (var record in list) record.id: record};
  }

  // load notebooks
  Future<void> loadNotebooks(String userId) async {
    _userId = userId;
    print('loading notebooks');
    _isLoading = true;
    //notifyListeners();
    try {
      _sortedNotebooks = await pb.collection('notebooks').getFullList();
      _sortedNotebooks.sort((a, b) => a
          .getStringValue('name')
          .toLowerCase()
          .compareTo(b.getStringValue('name').toLowerCase()));
      _notebooks = recordModelListToMap(_sortedNotebooks);
      parseFlashcardsFromNotebooks();
      syncFlashcards();
      //getNotebookSortedByName();
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      _notebooks = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // load notebook
  Future<void> loadNotebook(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notebooks[id] = await pb.collection('notebooks').getOne(id);
      parseFlashcardsFromNotebooks();
      syncFlashcards();
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // add notebook
  Future<void> addNotebook(String name) async {
    _isLoading = true;
    notifyListeners();
    print('attempting to add notebook ${name} ${_userId}');
    try {
      await pb
          .collection('notebooks')
          .create(body: {'name': name, 'userId': _userId});
      await loadNotebooks(_userId);
      parseFlashcardsFromNotebooks();
      syncFlashcards();
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // update notebook
  Future<void> updateNotebook(
      String notebookId, String name, String content) async {
    _isLoading = true;
    notifyListeners();
    try {
      await pb
          .collection('notebooks')
          .update(notebookId, body: {'name': name, 'content': content});
      await loadNotebook(notebookId);
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
      await loadNotebooks(_userId); // Update notebooks list
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
    // Step 1: Markdown to HTML conversion
    String html = markdown.markdownToHtml(
        _notebooks[notebookId]?.getStringValue('content') ?? "no content");

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
            id: sha,
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

  void syncFlashcards() async {
    // TODO: try/catch, error handling
    final pbFlashcardsList = await pb.collection('flashcards').getFullList();
    final pbFlashcardsMap = recordModelListToMap(pbFlashcardsList);
    for (var fc in _flashcards.values) {
      // handle flashcards already in PB
      if (pbFlashcardsMap.containsKey(fc.id)) {
        _flashcards[fc.id]!.due =
            pbFlashcardsMap[fc.id]?.getStringValue('due') ?? "";
      }
      // handle flashcards not in PB yet
      else {
        await pb.collection('flashcards').create(body: {
          'id': fc.id,
          'notebookId': fc.notebookId,
          'userId': _userId
        });
        notifyListeners();
      }
    }
  }
}
