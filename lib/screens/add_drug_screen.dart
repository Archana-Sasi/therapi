import 'package:flutter/material.dart';

import '../models/custom_drug.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

/// Screen for pharmacists/admins to add a new drug to the inventory
class AddDrugScreen extends StatefulWidget {
  const AddDrugScreen({super.key});

  @override
  State<AddDrugScreen> createState() => _AddDrugScreenState();
}

class _AddDrugScreenState extends State<AddDrugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _genericNameController = TextEditingController();
  final _brandNamesController = TextEditingController();
  final _doseFormController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _precautionsController = TextEditingController();
  
  String _selectedCategory = 'bronchodilator';
  final List<String> _selectedDiseases = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'bronchodilator', 'name': 'Bronchodilator', 'icon': Icons.air},
    {'id': 'corticosteroid', 'name': 'Corticosteroid', 'icon': Icons.healing},
    {'id': 'anticholinergic', 'name': 'Anticholinergic', 'icon': Icons.science},
    {'id': 'leukotriene_modifier', 'name': 'Leukotriene Modifier', 'icon': Icons.health_and_safety},
    {'id': 'antihistamine', 'name': 'Antihistamine', 'icon': Icons.pest_control_rodent},
    {'id': 'mucolytic', 'name': 'Mucolytic', 'icon': Icons.water_drop},
    {'id': 'combination', 'name': 'Combination Therapy', 'icon': Icons.merge_type},
    {'id': 'antibiotic', 'name': 'Antibiotic', 'icon': Icons.coronavirus},
    {'id': 'antifibrotic', 'name': 'Antifibrotic', 'icon': Icons.blur_on},
    {'id': 'other', 'name': 'Other', 'icon': Icons.medical_services},
  ];

  final List<Map<String, String>> _diseases = [
    {'id': 'asthma', 'name': 'Asthma'},
    {'id': 'copd', 'name': 'COPD'},
    {'id': 'bronchitis', 'name': 'Bronchitis'},
    {'id': 'allergic_rhinitis', 'name': 'Allergic Rhinitis'},
    {'id': 'ild', 'name': 'Interstitial Lung Disease'},
    {'id': 'pneumonia', 'name': 'Pneumonia'},
  ];

  @override
  void dispose() {
    _genericNameController.dispose();
    _brandNamesController.dispose();
    _doseFormController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _sideEffectsController.dispose();
    _precautionsController.dispose();
    super.dispose();
  }

  Future<void> _saveDrug() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDiseases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one disease'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final brandNames = _brandNamesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final sideEffects = _sideEffectsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final precautions = _precautionsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final drug = CustomDrug(
        id: '',
        genericName: _genericNameController.text.trim(),
        brandNames: brandNames,
        category: _selectedCategory,
        doseForm: _doseFormController.text.trim(),
        description: _descriptionController.text.trim(),
        dosage: _dosageController.text.trim().isNotEmpty 
            ? _dosageController.text.trim() 
            : null,
        sideEffects: sideEffects,
        precautions: precautions,
        diseases: _selectedDiseases,
        addedBy: _authService.currentUser?.uid,
        addedAt: DateTime.now(),
      );

      final success = await _authService.addCustomDrug(drug);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drug added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add drug: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Drug'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card with Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Medication',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This drug will be visible to all patients',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Basic Information
              _buildSectionHeader('Basic Information', Icons.medication),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Generic Name
                      TextFormField(
                        controller: _genericNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Generic Name',
                          hintText: 'e.g., Salbutamol',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the generic name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Brand Names
                      TextFormField(
                        controller: _brandNamesController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Brand Names',
                          hintText: 'e.g., Ventolin, Asthalin',
                          helperText: 'Separate multiple brands with commas',
                          prefixIcon: Icon(Icons.branding_watermark),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter at least one brand name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dose Form
                      TextFormField(
                        controller: _doseFormController,
                        decoration: const InputDecoration(
                          labelText: 'Dose Form',
                          hintText: 'e.g., Tablet / Inhaler / Syrup',
                          prefixIcon: Icon(Icons.medical_services),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the dose form';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Category
              _buildSectionHeader('Category', Icons.category),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      return ChoiceChip(
                        label: Text(cat['name']),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat['id']);
                          }
                        },
                        avatar: Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Applicable Diseases
              _buildSectionHeader('Applicable Diseases', Icons.local_hospital),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select the conditions this drug treats:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _diseases.map((disease) {
                          final isSelected = _selectedDiseases.contains(disease['id']);
                          return FilterChip(
                            label: Text(disease['name']!),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDiseases.add(disease['id']!);
                                } else {
                                  _selectedDiseases.remove(disease['id']);
                                }
                              });
                            },
                            selectedColor: AppColors.secondary.withAlpha(50),
                            checkmarkColor: AppColors.secondary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.secondary : Colors.grey[300]!,
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedDiseases.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '* At least one disease must be selected',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Description
              _buildSectionHeader('Description & Dosage', Icons.description),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the drug and its uses',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _dosageController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dosage (Optional)',
                          hintText: 'e.g., 1-2 puffs every 4-6 hours as needed',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section: Side Effects & Precautions (Collapsible)
              ExpansionTile(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Side Effects & Precautions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                subtitle: const Text('Optional additional information', style: TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _sideEffectsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Side Effects',
                            hintText: 'e.g., Headache, Nausea, Dizziness',
                            helperText: 'Separate with commas',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _precautionsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Precautions',
                            hintText: 'e.g., Use with caution in heart disease',
                            helperText: 'Separate with commas',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDrug,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Add Drug to Inventory',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
