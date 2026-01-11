import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curated_medicine_data.dart';
import '../data/drug_data.dart';
import '../data/tamil_translations.dart';
import '../models/custom_drug.dart';
import '../models/drug_model.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'drug_detail_screen.dart';

/// Screen showing all drugs alphabetically - user can search and select any drug
class DrugDirectoryScreen extends StatefulWidget {
  const DrugDirectoryScreen({super.key});

  static const route = '/drug-directory';

  @override
  State<DrugDirectoryScreen> createState() => _DrugDirectoryScreenState();
}

class _DrugDirectoryScreenState extends State<DrugDirectoryScreen> {
  final _searchController = TextEditingController();
  final _authService = AuthService();
  
  List<dynamic> _filteredDrugs = [];
  List<dynamic> _allDrugs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  Future<void> _loadDrugs() async {
    setState(() => _isLoading = true);
    
    // Load all static drugs (existing respiratory drugs)
    final staticDrugs = List<DrugModel>.from(DrugData.drugs);
    
    // Load curated medicines (600 from Kaggle dataset)
    final curatedMedicines = CuratedMedicineData.medicines;
    
    // Load custom drugs
    final customDrugs = await _authService.getCustomDrugs();
    
    // Combine all: static drugs + curated medicines + custom drugs
    _allDrugs = [...staticDrugs, ...curatedMedicines, ...customDrugs];
    _allDrugs.sort((a, b) => _getGenericName(a).compareTo(_getGenericName(b)));
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

  String _getGenericName(dynamic drug) {
    if (drug is DrugModel) return drug.genericName;
    if (drug is CustomDrug) return drug.genericName;
    if (drug is CuratedMedicine) return drug.genericName;
    return '';
  }

  List<String> _getBrandNames(dynamic drug) {
    if (drug is DrugModel) return drug.brandNames;
    if (drug is CustomDrug) return drug.brandNames;
    if (drug is CuratedMedicine) return [drug.brandName];
    return [];
  }

  String _getDoseForm(dynamic drug) {
    if (drug is DrugModel) return drug.doseForm;
    if (drug is CustomDrug) return drug.doseForm;
    if (drug is CuratedMedicine) return drug.category;
    return '';
  }

  bool _isCustom(dynamic drug) => drug is CustomDrug;
  bool _isCurated(dynamic drug) => drug is CuratedMedicine;

  void _filterDrugs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrugs = _allDrugs;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredDrugs = _allDrugs.where((drug) =>
            _getGenericName(drug).toLowerCase().contains(lowerQuery) ||
            _getBrandNames(drug).any((b) => b.toLowerCase().contains(lowerQuery))
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final isTamil = langProvider.isTamil;
    
    // Helper function to get translated label
    String t(String english) => isTamil ? TamilTranslations.getLabel(english) : english;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Drug Directory')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrugs,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterDrugs,
              decoration: InputDecoration(
                hintText: isTamil ? 'பொதுப் பெயர் அல்லது வர்த்தக பெயரில் தேடுக...' : 'Search by generic or brand name...',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.medication, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_filteredDrugs.length} ${t('medications')}',
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
                          t('No medications found'),
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('Try a different search term'),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = _filteredDrugs[index];
                      final genericName = _getGenericName(drug);
                      final brandNames = _getBrandNames(drug);
                      final doseForm = _getDoseForm(drug);
                      final isCustom = _isCustom(drug);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCustom 
                                  ? Colors.amber.withAlpha(30)
                                  : AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                genericName.isNotEmpty ? genericName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCustom ? Colors.amber[700] : AppColors.primary,
                                ),
                              ),
                            ),
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
                              const SizedBox(height: 2),
                              Text(
                                brandNames.isNotEmpty ? brandNames.join(', ') : 'No brand names',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (doseForm.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  doseForm,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
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
                            } else if (drug is CustomDrug) {
                              _showCustomDrugDialog(drug);
                            } else if (drug is CuratedMedicine) {
                              _showCuratedMedicineDialog(drug);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCustomDrugDialog(CustomDrug drug) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(drug.genericName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Brand Names', drug.brandNames.join(', ')),
              _buildInfoRow('Dose Form', drug.doseForm),
              if (drug.description.isNotEmpty)
                _buildInfoRow('Description', drug.description),
              if (drug.dosage != null && drug.dosage!.isNotEmpty)
                _buildInfoRow('Dosage', drug.dosage!),
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

  void _showCuratedMedicineDialog(CuratedMedicine medicine) {
    final langProvider = context.read<LanguageProvider>();
    final isTamil = langProvider.isTamil;
    
    // Helper for labels
    String t(String english) => isTamil ? TamilTranslations.getLabel(english) : english;
    // Helper for categories
    String cat(String english) => isTamil ? TamilTranslations.getCategory(english) : english;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(medicine.brandName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(t('Generic Name'), medicine.genericName),
              _buildInfoRow(t('Category'), cat(medicine.category)),
              _buildInfoRow(t('Manufacturer'), medicine.manufacturer),
              if (medicine.price != null && medicine.price!.isNotEmpty)
                _buildInfoRow(t('Price'), medicine.price!),
              if (medicine.description != null && medicine.description!.isNotEmpty)
                _buildInfoRow(t('Description'), medicine.description!),
              if (medicine.sideEffects != null && medicine.sideEffects!.isNotEmpty)
                _buildInfoRow(
                  t('Side Effects'), 
                  isTamil 
                      ? TamilTranslations.translateSideEffects(medicine.sideEffects!)
                      : medicine.sideEffects!.replaceAll(',', ', '),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('Close')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}
