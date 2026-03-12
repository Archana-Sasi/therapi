import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curated_medicine_data.dart';
import '../data/drug_data.dart';
import '../models/custom_drug.dart';
import '../models/drug_model.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'prescription_sheet_screen.dart';

/// Screen for creating a new prescription with multiple medications
class CreatePrescriptionScreen extends StatefulWidget {
  final UserModel? initialPatient;

  const CreatePrescriptionScreen({super.key, this.initialPatient});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  List<UserModel> _patients = [];
  List<Object> _allDrugs = [];

  UserModel? _selectedPatient;
  bool _isLoading = true;
  bool _isSaving = false;

  // List of medication entries being added
  final List<_MedicationEntry> _medicationEntries = [];

  // Clinical consultation-note fields
  final _complaintsController = TextEditingController();
  final _examinationController = TextEditingController();
  final List<String> _diagnoses = [];
  final _diagnosisController = TextEditingController();
  String _selectedDepartment = 'Respiratory Medicine';
  String _selectedVisitType = 'Outpatient';
  final _visitIdController = TextEditingController();
  
  final _adviceController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _departmentOptions = [
    'Respiratory Medicine',
    
  ];

  final List<String> _visitTypeOptions = [
    'Outpatient',
    'Inpatient',
    'Emergency',
    'Teleconsultation',
  ];

  final List<String> _durationOptions = [
    '3 days', '5 days', '7 days', '10 days', '14 days',
    '21 days', '30 days', '60 days', '90 days', 'Ongoing',
  ];

  @override
  void initState() {
    super.initState();
    _addMedication(); // Add an empty row immediately so doctors can start typing
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final allUsers = await _authService.getAllUsers();
    final patients = allUsers.where((u) => u.role == 'patient').toList();

    final customDrugs = await _authService.getCustomDrugs();
    final curatedMedicines = CuratedMedicineData.medicines;

    final allDrugs = [...DrugData.drugs, ...curatedMedicines, ...customDrugs];
    allDrugs.sort((a, b) {
      final nameA = _getDrugGenericNameSafe(a);
      final nameB = _getDrugGenericNameSafe(b);
      return nameA.compareTo(nameB);
    });

    if (mounted) {
      setState(() {
        _patients = patients;
        _allDrugs = allDrugs;

        if (widget.initialPatient != null) {
          try {
            _selectedPatient = _patients.firstWhere((p) => p.id == widget.initialPatient!.id);
          } catch (e) {
            // Patient not found in list, ignore
          }
        }

        _isLoading = false;
      });
    }
  }

  String _getDrugGenericNameSafe(dynamic drug) {
    if (drug is DrugModel) return drug.genericName;
    if (drug is CustomDrug) return drug.genericName;
    if (drug is CuratedMedicine) return drug.genericName;
    return '';
  }

  String _getDrugGenericName(dynamic drug) {
    return _getDrugGenericNameSafe(drug);
  }

  List<String> _getDrugBrandNames(dynamic drug) {
    if (drug is DrugModel) return drug.brandNames;
    if (drug is CustomDrug) return drug.brandNames;
    if (drug is CuratedMedicine) return [drug.brandName];
    return [];
  }

  String _getDrugId(dynamic drug) {
    if (drug is DrugModel) return drug.id;
    if (drug is CustomDrug) return drug.id;
    if (drug is CuratedMedicine) return drug.id;
    return '';
  }

  void _addDiagnosis() {
    final text = _diagnosisController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _diagnoses.add(text);
        _diagnosisController.clear();
      });
    }
  }

  void _addMedication() {
    setState(() {
      _medicationEntries.add(_MedicationEntry(
        dosageController: TextEditingController(),
        instructionsController: TextEditingController(),
        drugSearchController: TextEditingController(),
      ));
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medicationEntries[index].dosageController.dispose();
      _medicationEntries[index].instructionsController.dispose();
      _medicationEntries[index].drugSearchController.dispose();
      _medicationEntries.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_medicationEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medication'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate each medication entry
    for (int i = 0; i < _medicationEntries.length; i++) {
      final entry = _medicationEntries[i];
      if (entry.selectedDrug == null || entry.selectedBrand == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete medication ${i + 1}'), backgroundColor: Colors.red),
        );
        return;
      }
      if (entry.dosageController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter dosage for medication ${i + 1}'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final currentUser = context.read<AuthProvider>().user;
    final prescriptionId = '${currentUser?.id}_${DateTime.now().millisecondsSinceEpoch}';
    final isDoctor = currentUser?.role == 'doctor';

    final medications = _medicationEntries.map((entry) {
      return PrescriptionItem(
        drugId: _getDrugId(entry.selectedDrug),
        genericName: _getDrugGenericName(entry.selectedDrug),
        brandName: entry.selectedBrand!,
        dosage: entry.dosageController.text.trim(),
        duration: entry.selectedDuration,
        instructions: entry.instructionsController.text.trim(),
        morning: entry.morning,
        afternoon: entry.afternoon,
        evening: entry.evening,
        night: entry.night,
        beforeFood: entry.beforeFood,
      );
    }).toList();

    final prescription = Prescription(
      id: prescriptionId,
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.fullName,
      pharmacistId: isDoctor ? '' : (currentUser?.id ?? ''),
      pharmacistName: isDoctor ? '' : (currentUser?.fullName ?? 'Pharmacist'),
      doctorId: isDoctor ? currentUser?.id : null,
      doctorName: isDoctor ? currentUser?.fullName : null,
      createdAt: DateTime.now(),
      status: isDoctor ? 'pending' : 'approved',
      isActive: !isDoctor,
      medications: medications,
      complaints: _complaintsController.text.trim(),
      examination: _examinationController.text.trim(),
      diagnoses: List<String>.from(_diagnoses),
      department: _selectedDepartment,
      patientAge: _selectedPatient!.age,
      patientGender: _selectedPatient!.gender,
      patientOpNumber: _selectedPatient!.opNumber,
      visitType: _selectedVisitType,
      visitId: _visitIdController.text.trim().isNotEmpty ? _visitIdController.text.trim() : null,
      advice: _adviceController.text.trim(),
      followUpNotes: _notesController.text.trim(),
    );

    final success = await _authService.createPrescription(prescription);

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDoctor
                ? 'Prescription sent to pharmacist for approval'
                : 'Prescription created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PrescriptionSheetScreen(prescription: prescription),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create prescription'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _complaintsController.dispose();
    _examinationController.dispose();
    _diagnosisController.dispose();
    _visitIdController.dispose();
    _adviceController.dispose();
    _notesController.dispose();
    for (final entry in _medicationEntries) {
      entry.dosageController.dispose();
      entry.instructionsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Prescription'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient Selection
                          const Text(
                            'Patient *',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<UserModel>(
                            value: _selectedPatient,
                            decoration: InputDecoration(
                              hintText: 'Select a patient',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _patients.map((patient) {
                              return DropdownMenuItem(
                                value: patient,
                                child: Text(patient.fullName.isNotEmpty ? patient.fullName : patient.email),
                              );
                            }).toList(),
                            onChanged: widget.initialPatient != null 
                                ? null // Disable if patient is pre-selected
                                : (value) => setState(() => _selectedPatient = value),
                            validator: (value) => value == null ? 'Please select a patient' : null,
                          ),

                          const SizedBox(height: 24),

                          // ── Consultation Note Fields ──
                          const Text(
                            'Consultation Note',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Optional — adds clinical details to the printed prescription',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),

                          // Department
                          const Text('Department', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    isDense: true,
                                  ),
                                  items: _departmentOptions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                  isExpanded: true,
                                  onChanged: (v) => setState(() => _selectedDepartment = v ?? 'Respiratory Medicine'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedVisitType,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    isDense: true,
                                  ),
                                  items: _visitTypeOptions.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                                  isExpanded: true,
                                  onChanged: (v) => setState(() => _selectedVisitType = v ?? 'Outpatient'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Visit ID
                          const Text('Visit ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _visitIdController,
                            decoration: InputDecoration(
                              hintText: 'e.g., V-12345',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          // Presenting Complaints
                          const Text('Presenting Complaints', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _complaintsController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Breathlessness, chronic cough...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),

                          // Systemic Examination
                          const Text('Systemic Examination', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _examinationController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Diminished breath sounds...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),

                          // Diagnosis
                          const Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _diagnosisController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., J44.9 COPD',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onSubmitted: (_) => _addDiagnosis(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addDiagnosis,
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              ),
                            ],
                          ),
                          if (_diagnoses.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _diagnoses.asMap().entries.map((e) {
                                return Chip(
                                  label: Text(e.value, style: const TextStyle(fontSize: 12)),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => setState(() => _diagnoses.removeAt(e.key)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 16),
                          
                          // Advice & Follow Up
                          const Text('Advice & Follow up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              hintText: 'e.g., S/B DR KABINTHRA',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          const Text('Advice', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _adviceController,
                            decoration: InputDecoration(
                              hintText: 'e.g., REVIEW AFTER 15 DAYS',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Medications Header
                          Row(
                            children: [
                              const Text(
                                'Medications',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                '${_medicationEntries.length} added',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Medication Cards
                          ..._medicationEntries.asMap().entries.map((mapEntry) {
                            final index = mapEntry.key;
                            final entry = mapEntry.value;
                            return _buildMedicationCard(index, entry);
                          }),

                          // Add Medication Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _addMedication,
                              icon: const Icon(Icons.add),
                              label: Text(_medicationEntries.isEmpty ? 'Add Medication' : 'Add Another Medication'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Save Button at Bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePrescription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(
                              'Create Prescription (${_medicationEntries.length} ${_medicationEntries.length == 1 ? "medication" : "medications"})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMedicationCard(int index, _MedicationEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    entry.selectedDrug != null
                        ? _getDrugGenericName(entry.selectedDrug)
                        : 'Medication ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeMedication(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const Divider(height: 20),

            // Drug Search
            const Text('Drug *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: entry.drugSearchController,
              onChanged: (value) {
                setState(() {
                  entry.drugSearchQuery = value;
                  // Clear selection if user edits the text after selecting
                  if (entry.selectedDrug != null && value != _getDrugGenericName(entry.selectedDrug)) {
                    entry.selectedDrug = null;
                    entry.selectedBrand = null;
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Type to search drug name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: entry.drugSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            entry.drugSearchController.clear();
                            entry.drugSearchQuery = '';
                            entry.selectedDrug = null;
                            entry.selectedBrand = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),

            // Drug Suggestions Dropdown
            if (entry.selectedDrug == null && entry.drugSearchQuery.length >= 2) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    final query = entry.drugSearchQuery.toLowerCase();
                    final matches = _allDrugs.where((drug) {
                      final name = _getDrugGenericName(drug).toLowerCase();
                      final brands = _getDrugBrandNames(drug);
                      return name.contains(query) || brands.any((b) => b.toLowerCase().contains(query));
                    }).toList();
                    
                    if (matches.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No drugs found', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final drug = matches[i];
                        return ListTile(
                          dense: true,
                          title: Text(_getDrugGenericName(drug), style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            _getDrugBrandNames(drug).join(', '),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() {
                              entry.selectedDrug = drug;
                              entry.selectedBrand = null;
                              entry.drugSearchController.text = _getDrugGenericName(drug);
                              entry.drugSearchQuery = '';
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],

            // Brand Selection
            if (entry.selectedDrug != null) ...[
              const SizedBox(height: 12),
              const Text('Brand *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: entry.selectedBrand,
                decoration: InputDecoration(
                  hintText: 'Select brand',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  isDense: true,
                ),
                isExpanded: true,
                items: _getDrugBrandNames(entry.selectedDrug).map((brand) {
                  return DropdownMenuItem(value: brand, child: Text(brand, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (v) => setState(() => entry.selectedBrand = v),
              ),
            ],

            // Dosage
            const SizedBox(height: 12),
            const Text('Dosage *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: entry.dosageController,
              decoration: InputDecoration(
                hintText: 'e.g., 500mg, 1 tablet',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),

            // Duration
            const SizedBox(height: 12),
            const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: entry.selectedDuration,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
              ),
              items: _durationOptions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => entry.selectedDuration = v ?? '7 days'),
            ),

            // Tablets Per Time
            const SizedBox(height: 12),
            const Text('Tablets Per Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildTabletRow('Morning', entry.morning, (v) => setState(() => entry.morning = v)),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildTabletRow('Afternoon', entry.afternoon, (v) => setState(() => entry.afternoon = v)),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildTabletRow('Evening', entry.evening, (v) => setState(() => entry.evening = v)),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _buildTabletRow('Night', entry.night, (v) => setState(() => entry.night = v)),
                ],
              ),
            ),

            // Food Timing
            const SizedBox(height: 12),
            const Text('Food Timing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      'Before Food',
                      style: TextStyle(
                        color: entry.beforeFood ? Colors.green[900] : Colors.grey[800],
                        fontWeight: FontWeight.w600, fontSize: 12,
                      ),
                    ),
                    selected: entry.beforeFood,
                    onSelected: (v) => setState(() => entry.beforeFood = true),
                    selectedColor: Colors.green.shade100,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: entry.beforeFood ? Colors.green : Colors.grey.shade300),
                    showCheckmark: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      'After Food',
                      style: TextStyle(
                        color: !entry.beforeFood ? Colors.orange[900] : Colors.grey[800],
                        fontWeight: FontWeight.w600, fontSize: 12,
                      ),
                    ),
                    selected: !entry.beforeFood,
                    onSelected: (v) => setState(() => entry.beforeFood = false),
                    selectedColor: Colors.orange.shade100,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: !entry.beforeFood ? Colors.orange : Colors.grey.shade300),
                    showCheckmark: false,
                  ),
                ),
              ],
            ),

            // Instructions
            const SizedBox(height: 12),
            const Text('Instructions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: entry.instructionsController,
              decoration: InputDecoration(
                hintText: 'e.g., Take with water',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletRow(String label, int count, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: count > 0 ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: count > 0 ? () => onChanged(count - 1) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count > 0 ? Colors.red.shade50 : Colors.grey.shade100,
                border: Border.all(color: count > 0 ? Colors.red.shade200 : Colors.grey.shade300),
              ),
              child: Icon(Icons.remove, size: 14, color: count > 0 ? Colors.red : Colors.grey),
            ),
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: count > 0 ? AppColors.primary : Colors.grey)),
            ),
          ),
          InkWell(
            onTap: count < 3 ? () => onChanged(count + 1) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count < 3 ? Colors.green.shade50 : Colors.grey.shade100,
                border: Border.all(color: count < 3 ? Colors.green.shade200 : Colors.grey.shade300),
              ),
              child: Icon(Icons.add, size: 14, color: count < 3 ? Colors.green : Colors.grey),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 45,
            child: Text(
              count == 0 ? '' : count == 1 ? 'tablet' : 'tablets',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal state holder for one medication entry in the form
class _MedicationEntry {
  dynamic selectedDrug;
  String? selectedBrand;
  String selectedDuration = '7 days';
  final TextEditingController dosageController;
  final TextEditingController instructionsController;
  late final TextEditingController drugSearchController;
  String drugSearchQuery = '';
  int morning = 0;
  int afternoon = 0;
  int evening = 0;
  int night = 0;
  bool beforeFood = true;

  _MedicationEntry({
    required this.dosageController,
    required this.instructionsController,
    TextEditingController? drugSearchController,
  }) : drugSearchController = drugSearchController ?? TextEditingController();
}
