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
    // Fetch user profile from Firestore to get role
    final userProfile = await getUserProfile(credential.user!.uid);
    return userProfile ?? _mapFirebaseUser(credential.user!);
  }

  /// Creates a new user account with email, password, full name, and role.
  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    String role = 'patient',
    int? age,
    String? gender,
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
      role: role,
      age: age,
      gender: gender,
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

  /// Gets all users from Firestore (for admin/pharmacist dashboards).
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Firestore unavailable: $e');
      return [];
    }
  }

  /// Adds a medication with brand to the current user's medication list.
  Future<bool> addMedication(String drugId, String brandName) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'medications': FieldValue.arrayUnion([{
          'drugId': drugId,
          'brandName': brandName,
        }]),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Failed to add medication: $e');
      return false;
    }
  }

  /// Removes a medication from the current user's medication list.
  Future<bool> removeMedication(String drugId, String brandName) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'medications': FieldValue.arrayRemove([{
          'drugId': drugId,
          'brandName': brandName,
        }]),
      });
      return true;
    } catch (e) {
      print('Failed to remove medication: $e');
      return false;
    }
  }

  /// Checks if the current user is taking a specific medication.
  Future<bool> isUserTakingMedication(String drugId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final medications = doc.data()?['medications'] ?? [];
        if (medications is List) {
          for (final med in medications) {
            if (med is Map && med['drugId'] == drugId) {
              return true;
            }
            // Support old format (string only)
            if (med is String && med == drugId) {
              return true;
            }
          }
        }
      }
    } catch (e) {
      print('Failed to check medication: $e');
    }
    return false;
  }

  /// Gets the brand name the user is using for a specific drug.
  Future<String?> getUserMedicationBrand(String drugId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final medications = doc.data()?['medications'] ?? [];
        if (medications is List) {
          for (final med in medications) {
            if (med is Map && med['drugId'] == drugId) {
              return med['brandName'] as String?;
            }
          }
        }
      }
    } catch (e) {
      print('Failed to get medication brand: $e');
    }
    return null;
  }

  /// Gets the current user's medication list as maps.
  Future<List<Map<String, String>>> getCurrentUserMedications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final medications = doc.data()?['medications'] ?? [];
        if (medications is List) {
          return medications.map((med) {
            if (med is Map) {
              return {
                'drugId': (med['drugId'] ?? '').toString(),
                'brandName': (med['brandName'] ?? '').toString(),
              };
            }
            // Support old format
            return {'drugId': med.toString(), 'brandName': ''};
          }).toList();
        }
      }
    } catch (e) {
      print('Failed to get medications: $e');
    }
    return [];
  }
}

