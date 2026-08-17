import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'soil_detector_validator.dart';
import 'soil_scan_field_mapper.dart';
import 'soil_scan_geometry.dart';
import 'soil_scan_ocr.dart';
import 'soil_scan_result.dart';

import '../gemini_soil_scanner_service.dart';

/// Two-stage computer vision & OCR pipeline for the physical Intelligent Soil Detector:
/// 1. Online Stage: Gemini Vision AI extraction when online & API key is available.
/// 2. Offline Stage: Local image orientation -> Detector/LCD validation -> Enhancement/Binarization -> Multi-pass ML Kit OCR -> Layout Mapping -> Validation.
class SoilScanProcessor {
  SoilScanProcessor({
    SoilScanOcr? ocr,
    GeminiSoilScannerService? geminiService,
    SoilDetectorValidator? validator,
    this.enableOnlineAi = true,
  })  : _ocr = ocr ?? SoilScanOcr(),
        _geminiService = geminiService,
        _validator = validator ?? const SoilDetectorValidator();

  final SoilScanOcr _ocr;
  final GeminiSoilScannerService? _geminiService;
  final SoilDetectorValidator _validator;
  final bool enableOnlineAi;

  /// Fraction of the capture kept around the center (the LCD region).
  static const double _cropFraction = 0.86;

  /// Longest side cap after upscaling, keeping ML Kit inputs fast.
  static const int _maxDimension = 2400;

  Future<SoilScanResult> process(
    Uint8List capturedBytes, {
    Size? previewSize,
    Rect? frame,
  }) async {
    // 1. Try Gemini Vision AI scanner first if enabled
    if (enableOnlineAi) {
      try {
        final service = _geminiService ?? const GeminiSoilScannerService();
        final geminiResult = await service.analyzeImage(capturedBytes);
        if (geminiResult.hasAnyValue) {
          return geminiResult;
        }
      } on SoilScanException catch (e) {
        // If Gemini Vision explicitly confirmed device is not present, fall through to verify locally
        if (e.error == SoilScanError.displayNotFound && _geminiService != null) {
          rethrow;
        }
      } catch (_) {
        // Fallback to local offline pipeline
      }
    }

    // 2. Local offline image processing & OCR fallback
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(capturedBytes);
    } catch (_) {
      throw const SoilScanException(SoilScanError.invalidImage);
    }
    if (decoded == null) {
      throw const SoilScanException(SoilScanError.invalidImage);
    }

    final oriented = img.bakeOrientation(decoded);

    // 2a. Frame-aligned crop (the region the farmer framed).
    final frameRect = (previewSize != null && frame != null)
        ? mapFrameToImage(frame, previewSize, oriented.width, oriented.height)
        : null;
    if (frameRect != null) {
      final crop = _cropToRect(oriented, frameRect);
      if (crop != null) {
        final result = await _runCropPass(crop, oriented);
        if (result != null && result.hasAnyValue) return result;
      }
    }

    // 2b. Centered crop fallback.
    final centerCrop = _cropCenter(oriented, _cropFraction);
    final centerResult = await _runCropPass(centerCrop, oriented);
    if (centerResult != null && centerResult.hasAnyValue) return centerResult;

    // 2c. Full-image fallback.
    final fullResult = await _runCropPass(oriented, oriented);
    if (fullResult != null && fullResult.hasAnyValue) return fullResult;

    throw const SoilScanException(SoilScanError.displayNotFound);
  }

  /// Enhances, upsamples and OCRs [crop]. Validates detector signature before mapping readings.
  Future<SoilScanResult?> _runCropPass(img.Image crop, img.Image fullImage) async {
    final enhanced = _enhance(crop);
    final upscaled = _upscale(enhanced);
    final ocrResult = await _runOcrPasses(upscaled);
    if (ocrResult.lines.isEmpty) return null;

    // Two-stage validation: check if the image matches the Intelligent Soil Detector visual/text signature
    final validation = _validator.validate(
      image: crop,
      recognizedLines: ocrResult.lines,
    );

    if (!validation.isValidDevice) {
      return null;
    }

    final mapped = SoilScanFieldMapper().mapLines(
      ocrResult.lines,
      imageWidth: upscaled.width.toDouble(),
      imageHeight: upscaled.height.toDouble(),
    );
    return mapped;
  }

  Future<SoilScanResult> _runOcrPasses(img.Image upscaled) async {
    final lines = <RecognizedLine>[];
    final jpgBytes = img.encodeJpg(upscaled, quality: 92);
    final binaryBytes = img.encodeJpg(_binarize(upscaled), quality: 92);

    for (final bytes in [jpgBytes, binaryBytes]) {
      try {
        lines.addAll(await _ocr.recognize(Uint8List.fromList(bytes)));
      } on SoilScanException catch (e) {
        if (e.error == SoilScanError.unavailable) rethrow;
      }
    }

    return SoilScanResult(
      values: const [],
      lines: _mergeLines(lines),
    );
  }

  /// Crops the central [fraction] of the image (the sensor display region).
  img.Image _cropCenter(img.Image image, double fraction) {
    final left = (image.width * (1 - fraction) / 2).round();
    final top = (image.height * (1 - fraction) / 2).round();
    final width = (image.width * fraction).round();
    final height = (image.height * fraction).round();
    if (width <= 0 || height <= 0) return image;
    return img.copyCrop(image, x: left, y: top, width: width, height: height);
  }

  /// Crops to [rect] (image pixel coordinates, already clamped by the mapper).
  img.Image? _cropToRect(img.Image image, Rect rect) {
    final left = rect.left.floor().clamp(0, image.width - 1);
    final top = rect.top.floor().clamp(0, image.height - 1);
    final right = rect.right.ceil().clamp(0, image.width);
    final bottom = rect.bottom.ceil().clamp(0, image.height);
    final width = right - left;
    final height = bottom - top;
    if (width < 32 || height < 32) return null;
    return img.copyCrop(image, x: left, y: top, width: width, height: height);
  }

  /// Grayscale -> contrast/gamma boost -> sharpening to make LCD digits legible.
  img.Image _enhance(img.Image image) {
    var out = img.grayscale(image);
    out = img.adjustColor(out, contrast: 1.35, gamma: 0.95);
    out = img.convolution(
      out,
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
    );
    return out;
  }

  /// Upscales 2x (capped) so small LCD digits occupy more OCR pixels.
  img.Image _upscale(img.Image image) {
    final scale = _maxDimension /
        (image.width > image.height ? image.width : image.height);
    if (scale <= 1) {
      return img.copyResize(image, width: image.width, height: image.height);
    }
    final factor = scale > 2 ? 2.0 : scale;
    return img.copyResize(
      image,
      width: (image.width * factor).round(),
      height: (image.height * factor).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Otsu binarization tuned for LCD digits. Output is black-on-white so OCR
  /// sees classic text regardless of the device's backlight polarity.
  img.Image _binarize(img.Image image) {
    final pixels = List<int>.generate(256, (_) => 0);
    var sum = 0;
    var count = 0;

    for (final pixel in image) {
      final v = pixel.r.toInt();
      pixels[v]++;
      sum += v;
      count++;
    }
    if (count == 0) return image;

    final total = count;
    var sumB = 0;
    var weightB = 0;
    var maxVariance = 0.0;
    var threshold = 128;

    for (var t = 0; t < 256; t++) {
      weightB += pixels[t];
      if (weightB == 0) continue;
      final weightF = total - weightB;
      if (weightF == 0) break;
      sumB += t * pixels[t];
      final meanB = sumB / weightB;
      final meanF = (sum - sumB) / weightF;
      final diff = meanB - meanF;
      final variance = weightB * weightF * diff * diff;
      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = t;
      }
    }

    final invert = (sum / total) < 128;
    final out = img.Image(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final v = image.getPixel(x, y).r;
        final value = v > threshold ? 255 : 0;
        final finalValue = invert ? 255 - value : value;
        out.setPixelRgb(x, y, finalValue, finalValue, finalValue);
      }
    }
    return out;
  }

  /// Removes duplicate lines produced by the multi-pass OCR.
  List<RecognizedLine> _mergeLines(List<RecognizedLine> lines) {
    final merged = <RecognizedLine>[];
    for (final line in lines) {
      final isDuplicate = merged.any((existing) {
        if (existing.text != line.text) return false;
        final dx = (existing.box.centerX - line.box.centerX).abs();
        final dy = (existing.box.centerY - line.box.centerY).abs();
        return dx < 6 && dy < 6;
      });
      if (!isDuplicate) merged.add(line);
    }
    return merged;
  }

  void dispose() {
    _ocr.dispose();
  }
}
