/// Model representing a medication
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
  final List<String> diseases;
  final String doseForm;
  final String category;
  final String description;
  final String dosage;
  final List<String> sideEffects;
  final List<String> precautions;

  /// Get display-friendly disease names
  static String getDiseaseDisplayName(String disease) {
    switch (disease) {
      // Respiratory
      case 'asthma': return 'Asthma';
      case 'copd': return 'COPD';
      case 'bronchitis': return 'Bronchitis';
      case 'allergic_rhinitis': return 'Allergic Rhinitis';
      case 'ild': return 'Interstitial Lung Disease';
      case 'pneumonia': return 'Pneumonia';
      // Cardiovascular
      case 'hypertension': return 'Hypertension';
      case 'heart_disease': return 'Heart Disease';
      case 'arrhythmia': return 'Arrhythmia';
      case 'hyperlipidemia': return 'High Cholesterol';
      // Metabolic
      case 'diabetes': return 'Diabetes';
      case 'thyroid': return 'Thyroid Disorders';
      // Gastrointestinal
      case 'gerd': return 'GERD/Acid Reflux';
      case 'ulcer': return 'Peptic Ulcer';
      case 'ibs': return 'IBS';
      // Pain & Inflammation
      case 'pain': return 'Pain';
      case 'fever': return 'Fever';
      case 'arthritis': return 'Arthritis';
      case 'migraine': return 'Migraine';
      // Infections
      case 'bacterial_infection': return 'Bacterial Infection';
      case 'fungal_infection': return 'Fungal Infection';
      case 'viral_infection': return 'Viral Infection';
      // Mental Health
      case 'depression': return 'Depression';
      case 'anxiety': return 'Anxiety';
      case 'insomnia': return 'Insomnia';
      // Other
      case 'allergy': return 'Allergy';
      case 'skin': return 'Skin Conditions';
      case 'general': return 'General';
      default: return disease;
    }
  }

  /// Get display-friendly category names
  static String getCategoryDisplayName(String category) {
    switch (category) {
      // Respiratory
      case 'bronchodilator': return 'Bronchodilator';
      case 'corticosteroid': return 'Corticosteroid';
      case 'mucolytic': return 'Mucolytic';
      case 'anticholinergic': return 'Anticholinergic';
      case 'antifibrotic': return 'Antifibrotic';
      case 'leukotriene_modifier': return 'Leukotriene Modifier';
      // Anti-infective
      case 'antibiotic': return 'Antibiotic';
      case 'antifungal': return 'Antifungal';
      case 'antiviral': return 'Antiviral';
      // Cardiovascular
      case 'antihypertensive': return 'Antihypertensive';
      case 'beta_blocker': return 'Beta Blocker';
      case 'calcium_channel_blocker': return 'Calcium Channel Blocker';
      case 'ace_inhibitor': return 'ACE Inhibitor';
      case 'arb': return 'ARB';
      case 'diuretic': return 'Diuretic';
      case 'statin': return 'Statin';
      case 'antiplatelet': return 'Antiplatelet';
      case 'anticoagulant': return 'Anticoagulant';
      // Metabolic
      case 'antidiabetic': return 'Antidiabetic';
      case 'insulin': return 'Insulin';
      case 'thyroid_hormone': return 'Thyroid Hormone';
      // GI
      case 'ppi': return 'Proton Pump Inhibitor';
      case 'h2_blocker': return 'H2 Blocker';
      case 'antacid': return 'Antacid';
      case 'antiemetic': return 'Antiemetic';
      case 'laxative': return 'Laxative';
      // Pain & Inflammation
      case 'analgesic': return 'Analgesic';
      case 'nsaid': return 'NSAID';
      case 'opioid': return 'Opioid';
      case 'muscle_relaxant': return 'Muscle Relaxant';
      // Allergy
      case 'antihistamine': return 'Antihistamine';
      // Mental Health
      case 'antidepressant': return 'Antidepressant';
      case 'anxiolytic': return 'Anxiolytic';
      case 'antipsychotic': return 'Antipsychotic';
      case 'sedative': return 'Sedative';
      // Other
      case 'vitamin': return 'Vitamin/Supplement';
      case 'combination': return 'Combination Therapy';
      case 'immunosuppressant': return 'Immunosuppressant';
      default: return category;
    }
  }
}
