import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Model to hold missed medication info with patient details
class MissedMedicationInfo {
  final String patientId;
  final String patientName;
  final String drugId;
  final String brandName;
  final DateTime scheduledTime;
  final DateTime date;

  const MissedMedicationInfo({
    required this.patientId,
    required this.patientName,
    required this.drugId,
    required this.brandName,
    required this.scheduledTime,
    required this.date,
  });
}

class MissedMedicationsScreen extends StatefulWidget {
  const MissedMedicationsScreen({super.key});

  static const route = '/missed-medications';

  @override
  State<MissedMedicationsScreen> createState() => _MissedMedicationsScreenState();
}

class _MissedMedicationsScreenState extends State<MissedMedicationsScreen> {
  final _authService = AuthService();
  List<MissedMedicationInfo> _missedMedications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissedMedications();
  }

  Future<void> _loadMissedMedications() async {
    setState(() => _isLoading = true);
    final missedData = await _authService.getAllMissedMedicationLogs();
    
    // Convert maps to model objects
    final missed = missedData.map((map) => MissedMedicationInfo(
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Unknown',
      drugId: map['drugId'] ?? '',
      brandName: map['brandName'] ?? '',
      scheduledTime: DateTime.tryParse(map['scheduledTime'] ?? '') ?? DateTime.now(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    )).toList();
    
    if (mounted) {
      setState(() {
        _missedMedications = missed;
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missed Medications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMissedMedications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _missedMedications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 72,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Missed Medications',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All patients are taking their medications on time!',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMissedMedications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _missedMedications.length,
                    itemBuilder: (context, index) {
                      final item = _missedMedications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.medication,
                                  color: Colors.red[700],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Patient Name
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.red[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.patientName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[800],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Medication Name
                                    Text(
                                      item.brandName.isNotEmpty
                                          ? item.brandName
                                          : item.drugId,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Time and Date
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTime(item.scheduledTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(item.date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
