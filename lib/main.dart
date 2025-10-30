import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'models/annotation.dart';
import 'widgets/pdf_viewer_widget.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/quality_control_palette.dart';
import 'widgets/progress_slider_widget.dart';
import 'widgets/layer_management_panel.dart';

void main() {
  runApp(const PDFPoCApp());
}

class PDFPoCApp extends StatelessWidget {
  const PDFPoCApp({super.key});

  static const Color primaryNavy = Color(0xFF3D4D7B);
  static const Color backgroundPeriwinkle = Color(0xFFE8ECF5);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'PDF PoC - Music Annotation',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryNavy,
            primary: primaryNavy,
            surface: Colors.white,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: backgroundPeriwinkle,
          appBarTheme: AppBarTheme(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF PoC - Music Annotation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              if (appState.currentBarNumber != null) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(
                      'Bar ${appState.currentBarNumber}',
                      style: const TextStyle(
                        color: Color(0xFF3D4D7B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFB8C5E8),
                      width: 2,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopToolbar(),
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                return Stack(
                  children: [
                    _buildPDFSection(),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      right: appState.isVideoDrawerOpen ? 0 : -400,
                      top: 0,
                      bottom: 0,
                      width: 400,
                      child: _buildVideoDrawer(appState),
                    ),
                    Positioned(
                      right: appState.isVideoDrawerOpen ? 400 : 0,
                      top: MediaQuery.of(context).size.height * 0.4,
                      child: _buildDrawerToggle(appState),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildAnnotationToolsBox(appState),
                    ),
                    Positioned(
                      top: 16,
                      left: 232,
                      child: const QualityControlPalette(),
                    ),
                    Positioned(
                      bottom: 100,
                      right: appState.isVideoDrawerOpen ? 416 : 16,
                      child: const LayerManagementPanel(),
                    ),
                  ],
                );
              },
            ),
          ),
          const ProgressSliderWidget(),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildSelectorButton(appState),
              const SizedBox(width: 12),
              _buildQCButton(appState),
              const SizedBox(width: 12),
              _buildLayerButton(
                context,
                'Teacher',
                AnnotationLayer.teacher,
                appState,
                Colors.purple.shade400,
              ),
              const SizedBox(width: 8),
              _buildEyeButton(
                appState,
                AnnotationLayer.teacher,
                'T',
                Colors.purple.shade400,
              ),
              const SizedBox(width: 12),
              _buildLayerButton(
                context,
                'Student',
                AnnotationLayer.student,
                appState,
                PDFPoCApp.primaryNavy,
              ),
              const SizedBox(width: 8),
              _buildEyeButton(
                appState,
                AnnotationLayer.student,
                'S',
                PDFPoCApp.primaryNavy,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectorButton(AppState appState) {
    final isSelected = appState.isSelectionMode;
    return GestureDetector(
      onTap: () {
        appState.toggleSelectionMode();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? PDFPoCApp.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PDFPoCApp.primaryNavy : const Color(0xFFB8C5E8),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.touch_app,
          color: isSelected ? Colors.white : PDFPoCApp.primaryNavy,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildQCButton(AppState appState) {
    final isActive = appState.isQualityControlMode;
    return GestureDetector(
      onTap: () {
        appState.toggleQualityControlMode();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green.shade600 : const Color(0xFFB8C5E8),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.assessment,
              color: isActive ? Colors.white : Colors.green.shade600,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'QC Mode',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.green.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
          foregroundColor: isSelected ? Colors.white : PDFPoCApp.primaryNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? color : const Color(0xFFB8C5E8),
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

  Widget _buildEyeButton(
    AppState appState,
    AnnotationLayer layer,
    String label,
    Color color,
  ) {
    final isVisible = appState.isLayerVisible(layer);
    return GestureDetector(
      onTap: () {
        appState.toggleLayerVisibility(layer);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB8C5E8),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPDFSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const PDFViewerWidget(),
    );
  }

  Widget _buildAnnotationToolsBox(AppState appState) {
    return Container(
      width: 200,
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
            child: const Row(
              children: [
                Icon(Icons.edit, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Tools',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                const Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D4D7B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactPenColorButton(appState, Colors.red),
                    _buildCompactPenColorButton(appState, PDFPoCApp.primaryNavy),
                    _buildCompactPenColorButton(appState, Colors.green.shade600),
                    _buildCompactPenColorButton(appState, Colors.orange.shade700),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Size',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D4D7B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.remove, size: 14, color: Color(0xFF3D4D7B)),
                    Expanded(
                      child: Slider(
                        value: appState.strokeWidth,
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        label: appState.strokeWidth.round().toString(),
                        activeColor: PDFPoCApp.primaryNavy,
                        onChanged: (value) {
                          appState.setStrokeWidth(value);
                        },
                      ),
                    ),
                    const Icon(Icons.add, size: 14, color: Color(0xFF3D4D7B)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: appState.canUndo(appState.currentLayer)
                            ? () => appState.undo(appState.currentLayer)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PDFPoCApp.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                        ),
                        child: const Icon(Icons.undo, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: appState.canRedo(appState.currentLayer)
                            ? () => appState.redo(appState.currentLayer)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PDFPoCApp.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                        ),
                        child: const Icon(Icons.redo, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showClearConfirmation(context, appState);
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDrawer(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PDFPoCApp.primaryNavy,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Video Player',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    appState.toggleVideoDrawer();
                  },
                ),
              ],
            ),
          ),
          const Expanded(
            child: VideoPlayerWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPenColorButton(AppState appState, Color color) {
    final isSelected = appState.currentColor == color;
    return GestureDetector(
      onTap: () {
        appState.setCurrentColor(color);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFB8C5E8),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
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

  Widget _buildDrawerToggle(AppState appState) {
    return GestureDetector(
      onTap: () {
        appState.toggleVideoDrawer();
      },
      child: Container(
        width: 40,
        height: 80,
        decoration: BoxDecoration(
          color: PDFPoCApp.primaryNavy,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            appState.isVideoDrawerOpen
                ? Icons.chevron_right
                : Icons.chevron_left,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
