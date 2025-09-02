import 'package:anidong/data/services/auth_service.dart';
import 'package:flutter/material.dart';

enum AuthState { initial, authenticated, unauthenticated, authenticating, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  String? _authToken;
  String _errorMessage = '';

  AuthState get state => _state;
  String? get authToken => _authToken;
  String get errorMessage => _errorMessage;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _state = AuthState.authenticating;
    notifyListeners();
    try {
      _authToken = await _authService.getAuthToken();
      if (_authToken != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _state = AuthState.authenticating;
    notifyListeners();
    try {
      _authToken = await _authService.signInWithGoogle();
      if (_authToken != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated; // User cancelled login
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = AuthState.error;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _state = AuthState.authenticating;
    notifyListeners();
    try {
      await _authService.signOut();
      _authToken = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = AuthState.error;
    }
    notifyListeners();
  }
}
