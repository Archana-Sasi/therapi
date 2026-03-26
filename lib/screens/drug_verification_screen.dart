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
  List<_PrescriptionGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    final allUsers = await _authService.getAllUsers();

    // Collect all pending requests
    final allRequests = <_VerificationRequest>[];
    for (final user in allUsers) {
      if (user.role != 'patient') continue;
      for (final med in user.medications) {
        if (med.verificationStatus == 'pending') {
          final drug = DrugData.getDrugById(med.drugId);
          if (drug != null) {
            allRequests.add(_VerificationRequest(
              user: user,
              medication: med,
              drug: drug,
            ));
          }
        }
      }
    }

    // Group by user + prescription URL
    final groupMap = <String, _PrescriptionGroup>{};
    for (final request in allRequests) {
      final key = '${request.user.id}_${request.medication.prescriptionUrl ?? 'none'}';
      if (!groupMap.containsKey(key)) {
        groupMap[key] = _PrescriptionGroup(
          user: request.user,
          prescriptionUrl: request.medication.prescriptionUrl,
          requests: [],
        );
      }
      groupMap[key]!.requests.add(request);
    }

    if (mounted) {
      setState(() {
        _groups = groupMap.values.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyMedication(_VerificationRequest request, bool isApproved) async {
    final status = isApproved ? 'verified' : 'rejected';

    final success = await _authService.verifyMedication(
      request.user.id,
      request.medication.drugId,
      status,
    );

    if (!success && mounted) {
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
    _loadPendingRequests();
  }

  Future<void> _verifyAllInGroup(_PrescriptionGroup group, bool isApproved) async {
    final status = isApproved ? 'verified' : 'rejected';
    bool allSuccess = true;

    for (final request in group.requests) {
      final success = await _authService.verifyMedication(
        request.user.id,
        request.medication.drugId,
        status,
      );
      if (!success) allSuccess = false;
    }

    if (mounted) {
      if (!allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some updates failed. Please try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved
                ? 'All ${group.requests.length} medications approved'
                : 'All ${group.requests.length} medications rejected'),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );
      }
    }
    _loadPendingRequests();
  }

  void _showImageDialog(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Prescription Image'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          : _groups.isEmpty
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
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient info header
                          ListTile(
                            leading: CircleAvatar(
                              child: Text(group.user.fullName[0].toUpperCase()),
                            ),
                            title: Text(group.user.fullName),
                            subtitle: Text('OP: ${group.user.opNumber ?? "N/A"}'),
                            trailing: group.requests.length > 1
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${group.requests.length} drugs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const Divider(height: 0),

                          // Prescription image
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (group.prescriptionUrl != null) {
                                      _showImageDialog(group.prescriptionUrl!);
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
                                    child: group.prescriptionUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              group.prescriptionUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.broken_image),
                                            ),
                                          )
                                        : const Icon(Icons.no_photography, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Drug list
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: group.requests.map((request) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.medication, size: 18, color: Colors.blue),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    request.drug.genericName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (request.medication.brandName.isNotEmpty)
                                                    Text(
                                                      request.medication.brandName,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action buttons
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                if (group.requests.length > 1) ...[
                                  // Batch actions for multi-drug groups
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _verifyAllInGroup(group, false),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Reject All'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _verifyAllInGroup(group, true),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Approve All'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Single drug actions
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _verifyMedication(group.requests.first, false),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _verifyMedication(group.requests.first, true),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
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

class _PrescriptionGroup {
  final UserModel user;
  final String? prescriptionUrl;
  final List<_VerificationRequest> requests;

  _PrescriptionGroup({
    required this.user,
    required this.prescriptionUrl,
    required this.requests,
  });
}
