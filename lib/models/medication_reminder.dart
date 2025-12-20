import 'package:flutter/material.dart';

/// Model representing a medication reminder with scheduled times
class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.drugId,
    required this.brandName,
    required this.scheduledTimes,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7], // Default: every day
    this.isEnabled = true,
    this.dosage = '1 tablet',
  });

  final String id;
  final String drugId;
  final String brandName;
  final List<TimeOfDay> scheduledTimes;
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday
  final bool isEnabled;
  final String dosage;

  MedicationReminder copyWith({
    String? id,
    String? drugId,
    String? brandName,
    List<TimeOfDay>? scheduledTimes,
    List<int>? daysOfWeek,
    bool? isEnabled,
    String? dosage,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      drugId: drugId ?? this.drugId,
      brandName: brandName ?? this.brandName,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      dosage: dosage ?? this.dosage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drugId': drugId,
      'brandName': brandName,
      'scheduledTimes': scheduledTimes.map((t) => '${t.hour}:${t.minute}').toList(),
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
      'dosage': dosage,
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    final times = (map['scheduledTimes'] as List? ?? []).map((t) {
      final parts = t.toString().split(':');
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    }).toList();

    return MedicationReminder(
      id: map['id'] ?? '',
      drugId: map['drugId'] ?? '',
      brandName: map['brandName'] ?? '',
      scheduledTimes: times,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? [1, 2, 3, 4, 5, 6, 7]),
      isEnabled: map['isEnabled'] ?? true,
      dosage: map['dosage'] ?? '1 tablet',
    );
  }

  /// Get formatted time string for display
  String getFormattedTimes() {
    if (scheduledTimes.isEmpty) return 'No times set';
    return scheduledTimes.map((t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }).join(', ');
  }

  /// Get formatted days string for display
  String getFormattedDays() {
    if (daysOfWeek.length == 7) return 'Every day';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
  }

  /// Check if reminder is active for a given day (1-7)
  bool isActiveOnDay(int day) => daysOfWeek.contains(day);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationReminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
