import '../models/drug_model.dart';

/// Repository of respiratory medications organized by disease
class DrugData {
  /// All respiratory diseases covered in the app
  static const List<Map<String, dynamic>> diseases = [
    {
      'id': 'asthma',
      'name': 'Asthma',
      'icon': 'air',
      'description': 'Chronic inflammatory disease of the airways',
    },
    {
      'id': 'copd',
      'name': 'COPD',
      'icon': 'smoke_free',
      'description': 'Chronic Obstructive Pulmonary Disease',
    },
    {
      'id': 'bronchitis',
      'name': 'Bronchitis',
      'icon': 'healing',
      'description': 'Inflammation of the bronchial tubes',
    },
    {
      'id': 'allergic_rhinitis',
      'name': 'Allergic Rhinitis',
      'icon': 'grass',
      'description': 'Allergic inflammation of the nasal airways',
    },
    {
      'id': 'ild',
      'name': 'Interstitial Lung Disease',
      'icon': 'blur_on',
      'description': 'Group of disorders causing lung tissue scarring',
    },
    {
      'id': 'pneumonia',
      'name': 'Pneumonia',
      'icon': 'coronavirus',
      'description': 'Infection that inflames air sacs in lungs',
    },
  ];

  /// Get drugs filtered by disease
  static List<DrugModel> getDrugsByDisease(String diseaseId) {
    return drugs.where((drug) => drug.diseases.contains(diseaseId)).toList()
      ..sort((a, b) => a.genericName.compareTo(b.genericName));
  }

  /// Search drugs by name
  static List<DrugModel> searchDrugs(String query, {String? diseaseId}) {
    final lowerQuery = query.toLowerCase();
    var results = drugs.where((drug) {
      final matchesName = drug.genericName.toLowerCase().contains(lowerQuery) ||
          drug.brandNames.any((b) => b.toLowerCase().contains(lowerQuery));
      if (diseaseId != null) {
        return matchesName && drug.diseases.contains(diseaseId);
      }
      return matchesName;
    }).toList();
    results.sort((a, b) => a.genericName.compareTo(b.genericName));
    return results;
  }

  /// Get a drug by its ID
  static DrugModel? getDrugById(String id) {
    try {
      return drugs.firstWhere((drug) => drug.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Complete list of respiratory medications
  static const List<DrugModel> drugs = [
    // === BRONCHODILATORS ===
    DrugModel(
      id: 'salbutamol',
      genericName: 'Salbutamol',
      brandNames: ['Ventolin', 'Asthalin', 'Proventil'],
      diseases: ['asthma', 'copd', 'bronchitis'],
      doseForm: 'Inhaler / Nebulizer / Tablet',
      category: 'bronchodilator',
      description:
          'A short-acting beta-2 agonist (SABA) that relaxes airway muscles for quick relief of breathing difficulties.',
      dosage:
          'Inhaler: 1-2 puffs every 4-6 hours as needed. Nebulizer: 2.5mg every 4-6 hours. Tablet: 2-4mg 3-4 times daily.',
      sideEffects: [
        'Tremor',
        'Headache',
        'Palpitations',
        'Muscle cramps',
        'Nervousness'
      ],
      precautions: [
        'Use with caution in heart disease',
        'Monitor potassium levels',
        'Avoid overuse - seek medical help if needing more than 8 puffs/day'
      ],
    ),
    DrugModel(
      id: 'formoterol',
      genericName: 'Formoterol',
      brandNames: ['Foradil', 'Oxis', 'Perforomist'],
      diseases: ['asthma', 'copd'],
      doseForm: 'Inhaler / Nebulizer',
      category: 'bronchodilator',
      description:
          'A long-acting beta-2 agonist (LABA) providing 12-hour bronchodilation for maintenance therapy.',
      dosage:
          'Inhaler: 12mcg twice daily. Should not be used for acute symptoms.',
      sideEffects: [
        'Tremor',
        'Headache',
        'Palpitations',
        'Throat irritation'
      ],
      precautions: [
        'Never use as monotherapy in asthma',
        'Always use with inhaled corticosteroid',
        'Not for acute bronchospasm'
      ],
    ),
    DrugModel(
      id: 'salmeterol',
      genericName: 'Salmeterol',
      brandNames: ['Serevent', 'Salmeter'],
      diseases: ['asthma', 'copd'],
      doseForm: 'Inhaler',
      category: 'bronchodilator',
      description:
          'A long-acting beta-2 agonist (LABA) for twice-daily maintenance treatment.',
      dosage: '50mcg twice daily, approximately 12 hours apart.',
      sideEffects: ['Headache', 'Tremor', 'Palpitations', 'Muscle cramps'],
      precautions: [
        'Must be used with inhaled corticosteroid in asthma',
        'Not for acute relief',
        'May mask worsening asthma'
      ],
    ),
    DrugModel(
      id: 'theophylline',
      genericName: 'Theophylline',
      brandNames: ['Theo-Dur', 'Uniphyl', 'Deriphyllin'],
      diseases: ['asthma', 'copd'],
      doseForm: 'Tablet / Syrup',
      category: 'bronchodilator',
      description:
          'A methylxanthine bronchodilator that relaxes airway muscles and has mild anti-inflammatory effects.',
      dosage:
          'Initial: 300mg/day in divided doses. Maintenance: 400-600mg/day based on blood levels.',
      sideEffects: [
        'Nausea',
        'Headache',
        'Insomnia',
        'Tremor',
        'Seizures (at high levels)'
      ],
      precautions: [
        'Narrow therapeutic window - requires blood level monitoring',
        'Many drug interactions',
        'Avoid in liver disease'
      ],
    ),

    // === ANTICHOLINERGICS ===
    DrugModel(
      id: 'ipratropium',
      genericName: 'Ipratropium Bromide',
      brandNames: ['Atrovent', 'Ipravent'],
      diseases: ['copd', 'asthma', 'bronchitis'],
      doseForm: 'Inhaler / Nebulizer',
      category: 'anticholinergic',
      description:
          'A short-acting anticholinergic that blocks muscarinic receptors to relax airway muscles.',
      dosage:
          'Inhaler: 2 puffs 4 times daily. Nebulizer: 500mcg 3-4 times daily.',
      sideEffects: [
        'Dry mouth',
        'Bitter taste',
        'Headache',
        'Urinary retention'
      ],
      precautions: [
        'Use with caution in glaucoma',
        'Avoid contact with eyes',
        'Caution in prostate enlargement'
      ],
    ),
    DrugModel(
      id: 'tiotropium',
      genericName: 'Tiotropium',
      brandNames: ['Spiriva', 'Tiova'],
      diseases: ['copd', 'asthma'],
      doseForm: 'Inhaler',
      category: 'anticholinergic',
      description:
          'A long-acting anticholinergic bronchodilator providing 24-hour effect with once-daily dosing.',
      dosage: '18mcg once daily via HandiHaler or 2.5mcg via Respimat.',
      sideEffects: [
        'Dry mouth',
        'Constipation',
        'Urinary retention',
        'Blurred vision'
      ],
      precautions: [
        'Contraindicated in narrow-angle glaucoma',
        'Caution in prostatic hyperplasia',
        'Not for acute bronchospasm'
      ],
    ),

    // === CORTICOSTEROIDS ===
    DrugModel(
      id: 'budesonide',
      genericName: 'Budesonide',
      brandNames: ['Pulmicort', 'Budecort', 'Rhinocort'],
      diseases: ['asthma', 'copd', 'allergic_rhinitis'],
      doseForm: 'Inhaler / Nebulizer / Nasal Spray',
      category: 'corticosteroid',
      description:
          'An inhaled corticosteroid that reduces airway inflammation for long-term asthma control.',
      dosage:
          'Inhaler: 200-400mcg twice daily. Nebulizer: 0.5-1mg twice daily. Adjust based on severity.',
      sideEffects: [
        'Oral thrush',
        'Hoarseness',
        'Cough',
        'Growth suppression in children'
      ],
      precautions: [
        'Rinse mouth after use to prevent thrush',
        'Not for acute bronchospasm',
        'May suppress HPA axis at high doses'
      ],
    ),
    DrugModel(
      id: 'fluticasone',
      genericName: 'Fluticasone',
      brandNames: ['Flovent', 'Flonase', 'Flixotide'],
      diseases: ['asthma', 'copd', 'allergic_rhinitis'],
      doseForm: 'Inhaler / Nasal Spray',
      category: 'corticosteroid',
      description:
          'A potent inhaled corticosteroid for airway inflammation and allergic rhinitis.',
      dosage:
          'Inhaler: 100-500mcg twice daily based on severity. Nasal: 1-2 sprays per nostril daily.',
      sideEffects: [
        'Oral candidiasis',
        'Dysphonia',
        'Pharyngitis',
        'Nasal irritation'
      ],
      precautions: [
        'Rinse mouth after inhalation',
        'Monitor growth in children',
        'Increased risk of pneumonia in COPD'
      ],
    ),
    DrugModel(
      id: 'beclomethasone',
      genericName: 'Beclomethasone',
      brandNames: ['Qvar', 'Beconase', 'Beclate'],
      diseases: ['asthma', 'allergic_rhinitis'],
      doseForm: 'Inhaler / Nasal Spray',
      category: 'corticosteroid',
      description:
          'An inhaled corticosteroid that provides anti-inflammatory effects in the airways.',
      dosage:
          'Inhaler: 100-400mcg twice daily. Nasal: 1-2 sprays per nostril twice daily.',
      sideEffects: ['Throat irritation', 'Oral thrush', 'Hoarseness', 'Cough'],
      precautions: [
        'Use spacer device when possible',
        'Rinse mouth after use',
        'Regular use required for effect'
      ],
    ),
    DrugModel(
      id: 'prednisone',
      genericName: 'Prednisone',
      brandNames: ['Deltasone', 'Omnacortil', 'Rayos'],
      diseases: ['asthma', 'copd', 'ild'],
      doseForm: 'Tablet',
      category: 'corticosteroid',
      description:
          'An oral corticosteroid for acute exacerbations and severe inflammatory conditions.',
      dosage:
          'Acute: 40-60mg daily for 5-7 days. Chronic: Lowest effective dose with tapering.',
      sideEffects: [
        'Weight gain',
        'Mood changes',
        'Hyperglycemia',
        'Osteoporosis',
        'Immunosuppression'
      ],
      precautions: [
        'Taper gradually - do not stop abruptly',
        'Monitor blood sugar',
        'Consider bone protection for long-term use'
      ],
    ),

    // === LEUKOTRIENE MODIFIERS ===
    DrugModel(
      id: 'montelukast',
      genericName: 'Montelukast',
      brandNames: ['Singulair', 'Montair', 'Montek'],
      diseases: ['asthma', 'allergic_rhinitis'],
      doseForm: 'Tablet / Chewable',
      category: 'leukotriene_modifier',
      description:
          'A leukotriene receptor antagonist that blocks inflammatory mediators in asthma and allergies.',
      dosage:
          'Adults: 10mg once daily at bedtime. Children 6-14: 5mg chewable. Children 2-5: 4mg.',
      sideEffects: ['Headache', 'Abdominal pain', 'Mood changes', 'Fatigue'],
      precautions: [
        'Monitor for neuropsychiatric symptoms',
        'Not for acute asthma attacks',
        'Continue during acute episodes'
      ],
    ),
    DrugModel(
      id: 'zafirlukast',
      genericName: 'Zafirlukast',
      brandNames: ['Accolate'],
      diseases: ['asthma'],
      doseForm: 'Tablet',
      category: 'leukotriene_modifier',
      description:
          'A leukotriene receptor antagonist for chronic asthma management.',
      dosage: '20mg twice daily, at least 1 hour before or 2 hours after meals.',
      sideEffects: ['Headache', 'Nausea', 'Liver enzyme elevation', 'Infection'],
      precautions: [
        'Take on empty stomach',
        'Monitor liver function',
        'Drug interactions with warfarin'
      ],
    ),

    // === ANTIHISTAMINES ===
    DrugModel(
      id: 'cetirizine',
      genericName: 'Cetirizine',
      brandNames: ['Zyrtec', 'Cetzine', 'Alerid'],
      diseases: ['allergic_rhinitis', 'asthma'],
      doseForm: 'Tablet / Syrup',
      category: 'antihistamine',
      description:
          'A second-generation antihistamine that blocks histamine H1 receptors with minimal sedation.',
      dosage: 'Adults: 10mg once daily. Children 2-5: 2.5mg once or twice daily.',
      sideEffects: ['Drowsiness', 'Dry mouth', 'Fatigue', 'Headache'],
      precautions: [
        'May cause drowsiness in some patients',
        'Reduce dose in kidney impairment',
        'Avoid alcohol'
      ],
    ),
    DrugModel(
      id: 'fexofenadine',
      genericName: 'Fexofenadine',
      brandNames: ['Allegra', 'Fexova', 'Telfast'],
      diseases: ['allergic_rhinitis'],
      doseForm: 'Tablet',
      category: 'antihistamine',
      description:
          'A non-sedating second-generation antihistamine for allergic conditions.',
      dosage: 'Adults: 120-180mg once daily. Children 6-11: 30mg twice daily.',
      sideEffects: ['Headache', 'Nausea', 'Dizziness', 'Back pain'],
      precautions: [
        'Avoid fruit juices (reduce absorption)',
        'No significant drowsiness',
        'Safe in elderly'
      ],
    ),
    DrugModel(
      id: 'loratadine',
      genericName: 'Loratadine',
      brandNames: ['Claritin', 'Lorfast', 'Alavert'],
      diseases: ['allergic_rhinitis'],
      doseForm: 'Tablet / Syrup',
      category: 'antihistamine',
      description:
          'A long-acting non-sedating antihistamine for allergic rhinitis symptoms.',
      dosage: 'Adults and children over 6: 10mg once daily. Children 2-5: 5mg daily.',
      sideEffects: ['Headache', 'Fatigue', 'Dry mouth', 'Nervousness'],
      precautions: [
        'Generally non-sedating',
        'Reduce dose in liver impairment',
        'Once daily dosing'
      ],
    ),

    // === MUCOLYTICS ===
    DrugModel(
      id: 'acetylcysteine',
      genericName: 'Acetylcysteine',
      brandNames: ['Mucomyst', 'Mucobron', 'NAC'],
      diseases: ['bronchitis', 'copd', 'pneumonia'],
      doseForm: 'Tablet / Syrup / Nebulizer',
      category: 'mucolytic',
      description:
          'A mucolytic agent that breaks down mucus and has antioxidant properties.',
      dosage:
          'Oral: 200mg 3 times daily or 600mg once daily. Nebulizer: 3-5ml of 20% solution.',
      sideEffects: [
        'Nausea',
        'Vomiting',
        'Diarrhea',
        'Bronchospasm (nebulizer)'
      ],
      precautions: [
        'May cause bronchospasm when nebulized',
        'Use with bronchodilator',
        'Unpleasant sulfur smell'
      ],
    ),
    DrugModel(
      id: 'ambroxol',
      genericName: 'Ambroxol',
      brandNames: ['Mucosolvan', 'Ambrodil', 'Mucorid'],
      diseases: ['bronchitis', 'copd', 'pneumonia'],
      doseForm: 'Tablet / Syrup',
      category: 'mucolytic',
      description:
          'A mucoactive agent that promotes mucus clearance and has anti-inflammatory effects.',
      dosage:
          'Adults: 30mg 2-3 times daily. Children: 15mg 2-3 times daily. Reduce after 14 days.',
      sideEffects: ['Nausea', 'Diarrhea', 'Skin rash', 'Allergic reactions'],
      precautions: [
        'Rare severe skin reactions reported',
        'Take with food to reduce GI upset',
        'Drink plenty of fluids'
      ],
    ),

    // === COMBINATION THERAPIES ===
    DrugModel(
      id: 'fluticasone_salmeterol',
      genericName: 'Fluticasone/Salmeterol',
      brandNames: ['Advair', 'Seretide', 'Seroflo'],
      diseases: ['asthma', 'copd'],
      doseForm: 'Inhaler',
      category: 'combination',
      description:
          'A combination of inhaled corticosteroid and LABA for maintenance therapy.',
      dosage:
          'Asthma: 100/50 to 500/50mcg twice daily based on severity. COPD: 250/50mcg twice daily.',
      sideEffects: [
        'Oral thrush',
        'Hoarseness',
        'Headache',
        'Increased pneumonia risk'
      ],
      precautions: [
        'Not for acute bronchospasm',
        'Rinse mouth after use',
        'Step down to lowest effective dose'
      ],
    ),
    DrugModel(
      id: 'budesonide_formoterol',
      genericName: 'Budesonide/Formoterol',
      brandNames: ['Symbicort', 'Budamate', 'Foracort'],
      diseases: ['asthma', 'copd'],
      doseForm: 'Inhaler',
      category: 'combination',
      description:
          'An ICS-LABA combination that can be used for both maintenance and reliever therapy (MART).',
      dosage:
          'Maintenance: 1-2 puffs twice daily. MART: 1 puff as needed plus maintenance.',
      sideEffects: ['Oral candidiasis', 'Tremor', 'Palpitations', 'Headache'],
      precautions: [
        'Can be used as reliever in MART approach',
        'Maximum 8 puffs per day',
        'Rinse mouth after use'
      ],
    ),

    // === ANTIBIOTICS ===
    DrugModel(
      id: 'azithromycin',
      genericName: 'Azithromycin',
      brandNames: ['Zithromax', 'Azithral', 'Azee'],
      diseases: ['pneumonia', 'bronchitis', 'copd'],
      doseForm: 'Tablet / Syrup',
      category: 'antibiotic',
      description:
          'A macrolide antibiotic with anti-inflammatory properties, used for respiratory infections.',
      dosage:
          'Standard: 500mg day 1, then 250mg days 2-5. Pneumonia: 500mg daily for 7-10 days.',
      sideEffects: [
        'Nausea',
        'Diarrhea',
        'Abdominal pain',
        'QT prolongation'
      ],
      precautions: [
        'Check for drug interactions',
        'Caution in liver disease',
        'Monitor for QT prolongation'
      ],
    ),
    DrugModel(
      id: 'amoxicillin_clavulanate',
      genericName: 'Amoxicillin-Clavulanate',
      brandNames: ['Augmentin', 'Clavam', 'Moxikind-CV'],
      diseases: ['pneumonia', 'bronchitis'],
      doseForm: 'Tablet / Syrup',
      category: 'antibiotic',
      description:
          'A beta-lactam antibiotic combination for bacterial respiratory infections.',
      dosage:
          'Adults: 625mg 3 times daily or 1g twice daily. Duration: 5-10 days based on infection.',
      sideEffects: ['Diarrhea', 'Nausea', 'Skin rash', 'Liver enzyme elevation'],
      precautions: [
        'Take with food to reduce GI upset',
        'Check for penicillin allergy',
        'Monitor for C. difficile'
      ],
    ),

    // === ANTIFIBROTICS (for ILD) ===
    DrugModel(
      id: 'pirfenidone',
      genericName: 'Pirfenidone',
      brandNames: ['Esbriet', 'Pirfenex'],
      diseases: ['ild'],
      doseForm: 'Tablet',
      category: 'antifibrotic',
      description:
          'An antifibrotic agent that slows progression of idiopathic pulmonary fibrosis (IPF).',
      dosage:
          'Initial: 267mg 3 times daily. Titrate over 2 weeks to 801mg 3 times daily.',
      sideEffects: [
        'Nausea',
        'Rash',
        'Photosensitivity',
        'Fatigue',
        'Liver enzyme elevation'
      ],
      precautions: [
        'Avoid sun exposure',
        'Take with food',
        'Regular liver function monitoring',
        'Dose adjust for side effects'
      ],
    ),
    DrugModel(
      id: 'nintedanib',
      genericName: 'Nintedanib',
      brandNames: ['Ofev', 'Cyendiv'],
      diseases: ['ild'],
      doseForm: 'Capsule',
      category: 'antifibrotic',
      description:
          'A tyrosine kinase inhibitor that slows the decline of lung function in ILD.',
      dosage: '150mg twice daily with food, approximately 12 hours apart.',
      sideEffects: ['Diarrhea', 'Nausea', 'Liver enzyme elevation', 'Weight loss'],
      precautions: [
        'Manage diarrhea proactively',
        'Monitor liver function',
        'Avoid in pregnancy',
        'Take with food'
      ],
    ),
  ];
}
