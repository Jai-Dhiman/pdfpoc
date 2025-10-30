# PDF PoC - Music Annotation App

A Flutter cross-platform application for annotating music PDFs with synchronized YouTube video playback. This app allows teachers and students to annotate sheet music with the ability to sync annotations to specific bars of music.

## Features

### Core Functionality
- **PDF Viewer**: Display and interact with music sheet PDFs
- **Bar Detection**: Click on bars in the PDF to jump to corresponding video timestamps
- **Bar Highlighting**: Visual feedback showing the current bar being played
- **YouTube Integration**: Synchronized video playback with bar selection
- **Bi-directional Sync**:
  - Click a bar → video seeks to that timestamp
  - Video plays → bar highlights automatically update

### Annotation System
- **Dual-Layer Annotations**: Separate layers for teacher and student annotations
- **Drawing Tools**:
  - Freehand pen tool
  - Color picker (5 preset colors: red, blue, green, orange, black)
  - Adjustable stroke width (1-10)
  - Layer visibility toggles
  - Clear layer functionality
- **State Management**: Provider-based state management for all app state
- **Responsive Layout**: Adapts to different screen sizes (mobile, tablet, desktop)

## Technology Stack

- **Language**: Dart
- **Framework**: Flutter (iOS, Android, Web, macOS, Windows, Linux)
- **PDF Rendering**: Syncfusion Flutter PDFViewer
- **Video Player**: YouTube Player Flutter
- **State Management**: Provider
- **Local Storage**: SharedPreferences + Hive
- **Testing**: flutter_test

## Project Structure

```
lib/
├── main.dart                 # Main app entry point
├── models/                   # Data models
│   ├── annotation.dart       # Annotation and stroke models
│   ├── bar.dart             # Bar coordinate model
│   └── bar_timestamp.dart   # Video timestamp model
├── providers/               # State management
│   └── app_state.dart       # Main app state provider
├── services/                # Services
│   └── data_service.dart    # JSON data loading service
└── widgets/                 # UI components
    ├── annotation_painter.dart      # Annotation drawing widget
    ├── bar_overlay_painter.dart     # Bar highlighting overlay
    ├── control_panel.dart           # Annotation controls
    ├── pdf_viewer_widget.dart       # PDF viewer component
    └── video_player_widget.dart     # YouTube player component

assets/
└── data/
    ├── bars.json            # Bar coordinate definitions
    ├── timestamps.json      # Video timestamp mappings
    └── unsospiro.pdf        # Sheet music PDF
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- For iOS development: Xcode
- For Android development: Android Studio

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd pdfpoc
```

2. Install dependencies:
```bash
flutter pub get
```

3. Verify installation:
```bash
flutter doctor
```

### Running the App

#### Desktop (macOS/Windows/Linux)
```bash
flutter run -d macos
# or
flutter run -d windows
# or
flutter run -d linux
```

#### Mobile
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

#### Web
```bash
flutter run -d chrome
```

### Building for Production

#### iOS
```bash
flutter build ios --release
```

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### macOS
```bash
flutter build macos --release
```

#### Web
```bash
flutter build web --release
```

## Data Files

### bars.json
Defines clickable regions for each bar in the PDF:
```json
{
  "bars": [
    {
      "barNumber": 1,
      "x": 120,
      "y": 200,
      "width": 300,
      "height": 80
    }
  ]
}
```

### timestamps.json
Maps bars to video timestamps:
```json
{
  "videoId": "zucBfXpCA6s",
  "barTimestamps": [
    {
      "barNumber": 1,
      "timestamp": 0.5
    }
  ]
}
```

## Development

### Code Analysis
```bash
flutter analyze
```

### Testing
```bash
flutter test
```

### Hot Reload
When running the app, press `r` in the terminal for hot reload, or `R` for hot restart.

## Key Components

### AppState (Provider)
Central state management handling:
- Current bar selection
- Annotation layers and visibility
- Drawing tool settings
- Video sync state

### PDF Viewer Widget
- Displays PDF using Syncfusion PDFViewer
- Overlays bar detection regions
- Handles tap events for bar selection

### Video Player Widget
- YouTube player integration
- Auto-seeking when bars are clicked
- Periodic polling to update current bar during playback

### Annotation System
- CustomPainter-based drawing
- Multi-layer support (teacher/student)
- Stroke persistence to local storage

## Usage

1. **Select a Bar**: Tap on any bar in the PDF to highlight it
2. **Video Sync**: The video will automatically seek to the bar's timestamp
3. **Draw Annotations**:
   - Choose a layer (Teacher/Student)
   - Select a color
   - Adjust stroke width
   - Draw on the PDF
4. **Toggle Visibility**: Show/hide teacher or student layers
5. **Clear Annotations**: Clear all annotations from the current layer

## Future Enhancements

- Undo/redo functionality
- Export annotations to PDF
- Multi-page PDF support
- Cloud storage integration
- Real-time collaboration
- Audio recording and playback

## License

[Your License Here]

## Contributing

[Contributing Guidelines]
