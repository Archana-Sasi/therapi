import 'package:flutter/material.dart';

import '../models/drug_model.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfInMedications();
  }

  Future<void> _checkIfInMedications() async {
    final isInMedications = await _authService.isUserTakingMedication(widget.drug.id);
    String? brand;
    if (isInMedications) {
      brand = await _authService.getUserMedicationBrand(widget.drug.id);
    }
    if (mounted) {
      setState(() {
        _isInMyMedications = isInMedications;
        _selectedBrand = brand;
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
        content: Column(
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
    setState(() => _isLoading = true);
    
    final success = await _authService.addMedication(widget.drug.id, brandName);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.drug.genericName} ($brandName) added to your medications')),
      );
      setState(() {
        _isInMyMedications = true;
        _selectedBrand = brandName;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add medication. Please try again.')),
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
