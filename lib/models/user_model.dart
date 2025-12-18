import 'user_medication.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.role = 'patient',
    this.age,
    this.gender,
    this.medications = const [],
  });

  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String role; // patient, pharmacist, admin
  final int? age;
  final String? gender; // male, female, other
  final List<UserMedication> medications; // List of medications with brand names

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? photoUrl,
    String? role,
    int? age,
    String? gender,
    List<UserMedication>? medications,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      medications: medications ?? this.medications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'role': role,
      'age': age,
      'gender': gender,
      'medications': medications.map((m) => m.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final meds = map['medications'] ?? [];
    List<UserMedication> medicationsList;
    
    if (meds is List && meds.isNotEmpty) {
      // Check if it's the new format (list of maps) or old format (list of strings)
      if (meds.first is Map) {
        medicationsList = meds.map((m) => UserMedication.fromMap(m as Map<String, dynamic>)).toList();
      } else {
        // Migrate old format: string drugId -> UserMedication with empty brand
        medicationsList = meds.map((drugId) => UserMedication(
          drugId: drugId.toString(),
          brandName: '',
        )).toList();
      }
    } else {
      medicationsList = [];
    }
    
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'patient',
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      medications: medicationsList,
    );
  }
}


