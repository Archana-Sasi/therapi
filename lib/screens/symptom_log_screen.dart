import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/symptom_log.dart';
import '../services/auth_service.dart';

/// Screen for logging symptoms
class SymptomLogScreen extends StatefulWidget {
  const SymptomLogScreen({super.key});

  static const route = '/log-symptoms';

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  final _authService = AuthService();
  final _notesController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  
  int _breathlessness = 0;
  int _cough = 0;
  int _wheezing = 0;
  int _chestTightness = 0;
  int _fatigue = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSymptomLog() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final logId = DateTime.now().millisecondsSinceEpoch.toString();
      final symptomLog = SymptomLog(
        id: logId,
        userId: user.uid,
        timestamp: DateTime.now(),
        breathlessness: _breathlessness,
        cough: _cough,
        wheezing: _wheezing,
        chestTightness: _chestTightness,
        fatigue: _fatigue,
        notes: _notesController.text.trim(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('symptom_logs')
          .doc(logId)
          .set(symptomLog.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSymptomSlider({
    required String label,
    required IconData icon,
    required int value,
    required ValueChanged<int> onChanged,
    required Color color,
  }) {
    final labels = ['None', 'Very Mild', 'Mild', 'Moderate', 'Severe', 'Very Severe'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(value).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    labels[value],
                    style: TextStyle(
                      color: _getSeverityColor(value),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getSeverityColor(value),
                thumbColor: _getSeverityColor(value),
                inactiveTrackColor: Colors.grey[300],
                overlayColor: _getSeverityColor(value).withOpacity(0.2),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                onChanged: (v) => onChanged(v.toInt()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(int value) {
    switch (value) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.lightGreen;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Symptoms'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date/Time Header
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now()),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            Text(
              'Rate Your Symptoms',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Slide to indicate severity (0 = None, 5 = Very Severe)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Symptom Sliders
            _buildSymptomSlider(
              label: 'Breathlessness',
              icon: Icons.air,
              value: _breathlessness,
              onChanged: (v) => setState(() => _breathlessness = v),
              color: Colors.blue,
            ),
            _buildSymptomSlider(
              label: 'Cough',
              icon: Icons.sick_outlined,
              value: _cough,
              onChanged: (v) => setState(() => _cough = v),
              color: Colors.purple,
            ),
            _buildSymptomSlider(
              label: 'Wheezing',
              icon: Icons.volume_up,
              value: _wheezing,
              onChanged: (v) => setState(() => _wheezing = v),
              color: Colors.teal,
            ),
            _buildSymptomSlider(
              label: 'Chest Tightness',
              icon: Icons.favorite_outline,
              value: _chestTightness,
              onChanged: (v) => setState(() => _chestTightness = v),
              color: Colors.red,
            ),
            _buildSymptomSlider(
              label: 'Fatigue',
              icon: Icons.battery_2_bar,
              value: _fatigue,
              onChanged: (v) => setState(() => _fatigue = v),
              color: Colors.orange,
            ),

            const SizedBox(height: 16),

            // Notes field
            Text(
              'Additional Notes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any additional symptoms or observations...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveSymptomLog,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Symptom Log'),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
