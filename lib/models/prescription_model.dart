import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/prescription_expiry.dart';

class PrescriptionItem {
  PrescriptionItem({
    required this.drugId,
    required this.genericName,
    required this.brandName,
    required this.dosage,
    required this.duration,
    this.instructions = '',
    this.morning = 0.0,
    this.afternoon = 0.0,
    this.evening = 0.0,
    this.night = 0.0,
    this.beforeFood = true,
    this.frequency = 'Daily',
    this.foodTiming = 'Before food',
  });

  final String drugId;
  final String genericName;
  final String brandName;
  final String dosage;
  final String duration;
  final String instructions;
  final double morning;
  final double afternoon;
  final double evening;
  final double night;
  final bool beforeFood;
  final String frequency;
  final String foodTiming;

  Map<String, dynamic> toMap() {
    return {
      'drugId': drugId,
      'genericName': genericName,
      'brandName': brandName,
      'dosage': dosage,
      'duration': duration,
      'instructions': instructions,
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'night': night,
      'beforeFood': beforeFood,
      'frequency': frequency,
      'foodTiming': foodTiming,
    };
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      drugId: map['drugId'] ?? '',
      genericName: map['genericName'] ?? '',
      brandName: map['brandName'] ?? '',
      dosage: map['dosage'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'] ?? '',
      morning: _parseTabletCount(map['morning']),
      afternoon: _parseTabletCount(map['afternoon']),
      evening: _parseTabletCount(map['evening']),
      night: _parseTabletCount(map['night']),
      beforeFood: map['beforeFood'] ?? true,
      frequency: map['frequency'] ?? 'Daily',
      foodTiming: map['foodTiming'] ?? (map['beforeFood'] == true ? 'Before food' : 'After food'),
    );
  }

  static double _parseTabletCount(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String getReadableDosage(double val) {
    if (val == 0) return '0';
    if (val == 0.5) return '½ tablet';
    if (val == 1.0) return '1 tablet';
    if (val == 1.5) return '1½ tablets';
    if (val == 2.0) return '2 tablets';
    if (val == 2.5) return '2½ tablets';
    if (val == 3.0) return '3 tablets';
    // Fallback if someone enters something unusual
    bool isInteger = val == val.roundToDouble();
    return '${isInteger ? val.toInt() : val} tablet${val > 1 ? 's' : ''}';
  }
}

/// Model representing a medical prescription (can contain multiple medications)
class Prescription {
  Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacistId,
    required this.pharmacistName,
    required this.createdAt,
    DateTime? expiryDate,
    this.isActive = true,
    this.doctorId,
    this.doctorName,
    this.status = 'approved',
    this.rejectionReason,
    this.medications = const [],
    // Clinical / consultation-note fields
    this.complaints = '',
    this.examination = '',
    this.diagnoses = const [],
    this.department = '',
    this.patientAge,
    this.patientGender,
    this.patientOpNumber,
    this.visitType = 'Outpatient',
    this.visitId,
    this.advice = '',
    this.followUpNotes = '',
    // Legacy single-drug fields (kept for backward compat)
    this.drugId = '',
    this.genericName = '',
    this.brandName = '',
    this.dosage = '',
    this.instructions = '',
    this.duration = '',
    this.morning = 0.0,
    this.afternoon = 0.0,
    this.evening = 0.0,
    this.night = 0.0,
    this.beforeFood = true,
  }) : _expiryDate = expiryDate;

  final String id;
  final String patientId;
  final String patientName;
  final String pharmacistId;
  final String pharmacistName;
  final DateTime createdAt;
  /// When this prescription expires. Defaults to createdAt + 30 days.
  final DateTime? _expiryDate;
  DateTime get expiryDate => _expiryDate ?? createdAt.add(const Duration(days: 30));
  final bool isActive;
  final String? doctorId;
  final String? doctorName;
  final String status;
  final String? rejectionReason;
  final List<PrescriptionItem> medications;

  // Clinical / consultation-note fields
  final String complaints;
  final String examination;
  final List<String> diagnoses;
  final String department;
  final int? patientAge;
  final String? patientGender;
  final String? patientOpNumber;
  final String visitType;
  final String? visitId;
  final String advice;
  final String followUpNotes;

  // Legacy single-drug fields
  final String drugId;
  final String genericName;
  final String brandName;
  final String dosage;
  final String instructions;
  final String duration;
  final double morning;
  final double afternoon;
  final double evening;
  final double night;
  final bool beforeFood;

  // ---- Expiry helpers ----

  /// Whether the prescription has expired.
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Number of days since the prescription expired (0 if still valid).
  int get daysSinceExpiry => PrescriptionExpiryHelper.getDaysSinceExpiry(expiryDate);

  /// The escalation level based on how long the prescription has been expired.
  PrescriptionExpiryLevel get expiryLevel =>
      PrescriptionExpiryHelper.getExpiryLevel(expiryDate);

  /// Returns medications list — if empty, falls back to legacy single-drug fields
  List<PrescriptionItem> get effectiveMedications {
    if (medications.isNotEmpty) return medications;
    if (genericName.isEmpty) return [];
    return [
      PrescriptionItem(
        drugId: drugId,
        genericName: genericName,
        brandName: brandName,
        dosage: dosage,
        duration: duration,
        instructions: instructions,
        morning: morning,
        afternoon: afternoon,
        evening: evening,
        night: night,
        beforeFood: beforeFood,
      ),
    ];
  }

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? pharmacistId,
    String? pharmacistName,
    DateTime? createdAt,
    DateTime? expiryDate,
    bool? isActive,
    String? doctorId,
    String? doctorName,
    String? status,
    String? rejectionReason,
    List<PrescriptionItem>? medications,
    String? complaints,
    String? examination,
    List<String>? diagnoses,
    String? department,
    int? patientAge,
    String? patientGender,
    String? patientOpNumber,
    String? visitType,
    String? visitId,
    String? advice,
    String? followUpNotes,
    String? drugId,
    String? genericName,
    String? brandName,
    String? dosage,
    String? instructions,
    String? duration,
    double? morning,
    double? afternoon,
    double? evening,
    double? night,
    bool? beforeFood,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      pharmacistId: pharmacistId ?? this.pharmacistId,
      pharmacistName: pharmacistName ?? this.pharmacistName,
      createdAt: createdAt ?? this.createdAt,
      expiryDate: expiryDate ?? _expiryDate,
      isActive: isActive ?? this.isActive,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      medications: medications ?? this.medications,
      complaints: complaints ?? this.complaints,
      examination: examination ?? this.examination,
      diagnoses: diagnoses ?? this.diagnoses,
      department: department ?? this.department,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientOpNumber: patientOpNumber ?? this.patientOpNumber,
      visitType: visitType ?? this.visitType,
      visitId: visitId ?? this.visitId,
      advice: advice ?? this.advice,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      drugId: drugId ?? this.drugId,
      genericName: genericName ?? this.genericName,
      brandName: brandName ?? this.brandName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      duration: duration ?? this.duration,
      morning: morning ?? this.morning,
      afternoon: afternoon ?? this.afternoon,
      evening: evening ?? this.evening,
      night: night ?? this.night,
      beforeFood: beforeFood ?? this.beforeFood,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'pharmacistId': pharmacistId,
      'pharmacistName': pharmacistName,
      'createdAt': createdAt.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'status': status,
      'rejectionReason': rejectionReason,
      'medications': medications.map((m) => m.toMap()).toList(),
      'complaints': complaints,
      'examination': examination,
      'diagnoses': diagnoses,
      'department': department,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientOpNumber': patientOpNumber,
      'visitType': visitType,
      'visitId': visitId,
      'advice': advice,
      'followUpNotes': followUpNotes,
      // Legacy fields
      'drugId': drugId,
      'genericName': genericName,
      'brandName': brandName,
      'dosage': dosage,
      'instructions': instructions,
      'duration': duration,
      'morning': morning,
      'afternoon': afternoon,
      'evening': evening,
      'night': night,
      'beforeFood': beforeFood,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    List<PrescriptionItem> meds = [];
    if (map['medications'] != null && map['medications'] is List) {
      meds = (map['medications'] as List)
          .map((m) => PrescriptionItem.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }

    return Prescription(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      pharmacistId: map['pharmacistId'] ?? '',
      pharmacistName: map['pharmacistName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,  // will default to createdAt + 30 days via getter
      isActive: map['isActive'] ?? true,
      doctorId: map['doctorId'],
      doctorName: map['doctorName'],
      status: map['status'] ?? 'approved',
      rejectionReason: map['rejectionReason'],
      medications: meds,
      complaints: map['complaints'] ?? '',
      examination: map['examination'] ?? '',
      diagnoses: map['diagnoses'] != null
          ? List<String>.from(map['diagnoses'])
          : const [],
      department: map['department'] ?? '',
      patientAge: map['patientAge'] as int?,
      patientGender: map['patientGender'] as String?,
      patientOpNumber: map['patientOpNumber'] as String?,
      visitType: map['visitType'] ?? 'Outpatient',
      visitId: map['visitId'] as String?,
      advice: map['advice'] ?? '',
      followUpNotes: map['followUpNotes'] ?? '',
      drugId: map['drugId'] ?? '',
      genericName: map['genericName'] ?? '',
      brandName: map['brandName'] ?? '',
      dosage: map['dosage'] ?? '',
      instructions: map['instructions'] ?? '',
      duration: map['duration'] ?? '',
      morning: _parseTabletCount(map['morning']),
      afternoon: _parseTabletCount(map['afternoon']),
      evening: _parseTabletCount(map['evening']),
      night: _parseTabletCount(map['night']),
      beforeFood: map['beforeFood'] ?? true,
    );
  }

  static double _parseTabletCount(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

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
