import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a chat conversation between a patient and pharmacist.
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.pharmacistId,
    required this.pharmacistName,
    this.lastMessage = '',
    this.lastMessageTime,
    this.unreadPatient = 0,
    this.unreadPharmacist = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String pharmacistId;
  final String pharmacistName;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadPatient;
  final int unreadPharmacist;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'pharmacistId': pharmacistId,
      'pharmacistName': pharmacistName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : null,
      'unreadPatient': unreadPatient,
      'unreadPharmacist': unreadPharmacist,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      pharmacistId: map['pharmacistId'] ?? '',
      pharmacistName: map['pharmacistName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadPatient: map['unreadPatient'] ?? 0,
      unreadPharmacist: map['unreadPharmacist'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  ChatConversation copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? pharmacistId,
    String? pharmacistName,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadPatient,
    int? unreadPharmacist,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      pharmacistId: pharmacistId ?? this.pharmacistId,
      pharmacistName: pharmacistName ?? this.pharmacistName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadPatient: unreadPatient ?? this.unreadPatient,
      unreadPharmacist: unreadPharmacist ?? this.unreadPharmacist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get unread count for a specific user role
  int getUnreadCount(String userRole) {
    return userRole == 'patient' ? unreadPatient : unreadPharmacist;
  }

  /// Get the other participant's name based on current user role
  String getOtherParticipantName(String currentUserRole) {
    return currentUserRole == 'patient' ? pharmacistName : patientName;
  }

  /// Get the other participant's ID based on current user role
  String getOtherParticipantId(String currentUserRole) {
    return currentUserRole == 'patient' ? pharmacistId : patientId;
  }
}
