# Product Requirements Document: PDF Music Score Annotation POC

## Overview
Interactive music learning tool that synchronizes PDF sheet music (Un Sospiro) with YouTube performance video, enabling bar-level navigation and multi-layer annotations.

## Objectives
- Demonstrate bidirectional sync between PDF bars and video timestamps
- Enable teacher/student annotation workflows with layer filtering
- Validate technical feasibility of OMR + MIDI-to-timestamp mapping

## Target Users
- Music teachers providing annotated feedback
- Piano students reviewing lessons with synchronized video

## Core Features

### 1. Split-Pane Interface
- **Left:** PDF sheet music with annotation overlay
- **Right:** Embedded YouTube player
- Desktop-first responsive layout

### 2. Bar-Video Synchronization
- Click any bar → video jumps to corresponding timestamp
- Video playback → highlights current bar in real-time
- Preprocessing generates bar coordinates (OMR) and timestamp mapping (MIDI)

### 3. Multi-Layer Annotation System
- **Drawing Tools:** Freehand pen with 3 color options
- **Layers:** Separate canvases for teacher/student annotations
- **Filtering:** Toggle visibility per layer (show/hide teacher vs student notes)
- **Persistence:** LocalStorage for annotation data

## Technical Constraints

### In Scope (MVP)
- Single hardcoded PDF (Un Sospiro)
- Single hardcoded YouTube video URL
- 2 annotation layers (teacher/student simulation)
- 3 pen colors for annotations
- Desktop browser only (Chrome/Firefox)

### Out of Scope
- Multi-document support
- Authentication/user management
- Real-time collaboration
- Mobile responsiveness
- Undo/redo functionality
- Multiple videos per piece

## Data Requirements

### bars.json (OMR Output)
Maps bar numbers to PDF coordinate regions for click detection.

### timestamps.json (MIDI Mapping)
Maps bar numbers to video timestamps for synchronization.

### annotations.json (LocalStorage)
Stores stroke paths with layer metadata (author, color, visibility).

## Success Criteria
1. Click-to-seek latency < 500ms
2. Bar highlighting syncs within 100ms of video position
3. Smooth freehand drawing with no visible lag
4. Layer filtering updates < 100ms
5. Annotations persist across browser sessions

## Open Questions
- OMR accuracy on complex notation (Un Sospiro)
- Fallback strategy if auto-MIDI sync fails
- Performance with 50+ annotation strokes per layer
