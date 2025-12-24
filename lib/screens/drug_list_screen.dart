import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import '../models/custom_drug.dart';
import '../models/drug_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'drug_detail_screen.dart';

/// Screen showing drugs filtered by a specific disease
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  '${_filteredDrugs.length} medication${_filteredDrugs.length == 1 ? '' : 's'} found',
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
                      '+${_customDrugs.length} custom',
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
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
                                ),
                                child: Center(
                                  child: Text(
                                    genericName.isNotEmpty ? genericName[0] : '?',
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
                              fontSize: 16,
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
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: drugColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DrugModel.getCategoryDisplayName(category),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: drugColor,
                                      ),
                                    ),
                                  ),
                                  if (isCustom) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
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
                                  Expanded(
                                    child: Text(
                                      doseForm,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                            } else if (drug is CustomDrug) {
                              // Show dialog for custom drugs
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
                                        const SizedBox(height: 8),
                                        Text('Dose Form: $doseForm'),
                                        if (drug.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text('Description: ${drug.description}'),
                                        ],
                                        if (drug.dosage != null) ...[
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
    );
  }
}
