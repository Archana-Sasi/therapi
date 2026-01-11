import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/curated_medicine_data.dart';

/// Unified Medicine Service for hybrid local + Firebase search
/// - Local: 600 curated common medicines (works offline)
/// - Firebase: Full 195K medicine database (requires internet)
class MedicineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection name for medicines in Firebase
  static const String _medicinesCollection = 'medicines';
  
  /// Search local curated medicines (offline-capable)
  static List<CuratedMedicine> searchLocalMedicines(String query) {
    return CuratedMedicineData.searchMedicines(query);
  }
  
  /// Get all local medicines
  static List<CuratedMedicine> getAllLocalMedicines() {
    return CuratedMedicineData.medicines;
  }
  
  /// Get local medicine by ID
  static CuratedMedicine? getLocalMedicineById(String id) {
    return CuratedMedicineData.getMedicineById(id);
  }
  
  /// Get local medicines by category
  static List<CuratedMedicine> getLocalMedicinesByCategory(String category) {
    return CuratedMedicineData.getMedicinesByCategory(category);
  }
  
  /// Get all unique categories from local medicines
  static List<String> getLocalCategories() {
    final categories = CuratedMedicineData.medicines
        .map((m) => m.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
  
  /// Search Firebase for medicines (full 195K database)
  /// Returns empty list if Firebase not configured or offline
  static Future<List<Map<String, dynamic>>> searchFirebaseMedicines(
    String query, {
    int limit = 50,
  }) async {
    if (query.isEmpty) return [];
    
    try {
      final lowerQuery = query.toLowerCase();
      
      // Search by brand name
      final brandResults = await _firestore
          .collection(_medicinesCollection)
          .where('brandNameLower', isGreaterThanOrEqualTo: lowerQuery)
          .where('brandNameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(limit ~/ 2)
          .get();
      
      // Search by generic name
      final genericResults = await _firestore
          .collection(_medicinesCollection)
          .where('genericNameLower', isGreaterThanOrEqualTo: lowerQuery)
          .where('genericNameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(limit ~/ 2)
          .get();
      
      // Combine and deduplicate results
      final Map<String, Map<String, dynamic>> combinedResults = {};
      
      for (var doc in brandResults.docs) {
        combinedResults[doc.id] = {'id': doc.id, ...doc.data()};
      }
      
      for (var doc in genericResults.docs) {
        combinedResults[doc.id] = {'id': doc.id, ...doc.data()};
      }
      
      return combinedResults.values.toList();
    } catch (e) {
      // Firebase not configured or offline
      debugPrint('Firebase search error: $e');
      return [];
    }
  }
  
  /// Hybrid search - searches local first, then Firebase
  /// Returns a combined result with local matches prioritized
  static Future<MedicineSearchResult> hybridSearch(
    String query, {
    int firebaseLimit = 50,
  }) async {
    // Always search local first (offline-capable)
    final localResults = searchLocalMedicines(query);
    
    // Search Firebase if query is substantial enough
    List<Map<String, dynamic>> firebaseResults = [];
    if (query.length >= 3) {
      firebaseResults = await searchFirebaseMedicines(
        query,
        limit: firebaseLimit,
      );
    }
    
    return MedicineSearchResult(
      localResults: localResults,
      firebaseResults: firebaseResults,
    );
  }
  
  /// Check if Firebase medicines collection is available
  static Future<bool> isFirebaseAvailable() async {
    try {
      final snapshot = await _firestore
          .collection(_medicinesCollection)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get medicine count from Firebase
  static Future<int> getFirebaseMedicineCount() async {
    try {
      // Note: This is an approximation as Firestore doesn't have native count
      // For exact count, you'd need to maintain a counter document
      final snapshot = await _firestore
          .collection(_medicinesCollection)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty ? 195000 : 0; // Approximate count
    } catch (e) {
      return 0;
    }
  }
}

/// Result of hybrid medicine search
class MedicineSearchResult {
  final List<CuratedMedicine> localResults;
  final List<Map<String, dynamic>> firebaseResults;
  
  MedicineSearchResult({
    required this.localResults,
    required this.firebaseResults,
  });
  
  /// Check if any results were found
  bool get hasResults => localResults.isNotEmpty || firebaseResults.isNotEmpty;
  
  /// Total result count
  int get totalCount => localResults.length + firebaseResults.length;
  
  /// Get local result count
  int get localCount => localResults.length;
  
  /// Get Firebase result count
  int get firebaseCount => firebaseResults.length;
}
