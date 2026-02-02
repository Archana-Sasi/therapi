import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Model to hold missed medication info with patient details
class MissedMedicationInfo {
  final String patientId;
  final String patientName;
  final String opNumber;
  final String phoneNumber;
  final int? age;
  final String drugId;
  final String brandName;
  final DateTime scheduledTime;
  final DateTime date;
  final String logId; // Added for deletion

  const MissedMedicationInfo({
    required this.patientId,
    required this.patientName,
    required this.opNumber,
    required this.phoneNumber,
    this.age,
    required this.drugId,
    required this.brandName,
    required this.scheduledTime,
    required this.date,
    this.logId = '',
  });

  // Create unique key for deduplication
  String get uniqueKey => '${patientId}_${brandName}_${scheduledTime.millisecondsSinceEpoch}';
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
      opNumber: map['opNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      age: map['age'] as int?,
      drugId: map['drugId'] ?? '',
      brandName: map['brandName'] ?? '',
      scheduledTime: DateTime.tryParse(map['scheduledTime'] ?? '') ?? DateTime.now(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      logId: map['logId'] ?? '',
    )).toList();
    
    // Deduplicate entries
    final uniqueMap = <String, MissedMedicationInfo>{};
    for (final item in missed) {
      if (!uniqueMap.containsKey(item.uniqueKey)) {
        uniqueMap[item.uniqueKey] = item;
      }
    }
    
    if (mounted) {
      setState(() {
        _missedMedications = uniqueMap.values.toList();
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

  void _showPatientDetails(MissedMedicationInfo item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: Colors.green[700], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.patientName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.opNumber.isNotEmpty)
              _detailRow(Icons.badge_outlined, 'OP Number', item.opNumber),
            if (item.phoneNumber.isNotEmpty)
              _detailRow(Icons.phone_outlined, 'Phone', item.phoneNumber),
            if (item.age != null)
              _detailRow(Icons.cake_outlined, 'Age', '${item.age} years'),
            const Divider(height: 24),
            _detailRow(Icons.medication_outlined, 'Medication', item.brandName.isNotEmpty ? item.brandName : item.drugId),
            _detailRow(Icons.schedule_outlined, 'Scheduled Time', _formatTime(item.scheduledTime)),
            _detailRow(Icons.calendar_today_outlined, 'Missed Date', _formatDate(item.date)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (item.phoneNumber.isNotEmpty)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Could add phone call functionality here
              },
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call Patient'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(MissedMedicationInfo item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Entry'),
        content: Text('Remove this missed medication entry for ${item.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _missedMedications.removeWhere((m) => m.uniqueKey == item.uniqueKey);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry removed'),
          backgroundColor: Colors.green,
        ),
      );
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
                        color: Colors.green.shade50,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.shade200, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showPatientDetails(item),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Patient Header with Name and Delete Button
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.green[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.patientName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[900],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.opNumber.isNotEmpty)
                                            Text(
                                              'OP: ${item.opNumber}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Delete Button
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
                                      onPressed: () => _deleteEntry(item),
                                      tooltip: 'Remove',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Patient Details Row (Phone & Age)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      // Age
                                      if (item.age != null) ...[
                                        Icon(Icons.cake_outlined, size: 14, color: Colors.grey[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Age: ${item.age}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Divider
                                Divider(color: Colors.green.shade200, height: 1),
                                const SizedBox(height: 12),
                                // Medication Name
                                Row(
                                  children: [
                                    Icon(Icons.medication, size: 18, color: Colors.green[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.brandName.isNotEmpty
                                            ? item.brandName
                                            : item.drugId,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Missed Date and Time
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule, size: 16, color: Colors.teal[700]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Missed on ${_formatDate(item.date)} at ${_formatTime(item.scheduledTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Tap for details hint
                                Center(
                                  child: Text(
                                    'Tap to view details',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
