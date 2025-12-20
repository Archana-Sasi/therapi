import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/user_notification.dart';
import '../services/auth_service.dart';

/// Screen for pharmacists to send notifications to patients
class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({
    super.key,
    this.recipient, // If null, can send to all patients
  });

  final UserModel? recipient;

  static const route = '/send-notification';

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  NotificationType _selectedType = NotificationType.general;
  bool _sendToAll = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _sendToAll = widget.recipient == null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      if (_sendToAll) {
        final count = await _authService.sendNotificationToAllPatients(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to $count patients'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final success = await _authService.sendNotification(
          recipientId: widget.recipient!.id,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          type: _selectedType,
        );
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification sent to ${widget.recipient!.fullName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to send');
        }
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _sendToAll ? Icons.groups : Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sendToAll 
                                  ? 'All Patients' 
                                  : widget.recipient?.fullName ?? 'Patient',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _sendToAll
                                  ? 'Broadcast to everyone'
                                  : widget.recipient?.email ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
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

              // Notification Type
              Text(
                'Notification Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: NotificationType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(_getTypeLabel(type)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    avatar: Icon(
                      _getTypeIcon(type),
                      size: 18,
                      color: isSelected ? Colors.white : _getTypeColor(type),
                    ),
                    selectedColor: _getTypeColor(type),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Title Field
              Text(
                'Title',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter notification title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message Field
              Text(
                'Message',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your message to the patient...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNotification,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTypeColor(_selectedType),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return 'General';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.education:
        return 'Educational';
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return Icons.message;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.education:
        return Icons.school;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.education:
        return Colors.purple;
    }
  }
}
