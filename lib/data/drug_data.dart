import '../models/drug_model.dart';

/// Repository of medications organized by disease/condition
class DrugData {
  /// All diseases/conditions covered in the app
  static const List<Map<String, dynamic>> diseases = [
    // Respiratory
    {'id': 'asthma', 'name': 'Asthma', 'icon': 'air', 'description': 'Chronic inflammatory disease of the airways'},
    {'id': 'copd', 'name': 'COPD', 'icon': 'smoke_free', 'description': 'Chronic Obstructive Pulmonary Disease'},
    {'id': 'bronchitis', 'name': 'Bronchitis', 'icon': 'healing', 'description': 'Inflammation of the bronchial tubes'},
    {'id': 'allergic_rhinitis', 'name': 'Allergic Rhinitis', 'icon': 'grass', 'description': 'Allergic inflammation of nasal airways'},
    {'id': 'ild', 'name': 'Interstitial Lung Disease', 'icon': 'blur_on', 'description': 'Lung tissue scarring disorders'},
    {'id': 'pneumonia', 'name': 'Pneumonia', 'icon': 'coronavirus', 'description': 'Lung infection'},
    // Cardiovascular
    {'id': 'hypertension', 'name': 'Hypertension', 'icon': 'favorite', 'description': 'High blood pressure'},
    {'id': 'heart_disease', 'name': 'Heart Disease', 'icon': 'monitor_heart', 'description': 'Coronary artery disease and heart conditions'},
    {'id': 'hyperlipidemia', 'name': 'High Cholesterol', 'icon': 'water_drop', 'description': 'Elevated blood lipids'},
    // Metabolic
    {'id': 'diabetes', 'name': 'Diabetes', 'icon': 'bloodtype', 'description': 'Blood sugar management disorders'},
    {'id': 'thyroid', 'name': 'Thyroid Disorders', 'icon': 'accessibility', 'description': 'Thyroid hormone imbalances'},
    // Gastrointestinal
    {'id': 'gerd', 'name': 'GERD/Acid Reflux', 'icon': 'local_fire_department', 'description': 'Gastroesophageal reflux disease'},
    {'id': 'ulcer', 'name': 'Peptic Ulcer', 'icon': 'radio_button_unchecked', 'description': 'Stomach and duodenal ulcers'},
    // Pain & Inflammation
    {'id': 'pain', 'name': 'Pain & Fever', 'icon': 'thermostat', 'description': 'General pain and fever management'},
    {'id': 'arthritis', 'name': 'Arthritis', 'icon': 'accessibility_new', 'description': 'Joint inflammation and pain'},
    {'id': 'migraine', 'name': 'Migraine', 'icon': 'psychology', 'description': 'Severe headaches'},
    // Infections
    {'id': 'bacterial_infection', 'name': 'Bacterial Infections', 'icon': 'bug_report', 'description': 'Bacterial infections requiring antibiotics'},
    {'id': 'fungal_infection', 'name': 'Fungal Infections', 'icon': 'spa', 'description': 'Fungal/yeast infections'},
    // Mental Health
    {'id': 'depression', 'name': 'Depression', 'icon': 'mood_bad', 'description': 'Mood disorders'},
    {'id': 'anxiety', 'name': 'Anxiety', 'icon': 'sentiment_stressed', 'description': 'Anxiety disorders'},
    {'id': 'insomnia', 'name': 'Insomnia', 'icon': 'bedtime', 'description': 'Sleep disorders'},
    // Other
    {'id': 'allergy', 'name': 'Allergies', 'icon': 'warning', 'description': 'Allergic conditions'},
    {'id': 'skin', 'name': 'Skin Conditions', 'icon': 'face', 'description': 'Dermatological conditions'},
    {'id': 'general', 'name': 'General/Vitamins', 'icon': 'medication', 'description': 'General health and supplements'},
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

  /// Complete list of medications (generic + brand names)
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

    // === PAIN & FEVER ===
    DrugModel(
      id: 'paracetamol',
      genericName: 'Paracetamol (Acetaminophen)',
      brandNames: ['Crocin', 'Dolo', 'Tylenol', 'Calpol', 'Panadol'],
      diseases: ['pain', 'fever'],
      doseForm: 'Tablet / Syrup / Drops',
      category: 'analgesic',
      description: 'A widely used pain reliever and fever reducer.',
      dosage: 'Adults: 500-1000mg every 4-6 hours. Max 4g/day. Children: 10-15mg/kg every 4-6 hours.',
      sideEffects: ['Rare at normal doses', 'Liver damage with overdose', 'Allergic reactions'],
      precautions: ['Do not exceed 4g daily', 'Avoid in liver disease', 'Check other medications for paracetamol content'],
    ),
    DrugModel(
      id: 'ibuprofen',
      genericName: 'Ibuprofen',
      brandNames: ['Brufen', 'Advil', 'Motrin', 'Nurofen', 'Combiflam'],
      diseases: ['pain', 'fever', 'arthritis'],
      doseForm: 'Tablet / Syrup / Gel',
      category: 'nsaid',
      description: 'A nonsteroidal anti-inflammatory drug for pain, fever, and inflammation.',
      dosage: 'Adults: 200-400mg every 4-6 hours. Max 1200mg/day OTC.',
      sideEffects: ['Stomach upset', 'Nausea', 'Heartburn', 'Dizziness', 'GI bleeding'],
      precautions: ['Take with food', 'Avoid in kidney disease', 'Not for last trimester of pregnancy'],
    ),
    DrugModel(
      id: 'diclofenac',
      genericName: 'Diclofenac',
      brandNames: ['Voltaren', 'Voveran', 'Cataflam', 'Diclomax'],
      diseases: ['pain', 'arthritis'],
      doseForm: 'Tablet / Gel / Injection',
      category: 'nsaid',
      description: 'A potent NSAID for pain and inflammation.',
      dosage: 'Oral: 50mg 2-3 times daily. Gel: Apply 2-4 times daily.',
      sideEffects: ['GI upset', 'Headache', 'Dizziness', 'Skin rash'],
      precautions: ['Cardiovascular risk with long-term use', 'Avoid in aspirin allergy'],
    ),
    DrugModel(
      id: 'aspirin',
      genericName: 'Aspirin',
      brandNames: ['Disprin', 'Ecosprin', 'Bayer Aspirin'],
      diseases: ['pain', 'fever', 'heart_disease'],
      doseForm: 'Tablet',
      category: 'nsaid',
      description: 'Pain reliever and blood thinner for heart protection.',
      dosage: 'Pain: 325-650mg every 4 hours. Heart: 75-100mg daily.',
      sideEffects: ['Stomach irritation', 'Bleeding risk', 'Tinnitus'],
      precautions: ['Not for children with viral illness', 'Avoid before surgery'],
    ),

    // === CARDIOVASCULAR ===
    DrugModel(
      id: 'amlodipine',
      genericName: 'Amlodipine',
      brandNames: ['Norvasc', 'Amlong', 'Amlip', 'Amlopin'],
      diseases: ['hypertension', 'heart_disease'],
      doseForm: 'Tablet',
      category: 'calcium_channel_blocker',
      description: 'A calcium channel blocker for high blood pressure and angina.',
      dosage: 'Initial: 5mg once daily. Max: 10mg daily.',
      sideEffects: ['Ankle swelling', 'Flushing', 'Headache', 'Fatigue'],
      precautions: ['Monitor for edema', 'Avoid grapefruit juice'],
    ),
    DrugModel(
      id: 'atenolol',
      genericName: 'Atenolol',
      brandNames: ['Tenormin', 'Aten', 'Betacard'],
      diseases: ['hypertension', 'heart_disease', 'arrhythmia'],
      doseForm: 'Tablet',
      category: 'beta_blocker',
      description: 'A beta-blocker for blood pressure and heart rate control.',
      dosage: '25-100mg once daily.',
      sideEffects: ['Fatigue', 'Cold extremities', 'Bradycardia', 'Dizziness'],
      precautions: ['Do not stop abruptly', 'Caution in asthma', 'Monitor heart rate'],
    ),
    DrugModel(
      id: 'atorvastatin',
      genericName: 'Atorvastatin',
      brandNames: ['Lipitor', 'Atorva', 'Storvas', 'Atocor'],
      diseases: ['hyperlipidemia', 'heart_disease'],
      doseForm: 'Tablet',
      category: 'statin',
      description: 'A statin to lower cholesterol and reduce heart disease risk.',
      dosage: '10-80mg once daily, usually at bedtime.',
      sideEffects: ['Muscle pain', 'Liver enzyme elevation', 'Headache'],
      precautions: ['Monitor liver function', 'Report unexplained muscle pain', 'Avoid grapefruit'],
    ),
    DrugModel(
      id: 'losartan',
      genericName: 'Losartan',
      brandNames: ['Cozaar', 'Losacar', 'Repace', 'Losar'],
      diseases: ['hypertension', 'heart_disease', 'diabetes'],
      doseForm: 'Tablet',
      category: 'arb',
      description: 'An ARB for blood pressure and kidney protection in diabetes.',
      dosage: '25-100mg once or twice daily.',
      sideEffects: ['Dizziness', 'Hyperkalemia', 'Fatigue'],
      precautions: ['Monitor potassium', 'Avoid in pregnancy'],
    ),
    DrugModel(
      id: 'clopidogrel',
      genericName: 'Clopidogrel',
      brandNames: ['Plavix', 'Clopilet', 'Plagril'],
      diseases: ['heart_disease'],
      doseForm: 'Tablet',
      category: 'antiplatelet',
      description: 'Prevents blood clots after heart attack or stroke.',
      dosage: '75mg once daily.',
      sideEffects: ['Bleeding', 'Bruising', 'GI upset'],
      precautions: ['Stop before surgery', 'Avoid with omeprazole'],
    ),

    // === DIABETES ===
    DrugModel(
      id: 'metformin',
      genericName: 'Metformin',
      brandNames: ['Glucophage', 'Glycomet', 'Obimet', 'Cetapin'],
      diseases: ['diabetes'],
      doseForm: 'Tablet',
      category: 'antidiabetic',
      description: 'First-line medication for type 2 diabetes.',
      dosage: 'Start 500mg twice daily with meals. Max 2000-2500mg/day.',
      sideEffects: ['GI upset', 'Nausea', 'Diarrhea', 'Metallic taste'],
      precautions: ['Stop before contrast dye procedures', 'Avoid in kidney impairment'],
    ),
    DrugModel(
      id: 'glimepiride',
      genericName: 'Glimepiride',
      brandNames: ['Amaryl', 'Glimisave', 'Zoryl'],
      diseases: ['diabetes'],
      doseForm: 'Tablet',
      category: 'antidiabetic',
      description: 'A sulfonylurea that stimulates insulin release.',
      dosage: 'Start 1-2mg daily. Max 8mg daily.',
      sideEffects: ['Hypoglycemia', 'Weight gain', 'Dizziness'],
      precautions: ['Take with breakfast', 'Monitor blood sugar', 'Avoid alcohol'],
    ),

    // === GASTROINTESTINAL ===
    DrugModel(
      id: 'omeprazole',
      genericName: 'Omeprazole',
      brandNames: ['Prilosec', 'Omez', 'Ocid', 'Losec'],
      diseases: ['gerd', 'ulcer'],
      doseForm: 'Capsule / Tablet',
      category: 'ppi',
      description: 'A proton pump inhibitor that reduces stomach acid.',
      dosage: '20-40mg once daily before breakfast.',
      sideEffects: ['Headache', 'Diarrhea', 'Nausea', 'Vitamin B12 deficiency'],
      precautions: ['Long-term use may affect bone density', 'Take before meals'],
    ),
    DrugModel(
      id: 'pantoprazole',
      genericName: 'Pantoprazole',
      brandNames: ['Protonix', 'Pan', 'Pantocid', 'Nexpro'],
      diseases: ['gerd', 'ulcer'],
      doseForm: 'Tablet / Injection',
      category: 'ppi',
      description: 'A PPI for acid reflux and ulcer healing.',
      dosage: '20-40mg once daily.',
      sideEffects: ['Headache', 'Diarrhea', 'Abdominal pain'],
      precautions: ['Similar to omeprazole', 'Avoid long-term if possible'],
    ),
    DrugModel(
      id: 'ranitidine',
      genericName: 'Ranitidine',
      brandNames: ['Zantac', 'Rantac', 'Aciloc'],
      diseases: ['gerd', 'ulcer'],
      doseForm: 'Tablet / Syrup',
      category: 'h2_blocker',
      description: 'An H2 blocker that reduces stomach acid production.',
      dosage: '150mg twice daily or 300mg at bedtime.',
      sideEffects: ['Headache', 'Dizziness', 'Constipation'],
      precautions: ['Check availability - recalled in some countries'],
    ),
    DrugModel(
      id: 'ondansetron',
      genericName: 'Ondansetron',
      brandNames: ['Zofran', 'Ondem', 'Emeset', 'Vomikind'],
      diseases: ['general'],
      doseForm: 'Tablet / Injection / Oral dissolving',
      category: 'antiemetic',
      description: 'Prevents nausea and vomiting.',
      dosage: '4-8mg every 8 hours as needed.',
      sideEffects: ['Headache', 'Constipation', 'Dizziness'],
      precautions: ['May cause QT prolongation', 'Use caution with other QT-prolonging drugs'],
    ),

    // === ANTIBIOTICS ===
    DrugModel(
      id: 'amoxicillin',
      genericName: 'Amoxicillin',
      brandNames: ['Amoxil', 'Mox', 'Novamox', 'Wymox'],
      diseases: ['bacterial_infection', 'pneumonia'],
      doseForm: 'Capsule / Syrup',
      category: 'antibiotic',
      description: 'A penicillin-type antibiotic for various bacterial infections.',
      dosage: '250-500mg every 8 hours for 7-10 days.',
      sideEffects: ['Diarrhea', 'Nausea', 'Rash', 'Allergic reactions'],
      precautions: ['Check for penicillin allergy', 'Complete the full course'],
    ),
    DrugModel(
      id: 'ciprofloxacin',
      genericName: 'Ciprofloxacin',
      brandNames: ['Cipro', 'Ciplox', 'Cifran'],
      diseases: ['bacterial_infection'],
      doseForm: 'Tablet / Eye drops',
      category: 'antibiotic',
      description: 'A fluoroquinolone antibiotic for UTIs and other infections.',
      dosage: '250-750mg twice daily for 7-14 days.',
      sideEffects: ['Nausea', 'Diarrhea', 'Tendon problems', 'Photosensitivity'],
      precautions: ['Avoid in children', 'Risk of tendon rupture', 'Avoid dairy products'],
    ),
    DrugModel(
      id: 'metronidazole',
      genericName: 'Metronidazole',
      brandNames: ['Flagyl', 'Metrogyl', 'Aristogyl'],
      diseases: ['bacterial_infection', 'fungal_infection'],
      doseForm: 'Tablet / Gel / IV',
      category: 'antibiotic',
      description: 'Treats bacterial and parasitic infections.',
      dosage: '400-500mg every 8 hours for 7-10 days.',
      sideEffects: ['Metallic taste', 'Nausea', 'Headache', 'Dark urine'],
      precautions: ['Absolutely avoid alcohol - severe reaction', 'Complete full course'],
    ),
    DrugModel(
      id: 'fluconazole',
      genericName: 'Fluconazole',
      brandNames: ['Diflucan', 'Forcan', 'Flucos', 'Zocon'],
      diseases: ['fungal_infection'],
      doseForm: 'Tablet / IV',
      category: 'antifungal',
      description: 'An antifungal for yeast and fungal infections.',
      dosage: '150mg single dose for vaginal candidiasis. 50-400mg daily for other infections.',
      sideEffects: ['Headache', 'Nausea', 'Abdominal pain', 'Liver enzyme elevation'],
      precautions: ['Monitor liver function', 'Drug interactions with many medications'],
    ),

    // === MENTAL HEALTH ===
    DrugModel(
      id: 'escitalopram',
      genericName: 'Escitalopram',
      brandNames: ['Lexapro', 'Cipralex', 'Nexito', 'Stalopam'],
      diseases: ['depression', 'anxiety'],
      doseForm: 'Tablet',
      category: 'antidepressant',
      description: 'An SSRI antidepressant for depression and anxiety.',
      dosage: 'Start 10mg daily. Max 20mg daily.',
      sideEffects: ['Nausea', 'Insomnia', 'Sexual dysfunction', 'Weight changes'],
      precautions: ['Takes 2-4 weeks for effect', 'Do not stop abruptly', 'Monitor for suicidal thoughts in young adults'],
    ),
    DrugModel(
      id: 'alprazolam',
      genericName: 'Alprazolam',
      brandNames: ['Xanax', 'Alprax', 'Restyl', 'Trika'],
      diseases: ['anxiety', 'insomnia'],
      doseForm: 'Tablet',
      category: 'anxiolytic',
      description: 'A benzodiazepine for anxiety and panic disorders.',
      dosage: '0.25-0.5mg 2-3 times daily as needed.',
      sideEffects: ['Drowsiness', 'Dizziness', 'Memory impairment', 'Dependence'],
      precautions: ['Habit-forming', 'Avoid alcohol', 'Do not stop abruptly', 'Short-term use only'],
    ),
    DrugModel(
      id: 'zolpidem',
      genericName: 'Zolpidem',
      brandNames: ['Ambien', 'Stilnox', 'Zolfresh', 'Nitrest'],
      diseases: ['insomnia'],
      doseForm: 'Tablet',
      category: 'sedative',
      description: 'A sleep aid for short-term insomnia treatment.',
      dosage: '5-10mg at bedtime. Use lowest effective dose.',
      sideEffects: ['Next-day drowsiness', 'Dizziness', 'Sleepwalking', 'Memory issues'],
      precautions: ['Short-term use only', 'Avoid alcohol', 'May cause complex sleep behaviors'],
    ),

    // === VITAMINS & SUPPLEMENTS ===
    DrugModel(
      id: 'vitamin_d3',
      genericName: 'Vitamin D3 (Cholecalciferol)',
      brandNames: ['Calcirol', 'Uprise D3', 'Arachitol', 'D-Rise'],
      diseases: ['general'],
      doseForm: 'Tablet / Capsule / Drops',
      category: 'vitamin',
      description: 'Essential vitamin for bone health and immunity.',
      dosage: 'Maintenance: 1000-2000 IU daily. Deficiency: 60000 IU weekly.',
      sideEffects: ['Rare at normal doses', 'Hypercalcemia with excess'],
      precautions: ['Check levels before high-dose supplementation'],
    ),
    DrugModel(
      id: 'vitamin_b12',
      genericName: 'Vitamin B12 (Cyanocobalamin)',
      brandNames: ['Neurobion', 'Mecobalamin', 'Methylcobalamin', 'Cobadex'],
      diseases: ['general'],
      doseForm: 'Tablet / Injection',
      category: 'vitamin',
      description: 'Essential for nerve function and red blood cell formation.',
      dosage: 'Oral: 1000-2000mcg daily. Injection: 1000mcg monthly.',
      sideEffects: ['Generally well tolerated', 'Injection site pain'],
      precautions: ['Vegetarians and elderly at higher risk of deficiency'],
    ),
    DrugModel(
      id: 'calcium',
      genericName: 'Calcium + Vitamin D',
      brandNames: ['Shelcal', 'Calcimax', 'CCM', 'Gemcal'],
      diseases: ['general', 'arthritis'],
      doseForm: 'Tablet',
      category: 'vitamin',
      description: 'Supplement for bone health and osteoporosis prevention.',
      dosage: '500-1000mg calcium with 400-800 IU vitamin D daily.',
      sideEffects: ['Constipation', 'Bloating', 'Gas'],
      precautions: ['Take with food', 'Space from other medications'],
    ),

    // === THYROID ===
    DrugModel(
      id: 'levothyroxine',
      genericName: 'Levothyroxine',
      brandNames: ['Synthroid', 'Thyronorm', 'Eltroxin', 'Thyrox'],
      diseases: ['thyroid'],
      doseForm: 'Tablet',
      category: 'thyroid_hormone',
      description: 'Thyroid hormone replacement for hypothyroidism.',
      dosage: 'Start 25-50mcg daily. Adjust based on TSH levels.',
      sideEffects: ['Palpitations', 'Weight loss', 'Insomnia', 'Anxiety (if overdosed)'],
      precautions: ['Take on empty stomach', 'Consistent daily timing', 'Many drug interactions'],
    ),
  ];
}
