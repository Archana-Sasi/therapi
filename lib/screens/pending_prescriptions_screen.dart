import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class PendingPrescriptionsScreen extends StatefulWidget {
  const PendingPrescriptionsScreen({super.key});

  @override
  State<PendingPrescriptionsScreen> createState() => _PendingPrescriptionsScreenState();
}

class _PendingPrescriptionsScreenState extends State<PendingPrescriptionsScreen> {
  final _authService = AuthService();
  List<Prescription> _pendingPrescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPrescriptions();
  }

  Future<void> _loadPendingPrescriptions() async {
    setState(() => _isLoading = true);
    final prescriptions = await _authService.getPendingPrescriptions();
    if (mounted) {
      setState(() {
        _pendingPrescriptions = prescriptions;
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePrescription(Prescription prescription) async {
    final success = await _authService.approvePrescription(prescription);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription approved and sent to patient'), backgroundColor: Colors.green),
        );
        _loadPendingPrescriptions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve prescription'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectPrescription(Prescription prescription) async {
    final success = await _authService.rejectPrescription(prescription.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription rejected'), backgroundColor: Colors.orange),
        );
        _loadPendingPrescriptions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject prescription'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Prescriptions'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingPrescriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green[200]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending prescriptions',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingPrescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = _pendingPrescriptions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  prescription.patientName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PENDING',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Doctor: ${prescription.doctorName ?? "Unknown"}'),
                            const Divider(),
                            ...prescription.effectiveMedications.map((med) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${med.genericName} (${med.brandName}) — ${med.dosage}',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            )),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _rejectPrescription(prescription),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () => _approvePrescription(prescription),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
