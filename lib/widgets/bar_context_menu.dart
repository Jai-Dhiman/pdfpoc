import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Context menu displayed when user long-presses or right-clicks on a bar
class BarContextMenu extends StatelessWidget {
  final int barNumber;
  final Offset position;
  final VoidCallback onDismiss;

  const BarContextMenu({
    super.key,
    required this.barNumber,
    required this.position,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible overlay to detect clicks outside menu
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // The actual menu
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menu header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bar $barNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Menu items
                  _MenuItem(
                    icon: Icons.play_circle_outline,
                    label: 'Listen to this section',
                    onTap: () {
                      onDismiss();
                      _handleListenToSection(context);
                    },
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.note_add_outlined,
                    label: 'Add text note',
                    onTap: () {
                      onDismiss();
                      _handleAddTextNote(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleListenToSection(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    // Set the current bar
    appState.setCurrentBar(barNumber);

    // Open video drawer if not already open
    if (!appState.isVideoDrawerOpen) {
      appState.toggleVideoDrawer();
    }

    // Seek to this bar and play
    appState.seekToBarAndPlay(barNumber);
  }

  void _handleAddTextNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _TextNoteDialog(barNumber: barNumber);
      },
    );
  }
}

/// Menu item widget
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding text notes
class _TextNoteDialog extends StatefulWidget {
  final int barNumber;

  const _TextNoteDialog({required this.barNumber});

  @override
  State<_TextNoteDialog> createState() => _TextNoteDialogState();
}

class _TextNoteDialogState extends State<_TextNoteDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final appState = Provider.of<AppState>(context, listen: false);
    appState.addTextAnnotation(widget.barNumber, text);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note added to Bar ${widget.barNumber}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.note_add,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text('Add Note to Bar ${widget.barNumber}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your note or annotation:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'e.g., Watch finger positioning here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (_) => _handleSubmit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Note'),
        ),
      ],
    );
  }
}
