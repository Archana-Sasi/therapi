import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import '../models/medication_reminder.dart';
import '../models/prescription_model.dart';
import '../models/symptom_log.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Service for exporting user data as PDF
class DataExportService {
  final AuthService _authService = AuthService();

  /// Exports all user data to a PDF file and returns the file path
  Future<String?> exportUserDataAsPdf(UserModel user) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try manage external storage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Collect all user data
      final medications = await _authService.getCurrentUserMedications();
      final reminders = await _authService.getMedicationReminders();
      final symptoms = await _getSymptomLogs(user.id);
      final prescriptions = await _authService.getPrescriptionsForPatient(user.id);

      // Generate PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildUserProfile(user),
            pw.SizedBox(height: 20),
            _buildMedicationsSection(medications),
            pw.SizedBox(height: 20),
            _buildRemindersSection(reminders),
            pw.SizedBox(height: 20),
            _buildSymptomsSection(symptoms),
            pw.SizedBox(height: 20),
            _buildPrescriptionsSection(prescriptions),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ],
        ),
      );

      // Save to Downloads folder
      final outputDir = await _getDownloadsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'RespiriCare_HealthData_$timestamp.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('Error exporting data: $e');
      return null;
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Use external storage Downloads folder
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
      // Fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    } else {
      // iOS - use documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<List<SymptomLog>> _getSymptomLogs(String userId) async {
    try {
      // This would need to be implemented in AuthService
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      return [];
    }
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RespiriCare',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Personal Health Data Export',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated on: ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildUserProfile(UserModel user) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '👤 User Profile',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          _buildProfileRow('Name', user.fullName),
          _buildProfileRow('Email', user.email),
          _buildProfileRow('Age', user.age?.toString() ?? 'Not specified'),
          _buildProfileRow('Gender', user.gender ?? 'Not specified'),
          _buildProfileRow('Role', user.role.toUpperCase()),
        ],
      ),
    );
  }

  pw.Widget _buildProfileRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMedicationsSection(List<Map<String, String>> medications) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💊 My Medications (${medications.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          if (medications.isEmpty)
            pw.Text('No medications added yet.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            ...medications.map((med) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('${med['drugId'] ?? 'Unknown'}'),
                      if (med['brandName']?.isNotEmpty ?? false)
                        pw.Text(' (${med['brandName']})',
                            style:
                                const pw.TextStyle(color: PdfColors.grey600)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  pw.Widget _buildRemindersSection(List<MedicationReminder> reminders) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '⏰ Medication Reminders (${reminders.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          if (reminders.isEmpty)
            pw.Text('No reminders set.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            ...reminders.map((reminder) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        reminder.brandName.isNotEmpty
                            ? reminder.brandName
                            : reminder.drugId,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Times: ${reminder.scheduledTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'Status: ${reminder.isEnabled ? 'Active' : 'Disabled'}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  pw.Widget _buildSymptomsSection(List<SymptomLog> symptoms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📋 Symptom Logs (${symptoms.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          if (symptoms.isEmpty)
            pw.Text('No symptoms logged yet.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            ...symptoms.map((log) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Symptom Log',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Severity: ${log.severityLabel}',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Breathlessness: ${log.breathlessness}/5', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Cough: ${log.cough}/5', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Wheezing: ${log.wheezing}/5', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Chest Tightness: ${log.chestTightness}/5', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Fatigue: ${log.fatigue}/5', style: const pw.TextStyle(fontSize: 10)),
                      if (log.notes.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Notes: ${log.notes}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _formatDate(log.timestamp),
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  pw.Widget _buildPrescriptionsSection(List<Prescription> prescriptions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📝 Prescriptions (${prescriptions.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          if (prescriptions.isEmpty)
            pw.Text('No prescriptions received yet.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            ...prescriptions.map((rx) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            rx.brandName.isNotEmpty
                                ? rx.brandName
                                : rx.genericName,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: rx.isActive
                                  ? PdfColors.green100
                                  : PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.Text(
                              rx.isActive ? 'Active' : 'Inactive',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: rx.isActive
                                    ? PdfColors.green800
                                    : PdfColors.grey600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      _buildPrescriptionRow('Dosage', rx.dosage),
                      _buildPrescriptionRow('Duration', rx.duration),
                      _buildPrescriptionRow('Instructions', rx.instructions),
                      _buildPrescriptionRow('Prescribed by', rx.pharmacistName),
                      _buildPrescriptionRow('Date', rx.formattedDate),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  pw.Widget _buildPrescriptionRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'This document contains your personal health data from RespiriCare.',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Keep this document secure and share only with trusted healthcare providers.',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
