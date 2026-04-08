import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/consultation.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/video_consultation_service.dart';
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
  final _videoService = VideoConsultationService();
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

  // ── Confirm consultation (pharmacist sends link to both) ──
  Future<void> _confirmConsultation(Consultation consultation) async {
    final meetingLink = await _showMeetingLinkDialog();
    if (meetingLink == null) return;

    final success = await _authService.confirmConsultationWithLink(
      consultation.id,
      meetingLink,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Confirmed! Patient & Doctor notified.')),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadData();
    }
  }

  Future<String?> _showMeetingLinkDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link, color: Color(0xFF1565C0), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Meeting Link',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste the Google Meet link to share with the patient and doctor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'https://meet.google.com/xxx-xxxx-xxx',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.videocam_outlined, color: Color(0xFF1565C0)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          Navigator.pop(context, controller.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm & Send', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelConsultation(Consultation consultation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancel Consultation?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. The consultation will be permanently cancelled.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Keep'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Cancel It', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final success = await _authService.updateConsultationStatus(
        consultation.id,
        ConsultationStatus.cancelled,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Consultation cancelled'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.done_all, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Marked as completed'),
            ],
          ),
          backgroundColor: const Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadData();
    }
  }

  Future<void> _escalateConsultation(Consultation consultation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forward_to_inbox, color: Colors.orange, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Forward to Doctor?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The consultation request will be forwarded to all available doctors for their availability.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Not Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Forward', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final success = await _authService.escalateConsultation(consultation.id);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Forwarded to doctors successfully')),
              ],
            ),
            backgroundColor: Colors.orange[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to forward. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ── Doctor replies with availability ──
  Future<void> _doctorReplyToConsultation(Consultation consultation) async {
    final replyController = TextEditingController();
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final reply = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1565C0).withOpacity(0.1), const Color(0xFF42A5F5).withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_send, color: Color(0xFF1565C0), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share Your Availability',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Let the pharmacist know when you\'re free for this consultation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: replyController,
                decoration: InputDecoration(
                  hintText: 'e.g. Available on March 12, 3:00 PM',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.event_available, color: Color(0xFF1565C0)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (replyController.text.trim().isNotEmpty) {
                          Navigator.pop(context, replyController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Send Reply', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (reply == null) return;

    final success = await _authService.doctorReplyToConsultation(
      consultation.id,
      reply,
      user.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Availability sent to pharmacist'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadData();
    }
  }

  Future<void> _joinMeeting(String? link) async {
    if (link == null || link.isEmpty) return;
    
    try {
      await _videoService.launchMeetingUrl(link);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Consultations'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.center,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upcoming, size: 18),
                  const SizedBox(width: 6),
                  const Text('Upcoming'),
                  if (_upcomingConsultations.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge(_upcomingConsultations.length, const Color(0xFF66BB6A)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top, size: 18),
                  const SizedBox(width: 6),
                  const Text('Pending'),
                  if (_pendingConsultations.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge(_pendingConsultations.length, Colors.orange),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 6),
                  Text('Past'),
                ],
              ),
            ),
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
      floatingActionButton: null,
      bottomNavigationBar: (_userRole == 'patient' || _userRole == 'pharmacist')
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestConsultationScreen(),
                        ),
                      );
                      _loadData();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text('Request Consultation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            onEscalate: () => _escalateConsultation(consultation),
            onDoctorReply: () => _doctorReplyToConsultation(consultation),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'upcoming':
        message = 'No Upcoming Consultations';
        subtitle = 'Confirmed consultations will appear here';
        icon = Icons.video_call_outlined;
        break;
      case 'pending':
        message = 'No Pending Requests';
        subtitle = _userRole == 'patient'
            ? 'Tap + to request a consultation'
            : 'Patient requests will appear here';
        icon = Icons.pending_outlined;
        break;
      default:
        message = 'No Past Consultations';
        subtitle = 'Completed and cancelled consultations will appear here';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// CONSULTATION CARD
// ══════════════════════════════════════════════════════════════════

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({
    required this.consultation,
    required this.userRole,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
    required this.onJoin,
    required this.onEscalate,
    required this.onDoctorReply,
  });

  final Consultation consultation;
  final String userRole;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final VoidCallback onJoin;
  final VoidCallback onEscalate;
  final VoidCallback onDoctorReply;

  @override
  Widget build(BuildContext context) {
    final otherName = userRole == 'patient'
        ? consultation.pharmacistName
        : consultation.patientName + (consultation.patientOpNumber?.isNotEmpty == true ? ' (OP #${consultation.patientOpNumber})' : '');

    final roleLabel = userRole == 'patient' ? 'Pharmacist' : 'Patient';
    final avatarLetter = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
          ),

          // ── Flow Indicator ──
          _buildFlowIndicator(),

          // ── Date & Time ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    consultation.formattedDate,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.schedule, size: 15, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    consultation.requestedTime,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // ── Notes ──
          if (consultation.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sticky_note_2_outlined, size: 16, color: Colors.amber[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Note',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[800],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            consultation.notes,
                            style: TextStyle(color: Colors.amber[900], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Doctor's Reply ──
          if (consultation.doctorReply != null && consultation.doctorReply!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1565C0).withOpacity(0.06), const Color(0xFF42A5F5).withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.medical_services, size: 14, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DOCTOR\'S AVAILABILITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            consultation.doctorReply!,
                            style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.w500,
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

          // ── Actions ──
          _buildActions(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Flow step indicator ──
  Widget _buildFlowIndicator() {
    // Determine current step
    int currentStep = 0; // 0 = Requested, 1 = Forwarded, 2 = Doctor Replied, 3 = Confirmed
    
    if (consultation.status == ConsultationStatus.confirmed) {
      currentStep = 3;
    } else if (consultation.doctorReply != null && consultation.doctorReply!.isNotEmpty) {
      currentStep = 2;
    } else if (consultation.escalatedToDoctor) {
      currentStep = 1;
    }

    if (consultation.status == ConsultationStatus.cancelled ||
        consultation.status == ConsultationStatus.completed) {
      return const SizedBox.shrink();
    }

    final steps = ['Requested', 'Forwarded', 'Dr. Replied', 'Confirmed'];
    final stepColors = [
      Colors.orange,
      const Color(0xFFF57C00),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? stepColors[i] : Colors.grey[200],
                    ),
                  ),
                Container(
                  width: isCurrent ? 24 : 18,
                  height: isCurrent ? 24 : 18,
                  decoration: BoxDecoration(
                    color: isActive ? stepColors[i] : Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: isCurrent ? [
                      BoxShadow(
                        color: stepColors[i].withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: isActive
                        ? Icon(
                            i < currentStep ? Icons.check : Icons.circle,
                            size: isCurrent ? 12 : 10,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                if (i < steps.length - 1 && i == 0)
                  const SizedBox(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String chipText = consultation.statusText;
    IconData chipIcon;

    switch (consultation.status) {
      case ConsultationStatus.pending:
        chipColor = Colors.orange;
        chipIcon = Icons.hourglass_top;
        if (consultation.escalatedToDoctor) {
          chipText = 'Forwarded';
          chipIcon = Icons.forward_to_inbox;
        }
        if (consultation.doctorReply != null && consultation.doctorReply!.isNotEmpty) {
          chipText = 'Awaiting Link';
          chipColor = const Color(0xFF1565C0);
          chipIcon = Icons.link;
        }
        break;
      case ConsultationStatus.confirmed:
        chipColor = const Color(0xFF2E7D32);
        chipIcon = Icons.check_circle;
        break;
      case ConsultationStatus.completed:
        chipColor = const Color(0xFF1565C0);
        chipIcon = Icons.done_all;
        break;
      case ConsultationStatus.cancelled:
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 13, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final List<Widget> actions = [];

    if (consultation.status == ConsultationStatus.pending) {
      if (userRole == 'pharmacist') {
        if (!consultation.escalatedToDoctor) {
          actions.add(
            _ActionChip(
              icon: Icons.forward_to_inbox,
              label: 'Forward to Doctor',
              color: Colors.orange,
              onTap: onEscalate,
            ),
          );
        }
        if (consultation.doctorReply != null && consultation.doctorReply!.isNotEmpty) {
          actions.add(
            _ActionChip(
              icon: Icons.check_circle,
              label: 'Confirm & Send Link',
              color: const Color(0xFF2E7D32),
              filled: true,
              onTap: onConfirm,
            ),
          );
        } else {
          actions.add(
            _ActionChip(
              icon: Icons.check_circle_outline,
              label: 'Confirm',
              color: const Color(0xFF2E7D32),
              onTap: onConfirm,
            ),
          );
        }
      }
      actions.add(
        _ActionChip(
          icon: Icons.close,
          label: 'Cancel',
          color: Colors.red,
          onTap: onCancel,
        ),
      );
    } else if (consultation.status == ConsultationStatus.confirmed) {
      if (consultation.canJoin) {
        actions.add(
          _ActionChip(
            icon: Icons.videocam,
            label: 'Join Meeting',
            color: const Color(0xFF2E7D32),
            filled: true,
            onTap: onJoin,
          ),
        );
      }
      if (userRole == 'pharmacist') {
        actions.add(
          _ActionChip(
            icon: Icons.done_all,
            label: 'Complete',
            color: const Color(0xFF1565C0),
            onTap: onComplete,
          ),
        );
      }
      actions.add(
        _ActionChip(
          icon: Icons.close,
          label: 'Cancel',
          color: Colors.red,
          onTap: onCancel,
        ),
      );
    }

    // Doctor reply button
    if (userRole == 'doctor' && 
        consultation.escalatedToDoctor && 
        consultation.status == ConsultationStatus.pending &&
        (consultation.doctorReply == null || consultation.doctorReply!.isEmpty)) {
      actions.add(
        _ActionChip(
          icon: Icons.schedule_send,
          label: 'Reply with Availability',
          color: const Color(0xFF1565C0),
          filled: true,
          onTap: onDoctorReply,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions,
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════
// ACTION CHIP BUTTON
// ══════════════════════════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled ? null : Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: filled ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
