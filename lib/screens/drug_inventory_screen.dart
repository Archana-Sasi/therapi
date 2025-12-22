import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../utils/app_colors.dart';
import 'drug_detail_screen.dart';

/// Drug Inventory Screen for Pharmacists to view all medications
class DrugInventoryScreen extends StatefulWidget {
  const DrugInventoryScreen({super.key});

  @override
  State<DrugInventoryScreen> createState() => _DrugInventoryScreenState();
}

class _DrugInventoryScreenState extends State<DrugInventoryScreen> {
  final _searchController = TextEditingController();
  List<DrugModel> _filteredDrugs = [];
  List<DrugModel> _allDrugs = [];
  String _selectedCategory = 'all';
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.apps},
    {'id': 'bronchodilator', 'name': 'Bronchodilators', 'icon': Icons.air},
    {'id': 'corticosteroid', 'name': 'Corticosteroids', 'icon': Icons.healing},
    {'id': 'anticholinergic', 'name': 'Anticholinergics', 'icon': Icons.science},
    {'id': 'combination', 'name': 'Combinations', 'icon': Icons.merge_type},
    {'id': 'mucolytic', 'name': 'Mucolytics', 'icon': Icons.water_drop},
    {'id': 'antibiotic', 'name': 'Antibiotics', 'icon': Icons.medication},
  ];

  @override
  void initState() {
    super.initState();
    _allDrugs = DrugData.drugs;
    _filteredDrugs = _allDrugs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDrugs(String query) {
    setState(() {
      List<DrugModel> drugs = _selectedCategory == 'all'
          ? _allDrugs
          : _allDrugs.where((d) => d.category == _selectedCategory).toList();
      
      if (query.isEmpty) {
        _filteredDrugs = drugs;
      } else {
        _filteredDrugs = drugs.where((drug) =>
            drug.genericName.toLowerCase().contains(query.toLowerCase()) ||
            drug.brandNames.any((b) => b.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      if (category == 'all') {
        _filteredDrugs = _allDrugs;
      } else {
        _filteredDrugs = _allDrugs.where((d) => d.category == category).toList();
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'bronchodilator':
        return const Color(0xFF3B82F6);
      case 'corticosteroid':
        return const Color(0xFFF59E0B);
      case 'anticholinergic':
        return const Color(0xFF14B8A6);
      case 'leukotriene_modifier':
        return const Color(0xFF8B5CF6);
      case 'antihistamine':
        return const Color(0xFFEC4899);
      case 'mucolytic':
        return const Color(0xFF10B981);
      case 'combination':
        return const Color(0xFF6366F1);
      case 'antibiotic':
        return const Color(0xFFEF4444);
      case 'antifibrotic':
        return const Color(0xFF78716C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Inventory'),
        centerTitle: true,
      ),
      body: Container(
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
                    value: '${_allDrugs.fold<int>(0, (sum, d) => sum + d.brandNames.length)}',
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredDrugs.length,
                      itemBuilder: (context, index) {
                        final drug = _filteredDrugs[index];
                        const drugColor = AppColors.primary; // Same color for all drugs
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: drugColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: drugColor.withAlpha(100)),
                              ),
                              child: Center(
                                child: Text(
                                  drug.genericName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: drugColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              drug.genericName,
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
                                  drug.brandNames.join(', '),
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
                                        DrugModel.getCategoryDisplayName(drug.category),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: drugColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.local_pharmacy, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${drug.brandNames.length} brand${drug.brandNames.length == 1 ? '' : 's'}',
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DrugDetailScreen(drug: drug),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
