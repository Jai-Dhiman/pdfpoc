import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/bar.dart';
import '../models/bar_timestamp.dart';
import '../models/annotation.dart';
import '../models/text_annotation.dart';
import '../services/data_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();

  List<Bar> _bars = [];
  VideoData? _videoData;
  int? _currentBarNumber;
  AnnotationLayer _currentLayer = AnnotationLayer.student;
  Color _currentColor = Colors.red;
  double _strokeWidth = 3.0;
  bool _isDrawing = false;
  bool _isSelectionMode = false;
  bool _isVideoDrawerOpen = false;
  String? _currentVideoId;
  bool _isQualityControlMode = false;
  QualityLevel _currentQualityLevel = QualityLevel.none;
  List<CollaboratorInfo> _collaborators = [];
  int _annotationVersion = 0;

  final Map<AnnotationLayer, List<AnnotationStroke>> _annotations = {
    AnnotationLayer.teacher: [],
    AnnotationLayer.student: [],
  };

  final Map<AnnotationLayer, bool> _layerVisibility = {
    AnnotationLayer.teacher: true,
    AnnotationLayer.student: true,
  };

  final Map<AnnotationLayer, List<List<AnnotationStroke>>> _undoHistory = {
    AnnotationLayer.teacher: [],
    AnnotationLayer.student: [],
  };

  final Map<AnnotationLayer, List<List<AnnotationStroke>>> _redoHistory = {
    AnnotationLayer.teacher: [],
    AnnotationLayer.student: [],
  };

  final Map<AnnotationLayer, List<TextAnnotation>> _textAnnotations = {
    AnnotationLayer.teacher: [],
    AnnotationLayer.student: [],
  };

  Function(int)? _seekToBarAndPlayCallback;

  List<Bar> get bars => _bars;
  VideoData? get videoData => _videoData;
  int? get currentBarNumber => _currentBarNumber;
  AnnotationLayer get currentLayer => _currentLayer;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  bool get isDrawing => _isDrawing;
  bool get isSelectionMode => _isSelectionMode;
  bool get isVideoDrawerOpen => _isVideoDrawerOpen;
  String? get currentVideoId => _currentVideoId;
  bool get isQualityControlMode => _isQualityControlMode;
  QualityLevel get currentQualityLevel => _currentQualityLevel;
  List<CollaboratorInfo> get collaborators => _collaborators;
  int get annotationVersion => _annotationVersion;

  List<AnnotationStroke> getAnnotations(AnnotationLayer layer) =>
      _annotations[layer] ?? [];

  List<TextAnnotation> getTextAnnotations(AnnotationLayer layer) =>
      _textAnnotations[layer] ?? [];

  List<TextAnnotation> getAllTextAnnotations() {
    final allAnnotations = <TextAnnotation>[];
    for (var layer in AnnotationLayer.values) {
      if (isLayerVisible(layer)) {
        allAnnotations.addAll(_textAnnotations[layer] ?? []);
      }
    }
    return allAnnotations;
  }

  List<TextAnnotation> getTextAnnotationsForBar(int barNumber) {
    return getAllTextAnnotations()
        .where((annotation) => annotation.barNumber == barNumber)
        .toList();
  }

  bool isLayerVisible(AnnotationLayer layer) =>
      _layerVisibility[layer] ?? true;

  bool canUndo(AnnotationLayer layer) =>
      (_undoHistory[layer]?.isNotEmpty ?? false);

  bool canRedo(AnnotationLayer layer) =>
      (_redoHistory[layer]?.isNotEmpty ?? false);

  Future<void> loadData() async {
    final data = await _dataService.loadAllData();
    _bars = data['bars'] as List<Bar>;
    _videoData = data['videoData'] as VideoData;
    _currentVideoId = _videoData?.videoId;
    notifyListeners();
  }

  void setCurrentVideoId(String videoId) {
    _currentVideoId = videoId;
    notifyListeners();
  }

  void setCurrentBar(int? barNumber) {
    _currentBarNumber = barNumber;
    notifyListeners();
  }

  void setCurrentLayer(AnnotationLayer layer) {
    _currentLayer = layer;
    notifyListeners();
  }

  void setCurrentColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setDrawing(bool drawing) {
    _isDrawing = drawing;
    notifyListeners();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    notifyListeners();
  }

  void toggleVideoDrawer() {
    _isVideoDrawerOpen = !_isVideoDrawerOpen;
    notifyListeners();
  }

  void toggleQualityControlMode() {
    _isQualityControlMode = !_isQualityControlMode;
    if (_isQualityControlMode && _currentQualityLevel == QualityLevel.none) {
      _currentQualityLevel = QualityLevel.needsWork;
      _currentColor = _currentQualityLevel.color;
    }
    notifyListeners();
  }

  void setQualityLevel(QualityLevel level) {
    _currentQualityLevel = level;
    _currentColor = level.color;
    notifyListeners();
  }

  void toggleLayerVisibility(AnnotationLayer layer) {
    _layerVisibility[layer] = !(_layerVisibility[layer] ?? true);
    notifyListeners();
  }

  void addStroke(AnnotationStroke stroke, AnnotationLayer layer) {
    _saveToUndoHistory(layer);
    _annotations[layer]?.add(stroke);
    _redoHistory[layer]?.clear();
    notifyListeners();
  }

  void clearLayer(AnnotationLayer layer) {
    _saveToUndoHistory(layer);
    _annotations[layer]?.clear();
    _redoHistory[layer]?.clear();
    notifyListeners();
  }

  void _saveToUndoHistory(AnnotationLayer layer) {
    final currentState = List<AnnotationStroke>.from(_annotations[layer] ?? []);
    _undoHistory[layer]?.add(currentState);
  }

  void undo(AnnotationLayer layer) {
    if (!canUndo(layer)) return;

    final previousState = _undoHistory[layer]!.removeLast();
    final currentState = List<AnnotationStroke>.from(_annotations[layer] ?? []);
    _redoHistory[layer]?.add(currentState);
    _annotations[layer] = previousState;
    notifyListeners();
  }

  void redo(AnnotationLayer layer) {
    if (!canRedo(layer)) return;

    final nextState = _redoHistory[layer]!.removeLast();
    final currentState = List<AnnotationStroke>.from(_annotations[layer] ?? []);
    _undoHistory[layer]?.add(currentState);
    _annotations[layer] = nextState;
    notifyListeners();
  }

  void updateCurrentBarFromTimestamp(double timestamp) {
    if (_videoData == null) return;
    final barNumber = _videoData!.findBarNumberForTimestamp(timestamp);
    if (barNumber != null && barNumber != _currentBarNumber) {
      setCurrentBar(barNumber);
    }
  }

  double? getTimestampForBar(int barNumber) {
    return _videoData?.findTimestampForBar(barNumber);
  }

  Bar? findBarAtPoint(double x, double y) {
    for (var bar in _bars) {
      if (bar.containsPoint(x, y)) {
        return bar;
      }
    }
    return null;
  }

  void addTextAnnotation(int barNumber, String text, {Offset? position}) {
    final bar = _bars.firstWhere(
      (b) => b.barNumber == barNumber,
      orElse: () => _bars.first,
    );

    final annotationPosition = position ??
        Offset(
          bar.x + bar.width / 2,
          bar.y - 20,
        );

    final annotation = TextAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      barNumber: barNumber,
      text: text,
      position: annotationPosition,
      createdAt: DateTime.now(),
    );

    _textAnnotations[_currentLayer]?.add(annotation);
    notifyListeners();
  }

  void removeTextAnnotation(String annotationId) {
    for (var layer in AnnotationLayer.values) {
      _textAnnotations[layer]
          ?.removeWhere((annotation) => annotation.id == annotationId);
    }
    notifyListeners();
  }

  void updateTextAnnotation(String annotationId, String newText) {
    for (var layer in AnnotationLayer.values) {
      final annotations = _textAnnotations[layer];
      if (annotations != null) {
        final index =
            annotations.indexWhere((annotation) => annotation.id == annotationId);
        if (index != -1) {
          annotations[index] = annotations[index].copyWith(
            text: newText,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
          return;
        }
      }
    }
  }

  void registerSeekToBarAndPlayCallback(Function(int) callback) {
    _seekToBarAndPlayCallback = callback;
  }

  void seekToBarAndPlay(int barNumber) {
    _seekToBarAndPlayCallback?.call(barNumber);
  }

  void addBarAnnotation(int barNumber, QualityLevel qualityLevel) {
    final bar = _bars.firstWhere(
      (b) => b.barNumber == barNumber,
      orElse: () => _bars.first,
    );

    final barPoints = [
      Offset(bar.x, bar.y),
      Offset(bar.x + bar.width, bar.y),
      Offset(bar.x + bar.width, bar.y + bar.height),
      Offset(bar.x, bar.y + bar.height),
      Offset(bar.x, bar.y),
    ];

    final stroke = AnnotationStroke(
      points: barPoints,
      color: qualityLevel.color.withValues(alpha: 0.3),
      strokeWidth: 2.0,
      barNumber: barNumber,
      qualityLevel: qualityLevel,
      isBarAnnotation: true,
    );

    _saveToUndoHistory(_currentLayer);
    _annotations[_currentLayer]?.add(stroke);
    _redoHistory[_currentLayer]?.clear();
    notifyListeners();
  }

  Map<int, QualityLevel> getBarQualityMap() {
    final qualityMap = <int, QualityLevel>{};
    for (var layer in AnnotationLayer.values) {
      if (!isLayerVisible(layer)) continue;
      final annotations = _annotations[layer] ?? [];
      for (var stroke in annotations) {
        if (stroke.isBarAnnotation &&
            stroke.barNumber != null &&
            stroke.qualityLevel != null) {
          if (!qualityMap.containsKey(stroke.barNumber) ||
              stroke.createdAt.isAfter(
                annotations
                    .where((s) =>
                        s.barNumber == stroke.barNumber &&
                        s.isBarAnnotation)
                    .first
                    .createdAt)) {
            qualityMap[stroke.barNumber!] = stroke.qualityLevel!;
          }
        }
      }
    }
    return qualityMap;
  }

  List<int> getProblemBars() {
    final qualityMap = getBarQualityMap();
    return qualityMap.entries
        .where((entry) =>
            entry.value == QualityLevel.needsWork ||
            entry.value == QualityLevel.improving)
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  void addCollaborator(String name, AnnotationLayer layer, {Color? color}) {
    final collaborator = CollaboratorInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color ?? layer.defaultColor,
      layer: layer,
    );
    _collaborators.add(collaborator);
    notifyListeners();
  }

  void removeCollaborator(String id) {
    _collaborators.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  String exportAnnotations() {
    _annotationVersion++;
    final export = {
      'version': _annotationVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'collaborators': _collaborators.map((c) => c.toJson()).toList(),
      'layers': {
        'teacher': {
          'strokes': _annotations[AnnotationLayer.teacher]
              ?.map((s) => s.toJson())
              .toList(),
          'textAnnotations': _textAnnotations[AnnotationLayer.teacher]
              ?.map((t) => t.toJson())
              .toList(),
        },
        'student': {
          'strokes': _annotations[AnnotationLayer.student]
              ?.map((s) => s.toJson())
              .toList(),
          'textAnnotations': _textAnnotations[AnnotationLayer.student]
              ?.map((t) => t.toJson())
              .toList(),
        },
      },
    };
    return jsonEncode(export);
  }

  Future<bool> importAnnotations(String jsonData, {bool merge = false}) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (!merge) {
        for (var layer in AnnotationLayer.values) {
          _annotations[layer]?.clear();
          _textAnnotations[layer]?.clear();
        }
        _collaborators.clear();
      }

      if (data.containsKey('collaborators')) {
        final collabs = (data['collaborators'] as List)
            .map((c) => CollaboratorInfo.fromJson(c as Map<String, dynamic>))
            .toList();
        if (merge) {
          for (var collab in collabs) {
            if (!_collaborators.any((c) => c.id == collab.id)) {
              _collaborators.add(collab);
            }
          }
        } else {
          _collaborators = collabs;
        }
      }

      final layers = data['layers'] as Map<String, dynamic>;

      for (var layerName in layers.keys) {
        final layer = AnnotationLayer.values.firstWhere(
          (l) => l.name == layerName,
          orElse: () => AnnotationLayer.student,
        );

        final layerData = layers[layerName] as Map<String, dynamic>;

        if (layerData.containsKey('strokes')) {
          final strokes = (layerData['strokes'] as List)
              .map((s) => AnnotationStroke.fromJson(s as Map<String, dynamic>))
              .toList();
          if (merge) {
            _annotations[layer]?.addAll(strokes);
          } else {
            _annotations[layer] = strokes;
          }
        }

        if (layerData.containsKey('textAnnotations')) {
          final textAnns = (layerData['textAnnotations'] as List)
              .map((t) => TextAnnotation.fromJson(t as Map<String, dynamic>))
              .toList();
          if (merge) {
            _textAnnotations[layer]?.addAll(textAnns);
          } else {
            _textAnnotations[layer] = textAnns;
          }
        }
      }

      _annotationVersion = data['version'] as int? ?? 0;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error importing annotations: $e');
      return false;
    }
  }

  void incrementAnnotationVersion() {
    _annotationVersion++;
    notifyListeners();
  }
}
