import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/data_export_service.dart';
import '../utils/app_colors.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  static const route = '/privacy-security';

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _dataSharing = true;
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Security Section
            _buildSectionHeader('🔐 Security', const Color(0xFF6366F1)),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: Icons.fingerprint,
              iconColor: const Color(0xFF10B981),
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face ID to login',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) => setState(() => _biometricEnabled = value),
                activeColor: const Color(0xFF10B981),
              ),
            ),
            _buildSettingCard(
              icon: Icons.security,
              iconColor: const Color(0xFF3B82F6),
              title: 'Two-Factor Authentication',
              subtitle: 'Add extra security to your account',
              trailing: Switch(
                value: _twoFactorEnabled,
                onChanged: (value) => setState(() => _twoFactorEnabled = value),
                activeColor: const Color(0xFF3B82F6),
              ),
            ),
            _buildSettingCard(
              icon: Icons.lock_outline,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Change Password',
              subtitle: 'Update your account password',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showChangePasswordDialog(),
            ),

            const SizedBox(height: 24),

            // Privacy Section
            _buildSectionHeader('🛡️ Privacy', const Color(0xFF10B981)),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: Icons.share_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'Data Sharing with Pharmacist',
              subtitle: 'Allow pharmacist to view your health data',
              trailing: Switch(
                value: _dataSharing,
                onChanged: (value) => setState(() => _dataSharing = value),
                activeColor: const Color(0xFFF59E0B),
              ),
            ),
            _buildSettingCard(
              icon: Icons.analytics_outlined,
              iconColor: const Color(0xFFEC4899),
              title: 'Analytics & Crash Reports',
              subtitle: 'Help us improve the app',
              trailing: Switch(
                value: _analyticsEnabled,
                onChanged: (value) => setState(() => _analyticsEnabled = value),
                activeColor: const Color(0xFFEC4899),
              ),
            ),
            
            const SizedBox(height: 24),

            // Data Management Section
            _buildSectionHeader('📁 Data Management', const Color(0xFFEF4444)),
            const SizedBox(height: 12),
            _buildSettingCard(
              icon: Icons.download_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: 'Download My Data',
              subtitle: 'Get a copy of your personal data',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showDownloadDataDialog(),
            ),
            _buildSettingCard(
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFEF4444),
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showDeleteAccountDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('Change Password'),
          ],
        ),
        content: const Text('Password change feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_outlined, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('Download Data'),
          ],
        ),
        content: const Text(
          'Export your health data as a PDF file. This includes your profile, medications, reminders, symptoms, and prescriptions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Download Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadData() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF6366F1)),
            SizedBox(width: 20),
            Expanded(child: Text('Generating your health report...')),
          ],
        ),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to download your data.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final exportService = DataExportService();
      final filePath = await exportService.exportUserDataAsPdf(user);

      Navigator.pop(context); // Close loading dialog

      if (filePath != null) {
        // Show success dialog with option to open file
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 12),
                Text('Download Complete!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your health data has been saved as a PDF file.'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          filePath,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFile.open(filePath);
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF. Please check storage permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
