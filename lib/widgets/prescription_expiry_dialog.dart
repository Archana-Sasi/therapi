import 'package:flutter/material.dart';

import '../screens/request_consultation_screen.dart';
import '../utils/prescription_expiry.dart';

/// Handles showing the appropriate warning dialog/snackbar based on
/// the prescription expiry escalation level.
class PrescriptionExpiryDialog {
  PrescriptionExpiryDialog._();

  /// Shows the appropriate warning for the given [level].
  ///
  /// Returns `true` if the action should proceed ("Continue Anyway" tapped),
  /// `false` if the action should be blocked.
  static Future<bool> showWarning(
    BuildContext context, {
    required PrescriptionExpiryLevel level,
    required int daysSinceExpiry,
    required String drugName,
  }) async {
    switch (level) {
      case PrescriptionExpiryLevel.none:
        return true; // no warning needed

      case PrescriptionExpiryLevel.green:
        return _showGreenWarning(context, daysSinceExpiry, drugName);

      case PrescriptionExpiryLevel.yellow:
        return await _showYellowWarning(context, daysSinceExpiry, drugName);

      case PrescriptionExpiryLevel.red:
        await _showRedWarning(context, daysSinceExpiry, drugName);
        return false; // always blocked
    }
  }

  /// 🟢 Green (0–30 days): Subtle SnackBar warning. Action proceeds.
  static bool _showGreenWarning(
    BuildContext context,
    int daysSinceExpiry,
    String drugName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prescription for $drugName expired $daysSinceExpiry day${daysSinceExpiry == 1 ? '' : 's'} ago. Please renew.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return true; // allow action
  }

  /// 🟡 Yellow (30–60 days): Strong popup. User can "Continue Anyway" or
  /// navigate to consultation.
  static Future<bool> _showYellowWarning(
    BuildContext context,
    int daysSinceExpiry,
    String drugName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
        ),
        title: const Text(
          'Prescription Expired',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your prescription for $drugName expired $daysSinceExpiry days ago.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please consult your doctor to renew this prescription.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx, false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestConsultationScreen()),
              );
            },
            icon: const Icon(Icons.video_call, size: 18),
            label: const Text('Request Consultation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 🔴 Red (60+ days): Blocking dialog. No way to proceed – must request
  /// consultation.
  static Future<void> _showRedWarning(
    BuildContext context,
    int daysSinceExpiry,
    String drugName,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block, color: Colors.red, size: 40),
        ),
        title: const Text(
          'Prescription Expired',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your prescription for $drugName has been expired for $daysSinceExpiry days.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.do_not_disturb_alt, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For your safety, you cannot take this medicine without a valid prescription. Please request a consultation.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Go Back'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestConsultationScreen()),
              );
            },
            icon: const Icon(Icons.video_call, size: 18),
            label: const Text('Request Consultation'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
