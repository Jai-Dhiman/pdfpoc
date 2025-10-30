"""
OMR Service - Optical Music Recognition API
Detects bar lines and measures from sheet music PDFs
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import cv2
import numpy as np
from pdf2image import convert_from_bytes
from typing import List, Dict
import io
from PIL import Image

app = FastAPI(title="OMR Service", version="1.0.0")

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "service": "OMR API", "version": "1.0.0"}


@app.post("/detect-bars")
async def detect_bars(
    pdf: UploadFile = File(...),
    page: int = 0,
    min_bar_width: int = 50,
    min_bar_height: int = 100
):
    """
    Detect bar lines in a sheet music PDF

    Parameters:
    - pdf: PDF file containing sheet music
    - page: Page number to process (default: 0)
    - min_bar_width: Minimum width between bars in pixels
    - min_bar_height: Minimum height for a valid bar line

    Returns:
    - JSON with detected bars and their coordinates
    """
    try:
        # Read PDF file
        pdf_bytes = await pdf.read()

        # Convert PDF page to image
        images = convert_from_bytes(
            pdf_bytes,
            first_page=page + 1,
            last_page=page + 1,
            dpi=300
        )

        if not images:
            raise HTTPException(status_code=400, detail="Failed to convert PDF to image")

        # Convert PIL image to numpy array
        img = np.array(images[0])

        # Detect bars
        bars = detect_bar_lines(img, min_bar_width, min_bar_height)

        # Get image dimensions for reference
        height, width = img.shape[:2]

        return JSONResponse({
            "success": True,
            "page": page,
            "image_width": int(width),
            "image_height": int(height),
            "bars_detected": len(bars),
            "bars": bars
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PDF: {str(e)}")


def detect_bar_lines(img: np.ndarray, min_bar_width: int, min_bar_height: int) -> List[Dict]:
    """
    Detect vertical bar lines in sheet music using computer vision

    Algorithm:
    1. Convert to grayscale
    2. Apply adaptive thresholding
    3. Detect vertical lines using morphological operations
    4. Find contours and filter by size
    5. Group lines into measures/bars
    """

    # Convert to grayscale
    if len(img.shape) == 3:
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    else:
        gray = img.copy()

    # Apply adaptive thresholding to handle varying lighting
    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV, 15, 10
    )

    # Detect vertical lines (bar lines)
    vertical_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, min_bar_height))
    vertical_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, vertical_kernel, iterations=2)

    # Find contours
    contours, _ = cv2.findContours(vertical_lines, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Extract bar line x-coordinates
    bar_x_positions = []
    height, width = gray.shape

    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)

        # Filter by height (must be tall enough to be a bar line)
        if h >= min_bar_height:
            bar_x_positions.append({
                'x': int(x),
                'y': int(y),
                'width': int(w),
                'height': int(h)
            })

    # Sort by x position
    bar_x_positions.sort(key=lambda b: b['x'])

    # Group nearby lines (may be double bar lines)
    grouped_bars = []
    i = 0
    while i < len(bar_x_positions):
        current = bar_x_positions[i]

        # Check if next bar is very close (double bar line)
        if i + 1 < len(bar_x_positions):
            next_bar = bar_x_positions[i + 1]
            if next_bar['x'] - current['x'] < 20:  # Within 20 pixels
                # Merge as double bar line
                current['x'] = (current['x'] + next_bar['x']) // 2
                current['width'] = max(current['width'], next_bar['width'])
                current['height'] = max(current['height'], next_bar['height'])
                i += 2
                grouped_bars.append(current)
                continue

        grouped_bars.append(current)
        i += 1

    # Detect staff lines to determine staff boundaries
    staff_regions = detect_staff_lines(gray)

    # Create measures from bar lines
    measures = []
    bar_number = 1

    for i in range(len(grouped_bars) - 1):
        current_bar = grouped_bars[i]
        next_bar = grouped_bars[i + 1]

        measure_width = next_bar['x'] - current_bar['x']

        # Find which staff this measure belongs to
        measure_center_y = current_bar['y'] + current_bar['height'] // 2
        staff_y = None
        staff_height = None

        for staff in staff_regions:
            if staff['y'] <= measure_center_y <= staff['y'] + staff['height']:
                staff_y = staff['y']
                staff_height = staff['height']
                break

        # Use detected staff, or default to bar line dimensions
        if staff_y is None:
            staff_y = current_bar['y']
            staff_height = current_bar['height']

        if measure_width >= min_bar_width:
            measures.append({
                "barNumber": bar_number,
                "x": float(current_bar['x']),
                "y": float(staff_y),
                "width": float(measure_width),
                "height": float(staff_height)
            })
            bar_number += 1

    return measures


def detect_staff_lines(gray: np.ndarray) -> List[Dict]:
    """
    Detect horizontal staff lines to identify staff systems
    """
    # Apply binary threshold
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)

    # Detect horizontal lines (staff lines)
    horizontal_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
    horizontal_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, horizontal_kernel, iterations=2)

    # Find contours
    contours, _ = cv2.findContours(horizontal_lines, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Group staff lines into systems (5 lines per staff)
    staff_lines_y = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if w > gray.shape[1] * 0.5:  # Line spans at least half the width
            staff_lines_y.append(y)

    staff_lines_y.sort()

    # Group into staff systems (typically 5 lines with ~10-20px spacing)
    staff_systems = []
    i = 0
    while i < len(staff_lines_y):
        staff_start = staff_lines_y[i]

        # Find the next 4 lines (total 5 lines = 1 staff)
        j = i + 1
        while j < len(staff_lines_y) and j < i + 5:
            if staff_lines_y[j] - staff_lines_y[j-1] < 30:  # Lines are close together
                j += 1
            else:
                break

        if j >= i + 3:  # Found at least 3 lines (partial staff)
            staff_end = staff_lines_y[j - 1]
            staff_systems.append({
                'y': staff_start - 20,  # Add padding above
                'height': staff_end - staff_start + 40  # Add padding below
            })
            i = j
        else:
            i += 1

    return staff_systems


@app.post("/detect-bars-advanced")
async def detect_bars_advanced(
    pdf: UploadFile = File(...),
    page: int = 0
):
    """
    Advanced bar detection with multiple algorithms and confidence scoring
    """
    try:
        pdf_bytes = await pdf.read()
        images = convert_from_bytes(pdf_bytes, first_page=page+1, last_page=page+1, dpi=300)

        if not images:
            raise HTTPException(status_code=400, detail="Failed to convert PDF")

        img = np.array(images[0])

        # Run multiple detection algorithms
        basic_bars = detect_bar_lines(img, min_bar_width=50, min_bar_height=100)

        # Could add more algorithms here:
        # - Hough line transform
        # - Template matching
        # - Deep learning models (if available)

        return JSONResponse({
            "success": True,
            "page": page,
            "bars": basic_bars,
            "confidence": "medium",
            "algorithm": "morphological_operations"
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
