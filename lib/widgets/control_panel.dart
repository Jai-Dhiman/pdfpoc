import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/annotation.dart';
import '../providers/app_state.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  static const Color primaryNavy = Color(0xFF3D4D7B);
  static const Color lightPeriwinkle = Color(0xFFB8C5E8);
  static const Color backgroundPeriwinkle = Color(0xFFE8ECF5);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundPeriwinkle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _buildLayerButton(
                    context,
                    'Teacher',
                    AnnotationLayer.teacher,
                    appState,
                    Colors.purple.shade400,
                  ),
                  const SizedBox(width: 8),
                  _buildLayerButton(
                    context,
                    'Student',
                    AnnotationLayer.student,
                    appState,
                    primaryNavy,
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _showClearConfirmation(context, appState);
                },
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                tooltip: 'Clear Layer',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayerButton(
    BuildContext context,
    String label,
    AnnotationLayer layer,
    AppState appState,
    Color color,
  ) {
    final isSelected = appState.currentLayer == layer;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: () {
          appState.setCurrentLayer(layer);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.white,
          foregroundColor: isSelected ? Colors.white : primaryNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? color : lightPeriwinkle,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }


  void _showClearConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Layer'),
          content: Text(
            'Are you sure you want to clear all annotations from the ${appState.currentLayer.name} layer?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appState.clearLayer(appState.currentLayer);
                Navigator.of(context).pop();
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
