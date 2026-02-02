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
import 'my_medications_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'symptom_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  Map<String, int> _summary = {'taken': 0, 'pending': 0, 'missed': 0};
  List<MedicationLog> _pendingLogs = [];
  List<MedicationLog> _overdueLogs = [];
  List<Prescription> _prescriptions = [];
  bool _isLoadingSummary = true;
  bool _isLoadingPrescriptions = true;
  int _unreadNotifications = 0;
  int _unreadChats = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadNotificationCount();
    _loadPrescriptions();
    _loadUnreadChats();
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
    
    // Get summary and pending logs
    final summary = await _authService.getTodaysSummary();
    final logs = await _authService.getTodaysMedicationLogs();
    final now = DateTime.now();
    
    // Split into upcoming (future) and overdue (past but still pending)
    final pendingLogs = logs.where((log) => 
      log.status == MedicationStatus.pending && 
      !now.isAfter(log.scheduledTime)
    ).toList();
    
    final overdueLogs = logs.where((log) => 
      log.status == MedicationStatus.pending && 
      now.isAfter(log.scheduledTime)
    ).toList();

    // Deduplicate logs (in case of multiple reminders for same drug/time)
    final uniquePending = <String, MedicationLog>{};
    for (final log in pendingLogs) {
      final key = '${log.brandName}_${log.scheduledTime.millisecondsSinceEpoch}';
      if (!uniquePending.containsKey(key)) {
        uniquePending[key] = log;
      }
    }
    
    final uniqueOverdue = <String, MedicationLog>{};
    for (final log in overdueLogs) {
      final key = '${log.brandName}_${log.scheduledTime.millisecondsSinceEpoch}';
      if (!uniqueOverdue.containsKey(key)) {
        uniqueOverdue[key] = log;
      }
    }
    
    // Convert back to lists
    final dedupPendingLogs = uniquePending.values.toList();
    final dedupOverdueLogs = uniqueOverdue.values.toList();
    
    // Sort pending by scheduled time (soonest first)
    dedupPendingLogs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    // Sort overdue by scheduled time (most recent first)
    dedupOverdueLogs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    
    if (mounted) {
      setState(() {
        _summary = summary;
        _pendingLogs = dedupPendingLogs;
        _overdueLogs = dedupOverdueLogs;
        _isLoadingSummary = false;
      });
    }
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
                          ),
                          _SummaryItem(
                            icon: Icons.schedule,
                            value: _summary['pending'].toString(),
                            label: t('Pending'),
                            color: theme.colorScheme.tertiary,
                          ),
                          _SummaryItem(
                            icon: Icons.cancel,
                            value: _summary['missed'].toString(),
                            label: t('Missed'),
                            color: theme.colorScheme.error,
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
                                      '${prescription.genericName} (${prescription.brandName})',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      prescription.dosage,
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
                              Icon(Icons.timelapse, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'Duration: ${prescription.duration}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.person, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'By ${prescription.pharmacistName}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (prescription.instructions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      prescription.instructions,
                                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

