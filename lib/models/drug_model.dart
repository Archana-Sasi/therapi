/// Model representing a respiratory medication
class DrugModel {
  const DrugModel({
    required this.id,
    required this.genericName,
    required this.brandNames,
    required this.diseases,
    required this.doseForm,
    required this.category,
    required this.description,
    required this.dosage,
    required this.sideEffects,
    required this.precautions,
  });

  final String id;
  final String genericName;
  final List<String> brandNames;
  final List<String> diseases; // asthma, copd, bronchitis, allergic_rhinitis, ild, pneumonia
  final String doseForm; // inhaler, tablet, syrup, injection, nebulizer
  final String category; // bronchodilator, corticosteroid, antihistamine, mucolytic, antibiotic, etc.
  final String description;
  final String dosage;
  final List<String> sideEffects;
  final List<String> precautions;

  /// Get display-friendly disease names
  static String getDiseaseDisplayName(String disease) {
    switch (disease) {
      case 'asthma':
        return 'Asthma';
      case 'copd':
        return 'COPD';
      case 'bronchitis':
        return 'Bronchitis';
      case 'allergic_rhinitis':
        return 'Allergic Rhinitis';
      case 'ild':
        return 'Interstitial Lung Disease';
      case 'pneumonia':
        return 'Pneumonia';
      default:
        return disease;
    }
  }

  /// Get display-friendly category names
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'bronchodilator':
        return 'Bronchodilator';
      case 'corticosteroid':
        return 'Corticosteroid';
      case 'antihistamine':
        return 'Antihistamine';
      case 'mucolytic':
        return 'Mucolytic';
      case 'antibiotic':
        return 'Antibiotic';
      case 'leukotriene_modifier':
        return 'Leukotriene Modifier';
      case 'anticholinergic':
        return 'Anticholinergic';
      case 'combination':
        return 'Combination Therapy';
      case 'antifibrotic':
        return 'Antifibrotic';
      case 'immunosuppressant':
        return 'Immunosuppressant';
      default:
        return category;
    }
  }
}
