import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class PocketBaseAuthNotifier extends ChangeNotifier {
  PocketBase pb;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _errorOccurred = false;
  String _errorMessage = "";
  String _userId = "";

  // Getters
  bool get isLoading => _isLoading;
  bool get errorOccurred => _errorOccurred;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;

  // Constructor
  PocketBaseAuthNotifier(this.pb);

  // Sign in method
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorOccurred = false;
    _errorMessage = "";
    notifyListeners();

    try {
      await pb.collection('users').authWithPassword(email, password);
      notifyListeners();
      print('logged in');
      _isLoggedIn = true;
      _userId = await pb.authStore.model?.id;
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out method
  Future<void> signOut() async {
    _isLoading = true;
    _errorOccurred = false;
    _errorMessage = "";
    notifyListeners();

    try {
      pb.authStore.clear();
      notifyListeners();
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Sign up method
  Future<void> signUp(
      String email, String password, String passwordConfirm) async {
    _isLoading = true;
    _errorOccurred = false;
    _errorMessage = "";
    notifyListeners();

    final body = <String, dynamic>{
      "email": email,
      "password": password,
      "passwordConfirm": passwordConfirm,
      "emailVisibility": true,
    };

    try {
      await pb.collection('users').create(body: body);
      notifyListeners();
      print('logged in');
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Password reset mthod
  Future<void> passwordReset(String email) async {
    _isLoading = true;
    _errorOccurred = false;
    _errorMessage = "";
    notifyListeners();

    try {
      await pb.collection('users').requestPasswordReset(email);
      notifyListeners();
      print('logged in');
    } catch (error) {
      _errorOccurred = true;
      _errorMessage = error.toString();
      notifyListeners();
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
