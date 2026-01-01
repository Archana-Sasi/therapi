import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../models/medication_reminder.dart';
import '../models/prescription_model.dart';
import '../models/symptom_log.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Service for exporting user data as professional medical PDF report
class DataExportService {
  final AuthService _authService = AuthService();

  // Medical report colors
  static const _primaryColor = PdfColors.blue900;
  static const _accentColor = PdfColors.teal700;
  static const _headerBg = PdfColors.blue50;
  static const _tableBorderColor = PdfColors.grey400;
  static const _tableHeaderBg = PdfColors.blue100;

  /// Exports all user data to a PDF file and returns the file path
  Future<String?> exportUserDataAsPdf(UserModel user) async {
    try {
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
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildDocumentHeader(user, context),
          footer: (context) => _buildPageFooter(context),
          build: (context) => [
            pw.SizedBox(height: 10),
            _buildPatientInfoCard(user),
            pw.SizedBox(height: 16),
            _buildMedicationsTable(medications),
            pw.SizedBox(height: 16),
            _buildRemindersTable(reminders),
            pw.SizedBox(height: 16),
            _buildSymptomsTable(symptoms),
            pw.SizedBox(height: 16),
            _buildPrescriptionsTable(prescriptions),
            pw.SizedBox(height: 24),
            _buildDisclaimerSection(),
          ],
        ),
      );

      // Save to app's external files directory
      final outputDir = await _getOutputDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'RespiriCare_MedicalReport_$timestamp.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('Error exporting data: $e');
      return null;
    }
  }

  /// Exports pharmacist activity data as PDF (prescriptions given to patients)
  Future<String?> exportPharmacistDataAsPdf(UserModel pharmacist) async {
    try {
      // Get all prescriptions created by this pharmacist
      final prescriptions = await _authService.getPrescriptionsByPharmacist();
      
      // Get all users to find patient names
      final allUsers = await _authService.getAllUsers();
      final patientMap = <String, String>{};
      for (final user in allUsers) {
        patientMap[user.id] = user.fullName;
      }

      // Generate PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPharmacistReportHeader(pharmacist, context),
          footer: (context) => _buildPageFooter(context),
          build: (context) => [
            pw.SizedBox(height: 10),
            _buildPharmacistInfoCard(pharmacist),
            pw.SizedBox(height: 16),
            _buildPrescriptionActivityTable(prescriptions, patientMap),
            pw.SizedBox(height: 16),
            _buildPrescriptionSummary(prescriptions),
            pw.SizedBox(height: 24),
            _buildPharmacistDisclaimer(),
          ],
        ),
      );

      // Save to app's external files directory
      final outputDir = await _getOutputDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'RespiriCare_PharmacistActivity_$timestamp.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('Error exporting pharmacist data: $e');
      return null;
    }
  }

  /// Pharmacist report header
  pw.Widget _buildPharmacistReportHeader(UserModel pharmacist, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RESPIRICARE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Pharmacist Activity Report',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PRESCRIPTION RECORD',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal700,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Report ID: PH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                'Generated: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pharmacist info card
  pw.Widget _buildPharmacistInfoCard(UserModel pharmacist) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        border: pw.Border.all(color: PdfColors.teal800, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PHARMACIST INFORMATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Full Name', pharmacist.fullName),
                    _buildInfoRow('Email', pharmacist.email),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Staff ID', 'PH-${pharmacist.id.length > 8 ? pharmacist.id.substring(0, 8).toUpperCase() : pharmacist.id.toUpperCase()}'),
                    _buildInfoRow('Role', pharmacist.role.toUpperCase()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Prescription activity table
  pw.Widget _buildPrescriptionActivityTable(List<Prescription> prescriptions, Map<String, String> patientMap) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal100,
            border: pw.Border.all(color: _tableBorderColor),
          ),
          child: pw.Text(
            'PRESCRIPTIONS ISSUED (${prescriptions.length})',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: _tableBorderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(0.8),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeaderCell('S.No'),
                _buildTableHeaderCell('Patient Name'),
                _buildTableHeaderCell('Medication'),
                _buildTableHeaderCell('Dosage'),
                _buildTableHeaderCell('Date'),
                _buildTableHeaderCell('Status'),
              ],
            ),
            // Data rows
            if (prescriptions.isEmpty)
              pw.TableRow(
                children: [
                  _buildTableCell('--'),
                  _buildTableCell('No prescriptions issued'),
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                ],
              )
            else
              ...prescriptions.asMap().entries.map((entry) {
                final rx = entry.value;
                final patientName = patientMap[rx.patientId] ?? 'Unknown Patient';
                return pw.TableRow(
                  children: [
                    _buildTableCell('${entry.key + 1}'),
                    _buildTableCell(patientName),
                    _buildTableCell(rx.brandName.isNotEmpty ? rx.brandName : rx.genericName),
                    _buildTableCell(rx.dosage),
                    _buildTableCell(_formatShortDate(rx.createdAt)),
                    _buildTableCell(rx.isActive ? 'Active' : 'Done',
                        color: rx.isActive ? PdfColors.green700 : PdfColors.grey600),
                  ],
                );
              }),
          ],
        ),
      ],
    );
  }

  /// Prescription summary
  pw.Widget _buildPrescriptionSummary(List<Prescription> prescriptions) {
    final activeCount = prescriptions.where((rx) => rx.isActive).length;
    final completedCount = prescriptions.length - activeCount;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SUMMARY',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Prescriptions', '${prescriptions.length}', PdfColors.blue700),
              _buildSummaryItem('Active', '$activeCount', PdfColors.green700),
              _buildSummaryItem('Completed', '$completedCount', PdfColors.grey600),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Pharmacist disclaimer
  pw.Widget _buildPharmacistDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        border: pw.Border.all(color: PdfColors.teal200),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PHARMACIST ACTIVITY RECORD',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This document contains a record of prescriptions issued through RespiriCare. '
            'This report is for your professional records and internal use only. '
            'Please handle patient information in accordance with healthcare privacy regulations.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  Future<Directory> _getOutputDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final reportsDir = Directory('${externalDir.path}/Reports');
        if (!await reportsDir.exists()) {
          await reportsDir.create(recursive: true);
        }
        return reportsDir;
      }
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<List<SymptomLog>> _getSymptomLogs(String userId) async {
    try {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Professional medical report header
  pw.Widget _buildDocumentHeader(UserModel user, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RESPIRICARE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Digital Therapeutics Health Report',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PATIENT HEALTH RECORD',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Report ID: RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                'Generated: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Page footer with page numbers
  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'RespiriCare - Confidential Medical Document',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Patient information card
  pw.Widget _buildPatientInfoCard(UserModel user) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        border: pw.Border.all(color: _primaryColor, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT INFORMATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Full Name', user.fullName),
                    _buildInfoRow('Email', user.email),
                    _buildInfoRow('Patient ID', 'RC-${user.id.length > 12 ? user.id.substring(0, 12).toUpperCase() : user.id.toUpperCase()}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Age', '${user.age ?? 'N/A'} years'),
                    _buildInfoRow('Gender', user.gender?.toUpperCase() ?? 'N/A'),
                    _buildInfoRow('Account Type', user.role.toUpperCase()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
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
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  /// Section header builder
  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _tableHeaderBg,
        border: pw.Border.all(color: _tableBorderColor),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  /// Medications table with disease information
  pw.Widget _buildMedicationsTable(List<Map<String, String>> medications) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CURRENT MEDICATIONS'),
        pw.Table(
          border: pw.TableBorder.all(color: _tableBorderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeaderCell('S.No'),
                _buildTableHeaderCell('Generic Name'),
                _buildTableHeaderCell('Brand Name'),
                _buildTableHeaderCell('Condition/Disease'),
              ],
            ),
            // Data rows
            if (medications.isEmpty)
              pw.TableRow(
                children: [
                  _buildTableCell('--'),
                  _buildTableCell('No medications recorded'),
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                ],
              )
            else
              ...medications.asMap().entries.map((entry) {
                final drugId = entry.value['drugId'] ?? 'Unknown';
                final diseases = _getDiseaseNamesForDrug(drugId);
                return pw.TableRow(
                  children: [
                    _buildTableCell('${entry.key + 1}'),
                    _buildTableCell(drugId),
                    _buildTableCell(entry.value['brandName'] ?? '--'),
                    _buildTableCell(diseases),
                  ],
                );
              }),
          ],
        ),
      ],
    );
  }

  /// Get disease names for a drug
  String _getDiseaseNamesForDrug(String drugId) {
    final drug = DrugData.getDrugById(drugId.toLowerCase());
    if (drug != null && drug.diseases.isNotEmpty) {
      return drug.diseases.map((d) => _formatDiseaseName(d)).join(', ');
    }
    return 'General';
  }

  /// Format disease ID to readable name
  String _formatDiseaseName(String diseaseId) {
    switch (diseaseId.toLowerCase()) {
      case 'asthma': return 'Asthma';
      case 'copd': return 'COPD';
      case 'bronchitis': return 'Bronchitis';
      case 'allergic_rhinitis': return 'Allergic Rhinitis';
      case 'ild': return 'ILD';
      case 'pneumonia': return 'Pneumonia';
      default: return diseaseId;
    }
  }

  /// Medication reminders table - simplified without times
  pw.Widget _buildRemindersTable(List<MedicationReminder> reminders) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('MEDICATION SCHEDULE'),
        pw.Table(
          border: pw.TableBorder.all(color: _tableBorderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.5),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeaderCell('S.No'),
                _buildTableHeaderCell('Medication'),
                _buildTableHeaderCell('Dosage'),
                _buildTableHeaderCell('Status'),
              ],
            ),
            // Data rows
            if (reminders.isEmpty)
              pw.TableRow(
                children: [
                  _buildTableCell('--'),
                  _buildTableCell('No medications scheduled'),
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                ],
              )
            else
              ...reminders.asMap().entries.map((entry) {
                final r = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell('${entry.key + 1}'),
                    _buildTableCell(r.brandName.isNotEmpty ? r.brandName : r.drugId),
                    _buildTableCell(r.dosage),
                    _buildTableCell(r.isEnabled ? 'Active' : 'Inactive',
                        color: r.isEnabled ? PdfColors.green700 : PdfColors.red700),
                  ],
                );
              }),
          ],
        ),
      ],
    );
  }

  /// Symptoms table
  pw.Widget _buildSymptomsTable(List<SymptomLog> symptoms) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SYMPTOM HISTORY'),
        pw.Table(
          border: pw.TableBorder.all(color: _tableBorderColor, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
            6: const pw.FlexColumnWidth(1),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeaderCell('Date'),
                _buildTableHeaderCell('Breathing'),
                _buildTableHeaderCell('Cough'),
                _buildTableHeaderCell('Wheeze'),
                _buildTableHeaderCell('Chest'),
                _buildTableHeaderCell('Fatigue'),
                _buildTableHeaderCell('Severity'),
              ],
            ),
            // Data rows
            if (symptoms.isEmpty)
              pw.TableRow(
                children: [
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                  _buildTableCell('--'),
                  _buildTableCell('No symptom logs recorded', colSpan: 3),
                  _buildTableCell('--'),
                ],
              )
            else
              ...symptoms.map((log) => pw.TableRow(
                children: [
                  _buildTableCell(_formatShortDate(log.timestamp)),
                  _buildTableCell('${log.breathlessness}/5'),
                  _buildTableCell('${log.cough}/5'),
                  _buildTableCell('${log.wheezing}/5'),
                  _buildTableCell('${log.chestTightness}/5'),
                  _buildTableCell('${log.fatigue}/5'),
                  _buildTableCell(log.severityLabel,
                      color: _getSeverityColor(log.overallSeverity)),
                ],
              )),
          ],
        ),
      ],
    );
  }

  /// Prescriptions table
  pw.Widget _buildPrescriptionsTable(List<Prescription> prescriptions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PRESCRIPTION HISTORY'),
        if (prescriptions.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _tableBorderColor, width: 0.5),
            ),
            child: pw.Text(
              'No prescriptions on record.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          )
        else
          ...prescriptions.map((rx) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _tableBorderColor, width: 0.5),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      rx.brandName.isNotEmpty ? rx.brandName : rx.genericName,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: rx.isActive ? PdfColors.green50 : PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        rx.isActive ? 'ACTIVE' : 'COMPLETED',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: rx.isActive ? PdfColors.green800 : PdfColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        _buildRxDetail('Dosage', rx.dosage),
                        _buildRxDetail('Duration', rx.duration),
                        _buildRxDetail('Prescribed By', rx.pharmacistName),
                        _buildRxDetail('Date', rx.formattedDate),
                      ],
                    ),
                  ],
                ),
                if (rx.instructions.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Instructions: ${rx.instructions}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          )),
      ],
    );
  }

  pw.Widget _buildRxDetail(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.Text(
          value.isEmpty ? '--' : value,
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  /// Disclaimer section
  pw.Widget _buildDisclaimerSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber200),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IMPORTANT NOTICE',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This document is a digital health record generated by RespiriCare application. '
            'The information contained herein is for personal health management purposes only. '
            'Please share this document only with your authorized healthcare providers. '
            'This report does not replace professional medical advice, diagnosis, or treatment.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Table cell helpers
  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {PdfColor? color, int colSpan = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color ?? PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  PdfColor _getSeverityColor(double severity) {
    if (severity >= 4) return PdfColors.red700;
    if (severity >= 3) return PdfColors.orange700;
    if (severity >= 2) return PdfColors.amber700;
    return PdfColors.green700;
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
