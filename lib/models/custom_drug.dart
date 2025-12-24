import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for custom drugs added by pharmacists/admins
class CustomDrug {
  const CustomDrug({
    required this.id,
    required this.genericName,
    required this.brandNames,
    required this.category,
    required this.doseForm,
    required this.description,
    this.dosage,
    this.sideEffects = const [],
    this.precautions = const [],
    this.diseases = const [],
    this.addedBy,
    this.addedAt,
    this.isActive = true,
  });

  final String id;
  final String genericName;
  final List<String> brandNames;
  final String category;
  final String doseForm;
  final String description;
  final String? dosage;
  final List<String> sideEffects;
  final List<String> precautions;
  final List<String> diseases;
  final String? addedBy;
  final DateTime? addedAt;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'genericName': genericName,
      'brandNames': brandNames,
      'category': category,
      'doseForm': doseForm,
      'description': description,
      'dosage': dosage,
      'sideEffects': sideEffects,
      'precautions': precautions,
      'diseases': diseases,
      'addedBy': addedBy,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  factory CustomDrug.fromMap(Map<String, dynamic> map) {
    return CustomDrug(
      id: map['id'] ?? '',
      genericName: map['genericName'] ?? '',
      brandNames: List<String>.from(map['brandNames'] ?? []),
      category: map['category'] ?? 'other',
      doseForm: map['doseForm'] ?? '',
      description: map['description'] ?? '',
      dosage: map['dosage'],
      sideEffects: List<String>.from(map['sideEffects'] ?? []),
      precautions: List<String>.from(map['precautions'] ?? []),
      diseases: List<String>.from(map['diseases'] ?? []),
      addedBy: map['addedBy'],
      addedAt: map['addedAt'] != null 
          ? (map['addedAt'] as Timestamp).toDate() 
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  CustomDrug copyWith({
    String? id,
    String? genericName,
    List<String>? brandNames,
    String? category,
    String? doseForm,
    String? description,
    String? dosage,
    List<String>? sideEffects,
    List<String>? precautions,
    List<String>? diseases,
    String? addedBy,
    DateTime? addedAt,
    bool? isActive,
  }) {
    return CustomDrug(
      id: id ?? this.id,
      genericName: genericName ?? this.genericName,
      brandNames: brandNames ?? this.brandNames,
      category: category ?? this.category,
      doseForm: doseForm ?? this.doseForm,
      description: description ?? this.description,
      dosage: dosage ?? this.dosage,
      sideEffects: sideEffects ?? this.sideEffects,
      precautions: precautions ?? this.precautions,
      diseases: diseases ?? this.diseases,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Drug category display names
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'bronchodilator':
        return 'Bronchodilator';
      case 'corticosteroid':
        return 'Corticosteroid';
      case 'anticholinergic':
        return 'Anticholinergic';
      case 'leukotriene_modifier':
        return 'Leukotriene Modifier';
      case 'antihistamine':
        return 'Antihistamine';
      case 'mucolytic':
        return 'Mucolytic';
      case 'combination':
        return 'Combination Therapy';
      case 'antibiotic':
        return 'Antibiotic';
      case 'antifibrotic':
        return 'Antifibrotic';
      default:
        return 'Other';
    }
  }
}
