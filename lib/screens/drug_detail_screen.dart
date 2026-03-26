import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/drug_data.dart';
import '../models/drug_model.dart';
import '../services/auth_service.dart';
import 'medication_reminder_screen.dart';

/// Screen showing detailed information about a specific drug
class DrugDetailScreen extends StatefulWidget {
  const DrugDetailScreen({super.key, required this.drug});

  final DrugModel drug;

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  final _authService = AuthService();
  bool _isInMyMedications = false;
  bool _isLoading = true;
  String? _selectedBrand;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _checkIfInMedications();
  }

  Future<void> _checkIfInMedications() async {
    final isInMedications = await _authService.isUserTakingMedication(widget.drug.id);
    String? brand;
    String? status;
    if (isInMedications) {
      brand = await _authService.getUserMedicationBrand(widget.drug.id);
      status = await _authService.getUserMedicationStatus(widget.drug.id);
    }
    if (mounted) {
      setState(() {
        _isInMyMedications = isInMedications;
        _selectedBrand = brand;
        _verificationStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _showBrandSelectionDialog() async {
    final brands = widget.drug.brandNames;
    
    final selectedBrand = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Brand'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              'Which brand of ${widget.drug.genericName} are you using?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...brands.map((brand) => ListTile(
              title: Text(brand),
              leading: const Icon(Icons.medication),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () => Navigator.pop(context, brand),
            )),
          ],
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedBrand != null) {
      await _addMedicationWithBrand(selectedBrand);
    }
  }

  Future<void> _addMedicationWithBrand(String brandName) async {
    // Start building a list of drugs to submit with one prescription
    final drugsBatch = <Map<String, String>>[
      {'drugId': widget.drug.id, 'brandName': brandName, 'genericName': widget.drug.genericName},
    ];

    // Show the multi-drug builder bottom sheet
    final confirmedDrugs = await showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MultiDrugSheet(initialDrugs: drugsBatch),
    );

    if (confirmedDrugs == null || confirmedDrugs.isEmpty) return;

    // Now upload a single prescription for all drugs
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Upload prescription for ${confirmedDrugs.length} medication${confirmedDrugs.length > 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading prescription...')),
      );
    }

    String? prescriptionUrl;
    try {
      prescriptionUrl = await _authService.uploadPrescription(pickedFile.path);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (prescriptionUrl == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Use batch add for all drugs with a shared prescription
    final drugsForService = confirmedDrugs
        .map((d) => {'drugId': d['drugId']!, 'brandName': d['brandName']!})
        .toList();

    final success = await _authService.addMedications(
      drugsForService,
      prescriptionUrl: prescriptionUrl,
    );

    if (success && mounted) {
      final drugNames = confirmedDrugs.map((d) => d['genericName'] ?? d['drugId']).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Prescription submitted for $drugNames. Will be added after pharmacist approval.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() {
        _isInMyMedications = true;
        _selectedBrand = brandName;
        _verificationStatus = 'pending';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add medications. Please try again.')),
      );
    }
  }

  Future<void> _removeMedication() async {
    setState(() => _isLoading = true);
    
    final success = await _authService.removeMedication(widget.drug.id, _selectedBrand ?? '');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.drug.genericName} removed from your medications')),
      );
      setState(() {
        _isInMyMedications = false;
        _selectedBrand = null;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove medication. Please try again.')),
      );
    }
  }

  Future<void> _toggleMedication() async {
    if (_isInMyMedications) {
      await _removeMedication();
    } else {
      await _showBrandSelectionDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drug = widget.drug;

    return Scaffold(
      appBar: AppBar(
        title: Text(drug.genericName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Verification Banner
            if (_isInMyMedications && _verificationStatus == 'pending')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification Pending',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900),
                          ),
                          Text(
                            'This medication is awaiting approval from your pharmacist.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              drug.genericName[0],
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                drug.genericName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Brands: ${drug.brandNames.join(', ')}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.category,
                          label: DrugModel.getCategoryDisplayName(drug.category),
                          color: theme.colorScheme.primary,
                        ),
                        _InfoChip(
                          icon: Icons.medication,
                          label: drug.doseForm,
                          color: const Color(0xFF00C853),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: drug.diseases.map((disease) {
                        return _InfoChip(
                          icon: Icons.medical_services_outlined,
                          label: DrugModel.getDiseaseDisplayName(disease),
                          color: const Color(0xFF7C4DFF),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Section
            _SectionCard(
              title: 'Overview',
              icon: Icons.info_outline,
              iconColor: const Color(0xFF2962FF),
              child: Text(
                drug.description,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),

            // Dosage Section
            _SectionCard(
              title: 'Dosage',
              icon: Icons.schedule,
              iconColor: const Color(0xFF00C853),
              child: Text(
                drug.dosage,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),

            // Side Effects Section
            _SectionCard(
              title: 'Side Effects',
              icon: Icons.warning_amber,
              iconColor: const Color(0xFFFF9100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: drug.sideEffects.map((effect) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(effect)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Precautions Section
            _SectionCard(
              title: 'Precautions',
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFFFF5252),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: drug.precautions.map((precaution) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFFFF5252)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(precaution)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Add/Remove Medication Button
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _toggleMedication,
                      icon: Icon(
                        _isInMyMedications ? Icons.remove_circle_outline : Icons.add_circle_outline,
                      ),
                      label: Text(
                        _isInMyMedications ? 'Remove from My Medications' : 'Add to My Medications',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isInMyMedications 
                            ? Colors.red.shade50 
                            : theme.colorScheme.primaryContainer,
                        foregroundColor: _isInMyMedications 
                            ? Colors.red 
                            : theme.colorScheme.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
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
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for building a batch of drugs to submit with one prescription
class _MultiDrugSheet extends StatefulWidget {
  const _MultiDrugSheet({required this.initialDrugs});

  final List<Map<String, String>> initialDrugs;

  @override
  State<_MultiDrugSheet> createState() => _MultiDrugSheetState();
}

class _MultiDrugSheetState extends State<_MultiDrugSheet> {
  late List<Map<String, String>> _drugs;
  final _searchController = TextEditingController();
  List<DrugModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _drugs = List.from(widget.initialDrugs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchDrugs(String query) {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = DrugData.searchDrugs(query)
          .where((drug) => !_drugs.any((d) => d['drugId'] == drug.id))
          .take(10)
          .toList();
    });
  }

  Future<void> _addDrug(DrugModel drug) async {
    // Show brand selection for this drug
    final selectedBrand = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select brand for ${drug.genericName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drug.brandNames.map((brand) => ListTile(
            title: Text(brand),
            leading: const Icon(Icons.medication),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () => Navigator.pop(context, brand),
          )).toList(),
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedBrand != null) {
      setState(() {
        _drugs.add({
          'drugId': drug.id,
          'brandName': selectedBrand,
          'genericName': drug.genericName,
        });
        _searchController.clear();
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _removeDrug(int index) {
    setState(() {
      _drugs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.medication, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Medications to Submit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_drugs.length} drug${_drugs.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(),

          // Drug list
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Current drugs in batch
                ..._drugs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final drug = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.green.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      title: Text(
                        drug['genericName'] ?? drug['drugId'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Brand: ${drug['brandName']}'),
                      trailing: _drugs.length > 1
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeDrug(idx),
                            )
                          : null, // Can't remove the last drug
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Search to add more
                Text(
                  'Add more medications from the same prescription:',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: _searchDrugs,
                  decoration: InputDecoration(
                    hintText: 'Search by drug name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchDrugs('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),

                // Search results
                if (_isSearching && _searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No matching drugs found',
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ..._searchResults.map((drug) => Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.add, color: Colors.blue),
                    ),
                    title: Text(drug.genericName),
                    subtitle: Text(
                      drug.brandNames.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _addDrug(drug),
                  ),
                )),

                const SizedBox(height: 80), // Space for bottom button
              ],
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _drugs),
                    icon: const Icon(Icons.upload_file),
                    label: Text('Upload Prescription (${_drugs.length})'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
