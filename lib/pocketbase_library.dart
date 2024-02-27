import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseLibraryNotifier extends ChangeNotifier {
  PocketBase pb;
  bool _isLoading = false;
  bool _errorOccurred = false;
  String _errorMessage = "";
  List<RecordModel> _notebooks = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get errorOccurred => _errorOccurred;
  String get errorMessage => _errorMessage;
  List<RecordModel> get notebooks => _notebooks;

  // Constructor
  PocketBaseLibraryNotifier(this.pb);

  // load notebooks
  Future<void> loadNotebooks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notebooks = await pb.collection('notebooks').getFullList();
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      _notebooks = [];
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
}
