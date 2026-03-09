import 'package:flutter/material.dart';
import '../models/prescription_model.dart';

/// Displays a prescription in a professional black-and-white table format,
/// optimised for tablet-sized screens.
class PrescriptionSheetScreen extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionSheetScreen({super.key, required this.prescription});

  // ── Helpers ──

  String _fmtDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _tabletText(int count) {
    if (count == 0) return '—';
    return '$count ${count == 1 ? 'Tab' : 'Tabs'}';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final meds = prescription.effectiveMedications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Digital Prescription', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black12),
        ),
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
              child: Container(
                width: 650, // Fixed A4-like width

            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black, width: 1.5)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'RespiriCare',
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900,
                          letterSpacing: 2, color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DIGITAL PRESCRIPTION',
                        style: TextStyle(
                          fontSize: 11, letterSpacing: 3,
                          fontWeight: FontWeight.w500, color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Doctor / Patient / Date Row ──
                Table(
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Colors.black, width: 0.5),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        _headerCell('DOCTOR'),
                        _headerCell('PATIENT'),
                        _headerCell('DATE'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _valueCell('Dr. ${prescription.doctorName ?? prescription.pharmacistName}'),
                        _valueCell(prescription.patientName),
                        _valueCell(_fmtDate(prescription.createdAt)),
                      ],
                    ),
                  ],
                ),

                Container(height: 1.5, color: Colors.black),

                // ── Rx Symbol ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    children: [
                      const Text(
                        'Rx',
                        style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic, color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: Text(
                          prescription.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold,
                            letterSpacing: 1, color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Medication Table ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Table(
                        border: TableBorder.all(color: Colors.black, width: 0.8),
                        columnWidths: const {
                          0: FixedColumnWidth(30),   // S.No
                          1: FlexColumnWidth(2.5),   // Drug Name
                          2: FlexColumnWidth(1),     // Dosage
                          3: FlexColumnWidth(1),     // Duration
                          4: FixedColumnWidth(45),   // Morning
                          5: FixedColumnWidth(45),   // Afternoon
                          6: FixedColumnWidth(45),   // Evening
                          7: FixedColumnWidth(45),   // Night
                          8: FlexColumnWidth(1),     // Food
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF0F0F0)),
                            children: const [
                              _TCell(text: '#', bold: true),
                              _TCell(text: 'Drug Name', bold: true, alignLeft: true),
                              _TCell(text: 'Dosage', bold: true),
                              _TCell(text: 'Dur', bold: true),
                              _TCell(text: 'Morn', bold: true),
                              _TCell(text: 'Aft', bold: true),
                              _TCell(text: 'Eve', bold: true),
                              _TCell(text: 'Night', bold: true),
                              _TCell(text: 'Food', bold: true),
                            ],
                          ),
                          // Data rows
                          ...meds.asMap().entries.map((entry) {
                            final i = entry.key;
                            final med = entry.value;
                            final drugLabel = med.brandName.isNotEmpty
                                ? '${med.genericName}\n(${med.brandName})'
                                : med.genericName;

                            return TableRow(
                              children: [
                                _TCell(text: '${i + 1}'),
                                _TCell(text: drugLabel, alignLeft: true),
                                _TCell(text: med.dosage),
                                _TCell(text: med.duration),
                                _TCell(text: _tabletText(med.morning), highlight: med.morning > 0),
                                _TCell(text: _tabletText(med.afternoon), highlight: med.afternoon > 0),
                                _TCell(text: _tabletText(med.evening), highlight: med.evening > 0),
                                _TCell(text: _tabletText(med.night), highlight: med.night > 0),
                                _TCell(text: med.beforeFood ? 'Before' : 'After'),
                              ],
                            );
                          }),
                        ],
                      ),
                ),

                // ── Instructions (if any) ──
                if (meds.any((m) => m.instructions.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INSTRUCTIONS',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold,
                            letterSpacing: 1, color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...meds.where((m) => m.instructions.isNotEmpty).map((med) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${med.genericName}: ',
                                  style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    med.instructions,
                                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // ── Signature ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 160, height: 1, color: Colors.black),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. ${prescription.doctorName ?? prescription.pharmacistName}',
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black,
                          ),
                        ),
                        const Text(
                          'Authorized Signature',
                          style: TextStyle(
                            fontSize: 9, color: Colors.black54, fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Footer ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
                  ),
                  child: const Text(
                    'This is a digitally generated prescription from RespiriCare.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: Colors.black45, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  // ── Small helper cells for the header/value table ──

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700,
            letterSpacing: 1, color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _valueCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
    );
  }
}

// ── Table cell widget (used inside the medication table) ──
class _TCell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool alignLeft;
  final bool highlight;

  const _TCell({
    required this.text,
    this.bold = false,
    this.alignLeft = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: bold ? 10 : 11,
          fontWeight: (bold || highlight) ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }
}
