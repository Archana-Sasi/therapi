import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/drug_data.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const route = '/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _selectedReport = 'users';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = AuthService();
    final users = await authService.getAllUsers();
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (mounted) {
      setState(() {
        _users = users.where((u) => u.id != currentUserId).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Report Type Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildReportChip('users', 'User Report', Icons.people_outline),
                        const SizedBox(width: 8),
                        _buildReportChip('medications', 'Medication Report', Icons.medication_outlined),
                        const SizedBox(width: 8),
                        _buildReportChip('activity', 'Activity Report', Icons.timeline_outlined),
                      ],
                    ),
                  ),
                ),
                // Report Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildReportContent(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportChip(String id, String label, IconData icon) {
    final isSelected = _selectedReport == id;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedReport = id);
      },
      selectedColor: const Color(0xFF6366F1),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF6366F1),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
      side: BorderSide(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReport) {
      case 'users':
        return _buildUserReport();
      case 'medications':
        return _buildMedicationReport();
      case 'activity':
        return _buildActivityReport();
      default:
        return _buildUserReport();
    }
  }

  Widget _buildUserReport() {
    final patients = _users.where((u) => u.role == 'patient').toList();
    final pharmacists = _users.where((u) => u.role == 'pharmacist').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildReportCard(
          title: 'User Summary',
          icon: Icons.summarize_outlined,
          child: Column(
            children: [
              _buildSummaryRow('Total Registered Users', _users.length.toString()),
              _buildSummaryRow('Patients', patients.length.toString()),
              _buildSummaryRow('Pharmacists', pharmacists.length.toString()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // User List
        _buildReportCard(
          title: 'All Users',
          icon: Icons.list_alt_outlined,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    )),
                    Expanded(flex: 2, child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Expanded(flex: 1, child: Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Data rows
              ..._users.take(10).map((user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName : user.email,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        user.age?.toString() ?? '-',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
              if (_users.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${_users.length - 10} more users',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Export Button
        _buildExportButton('Export User Report'),
      ],
    );
  }

  Widget _buildMedicationReport() {
    final patients = _users.where((u) => u.role == 'patient').toList();
    final patientsWithMeds = patients.where((p) => p.medications.isNotEmpty).toList();
    final totalMeds = patients.fold<int>(0, (sum, p) => sum + p.medications.length);

    // Medication frequency
    final medicationCounts = <String, int>{};
    for (final patient in patients) {
      for (final med in patient.medications) {
        medicationCounts[med.drugId] = (medicationCounts[med.drugId] ?? 0) + 1;
      }
    }
    final sortedMeds = medicationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        _buildReportCard(
          title: 'Medication Summary',
          icon: Icons.analytics_outlined,
          child: Column(
            children: [
              _buildSummaryRow('Total Patients', patients.length.toString()),
              _buildSummaryRow('Patients with Medications', patientsWithMeds.length.toString()),
              _buildSummaryRow('Patients without Medications', (patients.length - patientsWithMeds.length).toString()),
              _buildSummaryRow('Total Medication Entries', totalMeds.toString()),
              _buildSummaryRow('Unique Medications', medicationCounts.length.toString()),
              _buildSummaryRow('Avg Meds per Patient', patients.isNotEmpty
                  ? (totalMeds / patients.length).toStringAsFixed(1)
                  : '0'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top Medications
        _buildReportCard(
          title: 'Most Prescribed Medications',
          icon: Icons.trending_up,
          child: sortedMeds.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No medication data', style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              : Column(
                  children: sortedMeds.take(10).map((entry) {
                    final drug = DrugData.getDrugById(entry.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              drug?.genericName ?? 'Unknown',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value} patients',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Export Button
        _buildExportButton('Export Medication Report'),
      ],
    );
  }

  Widget _buildActivityReport() {
    final now = DateTime.now();
    final patients = _users.where((u) => u.role == 'patient').toList();
    final withMeds = patients.where((p) => p.medications.isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Report Info Card
        _buildReportCard(
          title: 'Report Information',
          icon: Icons.info_outline,
          child: Column(
            children: [
              _buildSummaryRow('Report Generated', '${now.day}/${now.month}/${now.year}'),
              _buildSummaryRow('Report Time', '${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
              _buildSummaryRow('Report Period', 'All Time'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Activity Summary
        _buildReportCard(
          title: 'Activity Summary',
          icon: Icons.timeline_outlined,
          child: Column(
            children: [
              _buildSummaryRow('Total Users', _users.length.toString()),
              _buildSummaryRow('Active Patients (with Meds)', withMeds.toString()),
              _buildSummaryRow('Inactive Patients', (patients.length - withMeds).toString()),
              _buildSummaryRow('Medication Adoption Rate',
                  patients.isNotEmpty
                      ? '${(withMeds / patients.length * 100).toStringAsFixed(1)}%'
                      : 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // System Status
        _buildReportCard(
          title: 'System Status',
          icon: Icons.check_circle_outline,
          child: Column(
            children: [
              _buildStatusRow('Database', 'Connected', Colors.green),
              _buildStatusRow('Authentication', 'Active', Colors.green),
              _buildStatusRow('Notifications', 'Enabled', Colors.green),
              _buildStatusRow('Analytics', 'Running', Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Export Button
        _buildExportButton('Export Activity Report'),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFFD32F2F)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.download_outlined),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'pharmacist':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }
}
