import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/symptom_log.dart';
import '../services/auth_service.dart';
import 'symptom_log_screen.dart';

/// Screen to view symptom history
class SymptomHistoryScreen extends StatefulWidget {
  const SymptomHistoryScreen({super.key, this.userId});

  /// Optional userId - if null, shows current user's history
  final String? userId;

  static const route = '/symptom-history';

  @override
  State<SymptomHistoryScreen> createState() => _SymptomHistoryScreenState();
}

class _SymptomHistoryScreenState extends State<SymptomHistoryScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  List<SymptomLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSymptomLogs();
  }

  Future<void> _loadSymptomLogs() async {
    final userId = widget.userId ?? _authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('symptom_logs')
          .orderBy('timestamp', descending: true)
          .get();

      final logs = snapshot.docs.map((doc) {
        return SymptomLog.fromMap(doc.data());
      }).toList();

      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  Color _getSeverityColor(double severity) {
    if (severity == 0) return Colors.green;
    if (severity < 2) return Colors.lightGreen;
    if (severity < 3) return Colors.amber;
    if (severity < 4) return Colors.orange;
    return Colors.red;
  }

  Future<void> _deleteLog(SymptomLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Symptom Log'),
        content: Text('Delete the log from ${_formatDateTime(log.timestamp)}?'),
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

    if (confirm != true) return;

    final userId = widget.userId ?? _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('symptom_logs')
          .doc(log.id)
          .delete();

      setState(() {
        _logs.removeWhere((l) => l.id == log.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptom log deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnHistory = widget.userId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnHistory ? 'My Symptom History' : 'Symptom History'),
        centerTitle: true,
      ),
      floatingActionButton: isOwnHistory
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, SymptomLogScreen.route);
                _loadSymptomLogs(); // Refresh after logging
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Symptoms'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No symptom logs yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isOwnHistory) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to log your first symptoms',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final severity = log.overallSeverity;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getSeverityColor(severity).withOpacity(0.2),
                          child: Icon(
                            Icons.favorite,
                            color: _getSeverityColor(severity),
                          ),
                        ),
                        title: Text(
                          log.severityLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(severity),
                          ),
                        ),
                        subtitle: Text(
                          _formatDateTime(log.timestamp),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSymptomRow('Breathlessness', log.breathlessness, Icons.air),
                                _buildSymptomRow('Cough', log.cough, Icons.sick_outlined),
                                _buildSymptomRow('Wheezing', log.wheezing, Icons.volume_up),
                                _buildSymptomRow('Chest Tightness', log.chestTightness, Icons.favorite_outline),
                                _buildSymptomRow('Fatigue', log.fatigue, Icons.battery_2_bar),
                                if (log.notes.isNotEmpty) ...[
                                  const Divider(height: 24),
                                  Text(
                                    'Notes:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.notes,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                                // Delete button - only for own history
                                if (isOwnHistory) ...[
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _deleteLog(log),
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
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

  Widget _buildSymptomRow(String label, int value, IconData icon) {
    final colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];
    final labels = ['None', 'Very Mild', 'Mild', 'Moderate', 'Severe', 'Very Severe'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors[value].withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              labels[value],
              style: TextStyle(
                color: colors[value],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}
