import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/consultation.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'request_consultation_screen.dart';

/// Screen for viewing and managing video consultations.
class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  static const route = '/consultations';

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late TabController _tabController;
  
  List<Consultation> _consultations = [];
  bool _isLoading = true;
  String _userRole = 'patient';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _userRole = user.role;
    }

    final consultations = await _authService.getUserConsultations();

    if (mounted) {
      setState(() {
        _consultations = consultations;
        _isLoading = false;
      });
    }
  }

  List<Consultation> get _upcomingConsultations => _consultations
      .where((c) => c.status == ConsultationStatus.confirmed)
      .toList();

  List<Consultation> get _pendingConsultations => _consultations
      .where((c) => c.status == ConsultationStatus.pending)
      .toList();

  List<Consultation> get _pastConsultations => _consultations
      .where((c) => 
          c.status == ConsultationStatus.completed ||
          c.status == ConsultationStatus.cancelled)
      .toList();

  Future<void> _confirmConsultation(Consultation consultation) async {
    final meetingLink = await _showMeetingLinkDialog();
    if (meetingLink == null) return;

    final success = await _authService.updateConsultationStatus(
      consultation.id,
      ConsultationStatus.confirmed,
      meetingLink: meetingLink,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  }

  Future<String?> _showMeetingLinkDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meeting Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the video meeting link (Google Meet, Zoom, etc.)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://meet.google.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelConsultation(Consultation consultation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Consultation'),
        content: const Text('Are you sure you want to cancel this consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _authService.updateConsultationStatus(
        consultation.id,
        ConsultationStatus.cancelled,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation cancelled')),
        );
        _loadData();
      }
    }
  }

  Future<void> _markAsCompleted(Consultation consultation) async {
    final success = await _authService.updateConsultationStatus(
      consultation.id,
      ConsultationStatus.completed,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation marked as completed'),
          backgroundColor: Colors.blue,
        ),
      );
      _loadData();
    }
  }

  Future<void> _joinMeeting(String? link) async {
    if (link == null || link.isEmpty) return;
    
    // Ensure URL has a proper scheme
    String url = link.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    try {
      final uri = Uri.parse(url);
      // Don't use canLaunchUrl as it can be unreliable on Android 11+
      // Just attempt to launch and catch errors
      final launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open meeting link. Please check if you have a browser installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Consultations'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Upcoming'),
                  if (_upcomingConsultations.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge(_upcomingConsultations.length, Colors.green),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingConsultations.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge(_pendingConsultations.length, Colors.orange),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConsultationList(_upcomingConsultations, 'upcoming'),
                _buildConsultationList(_pendingConsultations, 'pending'),
                _buildConsultationList(_pastConsultations, 'past'),
              ],
            ),
      floatingActionButton: (_userRole == 'patient' || _userRole == 'pharmacist')
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestConsultationScreen(),
                  ),
                );
                _loadData();
              },
              tooltip: 'Request Consultation',
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConsultationList(List<Consultation> consultations, String type) {
    if (consultations.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final consultation = consultations[index];
          return _ConsultationCard(
            consultation: consultation,
            userRole: _userRole,
            onConfirm: () => _confirmConsultation(consultation),
            onCancel: () => _cancelConsultation(consultation),
            onComplete: () => _markAsCompleted(consultation),
            onJoin: () => _joinMeeting(consultation.meetingLink),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'upcoming':
        message = 'No upcoming consultations';
        icon = Icons.video_call_outlined;
        break;
      case 'pending':
        message = _userRole == 'patient'
            ? 'No pending requests'
            : 'No consultation requests to review';
        icon = Icons.pending_outlined;
        break;
      default:
        message = 'No past consultations';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a consultation
class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({
    required this.consultation,
    required this.userRole,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
    required this.onJoin,
  });

  final Consultation consultation;
  final String userRole;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherName = userRole == 'patient'
        ? consultation.pharmacistName
        : consultation.patientName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.video_call, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userRole == 'patient' ? 'Pharmacist' : 'Patient',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const Divider(height: 24),
            // Details
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(consultation.formattedDate),
                const SizedBox(width: 24),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(consultation.requestedTime),
              ],
            ),
            if (consultation.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consultation.notes,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ],
            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(consultation.statusColor).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        consultation.statusText,
        style: TextStyle(
          color: Color(consultation.statusColor),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActions() {
    final List<Widget> actions = [];

    if (consultation.status == ConsultationStatus.pending) {
      if (userRole == 'pharmacist') {
        actions.add(
          TextButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        );
      }
      actions.add(
        TextButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
      );
    } else if (consultation.status == ConsultationStatus.confirmed) {
      if (consultation.canJoin) {
        actions.add(
          ElevatedButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.video_call),
            label: const Text('Join Meeting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      if (userRole == 'pharmacist') {
        actions.add(
          TextButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.done_all),
            label: const Text('Mark Complete'),
          ),
        );
      }
      actions.add(
        TextButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel, color: Colors.red),
          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions,
      ),
    );
  }
}
