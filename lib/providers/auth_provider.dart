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
  
  // Phone OTP state
  bool _otpSent = false;
  String? _phoneNumber;
  bool _needsProfileCompletion = false;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isInitializing => _initializing;
  bool get isOtpSent => _otpSent;
  String? get phoneNumber => _phoneNumber;
  bool get needsProfileCompletion => _needsProfileCompletion;

  /// Checks if user is already logged in from a previous session
  Future<void> _initializeAuth() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserProfile(currentUser.uid);
        // Check if profile needs completion (new phone users)
        if (_user != null && (_user!.fullName.isEmpty || _user!.fullName == 'User')) {
          _needsProfileCompletion = true;
        }
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

  // ============ PHONE OTP METHODS ============

  /// Sends OTP to the given phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function() onCodeSent,
    required Function(String error) onError,
  }) async {
    _setLoading(true);
    _phoneNumber = phoneNumber;
    
    await _authService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        _otpSent = true;
        _setLoading(false);
        notifyListeners();
        onCodeSent();
      },
      onError: (error) {
        _otpSent = false;
        _setLoading(false);
        notifyListeners();
        onError(error);
      },
      onAutoVerified: (user) {
        _user = user;
        _otpSent = false;
        _needsProfileCompletion = user.fullName.isEmpty || user.fullName == 'User';
        _setLoading(false);
        notifyListeners();
      },
      resendToken: _authService.resendToken,
    );
  }

  /// Verifies OTP and signs in the user
  Future<void> verifyOTP(String otp) async {
    _setLoading(true);
    try {
      _user = await _authService.verifyOTP(otp);
      _otpSent = false;
      _needsProfileCompletion = _user!.fullName.isEmpty || _user!.fullName == 'User';
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  /// Completes profile after phone verification
  Future<void> completePhoneSignup({
    required String fullName,
    String role = 'patient',
    int? age,
    String? gender,
    String? opNumber,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.completePhoneSignup(
        fullName: fullName,
        role: role,
        age: age,
        gender: gender,
        opNumber: opNumber,
      );
      _needsProfileCompletion = false;
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  /// Resets OTP state (when user wants to change phone number)
  void resetOtpState() {
    _otpSent = false;
    _phoneNumber = null;
    notifyListeners();
  }

  /// Checks if current user has completed their profile
  Future<bool> isProfileComplete() async {
    return await _authService.isProfileComplete();
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
    _otpSent = false;
    _phoneNumber = null;
    _needsProfileCompletion = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _user = await _authService.getUserProfile(currentUser.uid);
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _user == null) return;

    _setLoading(true);
    try {
      await _authService.updateUserProfileFields(
        uid: currentUser.uid,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      // Refresh user data after update
      _user = await _authService.getUserProfile(currentUser.uid);
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}


