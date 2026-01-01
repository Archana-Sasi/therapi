import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/data_export_service.dart';
import 'arrival_screen.dart';
import 'drug_inventory_screen.dart';
import 'profile_screen.dart';
import 'prescriptions_screen.dart';
import 'reports_screen.dart';
import 'send_notification_screen.dart';
import 'symptom_history_screen.dart';

class PharmacistHomeScreen extends StatefulWidget {
  const PharmacistHomeScreen({super.key});

  static const route = '/pharmacist-home';

  @override
  State<PharmacistHomeScreen> createState() => _PharmacistHomeScreenState();
}

class _PharmacistHomeScreenState extends State<PharmacistHomeScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authService = AuthService();
    final allUsers = await authService.getAllUsers();
    final currentUser = authService.currentUser;
    
    // Filter to show only patients (not the current user, other pharmacists, or admins)
    final patients = allUsers.where((u) => 
        u.role == 'patient' && u.id != currentUser?.uid
    ).toList();
    
    if (mounted) {
      setState(() {
        _users = patients;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacist Dashboard'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, ProfileScreen.route),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage:
                    user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              color: const Color(0xFFE0F2F1), // Light vibrant teal
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB2DFDB), // Vibrant teal 100
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy,
                        size: 32,
                        color: Color(0xFF00796B), // Vibrant teal 700
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Pharmacist',
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PHARMACIST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
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

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildActionCard(
                  icon: Icons.notifications_active,
                  title: 'Send Notification',
                  color: const Color(0xFFE91E63), // Vibrant Pink
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SendNotificationScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Drug Inventory',
                  color: const Color(0xFF2196F3), // Vibrant Blue
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DrugInventoryScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Prescriptions',
                  color: const Color(0xFF00C853), // Vibrant Green
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrescriptionsScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  icon: Icons.analytics_outlined,
                  title: 'Reports',
                  color: const Color(0xFF7C4DFF), // Vibrant Purple
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Patients List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patients',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadUsers();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_users.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final u = _users[index];
                  return _UserMedicationCard(
                    user: u,
                    roleColor: _getRoleColor(u.role),
                    roleIcon: _getRoleIcon(u.role),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete User'),
                          content: Text('Are you sure you want to delete ${u.fullName}? This action cannot be undone.'),
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
                      
                      if (confirmed == true) {
                        final authService = AuthService();
                        final success = await authService.deleteUser(u.id);
                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${u.fullName} has been deleted'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadUsers(); // Refresh the list
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to delete user'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFFF5252); // Vibrant Red
      case 'pharmacist':
        return const Color(0xFF2962FF); // Vibrant Blue
      default:
        return const Color(0xFF2196F3); // Vibrant Blue
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'pharmacist':
        return Icons.local_pharmacy;
      default:
        return Icons.person;
    }
  }
}

/// Card widget showing a user with their medications
class _UserMedicationCard extends StatefulWidget {
  const _UserMedicationCard({
    required this.user,
    required this.roleColor,
    required this.roleIcon,
    required this.onDelete,
  });

  final UserModel user;
  final Color roleColor;
  final IconData roleIcon;
  final VoidCallback onDelete;

  @override
  State<_UserMedicationCard> createState() => _UserMedicationCardState();
}

class _UserMedicationCardState extends State<_UserMedicationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final medications = widget.user.medications;
    final hasMedications = medications.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.roleColor.withOpacity(0.2),
              child: Icon(
                widget.roleIcon,
                color: widget.roleColor,
              ),
            ),
            title: Text(
              widget.user.fullName.isNotEmpty 
                  ? widget.user.fullName 
                  : widget.user.email.isNotEmpty 
                      ? widget.user.email
                      : 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role badge and Age/Gender info
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.roleColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.user.role.toUpperCase(),
                          style: TextStyle(
                            color: widget.roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.user.age != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cake_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.user.age} yrs',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      if (widget.user.gender != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              widget.user.gender!.capitalize(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (hasMedications)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${medications.length} medication${medications.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  tooltip: 'Delete User',
                  onPressed: widget.onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                if (hasMedications)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                  ),
              ],
            ),
            onTap: hasMedications
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
          ),
          if (_isExpanded && hasMedications)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Current Medications:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: medications.map((med) {
                      final drug = DrugData.getDrugById(med.drugId);
                      if (drug == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medication,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              med.brandName.isNotEmpty 
                                  ? '${drug.genericName} (${med.brandName})'
                                  : drug.genericName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // View Symptoms Button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SymptomHistoryScreen(userId: widget.user.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.monitor_heart_outlined, size: 16),
                        label: const Text('View Symptoms'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Send Notification Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SendNotificationScreen(recipient: widget.user),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications, size: 16),
                        label: const Text('Send Notification'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      // Download Report Button
                      ElevatedButton.icon(
                        onPressed: () => _downloadPatientReport(context, widget.user),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download Report'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          backgroundColor: const Color(0xFF7C4DFF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Download patient health report as PDF
  Future<void> _downloadPatientReport(BuildContext context, UserModel patient) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating Report...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final exportService = DataExportService();
      final filePath = await exportService.exportUserDataAsPdf(patient);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (filePath != null) {
        // Share the PDF file
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Health Report - ${patient.fullName}',
          text: 'Patient Health Report for ${patient.fullName}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}


