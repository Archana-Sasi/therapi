import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Reports screen for pharmacists showing patient analytics
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const route = '/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  int _totalPatients = 0;
  int _patientsWithMedications = 0;
  int _totalMedications = 0;
  int _totalSymptomLogs = 0;
  int _totalPrescriptions = 0;
  Map<String, int> _severityDistribution = {};
  List<_PatientAdherence> _adherenceData = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      // Get all patients
      final allUsers = await _authService.getAllUsers();
      final patients = allUsers.where((u) => u.role == 'patient').toList();
      
      int totalMeds = 0;
      int patientsWithMeds = 0;
      int totalSymptomLogs = 0;
      Map<String, int> severityDist = {
        'Mild': 0,
        'Moderate': 0,
        'Severe': 0,
        'Very Severe': 0,
      };
      List<_PatientAdherence> adherence = [];

      for (final patient in patients) {
        // Count medications
        if (patient.medications.isNotEmpty) {
          patientsWithMeds++;
          totalMeds += patient.medications.length;
        }

        // Get symptom logs for this patient
        final logsSnapshot = await _firestore
            .collection('users')
            .doc(patient.id)
            .collection('symptom_logs')
            .get();
        
        totalSymptomLogs += logsSnapshot.docs.length;

        // Calculate severity distribution
        for (final doc in logsSnapshot.docs) {
          final data = doc.data();
          final overallSeverity = _calculateOverallSeverity(data);
          if (overallSeverity < 2) {
            severityDist['Mild'] = (severityDist['Mild'] ?? 0) + 1;
          } else if (overallSeverity < 3) {
            severityDist['Moderate'] = (severityDist['Moderate'] ?? 0) + 1;
          } else if (overallSeverity < 4) {
            severityDist['Severe'] = (severityDist['Severe'] ?? 0) + 1;
          } else {
            severityDist['Very Severe'] = (severityDist['Very Severe'] ?? 0) + 1;
          }
        }

        // Simple adherence calculation (has logged symptoms in last 7 days)
        final recentLogs = logsSnapshot.docs.where((doc) {
          final timestampValue = doc.data()['timestamp'];
          DateTime? timestamp;
          if (timestampValue is Timestamp) {
            timestamp = timestampValue.toDate();
          } else if (timestampValue is String) {
            timestamp = DateTime.tryParse(timestampValue);
          }
          if (timestamp == null) return false;
          return DateTime.now().difference(timestamp).inDays <= 7;
        }).length;

        if (patient.medications.isNotEmpty) {
          adherence.add(_PatientAdherence(
            name: patient.fullName.isNotEmpty ? patient.fullName : patient.email,
            medicationCount: patient.medications.length,
            recentLogsCount: recentLogs,
            isActive: recentLogs > 0,
          ));
        }
      }

      // Get total prescriptions
      final prescriptionsSnapshot = await _firestore.collection('prescriptions').get();

      if (mounted) {
        setState(() {
          _totalPatients = patients.length;
          _patientsWithMedications = patientsWithMeds;
          _totalMedications = totalMeds;
          _totalSymptomLogs = totalSymptomLogs;
          _totalPrescriptions = prescriptionsSnapshot.docs.length;
          _severityDistribution = severityDist;
          _adherenceData = adherence;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reports: $e')),
        );
      }
    }
  }

  double _calculateOverallSeverity(Map<String, dynamic> data) {
    final breathlessness = (data['breathlessness'] as int?) ?? 0;
    final cough = (data['cough'] as int?) ?? 0;
    final wheezing = (data['wheezing'] as int?) ?? 0;
    final chestTightness = (data['chestTightness'] as int?) ?? 0;
    final fatigue = (data['fatigue'] as int?) ?? 0;
    return (breathlessness + cough + wheezing + chestTightness + fatigue) / 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadReportData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          title: 'Total Patients',
                          value: _totalPatients.toString(),
                          icon: Icons.people,
                          color: const Color(0xFF2196F3),
                        ),
                        _buildStatCard(
                          title: 'Active Patients',
                          value: _patientsWithMedications.toString(),
                          icon: Icons.person_pin,
                          color: const Color(0xFF4CAF50),
                        ),
                        _buildStatCard(
                          title: 'Total Medications',
                          value: _totalMedications.toString(),
                          icon: Icons.medication,
                          color: const Color(0xFFFF9800),
                        ),
                        _buildStatCard(
                          title: 'Prescriptions',
                          value: _totalPrescriptions.toString(),
                          icon: Icons.receipt_long,
                          color: const Color(0xFF9C27B0),
                        ),
                        _buildStatCard(
                          title: 'Symptom Logs',
                          value: _totalSymptomLogs.toString(),
                          icon: Icons.monitor_heart,
                          color: const Color(0xFFE91E63),
                        ),
                        _buildStatCard(
                          title: 'Avg Meds/Patient',
                          value: _patientsWithMedications > 0
                              ? (_totalMedications / _patientsWithMedications).toStringAsFixed(1)
                              : '0',
                          icon: Icons.analytics,
                          color: const Color(0xFF00BCD4),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Symptom Severity Distribution
                    Text(
                      'Symptom Severity Distribution',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _totalSymptomLogs == 0
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No symptom logs recorded yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  _buildSeverityBar('Mild', _severityDistribution['Mild'] ?? 0, Colors.green),
                                  const SizedBox(height: 12),
                                  _buildSeverityBar('Moderate', _severityDistribution['Moderate'] ?? 0, Colors.orange),
                                  const SizedBox(height: 12),
                                  _buildSeverityBar('Severe', _severityDistribution['Severe'] ?? 0, Colors.deepOrange),
                                  const SizedBox(height: 12),
                                  _buildSeverityBar('Very Severe', _severityDistribution['Very Severe'] ?? 0, Colors.red),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Patient Adherence
                    Text(
                      'Patient Activity (Last 7 Days)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_adherenceData.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No patients with medications yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _adherenceData.length,
                        itemBuilder: (context, index) {
                          final patient = _adherenceData[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: patient.isActive
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                child: Icon(
                                  patient.isActive ? Icons.check : Icons.schedule,
                                  color: patient.isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                              title: Text(
                                patient.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${patient.medicationCount} medication${patient.medicationCount == 1 ? '' : 's'} • ${patient.recentLogsCount} log${patient.recentLogsCount == 1 ? '' : 's'} this week',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: patient.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  patient.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: patient.isActive ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBar(String label, int count, Color color) {
    final total = _totalSymptomLogs > 0 ? _totalSymptomLogs : 1;
    final percentage = (count / total * 100).round();
    
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: count / total,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientAdherence {
  final String name;
  final int medicationCount;
  final int recentLogsCount;
  final bool isActive;

  _PatientAdherence({
    required this.name,
    required this.medicationCount,
    required this.recentLogsCount,
    required this.isActive,
  });
}
