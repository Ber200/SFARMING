/// Pure geometry helpers that translate the on-screen scan frame into the
/// region of the captured (upright) image that it covers.
library;

import 'dart:ui';

/// Minimum size (pixels) for a mapped crop to be considered usable.
const double _minCropSize = 48.0;

/// Extra margin (fraction of the mapped crop) kept around the framed display
/// so OCR still sees the full LCD even if it slightly overflows the frame.
const double _cropMargin = 0.03;

/// Maps [frame] — drawn on the camera preview widget in widget coordinates —
/// into pixel coordinates of the captured image (already upright, i.e. after
/// EXIF orientation is baked).
///
/// The preview widget and the captured image rarely share an aspect ratio, so
/// the image is letterboxed inside the preview (fit-width or fit-height). This
/// computes the visible image rect inside the preview and maps the frame
/// through it, then expands by a small margin and clamps to the image bounds.
///
/// Returns null when the frame cannot be reliably mapped (too small, or
/// outside the visible image). Callers should fall back to a centered crop.
Rect? mapFrameToImage(
  Rect frame,
  Size preview,
  int imageWidth,
  int imageHeight,
) {
  if (preview.width <= 0 || preview.height <= 0) return null;
  if (imageWidth <= 0 || imageHeight <= 0) return null;

  final previewAspect = preview.width / preview.height;
  final imageAspect = imageWidth / imageHeight;

  // Visible (letterboxed) rect of the image inside the preview box.
  Rect visible;
  if (imageAspect > previewAspect) {
    // Image is wider (relative) than the box -> fits by width, bars top/bottom.
    final visibleHeight = preview.width / imageAspect;
    visible = Rect.fromLTWH(
      0,
      (preview.height - visibleHeight) / 2,
      preview.width,
      visibleHeight,
    );
  } else {
    // Image is taller (relative) than the box -> fits by height, bars on sides.
    final visibleWidth = preview.height * imageAspect;
    visible = Rect.fromLTWH(
      (preview.width - visibleWidth) / 2,
      0,
      visibleWidth,
      preview.height,
    );
  }

  final scaleX = imageWidth / visible.width;
  final scaleY = imageHeight / visible.height;

  var left = (frame.left - visible.left) * scaleX;
  var top = (frame.top - visible.top) * scaleY;
  var right = (frame.right - visible.left) * scaleX;
  var bottom = (frame.bottom - visible.top) * scaleY;

  final marginX = (right - left) * _cropMargin;
  final marginY = (bottom - top) * _cropMargin;
  left -= marginX;
  top -= marginY;
  right += marginX;
  bottom += marginY;

  left = left.clamp(0.0, imageWidth.toDouble());
  top = top.clamp(0.0, imageHeight.toDouble());
  right = right.clamp(0.0, imageWidth.toDouble());
  bottom = bottom.clamp(0.0, imageHeight.toDouble());

  if (right - left < _minCropSize || bottom - top < _minCropSize) return null;

  return Rect.fromLTRB(left, top, right, bottom);
}
