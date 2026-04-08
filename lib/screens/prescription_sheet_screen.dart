import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/prescription_model.dart';

/// Displays a prescription in a layout matching the reference image format.
class PrescriptionSheetScreen extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionSheetScreen({super.key, required this.prescription});

  @override
  State<PrescriptionSheetScreen> createState() => _PrescriptionSheetScreenState();
}

class _PrescriptionSheetScreenState extends State<PrescriptionSheetScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);
    try {
      final Uint8List? image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 2.0,
      );
      
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/Prescription_${widget.prescription.id}.png');
        await file.writeAsBytes(image);
        
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: 'Prescription for ${widget.prescription.patientName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save prescription: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  // ── Helpers ──

  String _fmtDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    
    int hour = dt.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12; // 12 AM / 12 PM
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hourStr:$minStr $amPm';
  }

  String _fmtDateOnly(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day $month $year';
  }

  String _frequencyText(PrescriptionItem med) {
    String f(double d) {
      if (d == 0) return '0';
      if (d == 0.5) return '½';
      if (d == 1.5) return '1½';
      if (d == 2.5) return '2½';
      return d.toInt().toString();
    }
    return '${f(med.morning)}-${f(med.afternoon)}-${f(med.evening)}-${f(med.night)}';
  }

  String _frequencyDescription(PrescriptionItem med) {
    final parts = <String>[];
    int count = 0;
    if (med.morning > 0) { parts.add('Morning'); count++; }
    if (med.afternoon > 0) { parts.add('Afternoon'); count++; }
    if (med.evening > 0) { parts.add('Evening'); count++; }
    if (med.night > 0) { parts.add('Night'); count++; }

    String timesLabel;
    if (med.frequency != 'Daily') {
      timesLabel = med.frequency;
    } else {
      if (count == 1) {
        timesLabel = 'Once a Day / ஒரு வேளை';
      } else if (count == 2) {
        timesLabel = 'Twice a Day / இரண்டு வேளை';
      } else if (count == 3) {
        timesLabel = 'Thrice a Day / மூன்று வேளை';
      } else if (count == 0) {
        timesLabel = 'As Directed / மருத்துவரின்\nஅறிவுரைப்படி';
      } else {
        timesLabel = '$count times a Day';
      }
    }

    String foodStr = med.foodTiming;
    if (med.foodTiming == 'Before food') foodStr = 'Before Food / உணவுக்கு முன்';
    else if (med.foodTiming == 'After food') foodStr = 'After Food / உணவுக்கு பின்';
    else if (med.foodTiming == 'Empty stomach') foodStr = 'Empty Stomach / வெறும் வயிற்றில்';
    else if (med.foodTiming == 'With food') foodStr = 'With Food / உணவோடு';

    return '($timesLabel)\n($foodStr)';
  }

  String _instructionsText(PrescriptionItem med) {
    final route = 'Oral'; // In a real app, this could be data driven
    final instr = med.instructions.isNotEmpty ? '${med.instructions}\n' : '';
    final startDate = 'StartDate: ${_fmtDateOnly(widget.prescription.createdAt)}';
    return '$route\n$instr$startDate';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final meds = widget.prescription.effectiveMedications;
    final hasConsultationData = widget.prescription.complaints.isNotEmpty ||
        widget.prescription.examination.isNotEmpty ||
        widget.prescription.diagnoses.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('Digital Prescription', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Save / Share Prescription',
                  onPressed: _exportAndShare,
                ),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.5,
        maxScale: 4.0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: 750, // A4-ish width
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ═══════════════════════════════════════
                  // HEADER
                  // ═══════════════════════════════════════
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════
                  // PATIENT INFO GRID
                  // ═══════════════════════════════════════
                  _buildPatientInfoSection(),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════
                  // TITLE & CONSULTATION NOTE
                  // ═══════════════════════════════════════
                  Center(
                    child: Text(
                      '${widget.prescription.department.isNotEmpty ? widget.prescription.department : "Consultation"} Note',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (hasConsultationData) _buildConsultationNote(),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════
                  // Rx: (DRUGS) TABLE
                  // ═══════════════════════════════════════
                  _buildDrugsSection(meds),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════
                  // ADVICE & FOLLOW UP (From 2nd Image)
                  // ═══════════════════════════════════════
                  _buildAdviceSection(),

                  const SizedBox(height: 60),

                      // Optional simple signature at bottom
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Dr. ${widget.prescription.doctorName ?? widget.prescription.pharmacistName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'PSG IMSR & HOSPITALS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '(Affiliated to PSG Institute of Medical Sciences & Research)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'PEELAMEDU, COIMBATORE - 6410 04. Phone : 0422 - 2570170',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoSection() {
    final ageStr = widget.prescription.patientAge != null ? '${widget.prescription.patientAge} Years' : '-';
    final genStr = (widget.prescription.patientGender?.isNotEmpty ?? false)
        ? widget.prescription.patientGender![0].toUpperCase() + widget.prescription.patientGender!.substring(1)
        : '-';
    final ageGender = '$ageStr / $genStr';
    final opNo = widget.prescription.patientOpNumber?.isNotEmpty == true ? widget.prescription.patientOpNumber! : 'N/A';
    final visitId = widget.prescription.visitId?.isNotEmpty == true ? widget.prescription.visitId! : 'N/A';
    final docName = 'Dr.${widget.prescription.doctorName ?? widget.prescription.pharmacistName}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Patient Name', widget.prescription.patientName),
              const SizedBox(height: 8),
              _infoRow('Age / Gender', ageGender),
              const SizedBox(height: 8),
              _infoRow('Department(Specialty)', widget.prescription.department.isNotEmpty ? widget.prescription.department.toUpperCase() : 'GENERAL'),
              const SizedBox(height: 8),
              _infoRow('Visit Date', _fmtDate(widget.prescription.createdAt)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // RIGHT COLUMN
        Expanded(
          flex: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Patient Id / Visit Id', '$opNo/ $visitId'),
              const SizedBox(height: 8),
              _infoRow('Location', widget.prescription.department.isNotEmpty ? widget.prescription.department.toUpperCase() : 'GENERAL'),
              const SizedBox(height: 8),
              _infoRow('Doctor / Unit Chief', docName),
              const SizedBox(height: 8),
              _infoRow('Type', widget.prescription.visitType),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const Text(':', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.prescription.diagnoses.isNotEmpty) ...[
          const Text(
            'Diagnosis :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          ...widget.prescription.diagnoses.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('► ', style: TextStyle(fontSize: 10, color: Colors.black)),
                    Expanded(
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],

        if (widget.prescription.complaints.isNotEmpty) ...[
          const Text(
            'Presenting Complaints :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              widget.prescription.complaints,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (widget.prescription.examination.isNotEmpty) ...[
          const Text(
            'Examination :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              widget.prescription.examination,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDrugsSection(List<PrescriptionItem> meds) {
    if (meds.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rx : (Drugs)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black54, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(40),  // S.No
            1: FlexColumnWidth(2.5),  // Name
            2: FlexColumnWidth(1.8),  // Frequency
            3: FlexColumnWidth(1.8),  // Instructions
            4: FixedColumnWidth(75),  // Duration
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF0F0F0)),
              children: const [
                _Cell(text: 'S.No', bold: true),
                _Cell(text: 'Name', bold: true, alignLeft: true),
                _Cell(text: 'Frequency', bold: true, alignLeft: true),
                _Cell(text: 'Instructions', bold: true, alignLeft: true),
                _Cell(text: 'Duration', bold: true),
              ],
            ),
            ...meds.asMap().entries.map((entry) {
              final i = entry.key;
              final med = entry.value;

              final dosageLabel = med.dosage.isNotEmpty ? '\n${med.dosage}' : '';
              final drugLabel = med.brandName.isNotEmpty
                  ? '${med.genericName}\n[${med.brandName}]$dosageLabel'
                  : '${med.genericName}$dosageLabel';

              return TableRow(
                children: [
                  _Cell(text: '${i + 1}'),
                  _Cell(text: drugLabel, alignLeft: true),
                  _CellRich(main: _frequencyText(med), sub: _frequencyDescription(med), alignLeft: true),
                  _Cell(text: _instructionsText(med), alignLeft: true),
                  _Cell(text: med.duration),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildAdviceSection() {
    if (widget.prescription.advice.isEmpty && widget.prescription.followUpNotes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advice & Follow up',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        if (widget.prescription.followUpNotes.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 60,
                child: Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const Text(' :   ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              Expanded(
                child: Text(
                  widget.prescription.followUpNotes,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        if (widget.prescription.advice.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 60,
                child: Text('Advice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const Text(' :   ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              Expanded(
                child: Text(
                  widget.prescription.advice,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool alignLeft;

  const _Cell({
    required this.text,
    this.bold = false,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _CellRich extends StatelessWidget {
  final String main;
  final String sub;
  final bool alignLeft;

  const _CellRich({required this.main, required this.sub, this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            main,
            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }
}
