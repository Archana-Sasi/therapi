/// Model representing a medication intake log entry
class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.reminderId,
    required this.drugId,
    required this.brandName,
    required this.scheduledTime,
    required this.date,
    this.actualTime,
    this.status = MedicationStatus.pending,
  });

  final String id;
  final String reminderId;
  final String drugId;
  final String brandName;
  final DateTime scheduledTime;
  final DateTime date;
  final DateTime? actualTime;
  final MedicationStatus status;

  MedicationLog copyWith({
    String? id,
    String? reminderId,
    String? drugId,
    String? brandName,
    DateTime? scheduledTime,
    DateTime? date,
    DateTime? actualTime,
    MedicationStatus? status,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      drugId: drugId ?? this.drugId,
      brandName: brandName ?? this.brandName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      date: date ?? this.date,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderId': reminderId,
      'drugId': drugId,
      'brandName': brandName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'date': date.toIso8601String(),
      'actualTime': actualTime?.toIso8601String(),
      'status': status.name,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] ?? '',
      reminderId: map['reminderId'] ?? '',
      drugId: map['drugId'] ?? '',
      brandName: map['brandName'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime']),
      date: DateTime.parse(map['date']),
      actualTime: map['actualTime'] != null ? DateTime.parse(map['actualTime']) : null,
      status: MedicationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => MedicationStatus.pending,
      ),
    );
  }

  /// Check if this log is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if medication is overdue (past scheduled time and still pending)
  bool get isOverdue {
    if (status != MedicationStatus.pending) return false;
    return DateTime.now().isAfter(scheduledTime);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Status of a medication log entry
enum MedicationStatus {
  pending,
  taken,
  missed,
  skipped,
}
