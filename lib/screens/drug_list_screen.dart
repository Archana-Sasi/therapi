import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import '../models/drug_model.dart';
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
  List<DrugModel> _filteredDrugs = [];
  List<DrugModel> _allDrugs = [];

  @override
  void initState() {
    super.initState();
    _allDrugs = DrugData.getDrugsByDisease(widget.diseaseId);
    _filteredDrugs = _allDrugs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDrugs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrugs = _allDrugs;
      } else {
        _filteredDrugs = DrugData.searchDrugs(query, diseaseId: widget.diseaseId);
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'bronchodilator':
        return const Color(0xFF2196F3); // Blue
      case 'corticosteroid':
        return const Color(0xFFFF9100); // Amber
      case 'anticholinergic':
        return const Color(0xFF00BFA6); // Teal
      case 'leukotriene_modifier':
        return const Color(0xFF7C4DFF); // Purple
      case 'antihistamine':
        return const Color(0xFFE91E63); // Pink
      case 'mucolytic':
        return const Color(0xFF00C853); // Green
      case 'combination':
        return const Color(0xFF3D5AFE); // Indigo
      case 'antibiotic':
        return const Color(0xFFFF5252); // Red
      case 'antifibrotic':
        return const Color(0xFF795548); // Brown
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diseaseName),
        centerTitle: true,
      ),
      body: Column(
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
                      final categoryColor = _getCategoryColor(drug.category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                drug.genericName[0],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            drug.genericName,
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
                                drug.brandNames.join(', '),
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
                                      color: categoryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DrugModel.getCategoryDisplayName(drug.category),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      drug.doseForm,
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
    );
  }
}
