import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/tamil_translations.dart';
import '../models/medication_log.dart';
import '../models/prescription_model.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import 'arrival_screen.dart';
import 'consultations_screen.dart';
import 'conversations_screen.dart';
import 'disease_selection_screen.dart';
import '../services/video_consultation_service.dart';
import 'my_medications_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'symptom_history_screen.dart';
import 'prescription_sheet_screen.dart';
import 'my_prescriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final VideoConsultationService _videoService = VideoConsultationService();
  String _greeting = '';
  Map<String, int> _summary = {'taken': 0, 'pending': 0, 'missed': 0};
  List<MedicationLog> _todaysLogs = [];
  List<MedicationLog> _pendingLogs = [];
  List<MedicationLog> _overdueLogs = [];
  List<Prescription> _prescriptions = [];
  bool _isLoadingSummary = true;
  bool _isLoadingPrescriptions = true;
  int _unreadNotifications = 0;
  int _unreadChats = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Safety check: Redirect Doctors/Pharmacists if they land here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        if (user.role == 'doctor') {
           Navigator.pushReplacementNamed(context, '/doctor-home');
           return;
        } else if (user.role == 'pharmacist') {
           Navigator.pushReplacementNamed(context, '/pharmacist-home');
           return;
        }
      }
    });

    _loadSummary();
    _loadNotificationCount();
    _loadPrescriptions();
    _loadUnreadChats();
    // Auto-refresh every minute to move pending -> overdue
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _todaysLogs.isNotEmpty) {
        _processLogs(_todaysLogs);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadChats() async {
    final conversations = await _authService.getUserConversations();
    final totalUnread = conversations.fold<int>(
      0, (sum, chat) => sum + chat.unreadPatient,
    );
    if (mounted) {
      setState(() => _unreadChats = totalUnread);
    }
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoadingPrescriptions = true);
    
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final prescriptions = await _authService.getPrescriptionsForPatient(user.id);
      if (mounted) {
        setState(() {
          _prescriptions = prescriptions.where((p) => p.isActive).toList();
          _isLoadingPrescriptions = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingPrescriptions = false);
    }
  }

  Future<void> _loadNotificationCount() async {
    final count = await _authService.getUnreadNotificationCount();
    if (mounted) {
      setState(() => _unreadNotifications = count);
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoadingSummary = true);
    
    // Generate today's logs based on reminders
    await _authService.generateTodaysLogs();
    
    // Check for medications that are 10+ minutes overdue and notify pharmacists
    await _authService.checkAndNotifyMissedMedications();
    
    // Get logs and process them locally
    final logs = await _authService.getTodaysMedicationLogs();
    _processLogs(logs);
  }

  /// Re-evaluates pending vs overdue based on current time.
  /// Called by _loadSummary and by the auto-refresh timer.
  void _processLogs(List<MedicationLog> logs) {
    if (!mounted) return;
    final now = DateTime.now();

    final pendingLogs = logs.where((log) =>
      log.status == MedicationStatus.pending &&
      !now.isAfter(log.scheduledTime)
    ).toList();

    final overdueLogs = logs.where((log) =>
      log.status == MedicationStatus.pending &&
      now.isAfter(log.scheduledTime)
    ).toList();

    // Deduplicate
    final uniquePending = <String, MedicationLog>{};
    for (final log in pendingLogs) {
      final key = '${log.brandName}_${log.scheduledTime.millisecondsSinceEpoch}';
      uniquePending.putIfAbsent(key, () => log);
    }
    final uniqueOverdue = <String, MedicationLog>{};
    for (final log in overdueLogs) {
      final key = '${log.brandName}_${log.scheduledTime.millisecondsSinceEpoch}';
      uniqueOverdue.putIfAbsent(key, () => log);
    }

    final dedupPending = uniquePending.values.toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final dedupOverdue = uniqueOverdue.values.toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    // Recalculate summary counts locally
    int taken = logs.where((l) => l.status == MedicationStatus.taken).length;
    int missed = logs.where((l) => l.status == MedicationStatus.missed).length;
    missed += dedupOverdue.length;

    setState(() {
      _todaysLogs = logs;
      _pendingLogs = dedupPending;
      _overdueLogs = dedupOverdue;
      _summary = {'taken': taken, 'pending': dedupPending.length, 'missed': missed};
      _isLoadingSummary = false;
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showMedicationList(String title, List<MedicationLog> logs, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No medications in this category',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      leading: Icon(Icons.medication, color: color),
                      title: Text(log.brandName.isNotEmpty ? log.brandName : log.drugId),
                      subtitle: Text('Scheduled: ${_formatTime(log.scheduledTime)}'),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsTaken(MedicationLog log) async {
    final success = await _authService.updateMedicationLogStatus(
      log.id, 
      MedicationStatus.taken,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${log.brandName} marked as taken!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSummary();
    }
  }

  Future<void> _markAsMissed(MedicationLog log) async {
    // Confirm before marking as missed
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Missed?'),
        content: Text(
          'Mark ${log.brandName} as missed? This will notify your pharmacist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Mark as Missed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _authService.updateMedicationLogStatus(
      log.id, 
      MedicationStatus.missed,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${log.brandName} marked as missed. Pharmacist notified.'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final langProvider = context.watch<LanguageProvider>();
    final isTamil = langProvider.isTamil;
    
    // Translation helper
    String t(String english) => isTamil ? TamilTranslations.getLabel(english) : english;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('RespiriCare')),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: t('Notifications'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, user, theme),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 30,
                                color: theme.colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('Welcome back,'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              user?.fullName ?? 'User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
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

              // Today's Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t("Today's Summary"),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isLoadingSummary)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: _loadSummary,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(
                            icon: Icons.check_circle,
                            value: _summary['taken'].toString(),
                            label: t('Taken'),
                            color: theme.colorScheme.secondary,
                            onTap: () {
                              final takenLogs = _todaysLogs.where((l) => l.status == MedicationStatus.taken).toList();
                              _showMedicationList('Taken', takenLogs, theme.colorScheme.secondary);
                            },
                          ),
                          _SummaryItem(
                            icon: Icons.schedule,
                            value: _summary['pending'].toString(),
                            label: t('Pending'),
                            color: theme.colorScheme.tertiary,
                            onTap: () {
                              _showMedicationList('Pending', _pendingLogs, theme.colorScheme.tertiary);
                            },
                          ),
                          _SummaryItem(
                            icon: Icons.cancel,
                            value: _summary['missed'].toString(),
                            label: t('Missed'),
                            color: theme.colorScheme.error,
                            onTap: () {
                              final missedLogs = _todaysLogs.where((l) => l.status == MedicationStatus.missed).toList();
                              final combined = {...{for (var l in missedLogs) l.id: l}, ...{for (var l in _overdueLogs) l.id: l}}.values.toList();
                              _showMedicationList('Missed', combined, theme.colorScheme.error);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Overdue Medications (past scheduled time but still pending)
              if (_overdueLogs.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      t('Overdue Medications'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_overdueLogs.take(5).map((log) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.medication, color: theme.colorScheme.error),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.brandName.isNotEmpty ? log.brandName : log.drugId,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Was due: ${_formatTime(log.scheduledTime)}',
                                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: OutlinedButton.icon(
                                onPressed: () => _markAsMissed(log),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Miss'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _markAsTaken(log),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Take Now'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ))),
                const SizedBox(height: 16),
              ],

              // Upcoming Medications
              if (_pendingLogs.isNotEmpty) ...[
                Text(
                  t('Upcoming Medications'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_pendingLogs.take(3).map((log) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medication, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      log.brandName.isNotEmpty ? log.brandName : log.drugId,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Scheduled: ${_formatTime(log.scheduledTime)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () => _markAsTaken(log),
                      child: const Text('Take'),
                    ),
                  ),
                ))),
                const SizedBox(height: 16),
              ],

              // Quick Actions Title
              Text(
                t('Quick Actions'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Quick Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
                children: [
                  _QuickActionCard(
                    icon: Icons.medication_outlined,
                    title: t('Drug Directory'),
                    subtitle: t('A-Z Medications'),
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DiseaseSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.alarm,
                    title: t('My Medications'),
                    subtitle: t('Set Reminders'),
                    color: const Color(0xFF00C853),
                    onTap: () async {
                      await Navigator.pushNamed(context, MyMedicationsScreen.route);
                      _loadSummary(); // Refresh after returning
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.note_add_outlined,
                    title: t('Log Symptoms'),
                    subtitle: t('Track health'),
                    color: const Color(0xFFFF6D00),
                    onTap: () {
                      Navigator.pushNamed(context, SymptomHistoryScreen.route);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.chat_bubble_outline,
                    title: t('Chat'),
                    subtitle: t('Ask Pharmacist'),
                    color: const Color(0xFF9C27B0),
                    badgeCount: _unreadChats,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConversationsScreen(),
                        ),
                      );
                      _loadUnreadChats(); // Refresh after returning
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.video_call_outlined,
                    title: t('Consultations'),
                    subtitle: t('Video Calls'),
                    color: const Color(0xFF00BCD4),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConsultationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // My Prescriptions Section
              if (_prescriptions.isNotEmpty || _isLoadingPrescriptions) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('My Prescriptions'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyPrescriptionsScreen()),
                          ),
                          child: Text(t('View All'), style: const TextStyle(fontSize: 12)),
                        ),
                        if (_isLoadingPrescriptions)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _loadPrescriptions,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_prescriptions.isEmpty && !_isLoadingPrescriptions)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No active prescriptions',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  )
                else
                  ...(_prescriptions.take(5).map((prescription) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrescriptionSheetScreen(prescription: prescription),
                          ),
                        );
                      },
                      child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853).withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long, color: Color(0xFF00C853)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPrescriptionTitle(prescription),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${prescription.effectiveMedications.length} medication${prescription.effectiveMedications.length == 1 ? '' : 's'}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Dr. ${prescription.doctorName ?? prescription.pharmacistName}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                prescription.formattedDate,
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ),
                  ))),
              ],
            ],
          ),
        ),
      ),
    );
  }


  String _getPrescriptionTitle(Prescription prescription) {
    final meds = prescription.effectiveMedications;
    if (meds.isEmpty) return 'No medications';
    if (meds.length == 1) return meds.first.genericName;
    return '${meds.first.genericName} & ${meds.length - 1} more';
  }

  Widget _buildDrawer(BuildContext context, dynamic user, ThemeData theme) {
    final langProvider = context.watch<LanguageProvider>();
    final isTamil = langProvider.isTamil;
    
    // Translation helper
    String t(String english) => isTamil ? TamilTranslations.getLabel(english) : english;
    
    return Drawer(
      child: Column(
        children: [
          // Drawer Header with user info
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          user?.fullName?.isNotEmpty == true
                              ? user!.fullName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  icon: Icons.medical_services_outlined,
                  label: 'Services',
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to services
                  },
                ),
                _buildActionCard(
                  icon: Icons.video_call_outlined,
                  label: 'Consult Doctor',
                  color: Colors.teal,
                  onTap: () {
                    _showJoinConsultationDialog();
                  },
                ),
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.role ?? 'patient',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: t('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, ProfileScreen.route);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: t('Notifications'),
                  trailing: _unreadNotifications > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_unreadNotifications',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                    _loadNotificationCount();
                  },
                ),
                const Divider(),
                
                // Language Toggle
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: Color(0xFF3B82F6)),
                  ),
                  title: const Text('Language / மொழி'),
                  subtitle: Text(
                    langProvider.isEnglish ? 'English' : 'தமிழ்',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: langProvider.isTamil,
                      onChanged: (_) => langProvider.toggleLanguage(),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF2196F3),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade400,
                    ),
                  ),
                  onTap: () => langProvider.toggleLanguage(),
                ),
                
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: t('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, SettingsScreen.route);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: t('About'),
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'RespiriCare',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.medical_services, size: 48),
                      children: [
                        const Text('A comprehensive medication management app for respiratory care.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Logout at bottom
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: Text(t('Logout'), style: const TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                ArrivalScreen.route,
                (_) => false,
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _showJoinConsultationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Consultation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter Room Code or Doctor ID',
            hintText: 'e.g. therap_app_doctor123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                final roomName = controller.text.trim();
                try {
                  // If input is just ID, prepend prefix, otherwise use as is
                  final fullRoomName = roomName.startsWith('therap_app_') 
                      ? roomName 
                      : 'therap_app_$roomName';
                      
                  await _videoService.launchMeeting(fullRoomName);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch video call')),
                    );
                  }
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1)),
      ),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
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
}

