# OMR Service - Optical Music Recognition API

A FastAPI-based service for detecting bar lines and measures in sheet music PDFs using computer vision.

## Features

- **PDF to Image Conversion**: Converts PDF pages to high-resolution images
- **Bar Line Detection**: Identifies vertical bar lines using morphological operations
- **Staff Detection**: Recognizes horizontal staff lines and groups them into systems
- **Measure Extraction**: Generates bar coordinates (x, y, width, height) for each measure
- **RESTful API**: Easy integration with Flutter or any HTTP client

## Installation

### Option 1: Docker (Recommended)

```bash
# Build the Docker image
docker build -t omr-service .

# Run the container
docker run -p 8000:8000 omr-service
```

### Option 2: Local Development

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python main.py
# Or with uvicorn directly:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### System Dependencies

For local development, you need:
- Python 3.11+
- poppler-utils (for pdf2image)
  - Ubuntu/Debian: `sudo apt-get install poppler-utils`
  - macOS: `brew install poppler`
  - Windows: Download from [poppler releases](https://github.com/oschwartz10612/poppler-windows/releases/)

## API Endpoints

### `GET /`
Health check endpoint

**Response:**
```json
{
  "status": "ok",
  "service": "OMR API",
  "version": "1.0.0"
}
```

### `POST /detect-bars`
Detect bar lines in a sheet music PDF

**Parameters:**
- `pdf` (file): PDF file containing sheet music
- `page` (int, optional): Page number to process (default: 0)
- `min_bar_width` (int, optional): Minimum width between bars in pixels (default: 50)
- `min_bar_height` (int, optional): Minimum height for a valid bar line (default: 100)

**Example with curl:**
```bash
curl -X POST "http://localhost:8000/detect-bars?page=0" \
  -F "pdf=@unsospiro.pdf"
```

**Response:**
```json
{
  "success": true,
  "page": 0,
  "image_width": 2480,
  "image_height": 3508,
  "bars_detected": 15,
  "bars": [
    {
      "barNumber": 1,
      "x": 120.0,
      "y": 450.0,
      "width": 280.0,
      "height": 120.0
    },
    ...
  ]
}
```

### `POST /detect-bars-advanced`
Advanced detection with multiple algorithms (future enhancement)

## Algorithm

The bar detection algorithm uses computer vision techniques:

1. **Preprocessing**
   - Convert PDF to 300 DPI image
   - Convert to grayscale
   - Apply adaptive thresholding

2. **Vertical Line Detection**
   - Use morphological operations to extract vertical lines
   - Filter by minimum height (bar lines must span the staff)

3. **Staff Line Detection**
   - Detect horizontal staff lines
   - Group lines into staff systems (5 lines per staff)

4. **Measure Grouping**
   - Sort bar lines by x-position
   - Merge double bar lines (within 20px)
   - Create measure bounding boxes between consecutive bar lines

5. **Output Generation**
   - Generate JSON with bar number, x, y, width, height
   - Compatible with Flutter Bar model format

## Integration with Flutter App

### 1. Add HTTP dependency to pubspec.yaml
```yaml
dependencies:
  http: ^1.1.0
```

### 2. Create OMR Service Client
```dart
// lib/services/omr_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/bar.dart';

class OMRService {
  final String baseUrl;

  OMRService({this.baseUrl = 'http://localhost:8000'});

  Future<List<Bar>> detectBars(File pdfFile, {int page = 0}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/detect-bars?page=$page'),
    );

    request.files.add(await http.MultipartFile.fromPath('pdf', pdfFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    if (jsonData['success']) {
      return (jsonData['bars'] as List)
          .map((b) => Bar.fromJson(b))
          .toList();
    } else {
      throw Exception('OMR detection failed');
    }
  }
}
```

### 3. Use in Flutter
```dart
final omrService = OMRService(baseUrl: 'http://localhost:8000');
final bars = await omrService.detectBars(pdfFile);
print('Detected ${bars.length} bars');
```

## Development

### Running Tests
```bash
# Install dev dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

### Debugging
- Set `log_level="debug"` in `uvicorn.run()` for detailed logs
- Use `/detect-bars?min_bar_height=80` to adjust sensitivity
- Higher `min_bar_height` = fewer false positives but may miss short bars
- Lower values = more bars detected but may include noise

## Performance

- Average processing time: 2-5 seconds per page at 300 DPI
- Memory usage: ~500MB for typical sheet music PDFs
- Concurrent requests: Supports multiple simultaneous requests

## Limitations

- Currently optimized for piano sheet music with standard notation
- May struggle with:
  - Hand-written music
  - Very old/degraded scans
  - Non-standard layouts (tablature, chord charts)
  - Multiple simultaneous systems (grand staff works fine)

## Future Enhancements

- [ ] Deep learning-based detection (YOLO, Faster R-CNN)
- [ ] Note head detection
- [ ] Tempo and key signature extraction
- [ ] Export to MusicXML format
- [ ] Batch processing endpoint
- [ ] Confidence scoring for detections
- [ ] Support for more music notation types

## License

MIT License - See main project LICENSE file

## Troubleshooting

### "poppler-utils not found"
Install poppler:
- Ubuntu: `sudo apt-get install poppler-utils`
- macOS: `brew install poppler`

### "Out of memory"
Reduce DPI in `convert_from_bytes()` from 300 to 200 or 150

### "No bars detected"
Try adjusting parameters:
- Decrease `min_bar_height` (e.g., 80 instead of 100)
- Decrease `min_bar_width` (e.g., 30 instead of 50)
- Check PDF quality - scan should be clear and high contrast
