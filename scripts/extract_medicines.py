"""
Script to extract common drugs from the large Kaggle dataset.
Creates a curated list of ~500 medicines across key therapeutic categories.
"""

import csv
import json
import os
from collections import defaultdict

# Categories to prioritize (matching RespiriCare app focus + general medicines)
PRIORITY_CATEGORIES = [
    # Respiratory (primary focus)
    'Bronchodilator', 'Asthma', 'COPD', 'Cough', 'Antihistamine', 'Decongestant',
    'Inhaler', 'Nebulizer', 'Corticosteroid', 'Respiratory',
    # Cardiovascular
    'Antihypertensive', 'Cardiac', 'Blood Pressure', 'Heart', 'Cholesterol',
    'Beta Blocker', 'ACE Inhibitor', 'Calcium Channel',
    # Diabetes
    'Antidiabetic', 'Diabetes', 'Insulin', 'Metformin', 'Glucose',
    # GI
    'Antacid', 'PPI', 'Gastric', 'Acid Reflux', 'GERD', 'Ulcer',
    # Pain & Fever
    'Analgesic', 'Painkiller', 'NSAID', 'Fever', 'Anti-inflammatory',
    # Antibiotics
    'Antibiotic', 'Antimicrobial', 'Antibacterial', 'Antifungal',
    # Mental Health
    'Antidepressant', 'Anxiolytic', 'Psychiatric', 'Sleep',
    # Common
    'Vitamin', 'Supplement', 'Allergy',
]

# Common generic names to definitely include
COMMON_GENERICS = [
    'paracetamol', 'acetaminophen', 'ibuprofen', 'aspirin', 'diclofenac',
    'salbutamol', 'albuterol', 'montelukast', 'cetirizine', 'loratadine',
    'omeprazole', 'pantoprazole', 'ranitidine', 'metformin', 'glimepiride',
    'amlodipine', 'atenolol', 'losartan', 'atorvastatin', 'rosuvastatin',
    'azithromycin', 'amoxicillin', 'ciprofloxacin', 'metronidazole',
    'fluticasone', 'budesonide', 'beclomethasone', 'prednisolone',
    'levothyroxine', 'vitamin d', 'vitamin b', 'folic acid', 'iron',
    'ondansetron', 'domperidone', 'ranitidine', 'famotidine',
    'sertraline', 'fluoxetine', 'alprazolam', 'clonazepam',
]

def parse_csv(filepath):
    """Parse the large CSV and extract relevant medicines."""
    drugs = []
    seen_salts = set()
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        reader = csv.DictReader(f)
        for row in reader:
            salt = row.get('salt_composition', '').strip()
            product = row.get('product_name', '').strip()
            category = row.get('sub_category', '').strip()
            
            if not salt or not product:
                continue
            
            # Normalize salt name for deduplication
            salt_lower = salt.lower()
            
            # Check if this is a priority medicine
            is_priority = False
            
            # Check category match
            for cat in PRIORITY_CATEGORIES:
                if cat.lower() in category.lower() or cat.lower() in salt_lower:
                    is_priority = True
                    break
            
            # Check common generics
            for generic in COMMON_GENERICS:
                if generic in salt_lower:
                    is_priority = True
                    break
            
            if is_priority and salt_lower not in seen_salts:
                seen_salts.add(salt_lower)
                drugs.append({
                    'product_name': product,
                    'salt_composition': salt,
                    'sub_category': category,
                    'manufacturer': row.get('product_manufactured', ''),
                    'price': row.get('product_price', ''),
                    'description': row.get('medicine_desc', '')[:500] if row.get('medicine_desc') else '',
                    'side_effects': row.get('side_effects', ''),
                })
                
                # Limit to ~600 drugs
                if len(drugs) >= 600:
                    break
    
    return drugs

def generate_dart_code(drugs):
    """Generate Dart code for the curated drug list."""
    
    dart_code = '''// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY
// Generated from Kaggle Indian Medicine Dataset
// Contains curated list of ~${count} common medicines

/// Model for medicines from the curated database
class CuratedMedicine {
  const CuratedMedicine({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.category,
    required this.manufacturer,
    this.price,
    this.description,
    this.sideEffects,
  });

  final String id;
  final String brandName;
  final String genericName;
  final String category;
  final String manufacturer;
  final String? price;
  final String? description;
  final String? sideEffects;

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brandName': brandName,
      'genericName': genericName,
      'category': category,
      'manufacturer': manufacturer,
      'price': price,
      'description': description,
      'sideEffects': sideEffects,
    };
  }

  /// Create from map
  factory CuratedMedicine.fromMap(Map<String, dynamic> map) {
    return CuratedMedicine(
      id: map['id'] ?? '',
      brandName: map['brandName'] ?? '',
      genericName: map['genericName'] ?? '',
      category: map['category'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      price: map['price'],
      description: map['description'],
      sideEffects: map['sideEffects'],
    );
  }
}

/// Repository of curated medicines
class CuratedMedicineData {
  /// Search medicines by name (brand or generic)
  static List<CuratedMedicine> searchMedicines(String query) {
    if (query.isEmpty) return medicines;
    final lowerQuery = query.toLowerCase();
    return medicines.where((m) =>
      m.brandName.toLowerCase().contains(lowerQuery) ||
      m.genericName.toLowerCase().contains(lowerQuery) ||
      m.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get medicine by ID
  static CuratedMedicine? getMedicineById(String id) {
    try {
      return medicines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get medicines by category
  static List<CuratedMedicine> getMedicinesByCategory(String category) {
    final lowerCategory = category.toLowerCase();
    return medicines.where((m) =>
      m.category.toLowerCase().contains(lowerCategory)
    ).toList();
  }

  /// All curated medicines
  static const List<CuratedMedicine> medicines = [
'''
    
    for i, drug in enumerate(drugs):
        # Escape strings for Dart
        brand = drug['product_name'].replace("'", "\\'").replace('"', '\\"')
        generic = drug['salt_composition'].replace("'", "\\'").replace('"', '\\"')
        category = drug['sub_category'].replace("'", "\\'").replace('"', '\\"')
        manufacturer = drug['manufacturer'].replace("'", "\\'").replace('"', '\\"')
        price = (drug['price'] or '').replace("'", "\\'").replace('"', '\\"')
        desc = (drug['description'] or '')[:200].replace("'", "\\'").replace('"', '\\"').replace('\n', ' ').replace('\r', '')
        side_effects = (drug['side_effects'] or '').replace("'", "\\'").replace('"', '\\"')
        
        dart_code += f'''    CuratedMedicine(
      id: 'med_{i+1}',
      brandName: '{brand}',
      genericName: '{generic}',
      category: '{category}',
      manufacturer: '{manufacturer}',
      price: '{price}',
      description: '{desc}',
      sideEffects: '{side_effects}',
    ),
'''
    
    dart_code += '''  ];
}
'''
    
    return dart_code.replace('${count}', str(len(drugs)))

def main():
    # Path to the CSV file
    csv_path = r'c:\MAD\Therap_app\assets\images\archive (3)\medicine_data.csv'
    output_path = r'c:\MAD\Therap_app\lib\data\curated_medicine_data.dart'
    
    print(f"Reading CSV from: {csv_path}")
    drugs = parse_csv(csv_path)
    print(f"Extracted {len(drugs)} curated medicines")
    
    dart_code = generate_dart_code(drugs)
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(dart_code)
    
    print(f"Generated Dart file: {output_path}")
    print("Done!")

if __name__ == '__main__':
    main()
