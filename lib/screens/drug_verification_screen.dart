import 'package:flutter/material.dart';
import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../models/user_medication.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class DrugVerificationScreen extends StatefulWidget {
  const DrugVerificationScreen({super.key});

  @override
  State<DrugVerificationScreen> createState() => _DrugVerificationScreenState();
}

class _DrugVerificationScreenState extends State<DrugVerificationScreen> {
  final _authService = AuthService();
  List<_VerificationRequest> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    final allUsers = await _authService.getAllUsers();
    final requests = <_VerificationRequest>[];

    for (final user in allUsers) {
      if (user.role != 'patient') continue;
      
      for (final med in user.medications) {
        if (med.verificationStatus == 'pending') {
          final drug = DrugData.getDrugById(med.drugId);
          if (drug != null) {
            requests.add(_VerificationRequest(
              user: user,
              medication: med,
              drug: drug,
            ));
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyMedication(_VerificationRequest request, bool isApproved) async {
    final status = isApproved ? 'verified' : 'rejected';
    
    // Optimistic update
    setState(() {
      _pendingRequests.remove(request);
    });

    final success = await _authService.verifyMedication(
      request.user.id,
      request.medication.drugId,
      status,
    );

    if (!success && mounted) {
      // Revert if failed (simple reload)
      _loadPendingRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status. Please try again.')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApproved ? 'Prescription verified' : 'Prescription rejected'),
          backgroundColor: isApproved ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Failed to load image'),
                    ],
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Prescriptions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending verifications',
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
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text(request.user.fullName[0].toUpperCase()),
                            ),
                            title: Text(request.user.fullName),
                            subtitle: Text('OP: ${request.user.opNumber ?? "N/A"}'),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                GestureDetector(
                                  onTap: () {
                                    if (request.medication.prescriptionUrl != null) {
                                      _showImageDialog(request.medication.prescriptionUrl!);
                                    }
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: request.medication.prescriptionUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              request.medication.prescriptionUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ),
                                          )
                                        : const Icon(Icons.no_photography, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.drug.genericName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (request.medication.brandName.isNotEmpty)
                                        Text(
                                          'Brand: ${request.medication.brandName}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      Text(
                                        'Category: ${DrugModel.getCategoryDisplayName(request.drug.category)}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _verifyMedication(request, false),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () => _verifyMedication(request, true),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _VerificationRequest {
  final UserModel user;
  final UserMedication medication;
  final DrugModel drug;

  _VerificationRequest({
    required this.user,
    required this.medication,
    required this.drug,
  });
}
