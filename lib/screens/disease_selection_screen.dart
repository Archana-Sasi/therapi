import 'package:flutter/material.dart';

import '../data/drug_data.dart';
import 'drug_list_screen.dart';

/// Screen for selecting a respiratory disease to view its medications
class DiseaseSelectionScreen extends StatelessWidget {
  const DiseaseSelectionScreen({super.key});

  static const route = '/drug-directory';

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'air':
        return Icons.air;
      case 'smoke_free':
        return Icons.smoke_free;
      case 'healing':
        return Icons.healing;
      case 'grass':
        return Icons.grass;
      case 'blur_on':
        return Icons.blur_on;
      case 'coronavirus':
        return Icons.coronavirus;
      default:
        return Icons.medical_services;
    }
  }

  Color _getDiseaseColor(String diseaseId) {
    switch (diseaseId) {
      case 'asthma':
        return const Color(0xFF2962FF); // Blue
      case 'copd':
        return const Color(0xFFFF6D00); // Orange
      case 'bronchitis':
        return const Color(0xFF00C853); // Green
      case 'allergic_rhinitis':
        return const Color(0xFF7C4DFF); // Purple
      case 'ild':
        return const Color(0xFFFF5252); // Red
      case 'pneumonia':
        return const Color(0xFF00BFA6); // Teal
      default:
        return const Color(0xFF2962FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Directory'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Select a Condition',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a respiratory disease to view recommended medications',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Disease Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: DrugData.diseases.length,
                itemBuilder: (context, index) {
                  final disease = DrugData.diseases[index];
                  final color = _getDiseaseColor(disease['id'] as String);
                  final drugCount = DrugData.getDrugsByDisease(disease['id'] as String).length;

                  return Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DrugListScreen(
                              diseaseId: disease['id'] as String,
                              diseaseName: disease['name'] as String,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getIcon(disease['icon'] as String),
                                color: color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              disease['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$drugCount medications',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
