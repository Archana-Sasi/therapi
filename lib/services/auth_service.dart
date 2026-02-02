import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/consultation.dart';
import '../models/custom_drug.dart';
import '../models/medication_log.dart';
import '../models/medication_reminder.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';
import '../models/user_notification.dart';

/// Firebase Authentication service for login, signup, Google sign-in, phone OTP, and password reset.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Phone OTP verification state
  String? _verificationId;
  int? _resendToken;
  
  /// Getter for verification ID (used by AuthProvider)
  String? get verificationId => _verificationId;

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

  // ============ PHONE OTP AUTHENTICATION ============

  /// Sends OTP to the given phone number
  /// [phoneNumber] should include country code (e.g., +919876543210)
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    required Function(UserModel user) onAutoVerified,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only - when SMS is auto-read)
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final user = userCredential.user!;
            
            // Check if user already exists in Firestore
            final existingUser = await getUserProfile(user.uid);
            if (existingUser != null) {
              onAutoVerified(existingUser);
            } else {
              // New user - create basic profile
              final userModel = UserModel(
                id: user.uid,
                email: '',
                fullName: 'User',
                phoneNumber: user.phoneNumber,
                role: 'patient',
              );
              await _trySaveUserToFirestore(userModel);
              onAutoVerified(userModel);
            }
          } catch (e) {
            onError('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String message = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            message = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded. Please try again later.';
          } else {
            message = e.message ?? 'Verification failed';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
    }
  }

  /// Verifies OTP and signs in the user
  /// Returns the user if successful, throws exception on failure
  Future<UserModel> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw Exception('No verification ID. Please request OTP first.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Check if user already exists in Firestore
    final existingUser = await getUserProfile(user.uid);
    if (existingUser != null) {
      return existingUser;
    }

    // New user - create basic profile (will complete profile later)
    final userModel = UserModel(
      id: user.uid,
      email: '',
      fullName: 'User',
      phoneNumber: user.phoneNumber,
      role: 'patient',
    );
    await _trySaveUserToFirestore(userModel);
    return userModel;
  }

  /// Creates/updates user profile after phone verification
  Future<UserModel> completePhoneSignup({
    required String fullName,
    String role = 'patient',
    int? age,
    String? gender,
    String? opNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user. Please verify OTP first.');
    }

    await user.updateDisplayName(fullName);

    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      fullName: fullName,
      phoneNumber: user.phoneNumber,
      role: role,
      age: age,
      gender: gender,
      opNumber: opNumber,
    );

    await _trySaveUserToFirestore(userModel);
    return userModel;
  }

  /// Checks if the current user has completed their profile
  Future<bool> isProfileComplete() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final profile = await getUserProfile(user.uid);
    if (profile == null) return false;

    // Profile is complete if fullName is set and not default
    return profile.fullName.isNotEmpty && profile.fullName != 'User';
  }

  /// Gets the resend token for resending OTP
  int? get resendToken => _resendToken;

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

  /// Updates specific user profile fields in Firestore.
  Future<void> updateUserProfileFields({
    required String uid,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['fullName'] = fullName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updateData);
      }
    } catch (e) {
      print('Firestore unavailable: $e');
      rethrow;
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

  /// Deletes a user from Firestore (for admin/pharmacist).
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      
      // Also delete user's reminders subcollection
      final remindersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .get();
      for (final doc in remindersSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete user's medication logs subcollection
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medication_logs')
          .get();
      for (final doc in logsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete user's notifications
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .get();
      for (final doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      print('Failed to delete user: $e');
      return false;
    }
  }

  /// Updates a user's role in Firestore (for admin).
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      return true;
    } catch (e) {
      print('Failed to update user role: $e');
      return false;
    }
  }

  /// Resets all medications for all patients (admin function)
  /// Clears: medications field, reminders subcollection, medication_logs subcollection
  Future<Map<String, dynamic>> resetAllPatientMedications() async {
    int patientsReset = 0;
    int remindersDeleted = 0;
    int logsDeleted = 0;

    try {
      // Get all patients
      final patientsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      for (final patientDoc in patientsSnapshot.docs) {
        final patientId = patientDoc.id;

        // Clear medications array in user document
        await _firestore.collection('users').doc(patientId).update({
          'medications': [],
        });

        // Delete all reminders
        final remindersSnapshot = await _firestore
            .collection('users')
            .doc(patientId)
            .collection('reminders')
            .get();
        for (final doc in remindersSnapshot.docs) {
          await doc.reference.delete();
          remindersDeleted++;
        }

        // Delete all medication logs
        final logsSnapshot = await _firestore
            .collection('users')
            .doc(patientId)
            .collection('medication_logs')
            .get();
        for (final doc in logsSnapshot.docs) {
          await doc.reference.delete();
          logsDeleted++;
        }

        patientsReset++;
      }

      return {
        'success': true,
        'patientsReset': patientsReset,
        'remindersDeleted': remindersDeleted,
        'logsDeleted': logsDeleted,
      };
    } catch (e) {
      print('Failed to reset patient medications: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
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

  // ============ MEDICATION REMINDER METHODS ============

  /// Saves a medication reminder to Firestore
  Future<bool> addMedicationReminder(MedicationReminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder.id)
          .set(reminder.toMap());
      return true;
    } catch (e) {
      print('Failed to add reminder: $e');
      return false;
    }
  }

  /// Updates an existing medication reminder
  Future<bool> updateMedicationReminder(MedicationReminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder.id)
          .update(reminder.toMap());
      return true;
    } catch (e) {
      print('Failed to update reminder: $e');
      return false;
    }
  }

  /// Deletes a medication reminder
  Future<bool> deleteMedicationReminder(String reminderId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminderId)
          .delete();
      return true;
    } catch (e) {
      print('Failed to delete reminder: $e');
      return false;
    }
  }

  /// Gets all medication reminders for the current user
  Future<List<MedicationReminder>> getMedicationReminders() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .get();
      return snapshot.docs
          .map((doc) => MedicationReminder.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get reminders: $e');
      return [];
    }
  }

  /// Gets a reminder for a specific drug
  Future<MedicationReminder?> getReminderForDrug(String drugId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .where('drugId', isEqualTo: drugId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return MedicationReminder.fromMap(snapshot.docs.first.data());
    } catch (e) {
      print('Failed to get reminder: $e');
      return null;
    }
  }

  // ============ MEDICATION LOG METHODS ============

  /// Logs a medication as taken
  Future<bool> logMedicationTaken(MedicationLog log) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medication_logs')
          .doc(log.id)
          .set(log.copyWith(
            status: MedicationStatus.taken,
            actualTime: DateTime.now(),
          ).toMap());
      return true;
    } catch (e) {
      print('Failed to log medication: $e');
      return false;
    }
  }

  /// Updates a medication log status
  Future<bool> updateMedicationLogStatus(String logId, MedicationStatus status) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Get the log details first (for missed medication notification)
      MedicationLog? log;
      if (status == MedicationStatus.missed) {
        final logDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medication_logs')
            .doc(logId)
            .get();
        if (logDoc.exists) {
          log = MedicationLog.fromMap(logDoc.data()!);
        }
      }

      final updateData = <String, dynamic>{'status': status.name};
      if (status == MedicationStatus.taken) {
        updateData['actualTime'] = DateTime.now().toIso8601String();
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medication_logs')
          .doc(logId)
          .update(updateData);

      // Notify pharmacists when medication is missed
      if (status == MedicationStatus.missed && log != null) {
        await _notifyPharmacistsOfMissedMedication(user.uid, log);
      }

      return true;
    } catch (e) {
      print('Failed to update log: $e');
      return false;
    }
  }

  /// Notifies all pharmacists when a patient misses their medication
  Future<void> _notifyPharmacistsOfMissedMedication(String patientId, MedicationLog log) async {
    try {
      // Get patient name
      final patientProfile = await getUserProfile(patientId);
      final patientName = patientProfile?.fullName ?? 'A patient';

      // Get all pharmacists
      final pharmacists = await getPharmacists();

      // Send notification to each pharmacist
      for (final pharmacist in pharmacists) {
        final notificationId = '${patientId}_missed_${DateTime.now().millisecondsSinceEpoch}';
        final notification = UserNotification(
          id: notificationId,
          title: '⚠️ Missed Medication Alert',
          message: '$patientName missed their ${log.brandName} scheduled at ${_formatTimeSimple(log.scheduledTime)}.',
          senderId: patientId,
          senderName: patientName,
          recipientId: pharmacist.id,
          createdAt: DateTime.now(),
          type: NotificationType.alert,
        );

        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .set(notification.toMap());
      }
    } catch (e) {
      print('Failed to notify pharmacists: $e');
    }
  }

  String _formatTimeSimple(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Checks for missed medications (5+ minutes overdue) and notifies pharmacists automatically
  Future<void> checkAndNotifyMissedMedications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));
      
      // Get today's logs
      final logs = await getTodaysMedicationLogs();
      
      for (final log in logs) {
        // Check if medication is overdue by 10+ minutes and not yet notified
        if (log.status == MedicationStatus.pending &&
            log.scheduledTime.isBefore(tenMinutesAgo) &&
            !log.notifiedPharmacist) {
          
          // Mark as missed and update notifiedPharmacist flag
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('medication_logs')
              .doc(log.id)
              .update({
                'status': MedicationStatus.missed.name,
                'notifiedPharmacist': true,
              });

          // Notify pharmacists
          await _notifyPharmacistsOfMissedMedication(user.uid, log);
        }
      }
    } catch (e) {
      print('Failed to check missed medications: $e');
    }
  }

  /// Creates medication logs for today based on reminders
  Future<void> generateTodaysLogs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayOfWeek = now.weekday; // 1=Monday, 7=Sunday

    try {
      final reminders = await getMedicationReminders();
      
      for (final reminder in reminders) {
        if (!reminder.isEnabled || !reminder.isActiveOnDay(dayOfWeek)) continue;

        for (final time in reminder.scheduledTimes) {
          final scheduledDateTime = DateTime(
            today.year,
            today.month,
            today.day,
            time.hour,
            time.minute,
          );
          
          final logId = '${reminder.id}_${today.toIso8601String()}_${time.hour}_${time.minute}';
          
          // Check if log already exists
          final existingLog = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('medication_logs')
              .doc(logId)
              .get();
          
          if (!existingLog.exists) {
            final log = MedicationLog(
              id: logId,
              reminderId: reminder.id,
              drugId: reminder.drugId,
              brandName: reminder.brandName,
              scheduledTime: scheduledDateTime,
              date: today,
              status: MedicationStatus.pending,
            );
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('medication_logs')
                .doc(logId)
                .set(log.toMap());
          }
        }
      }
    } catch (e) {
      print('Failed to generate logs: $e');
    }
  }

  /// Gets today's medication logs
  Future<List<MedicationLog>> getTodaysMedicationLogs() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();

    try {
      // Use simpler query to avoid composite index requirement
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medication_logs')
          .get();
      
      // Filter client-side for today's logs
      return snapshot.docs
          .map((doc) => MedicationLog.fromMap(doc.data()))
          .where((log) {
            final logDate = DateTime(log.date.year, log.date.month, log.date.day);
            return logDate.toIso8601String() == todayStr;
          })
          .toList();
    } catch (e) {
      print('Failed to get today\'s logs: $e');
      return [];
    }
  }

  /// Gets medication summary counts for today
  Future<Map<String, int>> getTodaysSummary() async {
    final logs = await getTodaysMedicationLogs();
    final now = DateTime.now();
    
    int taken = 0;
    int pending = 0;
    int missed = 0;

    for (final log in logs) {
      switch (log.status) {
        case MedicationStatus.taken:
          taken++;
          break;
        case MedicationStatus.missed:
          missed++;
          break;
        case MedicationStatus.pending:
          // Check if it's past the scheduled time
          if (now.isAfter(log.scheduledTime)) {
            missed++;
          } else {
            pending++;
          }
          break;
        case MedicationStatus.skipped:
          break;
      }
    }

    return {'taken': taken, 'pending': pending, 'missed': missed};
  }

  /// Gets all missed medication logs from all patients (for pharmacist dashboard)
  Future<List<Map<String, dynamic>>> getAllMissedMedicationLogs() async {
    try {
      // Get all patients
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      final List<Map<String, dynamic>> allMissed = [];

      // For each patient, get their missed medication logs
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final patientName = userData['fullName'] ?? 'Unknown Patient';

        // Get medication logs with status 'missed'
        final logsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medication_logs')
            .get();

        // Filter missed logs client-side (to avoid needing composite index)
        final missedLogs = logsSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['status'] == 'missed';
        });

        for (final logDoc in missedLogs) {
          final logData = logDoc.data();
          allMissed.add({
            'patientId': userId,
            'patientName': patientName,
            'opNumber': userData['opNumber'] ?? '',
            'phoneNumber': userData['phoneNumber'] ?? '',
            'age': userData['age'],
            'drugId': logData['drugId'] ?? '',
            'brandName': logData['brandName'] ?? '',
            'scheduledTime': logData['scheduledTime'],
            'date': logData['date'],
          });
        }
      }

      // Sort by date descending (most recent first)
      allMissed.sort((a, b) {
        final dateA = DateTime.tryParse(a['scheduledTime'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['scheduledTime'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      return allMissed;
    } catch (e) {
      print('Failed to get all missed medications: $e');
      return [];
    }
  }

  // ============ NOTIFICATION METHODS ============

  /// Sends a notification to a specific user
  Future<bool> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) return false;

    try {
      // Get sender's name
      final senderProfile = await getUserProfile(sender.uid);
      final senderName = senderProfile?.fullName ?? 'Pharmacist';

      final notificationId = '${sender.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final notification = UserNotification(
        id: notificationId,
        title: title,
        message: message,
        senderId: sender.uid,
        senderName: senderName,
        recipientId: recipientId,
        createdAt: DateTime.now(),
        type: type,
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap());
      return true;
    } catch (e) {
      print('Failed to send notification: $e');
      return false;
    }
  }

  /// Sends a notification to all patients
  Future<int> sendNotificationToAllPatients({
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) return 0;

    try {
      final allUsers = await getAllUsers();
      final patients = allUsers.where((u) => u.role == 'patient').toList();
      
      int sentCount = 0;
      for (final patient in patients) {
        final success = await sendNotification(
          recipientId: patient.id,
          title: title,
          message: message,
          type: type,
        );
        if (success) sentCount++;
      }
      return sentCount;
    } catch (e) {
      print('Failed to send notifications: $e');
      return 0;
    }
  }

  /// Gets notifications for the current user
  Future<List<UserNotification>> getMyNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Simple query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .get();
      
      // Sort client-side by createdAt descending
      final notifications = snapshot.docs
          .map((doc) => UserNotification.fromMap(doc.data()))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Return most recent 50
      return notifications.take(50).toList();
    } catch (e) {
      print('Failed to get notifications: $e');
      return [];
    }
  }

  /// Gets unread notification count for the current user
  Future<int> getUnreadNotificationCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      // Get all notifications for user, filter unread client-side
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .get();
      
      // Count unread
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isRead'] != true;
      }).length;
    } catch (e) {
      print('Failed to get notification count: $e');
      return 0;
    }
  }

  /// Marks a notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      return true;
    } catch (e) {
      print('Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Marks all notifications as read for the current user
  Future<bool> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Failed to mark all as read: $e');
      return false;
    }
  }

  /// Deletes a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      print('Failed to delete notification: $e');
      return false;
    }
  }

  // ============== CUSTOM DRUG MANAGEMENT ==============

  /// Adds a new custom drug to Firestore
  Future<bool> addCustomDrug(CustomDrug drug) async {
    try {
      final docRef = _firestore.collection('custom_drugs').doc();
      final drugWithId = drug.copyWith(id: docRef.id);
      await docRef.set(drugWithId.toMap());
      return true;
    } catch (e) {
      print('Failed to add custom drug: $e');
      return false;
    }
  }

  /// Gets all custom drugs from Firestore
  Future<List<CustomDrug>> getCustomDrugs() async {
    try {
      final snapshot = await _firestore
          .collection('custom_drugs')
          .where('isActive', isEqualTo: true)
          .orderBy('genericName')
          .get();
      return snapshot.docs
          .map((doc) => CustomDrug.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get custom drugs: $e');
      return [];
    }
  }

  /// Updates an existing custom drug
  Future<bool> updateCustomDrug(CustomDrug drug) async {
    try {
      await _firestore
          .collection('custom_drugs')
          .doc(drug.id)
          .update(drug.toMap());
      return true;
    } catch (e) {
      print('Failed to update custom drug: $e');
      return false;
    }
  }

  /// Deletes a custom drug (soft delete - sets isActive to false)
  Future<bool> deleteCustomDrug(String drugId) async {
    try {
      await _firestore
          .collection('custom_drugs')
          .doc(drugId)
          .update({'isActive': false});
      return true;
    } catch (e) {
      print('Failed to delete custom drug: $e');
      return false;
    }
  }

  // ============== PRESCRIPTION MANAGEMENT ==============

  /// Creates a new prescription
  Future<bool> createPrescription(Prescription prescription) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .set(prescription.toMap());
      return true;
    } catch (e) {
      print('Failed to create prescription: $e');
      return false;
    }
  }

  /// Gets all prescriptions created by the current pharmacist
  Future<List<Prescription>> getPrescriptionsByPharmacist() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('prescriptions')
          .where('pharmacistId', isEqualTo: user.uid)
          .get();
      
      final prescriptions = snapshot.docs
          .map((doc) => Prescription.fromMap(doc.data()))
          .toList();
      
      // Sort by createdAt descending
      prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prescriptions;
    } catch (e) {
      print('Failed to get prescriptions: $e');
      return [];
    }
  }

  /// Gets all prescriptions for a specific patient
  Future<List<Prescription>> getPrescriptionsForPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: patientId)
          .get();
      
      final prescriptions = snapshot.docs
          .map((doc) => Prescription.fromMap(doc.data()))
          .toList();
      
      // Sort by createdAt descending
      prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prescriptions;
    } catch (e) {
      print('Failed to get patient prescriptions: $e');
      return [];
    }
  }

  /// Updates an existing prescription
  Future<bool> updatePrescription(Prescription prescription) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescription.id)
          .update(prescription.toMap());
      return true;
    } catch (e) {
      print('Failed to update prescription: $e');
      return false;
    }
  }

  /// Deletes a prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .delete();
      return true;
    } catch (e) {
      print('Failed to delete prescription: $e');
      return false;
    }
  }

  /// Toggles prescription active status
  Future<bool> togglePrescriptionActive(String prescriptionId, bool isActive) async {
    try {
      await _firestore
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Failed to toggle prescription: $e');
      return false;
    }
  }

  // ============== CHAT METHODS ==============

  /// Gets all pharmacists (for patients to start a chat)
  Future<List<UserModel>> getPharmacists() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'pharmacist')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get pharmacists: $e');
      return [];
    }
  }

  /// Gets or creates a conversation between a patient and pharmacist
  Future<ChatConversation?> getOrCreateConversation({
    required String patientId,
    required String patientName,
    required String pharmacistId,
    required String pharmacistName,
  }) async {
    try {
      // Check if conversation already exists
      final existingSnapshot = await _firestore
          .collection('conversations')
          .where('patientId', isEqualTo: patientId)
          .where('pharmacistId', isEqualTo: pharmacistId)
          .limit(1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        return ChatConversation.fromMap(existingSnapshot.docs.first.data());
      }

      // Create new conversation
      final docRef = _firestore.collection('conversations').doc();
      final conversation = ChatConversation(
        id: docRef.id,
        patientId: patientId,
        patientName: patientName,
        pharmacistId: pharmacistId,
        pharmacistName: pharmacistName,
        createdAt: DateTime.now(),
      );

      await docRef.set(conversation.toMap());
      return conversation;
    } catch (e) {
      print('Failed to get/create conversation: $e');
      return null;
    }
  }

  /// Sends a message in a conversation
  Future<bool> sendMessage({
    required String conversationId,
    required String message,
    required String senderRole,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Get sender's name
      final userProfile = await getUserProfile(user.uid);
      final senderName = userProfile?.fullName ?? 'User';

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final chatMessage = ChatMessage(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: user.uid,
        senderName: senderName,
        senderRole: senderRole,
        message: message,
        timestamp: DateTime.now(),
      );

      await messageRef.set(chatMessage.toMap());

      // Update conversation with last message
      final unreadField = senderRole == 'patient' 
          ? 'unreadPharmacist' 
          : 'unreadPatient';

      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        unreadField: FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Failed to send message: $e');
      return false;
    }
  }

  /// Gets real-time stream of messages for a conversation
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .toList());
  }

  /// Gets all conversations for the current user
  Future<List<ChatConversation>> getUserConversations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get user's role
      final userProfile = await getUserProfile(user.uid);
      final role = userProfile?.role ?? 'patient';

      final fieldName = role == 'patient' ? 'patientId' : 'pharmacistId';
      
      final snapshot = await _firestore
          .collection('conversations')
          .where(fieldName, isEqualTo: user.uid)
          .get();

      final conversations = snapshot.docs
          .map((doc) => ChatConversation.fromMap(doc.data()))
          .toList();

      // Sort by lastMessageTime descending
      conversations.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt ?? DateTime(2000);
        final bTime = b.lastMessageTime ?? b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return conversations;
    } catch (e) {
      print('Failed to get conversations: $e');
      return [];
    }
  }

  /// Marks messages as read for the current user
  Future<void> markConversationAsRead(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get user's role
      final userProfile = await getUserProfile(user.uid);
      final role = userProfile?.role ?? 'patient';
      
      final unreadField = role == 'patient' ? 'unreadPatient' : 'unreadPharmacist';

      await _firestore.collection('conversations').doc(conversationId).update({
        unreadField: 0,
      });

      // Mark all messages as read
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        final senderId = doc.data()['senderId'];
        if (senderId != user.uid) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  // ============== CONSULTATION METHODS ==============

  /// Creates a new consultation request
  Future<bool> createConsultation(Consultation consultation) async {
    try {
      await _firestore
          .collection('consultations')
          .doc(consultation.id)
          .set(consultation.toMap());
      return true;
    } catch (e) {
      print('Failed to create consultation: $e');
      return false;
    }
  }

  /// Gets consultations for the current user
  Future<List<Consultation>> getUserConsultations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Get user's role
      final userProfile = await getUserProfile(user.uid);
      final role = userProfile?.role ?? 'patient';

      final fieldName = role == 'patient' ? 'patientId' : 'pharmacistId';
      
      final snapshot = await _firestore
          .collection('consultations')
          .where(fieldName, isEqualTo: user.uid)
          .get();

      final consultations = snapshot.docs
          .map((doc) => Consultation.fromMap(doc.data()))
          .toList();

      // Sort by requestedDate descending
      consultations.sort((a, b) => b.requestedDate.compareTo(a.requestedDate));

      return consultations;
    } catch (e) {
      print('Failed to get consultations: $e');
      return [];
    }
  }

  /// Updates consultation status
  Future<bool> updateConsultationStatus(
    String consultationId, 
    ConsultationStatus status, 
    {String? meetingLink}
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (meetingLink != null) {
        updateData['meetingLink'] = meetingLink;
      }

      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Failed to update consultation: $e');
      return false;
    }
  }

  /// Deletes a consultation
  Future<bool> deleteConsultation(String consultationId) async {
    try {
      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .delete();
      return true;
    } catch (e) {
      print('Failed to delete consultation: $e');
      return false;
    }
  }
}


