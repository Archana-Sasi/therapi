import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/drug_data.dart';
import '../data/tamil_translations.dart';
import '../models/custom_drug.dart';
import '../models/drug_model.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'add_drug_screen.dart';
import 'drug_detail_screen.dart';
import 'medicine_search_screen.dart';

/// Drug Inventory Screen for Pharmacists to view all medications
class DrugInventoryScreen extends StatefulWidget {
  const DrugInventoryScreen({super.key});

  @override
  State<DrugInventoryScreen> createState() => _DrugInventoryScreenState();
}

class _DrugInventoryScreenState extends State<DrugInventoryScreen> {
  final _searchController = TextEditingController();
  final _authService = AuthService();
  
  List<DrugModel> _staticDrugs = [];
  List<CustomDrug> _customDrugs = [];
  List<dynamic> _allDrugs = []; // Combined list
  List<dynamic> _filteredDrugs = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  
  // Simple filter - just All drugs or Custom drugs added by pharmacist
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All Drugs', 'icon': Icons.medication},
    {'id': 'custom', 'name': 'Custom Added', 'icon': Icons.star},
  ];

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  Future<void> _loadDrugs() async {
    setState(() => _isLoading = true);
    
    // Load static drugs
    _staticDrugs = DrugData.drugs;
    
    // Load custom drugs from Firestore
    _customDrugs = await _authService.getCustomDrugs();
    
    // Combine both lists
    _allDrugs = [..._staticDrugs, ..._customDrugs];
    _filteredDrugs = _allDrugs;
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDrugGenericName(dynamic drug) {
    if (drug is DrugModel) return drug.genericName;
    if (drug is CustomDrug) return drug.genericName;
    return '';
  }

  List<String> _getDrugBrandNames(dynamic drug) {
    if (drug is DrugModel) return drug.brandNames;
    if (drug is CustomDrug) return drug.brandNames;
    return [];
  }

  String _getDrugCategory(dynamic drug) {
    if (drug is DrugModel) return drug.category;
    if (drug is CustomDrug) return drug.category;
    return '';
  }

  List<String> _getDrugDiseases(dynamic drug) {
    if (drug is DrugModel) return drug.diseases;
    if (drug is CustomDrug) return drug.diseases;
    return [];
  }

  bool _isCustomDrug(dynamic drug) {
    return drug is CustomDrug;
  }

  void _filterDrugs(String query) {
    setState(() {
      List<dynamic> drugs;
      
      if (_selectedCategory == 'custom') {
        drugs = _customDrugs;
      } else {
        drugs = _allDrugs;
      }
      
      if (query.isEmpty) {
        _filteredDrugs = drugs;
      } else {
        _filteredDrugs = drugs.where((drug) =>
            _getDrugGenericName(drug).toLowerCase().contains(query.toLowerCase()) ||
            _getDrugBrandNames(drug).any((b) => b.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      if (category == 'custom') {
        _filteredDrugs = _customDrugs;
      } else {
        _filteredDrugs = _allDrugs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isTamil = langProvider.isTamil;
    String t(String english) => isTamil ? TamilTranslations.getLabel(english) : english;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Drug Inventory')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Full Database',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicineSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrugs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.backgroundGradient,
                  ),
                  child: Column(
                    children: [
                      // Stats Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.medication,
                              value: '${_allDrugs.length}',
                              label: 'Total Drugs',
                            ),
                            Container(width: 1, height: 40, color: Colors.white30),
                            _buildStatItem(
                              icon: Icons.category,
                              value: '${_categories.length - 1}',
                              label: 'Categories',
                            ),
                            Container(width: 1, height: 40, color: Colors.white30),
                            _buildStatItem(
                              icon: Icons.branding_watermark,
                              value: '${_allDrugs.fold<int>(0, (sum, d) => sum + _getDrugBrandNames(d).length)}',
                              label: 'Brands',
                            ),
                          ],
                        ),
                      ),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterDrugs,
                          decoration: InputDecoration(
                            hintText: 'Search medications...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterDrugs('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Category Filter Chips
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _selectedCategory == cat['id'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(cat['name']),
                                selected: isSelected,
                                onSelected: (_) => _filterByCategory(cat['id']),
                                avatar: Icon(
                                  cat['icon'],
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surface,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Results Count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.medication, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              '${_filteredDrugs.length} medication${_filteredDrugs.length == 1 ? '' : 's'} found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Drug List
                      Expanded(
                        child: _filteredDrugs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No medications found',
                                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                                itemCount: _filteredDrugs.length,
                                itemBuilder: (context, index) {
                                  final drug = _filteredDrugs[index];
                                  final genericName = _getDrugGenericName(drug);
                                  final brandNames = _getDrugBrandNames(drug);
                                  final category = _getDrugCategory(drug);
                                  final isCustom = _isCustomDrug(drug);
                                  const drugColor = AppColors.primary;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: Stack(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isCustom 
                                                  ? Colors.amber.withAlpha(25) 
                                                  : drugColor.withAlpha(25),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isCustom 
                                                    ? Colors.amber.withAlpha(100) 
                                                    : drugColor.withAlpha(100),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                genericName.isNotEmpty 
                                                    ? genericName[0].toUpperCase() 
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCustom ? Colors.amber[700] : drugColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isCustom)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: Colors.amber,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                ),
                                                child: const Icon(
                                                  Icons.star,
                                                  size: 8,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(
                                        genericName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            brandNames.join(', '),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: drugColor.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  DrugModel.getCategoryDisplayName(category),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: drugColor,
                                                  ),
                                                ),
                                              ),
                                              if (isCustom) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withAlpha(30),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'CUSTOM',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.amber[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              Icon(Icons.local_pharmacy, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${brandNames.length} brand${brandNames.length == 1 ? '' : 's'}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        if (drug is DrugModel) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DrugDetailScreen(drug: drug),
                                            ),
                                          );
                                        } else {
                                          // Show basic info for custom drugs
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(genericName),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('Brands: ${brandNames.join(", ")}'),
                                                    const SizedBox(height: 8),
                                                    Text('Category: ${DrugModel.getCategoryDisplayName(category)}'),
                                                    if (drug is CustomDrug && drug.description.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Text('Description: ${drug.description}'),
                                                    ],
                                                    if (drug is CustomDrug && drug.dosage != null) ...[
                                                      const SizedBox(height: 8),
                                                      Text('Dosage: ${drug.dosage}'),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Positioned FAB at bottom right
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddDrugScreen()),
                      );
                      if (result == true) {
                        _loadDrugs(); // Refresh list after adding
                      }
                    },
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    tooltip: 'Add Drug',
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
