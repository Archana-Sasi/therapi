import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/drug_data.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  static const route = '/analytics';

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

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
    final patients = _users.where((u) => u.role == 'patient').toList();
    final pharmacists = _users.where((u) => u.role == 'pharmacist').toList();
    final admins = _users.where((u) => u.role == 'admin').toList();

    // Calculate medication statistics
    final patientsWithMeds = patients.where((p) => p.medications.isNotEmpty).length;
    final totalMedications = patients.fold<int>(
        0, (sum, p) => sum + p.medications.length);
    
    // Get top medications
    final medicationCounts = <String, int>{};
    for (final patient in patients) {
      for (final med in patient.medications) {
        medicationCounts[med.drugId] = (medicationCounts[med.drugId] ?? 0) + 1;
      }
    }
    final sortedMeds = medicationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMedications = sortedMeds.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Section
                    _buildSectionTitle('Overview', Icons.dashboard_outlined),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Users',
                            _users.length.toString(),
                            Icons.people,
                            const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Patients',
                            patients.length.toString(),
                            Icons.person,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pharmacists',
                            pharmacists.length.toString(),
                            Icons.local_pharmacy,
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Admins',
                            admins.length.toString(),
                            Icons.admin_panel_settings,
                            const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User Distribution Chart
                    _buildSectionTitle('User Distribution', Icons.pie_chart_outline),
                    const SizedBox(height: 12),
                    _buildDistributionChart(patients.length, pharmacists.length, admins.length),
                    const SizedBox(height: 24),

                    // Medication Statistics
                    _buildSectionTitle('Medication Statistics', Icons.medication_outlined),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Patients on Meds',
                            patientsWithMeds.toString(),
                            Icons.people_outline,
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Prescriptions',
                            totalMedications.toString(),
                            Icons.receipt_long_outlined,
                            const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Medication adherence rate
                    if (patients.isNotEmpty)
                      _buildProgressCard(
                        'Medication Adoption Rate',
                        patientsWithMeds / patients.length,
                        '${(patientsWithMeds / patients.length * 100).toStringAsFixed(1)}% of patients have medications',
                        const Color(0xFF10B981),
                      ),
                    const SizedBox(height: 24),

                    // Top Medications
                    _buildSectionTitle('Top Medications', Icons.trending_up),
                    const SizedBox(height: 12),
                    if (topMedications.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.medication_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'No medication data yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: topMedications.asMap().entries.map((entry) {
                              final index = entry.key;
                              final med = entry.value;
                              final drug = DrugData.getDrugById(med.key);
                              final maxCount = topMedications.first.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                    top: index == 0 ? 0 : 12),
                                child: _buildMedicationBar(
                                  drug?.genericName ?? 'Unknown',
                                  med.value,
                                  med.value / maxCount,
                                  _getMedicationColor(index),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Age Distribution (if available)
                    _buildSectionTitle('Patient Demographics', Icons.people_alt_outlined),
                    const SizedBox(height: 12),
                    _buildDemographicsCard(patients),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD32F2F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(int patients, int pharmacists, int admins) {
    final total = patients + pharmacists + admins;
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('No user data', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Visual bar chart
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    if (patients > 0)
                      Expanded(
                        flex: patients,
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    if (pharmacists > 0)
                      Expanded(
                        flex: pharmacists,
                        child: Container(color: const Color(0xFF3B82F6)),
                      ),
                    if (admins > 0)
                      Expanded(
                        flex: admins,
                        child: Container(color: const Color(0xFFEF4444)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Patients', patients, total, const Color(0xFF10B981)),
                _buildLegendItem('Pharmacists', pharmacists, total, const Color(0xFF3B82F6)),
                _buildLegendItem('Admins', admins, total, const Color(0xFFEF4444)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(String title, double progress, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationBar(String name, int count, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count patients',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getMedicationColor(int index) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  Widget _buildDemographicsCard(List<UserModel> patients) {
    final withAge = patients.where((p) => p.age != null).toList();
    final withGender = patients.where((p) => p.gender != null).toList();

    // Age groups
    final ageGroups = <String, int>{
      '0-18': 0,
      '19-35': 0,
      '36-50': 0,
      '51-65': 0,
      '65+': 0,
    };
    for (final patient in withAge) {
      final age = patient.age!;
      if (age <= 18) {
        ageGroups['0-18'] = ageGroups['0-18']! + 1;
      } else if (age <= 35) {
        ageGroups['19-35'] = ageGroups['19-35']! + 1;
      } else if (age <= 50) {
        ageGroups['36-50'] = ageGroups['36-50']! + 1;
      } else if (age <= 65) {
        ageGroups['51-65'] = ageGroups['51-65']! + 1;
      } else {
        ageGroups['65+'] = ageGroups['65+']! + 1;
      }
    }

    // Gender distribution
    final genderCounts = <String, int>{
      'male': 0,
      'female': 0,
      'other': 0,
    };
    for (final patient in withGender) {
      final gender = patient.gender!.toLowerCase();
      genderCounts[gender] = (genderCounts[gender] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gender Distribution
            const Text(
              'Gender Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (withGender.isEmpty)
              Text('No gender data available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13))
            else
              Row(
                children: [
                  _buildGenderChip('Male', genderCounts['male']!, const Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  _buildGenderChip('Female', genderCounts['female']!, const Color(0xFFEC4899)),
                  const SizedBox(width: 8),
                  _buildGenderChip('Other', genderCounts['other']!, const Color(0xFF8B5CF6)),
                ],
              ),
            const SizedBox(height: 20),
            // Age Distribution
            const Text(
              'Age Groups',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (withAge.isEmpty)
              Text('No age data available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ageGroups.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: e.value > 0
                          ? const Color(0xFF6366F1).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: e.value > 0 ? const Color(0xFF6366F1) : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: e.value > 0 ? const Color(0xFF6366F1) : Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Male' ? Icons.male : label == 'Female' ? Icons.female : Icons.transgender,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
