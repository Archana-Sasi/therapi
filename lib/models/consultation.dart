import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a video consultation request.
enum ConsultationStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

/// Model representing a video consultation between a patient and pharmacist.
class Consultation {
  const Consultation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacistId,
    required this.pharmacistName,
    required this.requestedDate,
    required this.requestedTime,
    this.status = ConsultationStatus.pending,
    this.notes = '',
    this.meetingLink,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String pharmacistId;
  final String pharmacistName;
  final DateTime requestedDate;
  final String requestedTime; // e.g., "10:30 AM"
  final ConsultationStatus status;
  final String notes;
  final String? meetingLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'pharmacistId': pharmacistId,
      'pharmacistName': pharmacistName,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'requestedTime': requestedTime,
      'status': status.name,
      'notes': notes,
      'meetingLink': meetingLink,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      pharmacistId: map['pharmacistId'] ?? '',
      pharmacistName: map['pharmacistName'] ?? '',
      requestedDate: map['requestedDate'] != null
          ? (map['requestedDate'] as Timestamp).toDate()
          : DateTime.now(),
      requestedTime: map['requestedTime'] ?? '',
      status: ConsultationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ConsultationStatus.pending,
      ),
      notes: map['notes'] ?? '',
      meetingLink: map['meetingLink'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Consultation copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? pharmacistId,
    String? pharmacistName,
    DateTime? requestedDate,
    String? requestedTime,
    ConsultationStatus? status,
    String? notes,
    String? meetingLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consultation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      pharmacistId: pharmacistId ?? this.pharmacistId,
      pharmacistName: pharmacistName ?? this.pharmacistName,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if consultation is upcoming (not completed/cancelled)
  bool get isUpcoming => 
      status == ConsultationStatus.pending || 
      status == ConsultationStatus.confirmed;

  /// Check if consultation can be joined (confirmed and has meeting link)
  bool get canJoin => 
      status == ConsultationStatus.confirmed && 
      meetingLink != null && 
      meetingLink!.isNotEmpty;

  /// Get status color
  int get statusColor {
    switch (status) {
      case ConsultationStatus.pending:
        return 0xFFFF9800; // Orange
      case ConsultationStatus.confirmed:
        return 0xFF4CAF50; // Green
      case ConsultationStatus.completed:
        return 0xFF2196F3; // Blue
      case ConsultationStatus.cancelled:
        return 0xFFF44336; // Red
    }
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.confirmed:
        return 'Confirmed';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Format the requested date for display
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${requestedDate.day} ${months[requestedDate.month - 1]} ${requestedDate.year}';
  }
}
