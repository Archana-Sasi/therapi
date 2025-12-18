import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../services/auth_service.dart';
import 'drug_detail_screen.dart';

/// Screen showing the user's selected medications
class MyMedicationsScreen extends StatefulWidget {
  const MyMedicationsScreen({super.key});

  static const route = '/my-medications';

  @override
  State<MyMedicationsScreen> createState() => _MyMedicationsScreenState();
}

class _MyMedicationsScreenState extends State<MyMedicationsScreen> {
  final _authService = AuthService();
  List<_MedicationWithBrand> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    
    final medicationMaps = await _authService.getCurrentUserMedications();
    final drugs = <_MedicationWithBrand>[];
    
    for (final med in medicationMaps) {
      final drug = DrugData.getDrugById(med['drugId'] ?? '');
      if (drug != null) {
        drugs.add(_MedicationWithBrand(
          drug: drug,
          brandName: med['brandName'] ?? '',
        ));
      }
    }
    
    if (mounted) {
      setState(() {
        _medications = drugs;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMedication(_MedicationWithBrand med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medication'),
        content: Text('Are you sure you want to remove ${med.drug.genericName}${med.brandName.isNotEmpty ? ' (${med.brandName})' : ''} from your medications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _authService.removeMedication(med.drug.id, med.brandName);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${med.drug.genericName} removed from your medications')),
        );
        _loadMedications();
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'bronchodilator':
        return const Color(0xFF2196F3);
      case 'corticosteroid':
        return const Color(0xFFFF9100);
      case 'anticholinergic':
        return const Color(0xFF00BFA6);
      case 'leukotriene_modifier':
        return const Color(0xFF7C4DFF);
      case 'antihistamine':
        return const Color(0xFFE91E63);
      case 'mucolytic':
        return const Color(0xFF00C853);
      case 'combination':
        return const Color(0xFF3D5AFE);
      case 'antibiotic':
        return const Color(0xFFFF5252);
      case 'antifibrotic':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No medications added yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Browse the Drug Directory and add medications you are currently taking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.search),
                          label: const Text('Browse Drugs'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    final drug = med.drug;
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
                            // Show selected brand prominently
                            if (med.brandName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      med.brandName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                drug.brandNames.join(', '),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
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
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeMedication(med),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DrugDetailScreen(drug: drug),
                            ),
                          );
                          _loadMedications(); // Refresh after returning
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

/// Helper class to hold medication with its selected brand
class _MedicationWithBrand {
  const _MedicationWithBrand({
    required this.drug,
    required this.brandName,
  });

  final DrugModel drug;
  final String brandName;
}

