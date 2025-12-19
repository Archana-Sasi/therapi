/// Model representing a symptom log entry
class SymptomLog {
  const SymptomLog({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.breathlessness = 0,
    this.cough = 0,
    this.wheezing = 0,
    this.chestTightness = 0,
    this.fatigue = 0,
    this.notes = '',
  });

  final String id;
  final String userId;
  final DateTime timestamp;
  final int breathlessness; // 0-5 severity scale
  final int cough; // 0-5 severity scale
  final int wheezing; // 0-5 severity scale
  final int chestTightness; // 0-5 severity scale
  final int fatigue; // 0-5 severity scale
  final String notes;

  /// Returns overall severity (average of all symptoms)
  double get overallSeverity {
    final total = breathlessness + cough + wheezing + chestTightness + fatigue;
    return total / 5;
  }

  /// Returns severity label based on overall score
  String get severityLabel {
    final avg = overallSeverity;
    if (avg == 0) return 'None';
    if (avg < 2) return 'Mild';
    if (avg < 3) return 'Moderate';
    if (avg < 4) return 'Severe';
    return 'Very Severe';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'breathlessness': breathlessness,
      'cough': cough,
      'wheezing': wheezing,
      'chestTightness': chestTightness,
      'fatigue': fatigue,
      'notes': notes,
    };
  }

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    return SymptomLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      breathlessness: map['breathlessness'] ?? 0,
      cough: map['cough'] ?? 0,
      wheezing: map['wheezing'] ?? 0,
      chestTightness: map['chestTightness'] ?? 0,
      fatigue: map['fatigue'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }

  SymptomLog copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    int? breathlessness,
    int? cough,
    int? wheezing,
    int? chestTightness,
    int? fatigue,
    String? notes,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      breathlessness: breathlessness ?? this.breathlessness,
      cough: cough ?? this.cough,
      wheezing: wheezing ?? this.wheezing,
      chestTightness: chestTightness ?? this.chestTightness,
      fatigue: fatigue ?? this.fatigue,
      notes: notes ?? this.notes,
    );
  }
}
