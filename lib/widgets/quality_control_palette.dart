import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/annotation.dart';
import '../providers/app_state.dart';

class QualityControlPalette extends StatelessWidget {
  const QualityControlPalette({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!appState.isQualityControlMode) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assessment, size: 18, color: Colors.black87),
                  const SizedBox(width: 8),
                  const Text(
                    'Quality Control Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      appState.toggleQualityControlMode();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap a bar to mark its quality level:',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in [
                    QualityLevel.needsWork,
                    QualityLevel.improving,
                    QualityLevel.almostThere,
                    QualityLevel.good,
                    QualityLevel.mastered,
                  ])
                    _QualityLevelChip(
                      level: level,
                      isSelected: appState.currentQualityLevel == level,
                      onTap: () {
                        appState.setQualityLevel(level);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QualityLevelChip extends StatelessWidget {
  final QualityLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityLevelChip({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? level.color : level.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: level.color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: level.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              level.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
