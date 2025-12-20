import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import '../models/medication_reminder.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Screen to add or edit medication reminders
class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({
    super.key,
    required this.drugId,
    required this.brandName,
    this.existingReminder,
  });

  final String drugId;
  final String brandName;
  final MedicationReminder? existingReminder;

  static const route = '/medication-reminder';

  @override
  State<MedicationReminderScreen> createState() => _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  final _dosageController = TextEditingController();
  
  List<TimeOfDay> _scheduledTimes = [];
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // All days by default
  bool _isEnabled = true;
  bool _isSaving = false;

  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _scheduledTimes = List.from(widget.existingReminder!.scheduledTimes);
      _selectedDays = List.from(widget.existingReminder!.daysOfWeek);
      _isEnabled = widget.existingReminder!.isEnabled;
      _dosageController.text = widget.existingReminder!.dosage;
    } else {
      _dosageController.text = '1 tablet';
      // Add default morning time
      _scheduledTimes.add(const TimeOfDay(hour: 8, minute: 0));
    }
  }

  @override
  void dispose() {
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (!_scheduledTimes.any((t) => t.hour == time.hour && t.minute == time.minute)) {
          _scheduledTimes.add(time);
          _scheduledTimes.sort((a, b) {
            final aMinutes = a.hour * 60 + a.minute;
            final bMinutes = b.hour * 60 + b.minute;
            return aMinutes.compareTo(bMinutes);
          });
        }
      });
    }
  }

  void _removeTime(TimeOfDay time) {
    setState(() {
      _scheduledTimes.removeWhere((t) => t.hour == time.hour && t.minute == time.minute);
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _saveReminder() async {
    if (_scheduledTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final reminder = MedicationReminder(
      id: widget.existingReminder?.id ?? 
          '${widget.drugId}_${DateTime.now().millisecondsSinceEpoch}',
      drugId: widget.drugId,
      brandName: widget.brandName,
      scheduledTimes: _scheduledTimes,
      daysOfWeek: _selectedDays,
      isEnabled: _isEnabled,
      dosage: _dosageController.text.trim().isEmpty 
          ? '1 tablet' 
          : _dosageController.text.trim(),
    );

    bool success;
    if (widget.existingReminder != null) {
      success = await _authService.updateMedicationReminder(reminder);
    } else {
      success = await _authService.addMedicationReminder(reminder);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      // Generate today's logs for the new reminder
      await _authService.generateTodaysLogs();
      
      // Schedule push notifications
      if (_isEnabled) {
        await _notificationService.scheduleReminder(reminder);
      } else {
        await _notificationService.cancelReminder(reminder.id);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingReminder != null 
              ? 'Reminder updated successfully' 
              : 'Reminder set with notifications!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save reminder'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteReminder() async {
    if (widget.existingReminder == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      
      // Cancel scheduled notifications
      await _notificationService.cancelReminder(widget.existingReminder!.id);
      
      final success = await _authService.deleteMedicationReminder(widget.existingReminder!.id);
      
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drug = DrugData.getDrugById(widget.drugId);
    final theme = Theme.of(context);
    final isEditing = widget.existingReminder != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Reminder' : 'Set Reminder'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isSaving ? null : _deleteReminder,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.medication,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drug?.genericName ?? 'Unknown Drug',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (widget.brandName.isNotEmpty)
                            Text(
                              widget.brandName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Enable/Disable Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Enable Reminder'),
                subtitle: Text(_isEnabled ? 'Notifications active' : 'Notifications paused'),
                value: _isEnabled,
                onChanged: (value) => setState(() => _isEnabled = value),
                secondary: Icon(
                  _isEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: _isEnabled ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dosage Input
            Text(
              'Dosage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(
                hintText: 'e.g., 1 tablet, 2 puffs, 5ml',
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            // Scheduled Times
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminder Times',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_scheduledTimes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.access_time, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No times set',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _addTime,
                          child: const Text('Add a reminder time'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _scheduledTimes.map((time) {
                  return Chip(
                    label: Text(
                      _formatTime(time),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    avatar: const Icon(Icons.access_time, size: 18),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTime(time),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Days of Week
            Text(
              'Repeat on',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => _toggleDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[index][0],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _selectedDays.length == 7 
                    ? 'Every day'
                    : _selectedDays.map((d) => _dayNames[d - 1]).join(', '),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReminder,
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving 
                    ? 'Saving...' 
                    : (isEditing ? 'Update Reminder' : 'Save Reminder')),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
