import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../models/medication_reminder.dart';
import '../services/auth_service.dart';
import 'drug_detail_screen.dart';
import 'medication_reminder_screen.dart';

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
  Map<String, MedicationReminder?> _reminders = {}; // drugId -> reminder
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    
    final medicationMaps = await _authService.getCurrentUserMedications();
    final allReminders = await _authService.getMedicationReminders();
    final drugs = <_MedicationWithBrand>[];
    final remindersMap = <String, MedicationReminder?>{};
    
    for (final med in medicationMaps) {
      final drugId = med['drugId'] ?? '';
      final drug = DrugData.getDrugById(drugId);
      if (drug != null) {
        drugs.add(_MedicationWithBrand(
          drug: drug,
          brandName: med['brandName'] ?? '',
        ));
        // Find reminder for this drug
        remindersMap[drugId] = allReminders.cast<MedicationReminder?>().firstWhere(
          (r) => r?.drugId == drugId,
          orElse: () => null,
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _medications = drugs;
        _reminders = remindersMap;
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
                    final reminder = _reminders[drug.id];
                    final hasReminder = reminder != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DrugDetailScreen(drug: drug),
                            ),
                          );
                          _loadMedications(); // Refresh after returning
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Drug icon
                                  Container(
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
                                  const SizedBox(width: 12),
                                  // Drug info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drug.genericName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Show selected brand
                                        if (med.brandName.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            margin: const EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  med.brandName,
                                                  style: TextStyle(
                                                    fontSize: 11,
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
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        // Category chip
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
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: categoryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removeMedication(med),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // Reminder section
                              Row(
                                children: [
                                  Icon(
                                    hasReminder ? Icons.alarm_on : Icons.alarm_off,
                                    size: 20,
                                    color: hasReminder ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: hasReminder
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reminder.getFormattedTimes(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${reminder.dosage} • ${reminder.getFormattedDays()}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'No reminder set',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MedicationReminderScreen(
                                            drugId: drug.id,
                                            brandName: med.brandName,
                                            existingReminder: reminder,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadMedications();
                                      }
                                    },
                                    icon: Icon(
                                      hasReminder ? Icons.edit : Icons.add_alarm,
                                      size: 16,
                                    ),
                                    label: Text(hasReminder ? 'Edit' : 'Set'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      visualDensity: VisualDensity.compact,
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

