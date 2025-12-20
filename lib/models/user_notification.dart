/// Model representing a notification sent to a user
class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.general,
  });

  final String id;
  final String title;
  final String message;
  final String senderId;     // Pharmacist or Admin who sent it
  final String senderName;
  final String recipientId;  // Patient receiving the notification
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  UserNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? senderId,
    String? senderName,
    String? recipientId,
    DateTime? createdAt,
    bool? isRead,
    NotificationType? type,
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      recipientId: map['recipientId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.general,
      ),
    );
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of notifications
enum NotificationType {
  general,       // General message
  reminder,      // Medication reminder from pharmacist
  alert,         // Important health alert
  education,     // Educational content
}
