import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/drug_data.dart';
import '../models/custom_drug.dart';
import '../models/drug_model.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

/// Screen for creating a new prescription
class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  List<UserModel> _patients = [];
  List<dynamic> _allDrugs = []; // Can be DrugModel or CustomDrug
  
  UserModel? _selectedPatient;
  dynamic _selectedDrug;
  String? _selectedBrand;
  String _selectedDuration = '7 days';
  
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _durationOptions = [
    '3 days',
    '5 days',
    '7 days',
    '10 days',
    '14 days',
    '21 days',
    '30 days',
    '60 days',
    '90 days',
    'Ongoing',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load patients
    final allUsers = await _authService.getAllUsers();
    final patients = allUsers.where((u) => u.role == 'patient').toList();
    
    // Load drugs (static + custom)
    final customDrugs = await _authService.getCustomDrugs();
    final allDrugs = [...DrugData.drugs, ...customDrugs];
    allDrugs.sort((a, b) {
      final nameA = a is DrugModel ? a.genericName : (a as CustomDrug).genericName;
      final nameB = b is DrugModel ? b.genericName : (b as CustomDrug).genericName;
      return nameA.compareTo(nameB);
    });
    
    if (mounted) {
      setState(() {
        _patients = patients;
        _allDrugs = allDrugs;
        _isLoading = false;
      });
    }
  }

  String _getDrugGenericName(dynamic drug) {
    if (drug is DrugModel) return drug.genericName;
    if (drug is CustomDrug) return drug.genericName;
    return '';
  }

  List<String> _getDrugBrandNames(dynamic drug) {
    if (drug is DrugModel) return drug.brandNames;
    if (drug is CustomDrug) return drug.brandNames;
    return [];
  }

  String _getDrugId(dynamic drug) {
    if (drug is DrugModel) return drug.id;
    if (drug is CustomDrug) return drug.id;
    return '';
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null || _selectedDrug == null || _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final pharmacist = context.read<AuthProvider>().user;
    final prescriptionId = '${pharmacist?.id}_${DateTime.now().millisecondsSinceEpoch}';

    final prescription = Prescription(
      id: prescriptionId,
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.fullName,
      pharmacistId: pharmacist?.id ?? '',
      pharmacistName: pharmacist?.fullName ?? 'Pharmacist',
      drugId: _getDrugId(_selectedDrug),
      genericName: _getDrugGenericName(_selectedDrug),
      brandName: _selectedBrand!,
      dosage: _dosageController.text.trim(),
      instructions: _instructionsController.text.trim(),
      duration: _selectedDuration,
      createdAt: DateTime.now(),
      isActive: true,
    );

    final success = await _authService.createPrescription(prescription);

    if (mounted) {
      setState(() => _isSaving = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create prescription'), backgroundColor: Colors.red),
        );
      }
    }
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
          : SingleChildScrollView(
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
                      onChanged: (value) => setState(() => _selectedPatient = value),
                      validator: (value) => value == null ? 'Please select a patient' : null,
                    ),
                    const SizedBox(height: 20),

                    // Drug Selection
                    const Text(
                      'Medication *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<dynamic>(
                      value: _selectedDrug,
                      decoration: InputDecoration(
                        hintText: 'Select a medication',
                        prefixIcon: const Icon(Icons.medication),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      isExpanded: true,
                      items: _allDrugs.map((drug) {
                        return DropdownMenuItem(
                          value: drug,
                          child: Text(
                            _getDrugGenericName(drug),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDrug = value;
                          _selectedBrand = null;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a medication' : null,
                    ),
                    const SizedBox(height: 20),

                    // Brand Selection
                    if (_selectedDrug != null) ...[
                      const Text(
                        'Brand *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        decoration: InputDecoration(
                          hintText: 'Select a brand',
                          prefixIcon: const Icon(Icons.local_pharmacy),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _getDrugBrandNames(_selectedDrug).map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedBrand = value),
                        validator: (value) => value == null ? 'Please select a brand' : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Dosage
                    const Text(
                      'Dosage *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 1 tablet twice daily after meals',
                        prefixIcon: const Icon(Icons.schedule),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter dosage' : null,
                    ),
                    const SizedBox(height: 20),

                    // Duration
                    const Text(
                      'Duration *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDuration,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.timelapse),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _durationOptions.map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text(duration),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedDuration = value ?? '7 days'),
                    ),
                    const SizedBox(height: 20),

                    // Instructions (Optional)
                    const Text(
                      'Additional Instructions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Take with food. Avoid alcohol.',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePrescription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Prescription',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
