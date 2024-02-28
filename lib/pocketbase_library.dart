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

class ParsedFlashcard {
  final String question;
  final String answer;
  final String notebookId;
  final String sha512;

  ParsedFlashcard(
      {required this.question,
      required this.answer,
      required this.notebookId,
      required this.sha512});
}

class PocketBaseLibraryNotifier extends ChangeNotifier {
  PocketBase pb;
  bool _isLoading = false;
  bool _errorOccurred = false;
  String _errorMessage = "";
  Map<String, RecordModel> _notebooks = {};
  Map<String, ParsedFlashcard> _parsedFlashcards = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get errorOccurred => _errorOccurred;
  String get errorMessage => _errorMessage;
  Map<String, RecordModel> get notebooks => _notebooks;

  // Constructor
  PocketBaseLibraryNotifier(this.pb);

  Map<String, RecordModel> recordModelListToMap(List<RecordModel> list) {
    return Map.fromIterable(list.map((record) => record.id));
  }

  // load notebooks
  Future<void> loadNotebooks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notebooks =
          recordModelListToMap(await pb.collection('notebooks').getFullList());
      _notebooks.forEach((key, value) {
        parseFlashcardsFromNotebook(key);
      });
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      _notebooks = {};
      notifyListeners();
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
      _notebooks[id] = await pb.collection('noteoobks').getOne(id);
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
  Future<void> addNotebook(String name, String userid) async {
    _isLoading = true;
    notifyListeners();
    print('attempting to add notebook ${name} ${userid}');
    try {
      await pb
          .collection('notebooks')
          .create(body: {'name': name, 'userid': userid});
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
      await loadNotebooks();
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
      await loadNotebooks(); // Update notebooks list
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void parseFlashcardsFromNotebook(String notebookId) {
    // No 'async' or 'Future'
    // Step 1: Markdown to HTML conversion
    String html = markdown
        .markdownToHtml(_notebooks[notebookId]?.getDataValue('contents') ?? "");

    // Step 2: DOM parsing
    var document = parse(html);
    var allBlockquotes = document.querySelectorAll('blockquote');

    // Step 3: Flashcard extraction
    List<ParsedFlashcard> flashcards = [];
    for (var bq in allBlockquotes) {
      var nestedBlockquote = bq.querySelector('blockquote');
      if (nestedBlockquote != null) {
        final question = bq.text.trim();
        final answer = nestedBlockquote.text.trim();
        final sha = sha512.convert(utf8.encode(question)).toString();
        flashcards.add(ParsedFlashcard(
            sha512: sha,
            question: question,
            answer: answer,
            notebookId: notebookId));
      }
    }
    print(flashcards);
  }
}
