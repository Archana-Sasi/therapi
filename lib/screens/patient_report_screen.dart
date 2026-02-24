import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/prescription_model.dart';
import '../models/symptom_log.dart';
import '../models/consultation.dart';
import '../services/auth_service.dart';
import '../data/drug_data.dart';

/// Comprehensive patient report for doctors — summarises demographics,
/// prescriptions, adherence records, symptom history, and consultations.
class PatientReportScreen extends StatefulWidget {
  const PatientReportScreen({super.key, required this.patient});
  final UserModel patient;

  @override
  State<PatientReportScreen> createState() => _PatientReportScreenState();
}

class _PatientReportScreenState extends State<PatientReportScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _medications = [];
  List<Prescription> _prescriptions = [];
  List<SymptomLog> _symptomLogs = [];
  List<Consultation> _consultations = [];

  // Adherence stats
  int _totalTaken = 0;
  int _totalMissed = 0;
  int _totalPending = 0;
  int _totalLogs = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final pid = widget.patient.id;

    // Load all data in parallel
    final results = await Future.wait([
      _authService.getMedicationsForUser(pid),
      _authService.getPrescriptionsForPatient(pid),
      _loadSymptomLogs(pid),
      _loadConsultations(pid),
      _loadAdherenceStats(pid),
    ]);

    if (mounted) {
      setState(() {
        _medications = results[0] as List<Map<String, dynamic>>;
        _prescriptions = results[1] as List<Prescription>;
        _symptomLogs = results[2] as List<SymptomLog>;
        _consultations = results[3] as List<Consultation>;
        // adherence stats set in _loadAdherenceStats
        _isLoading = false;
      });
    }
  }

  Future<List<SymptomLog>> _loadSymptomLogs(String pid) async {
    try {
      final snap = await _firestore
          .collection('users').doc(pid)
          .collection('symptom_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => SymptomLog.fromMap(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Consultation>> _loadConsultations(String pid) async {
    try {
      final snap = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: pid)
          .get();
      final list = snap.docs.map((d) => Consultation.fromMap(d.data())).toList();
      list.sort((a, b) => b.requestedDate.compareTo(a.requestedDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadAdherenceStats(String pid) async {
    try {
      final snap = await _firestore
          .collection('users').doc(pid)
          .collection('medication_logs')
          .get();
      int taken = 0, missed = 0, pending = 0;
      for (final doc in snap.docs) {
        final s = doc.data()['status'] ?? '';
        if (s == 'taken') taken++;
        else if (s == 'missed') missed++;
        else if (s == 'pending') pending++;
      }
      _totalTaken = taken;
      _totalMissed = missed;
      _totalPending = pending;
      _totalLogs = snap.docs.length;
    } catch (_) {}
  }

  // ──────────── Helpers ────────────

  String _drugName(String drugId) {
    final d = DrugData.getDrugById(drugId);
    return d?.genericName ?? drugId;
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _fmtDateTime(DateTime d) {
    final hr = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${_fmtDate(d)}, $hr:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  Color _severityColor(double s) {
    if (s == 0) return Colors.green;
    if (s < 2) return Colors.lightGreen;
    if (s < 3) return Colors.amber;
    if (s < 4) return Colors.orange;
    return Colors.red;
  }

  // ──────────── Build ────────────

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Report'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ───
                  _reportHeader(p, theme),
                  const SizedBox(height: 20),

                  // 1. Patient Details
                  _sectionTitle('Patient Details', Icons.person),
                  _patientDetailsCard(p),
                  const SizedBox(height: 20),

                  // 2. Current Medications & Prescriptions
                  _sectionTitle('Prescriptions', Icons.receipt_long),
                  _prescriptionsCard(),
                  const SizedBox(height: 20),

                  // 3. Adherence Records
                  _sectionTitle('Adherence Records', Icons.check_circle),
                  _adherenceCard(),
                  const SizedBox(height: 20),

                  // 4. Symptom History
                  _sectionTitle('Symptom History', Icons.monitor_heart),
                  _symptomCard(),
                  const SizedBox(height: 20),

                  // 5. Consultation History
                  _sectionTitle('Consultation History', Icons.video_call),
                  _consultationCard(),
                ],
              ),
            ),
    );
  }

  // ── Report Header ──
  Widget _reportHeader(UserModel p, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                (p.fullName.isNotEmpty ? p.fullName[0] : '?').toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Report generated on ${_fmtDate(DateTime.now())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Title ──
  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── 1. Patient Details ──
  Widget _patientDetailsCard(UserModel p) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _infoRow('Full Name', p.fullName),
            _infoRow('Age', p.age != null ? '${p.age} years' : 'N/A'),
            _infoRow('Gender', p.gender != null && p.gender!.isNotEmpty ? p.gender! : 'N/A'),
            _infoRow('OP Number', p.opNumber != null && p.opNumber!.isNotEmpty ? p.opNumber! : 'N/A'),
            _infoRow('Phone', p.phoneNumber != null && p.phoneNumber!.isNotEmpty ? p.phoneNumber! : 'N/A'),
            _infoRow('Email', p.email),
            _infoRow('Active Medications', '${_medications.length}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── 2. Prescriptions ──
  Widget _prescriptionsCard() {
    if (_prescriptions.isEmpty) {
      return _emptyNotice('No prescriptions found');
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Current medications
          if (_medications.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Medications (${_medications.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _medications.map((m) {
                      final name = _drugName(m['drugId'] ?? '');
                      final brand = m['brandName'] ?? '';
                      return Chip(
                        label: Text(
                          brand.isNotEmpty ? brand : name,
                          style: const TextStyle(fontSize: 11),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          // Prescription list
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription History (${_prescriptions.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...(_prescriptions.take(10).map((rx) {
                  Color statusColor = Colors.grey;
                  if (rx.status == 'approved') statusColor = Colors.green;
                  else if (rx.status == 'pending') statusColor = Colors.orange;
                  else if (rx.status == 'rejected') statusColor = Colors.red;

                  final meds = rx.effectiveMedications;
                  final medNames = meds.map((m) {
                    final n = _drugName(m.drugId);
                    return m.brandName.isNotEmpty ? m.brandName : n;
                  }).join(', ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            medNames.isNotEmpty ? medNames : 'Prescription',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          rx.status.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                })),
                if (_prescriptions.length > 10)
                  Text(
                    '+ ${_prescriptions.length - 10} more',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Adherence Records ──
  Widget _adherenceCard() {
    if (_totalLogs == 0) {
      return _emptyNotice('No adherence records found');
    }

    final adherenceRate = _totalLogs > 0
        ? ((_totalTaken / (_totalTaken + _totalMissed)) * 100).toStringAsFixed(1)
        : '0.0';

    final adherencePercent = _totalLogs > 0
        ? (_totalTaken / (_totalTaken + _totalMissed))
        : 0.0;

    Color rateColor = Colors.green;
    if (adherencePercent < 0.5) {
      rateColor = Colors.red;
    } else if (adherencePercent < 0.75) {
      rateColor = Colors.orange;
    } else if (adherencePercent < 0.9) {
      rateColor = Colors.amber.shade700;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Adherence rate bar
            Row(
              children: [
                Text('Adherence Rate', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const Spacer(),
                Text(
                  '$adherenceRate%',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: rateColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: adherencePercent.toDouble(),
                backgroundColor: Colors.grey.shade200,
                color: rateColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                _statChip('Taken', _totalTaken, Colors.green),
                const SizedBox(width: 8),
                _statChip('Missed', _totalMissed, Colors.red),
                const SizedBox(width: 8),
                _statChip('Pending', _totalPending, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  // ── 4. Symptom History ──
  Widget _symptomCard() {
    if (_symptomLogs.isEmpty) {
      return _emptyNotice('No symptom logs recorded');
    }

    // Summary: average severity over time
    final recent = _symptomLogs.take(10).toList();
    final avgSeverity = recent.map((l) => l.overallSeverity).reduce((a, b) => a + b) / recent.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Average severity
            Row(
              children: [
                Text('Avg Severity (recent)', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor(avgSeverity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    avgSeverity.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _severityColor(avgSeverity),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Total entries: ${_symptomLogs.length}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const Divider(height: 16),
            // Recent entries
            Text('Recent Entries', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...recent.take(5).map((log) {
              final c = _severityColor(log.overallSeverity);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(log.severityLabel, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(_fmtDate(log.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              );
            }),
            if (log_has_notes()) ...[
              const SizedBox(height: 4),
              Text(
                'Latest note: ${_symptomLogs.first.notes}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool log_has_notes() => _symptomLogs.isNotEmpty && _symptomLogs.first.notes.isNotEmpty;

  // ── 5. Consultation History ──
  Widget _consultationCard() {
    if (_consultations.isEmpty) {
      return _emptyNotice('No consultation history');
    }

    int completed = _consultations.where((c) => c.status == ConsultationStatus.completed).length;
    int pending = _consultations.where((c) => c.status == ConsultationStatus.pending).length;
    int cancelled = _consultations.where((c) => c.status == ConsultationStatus.cancelled).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Total', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const Spacer(),
                Text(
                  '${_consultations.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniStat('Completed', completed, Colors.blue),
                const SizedBox(width: 8),
                _miniStat('Pending', pending, Colors.orange),
                const SizedBox(width: 8),
                _miniStat('Cancelled', cancelled, Colors.red),
              ],
            ),
            const Divider(height: 16),
            ...(_consultations.take(5).map((c) {
              final statusColor = Color(c.statusColor);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      c.status == ConsultationStatus.completed
                          ? Icons.check_circle
                          : c.status == ConsultationStatus.cancelled
                              ? Icons.cancel
                              : Icons.schedule,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${c.formattedDate} at ${c.requestedTime}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      c.statusText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              );
            })),
            if (_consultations.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${_consultations.length - 5} more consultations',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Empty Notice ──
  Widget _emptyNotice(String msg) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(msg, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ),
      ),
    );
  }
}
