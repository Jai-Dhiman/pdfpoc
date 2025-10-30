import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/annotation.dart';
import '../providers/app_state.dart';

class LayerManagementPanel extends StatelessWidget {
  const LayerManagementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF3D4D7B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.layers, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Layers & Collaboration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Export Annotations',
                      onPressed: () => _exportAnnotations(context, appState),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.file_download, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Import Annotations',
                      onPressed: () => _importAnnotations(context, appState),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Annotation Layers',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D4D7B),
                          ),
                        ),
                        Text(
                          'v${appState.annotationVersion}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final layer in AnnotationLayer.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LayerCard(
                          layer: layer,
                          appState: appState,
                        ),
                      ),
                    if (appState.collaborators.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Collaborators',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D4D7B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final collab in appState.collaborators)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _CollaboratorCard(
                            collaborator: collab,
                            appState: appState,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportAnnotations(BuildContext context, AppState appState) {
    final jsonData = appState.exportAnnotations();
    Clipboard.setData(ClipboardData(text: jsonData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Annotations exported to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _importAnnotations(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Annotations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste annotation data:'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON here',
              ),
              maxLines: 5,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                final success = await appState.importAnnotations(data!.text!);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Annotations imported successfully'
                          : 'Failed to import annotations'),
                    ),
                  );
                }
              }
            },
            child: const Text('Import from Clipboard'),
          ),
        ],
      ),
    );
  }
}

class _LayerCard extends StatelessWidget {
  final AnnotationLayer layer;
  final AppState appState;

  const _LayerCard({
    required this.layer,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = appState.isLayerVisible(layer);
    final annotations = appState.getAnnotations(layer);
    final textAnnotations = appState.getTextAnnotations(layer);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: layer.defaultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: layer.defaultColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: layer.defaultColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${annotations.length} strokes, ${textAnnotations.length} notes',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              appState.toggleLayerVisibility(layer);
            },
          ),
        ],
      ),
    );
  }
}

class _CollaboratorCard extends StatelessWidget {
  final CollaboratorInfo collaborator;
  final AppState appState;

  const _CollaboratorCard({
    required this.collaborator,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: collaborator.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: collaborator.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: collaborator.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              collaborator.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              appState.removeCollaborator(collaborator.id);
            },
          ),
        ],
      ),
    );
  }
}
