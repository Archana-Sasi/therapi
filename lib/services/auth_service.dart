import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

/// Firebase Authentication service for login, signup, Google sign-in, and password reset.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs in a user with email and password.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user!);
  }

  /// Creates a new user account with email, password, and full name.
  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(fullName);
    
    final userModel = UserModel(
      id: credential.user!.uid,
      email: email,
      fullName: fullName,
      role: 'patient',
    );
    
    // Try to save to Firestore, but don't fail if unavailable
    await _trySaveUserToFirestore(userModel);
    return userModel;
  }

  /// Signs in with Google.
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    
    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? 'User',
      photoUrl: user.photoURL,
      role: 'patient',
    );
    
    // Try to save to Firestore, but don't fail if unavailable
    await _trySaveUserToFirestore(userModel);
    return userModel;
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Returns the currently signed-in user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Maps a Firebase User to our UserModel.
  UserModel _mapFirebaseUser(User user, {String? fullName}) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      fullName: fullName ?? user.displayName ?? 'User',
      photoUrl: user.photoURL,
      role: 'patient',
    );
  }

  /// Tries to save user data to Firestore, silently fails if unavailable.
  Future<void> _trySaveUserToFirestore(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      // Firestore not available, continue without it
      print('Firestore unavailable: $e');
    }
  }

  /// Gets user profile from Firestore (returns null if unavailable).
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Firestore unavailable: $e');
    }
    // Fall back to Firebase Auth data
    final user = _auth.currentUser;
    if (user != null) {
      return _mapFirebaseUser(user);
    }
    return null;
  }

  /// Updates user profile in Firestore.
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      print('Firestore unavailable: $e');
    }
  }
}
