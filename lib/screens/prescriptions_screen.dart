import 'package:flutter/material.dart';

import '../models/prescription_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'create_prescription_screen.dart';

/// Screen showing all prescriptions created by the pharmacist
class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<Prescription> _prescriptions = [];
  List<Prescription> _filteredPrescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    
    final prescriptions = await _authService.getPrescriptionsByPharmacist();
    
    if (mounted) {
      setState(() {
        _prescriptions = prescriptions;
        _filteredPrescriptions = prescriptions;
        _isLoading = false;
      });
    }
  }

  void _filterPrescriptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPrescriptions = _prescriptions;
      } else {
        _filteredPrescriptions = _prescriptions.where((p) =>
            p.patientName.toLowerCase().contains(query.toLowerCase()) ||
            p.genericName.toLowerCase().contains(query.toLowerCase()) ||
            p.brandName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _deletePrescription(Prescription prescription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: Text('Are you sure you want to delete prescription for ${prescription.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _authService.deletePrescription(prescription.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription deleted'), backgroundColor: Colors.green),
        );
        _loadPrescriptions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
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
                    onChanged: _filterPrescriptions,
                    decoration: InputDecoration(
                      hintText: 'Search by patient or medication...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterPrescriptions('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredPrescriptions.length} prescription${_filteredPrescriptions.length == 1 ? '' : 's'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_prescriptions.where((p) => p.isActive).length} active',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Prescriptions List
                Expanded(
                  child: _filteredPrescriptions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _prescriptions.isEmpty
                                    ? 'No prescriptions yet'
                                    : 'No matching prescriptions',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_prescriptions.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to create your first prescription',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filteredPrescriptions.length,
                          itemBuilder: (context, index) {
                            final prescription = _filteredPrescriptions[index];
                            return _PrescriptionCard(
                              prescription: prescription,
                              onDelete: () => _deletePrescription(prescription),
                              onToggleActive: () async {
                                await _authService.togglePrescriptionActive(
                                  prescription.id,
                                  !prescription.isActive,
                                );
                                _loadPrescriptions();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePrescriptionScreen()),
          );
          if (result == true) {
            _loadPrescriptions();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create Prescription',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Card widget for displaying a prescription
class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Prescription prescription;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(30),
                  child: Text(
                    prescription.patientName.isNotEmpty 
                        ? prescription.patientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        prescription.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: prescription.isActive
                        ? Colors.green.withAlpha(30)
                        : Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prescription.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: prescription.isActive ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Medication Info
            Row(
              children: [
                Icon(Icons.medication, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${prescription.genericName} (${prescription.brandName})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Dosage
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  prescription.dosage,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Duration
            Row(
              children: [
                Icon(Icons.timelapse, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${prescription.duration}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            
            if (prescription.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prescription.instructions,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    prescription.isActive ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(prescription.isActive ? 'Deactivate' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor: prescription.isActive ? Colors.orange : Colors.green,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
