/// Model representing a medical prescription created by a pharmacist for a patient
class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacistId,
    required this.pharmacistName,
    required this.drugId,
    required this.genericName,
    required this.brandName,
    required this.dosage,
    required this.instructions,
    required this.duration,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String pharmacistId;
  final String pharmacistName;
  final String drugId;
  final String genericName;
  final String brandName;
  final String dosage;
  final String instructions;
  final String duration;
  final DateTime createdAt;
  final bool isActive;

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? pharmacistId,
    String? pharmacistName,
    String? drugId,
    String? genericName,
    String? brandName,
    String? dosage,
    String? instructions,
    String? duration,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      pharmacistId: pharmacistId ?? this.pharmacistId,
      pharmacistName: pharmacistName ?? this.pharmacistName,
      drugId: drugId ?? this.drugId,
      genericName: genericName ?? this.genericName,
      brandName: brandName ?? this.brandName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'pharmacistId': pharmacistId,
      'pharmacistName': pharmacistName,
      'drugId': drugId,
      'genericName': genericName,
      'brandName': brandName,
      'dosage': dosage,
      'instructions': instructions,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      pharmacistId: map['pharmacistId'] ?? '',
      pharmacistName: map['pharmacistName'] ?? '',
      drugId: map['drugId'] ?? '',
      genericName: map['genericName'] ?? '',
      brandName: map['brandName'] ?? '',
      dosage: map['dosage'] ?? '',
      instructions: map['instructions'] ?? '',
      duration: map['duration'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Get formatted date for display
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get time ago string for display
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formattedDate;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prescription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
