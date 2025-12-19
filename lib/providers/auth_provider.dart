import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService {
    // Automatically check for existing login session on startup
    _initializeAuth();
  }

  final AuthService _authService;
  UserModel? _user;
  bool _loading = false;
  bool _initializing = true;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isInitializing => _initializing;

  /// Checks if user is already logged in from a previous session
  Future<void> _initializeAuth() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserProfile(currentUser.uid);
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email: email, password: password);
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> signup(
    String fullName, 
    String email, 
    String password, {
    String role = 'patient',
    int? age,
    String? gender,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.signup(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        age: age,
        gender: gender,
      );
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithGoogle();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _user = await _authService.getUserProfile(currentUser.uid);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

