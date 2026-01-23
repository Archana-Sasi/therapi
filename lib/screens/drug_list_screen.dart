import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/drug_data.dart';
import '../data/tamil_translations.dart';
import '../models/custom_drug.dart';
import '../models/drug_model.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'drug_detail_screen.dart';

/// Screen showing drugs filtered by a specific respiratory disease
class DrugListScreen extends StatefulWidget {
  const DrugListScreen({
    super.key,
    required this.diseaseId,
    required this.diseaseName,
  });

  final String diseaseId;
  final String diseaseName;

  @override
  State<DrugListScreen> createState() => _DrugListScreenState();
}

class _DrugListScreenState extends State<DrugListScreen> {
  final _searchController = TextEditingController();
  final _authService = AuthService();
  
  List<dynamic> _filteredDrugs = [];
  List<dynamic> _allDrugs = [];
  List<CustomDrug> _customDrugs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrugs();
  }

  Future<void> _loadDrugs() async {
    setState(() => _isLoading = true);
    
    // Load static drugs for this disease
    final staticDrugs = DrugData.getDrugsByDisease(widget.diseaseId);
    
    // Load custom drugs from Firestore and filter by disease
    final allCustomDrugs = await _authService.getCustomDrugs();
    _customDrugs = allCustomDrugs
        .where((d) => d.diseases.contains(widget.diseaseId))
        .toList();
    
    // Combine both lists
    _allDrugs = [...staticDrugs, ..._customDrugs];
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

  String _getDrugDoseForm(dynamic drug) {
    if (drug is DrugModel) return drug.doseForm;
    if (drug is CustomDrug) return drug.doseForm;
    return '';
  }

  bool _isCustomDrug(dynamic drug) => drug is CustomDrug;

  void _filterDrugs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrugs = _allDrugs;
      } else {
        _filteredDrugs = _allDrugs.where((drug) =>
            _getDrugGenericName(drug).toLowerCase().contains(query.toLowerCase()) ||
            _getDrugBrandNames(drug).any((b) => b.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final isTamil = langProvider.isTamil;

    // Helper for translations
    String t(String english) =>
        isTamil ? TamilTranslations.getLabel(english) : english;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diseaseName),
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
                hintText: isTamil
                    ? 'பொதுப் பெயர் அல்லது வர்த்தக பெயரில் தேடுக...'
                    : 'Search by generic or brand name...',
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
                if (_customDrugs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${_customDrugs.length} ${t('custom')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Drug List with enhanced display
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = _filteredDrugs[index];
                      final genericName = _getDrugGenericName(drug);
                      final brandNames = _getDrugBrandNames(drug);
                      final category = _getDrugCategory(drug);
                      final doseForm = _getDrugDoseForm(drug);
                      final isCustom = _isCustomDrug(drug);
                      const drugColor = AppColors.primary;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (drug is DrugModel) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DrugDetailScreen(drug: drug),
                                ),
                              );
                            } else if (drug is CustomDrug) {
                              _showCustomDrugDialog(drug, isTamil, t);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row with icon and category
                                Row(
                                  children: [
                                    // Drug initial icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isCustom 
                                            ? Colors.amber.withAlpha(25)
                                            : drugColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          genericName.isNotEmpty ? genericName[0] : '?',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isCustom ? Colors.amber[700] : drugColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Category and dose form
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: drugColor.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isTamil
                                                      ? TamilTranslations.getCategory(
                                                          DrugModel.getCategoryDisplayName(category))
                                                      : DrugModel.getCategoryDisplayName(category),
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
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    t('CUSTOM'),
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.amber[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            doseForm,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                
                                // Generic Name Section
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        t('Generic'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        genericName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 10),
                                
                                // Brand Names Section
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        t('Brands'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: brandNames.map((brand) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withAlpha(20),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.blue.withAlpha(50),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            brand,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCustomDrugDialog(CustomDrug drug, bool isTamil, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(drug.genericName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(t('Brand Names'), drug.brandNames.join(', ')),
              _buildInfoRow(t('Category'), 
                  isTamil 
                      ? TamilTranslations.getCategory(DrugModel.getCategoryDisplayName(drug.category))
                      : DrugModel.getCategoryDisplayName(drug.category)),
              _buildInfoRow(t('Dose Form'), drug.doseForm),
              if (drug.description.isNotEmpty)
                _buildInfoRow(t('Description'), drug.description),
              if (drug.dosage != null && drug.dosage!.isNotEmpty)
                _buildInfoRow(t('Dosage'), drug.dosage!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
