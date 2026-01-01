import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medication_log.dart';
import '../models/prescription_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'arrival_screen.dart';
import 'disease_selection_screen.dart';
import 'my_medications_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadNotificationCount();
    _loadPrescriptions();
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
    
    // Sort pending by scheduled time (soonest first)
    pendingLogs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    // Sort overdue by scheduled time (most recent first)
    overdueLogs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    
    if (mounted) {
      setState(() {
        _summary = summary;
        _pendingLogs = pendingLogs;
        _overdueLogs = overdueLogs;
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RespiriCare'),
        centerTitle: true,
        actions: [
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
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
          // Profile Avatar Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, ProfileScreen.route),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
            ),
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                ArrivalScreen.route,
                (_) => false,
              );
            },
          ),
        ],
      ),
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
                              'Welcome back,',
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
                              "Today's Summary",
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
                            label: 'Taken',
                            color: const Color(0xFF00C853),
                          ),
                          _SummaryItem(
                            icon: Icons.schedule,
                            value: _summary['pending'].toString(),
                            label: 'Pending',
                            color: const Color(0xFFFF9100),
                          ),
                          _SummaryItem(
                            icon: Icons.cancel,
                            value: _summary['missed'].toString(),
                            label: 'Missed',
                            color: const Color(0xFFFF5252),
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
                    Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Overdue Medications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_overdueLogs.take(5).map((log) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medication, color: Colors.red[700]),
                    ),
                    title: Text(
                      log.brandName.isNotEmpty ? log.brandName : log.drugId,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Was due: ${_formatTime(log.scheduledTime)}',
                      style: TextStyle(color: Colors.red[400], fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _markAsTaken(log),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Take Now'),
                    ),
                  ),
                ))),
                const SizedBox(height: 16),
              ],

              // Upcoming Medications
              if (_pendingLogs.isNotEmpty) ...[
                Text(
                  'Upcoming Medications',
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication, color: Colors.blue),
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
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Quick Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _QuickActionCard(
                    icon: Icons.medication_outlined,
                    title: 'Drug Directory',
                    subtitle: 'A-Z Medications',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.pushNamed(context, DiseaseSelectionScreen.route);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.alarm,
                    title: 'My Medications',
                    subtitle: 'Set Reminders',
                    color: const Color(0xFF00C853),
                    onTap: () async {
                      await Navigator.pushNamed(context, MyMedicationsScreen.route);
                      _loadSummary(); // Refresh after returning
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.note_add_outlined,
                    title: 'Log Symptoms',
                    subtitle: 'Track health',
                    color: const Color(0xFFFF6D00),
                    onTap: () {
                      Navigator.pushNamed(context, SymptomHistoryScreen.route);
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
                      'My Prescriptions',
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
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
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
