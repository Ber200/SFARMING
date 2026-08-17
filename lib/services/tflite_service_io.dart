import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../utils/constants.dart';
import 'model_update_service.dart';

/// Mobile (Android/iOS) implementation of TFLiteService
class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;
  int _inputSize = AppConstants.modelInputSize;
  int _numClasses = 5;
  final double _confidenceThreshold = 0.6;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[TFLiteService] Initializing TensorFlow Lite model...');

      // 1. Prefer a model deployed through the admin Model Trainer.
      DownloadedModel? deployed;
      try {
        deployed = await ModelUpdateService.checkAndDownload();
      } catch (e) {
        debugPrint('[TFLiteService] Model update check failed: $e');
      }

      List<String>? deployedLabels;
      if (deployed != null && await deployed.modelFile.exists()) {
        try {
          _interpreter = Interpreter.fromFile(deployed.modelFile);
          deployedLabels = deployed.labels;
          debugPrint('[TFLiteService] Loaded deployed model: ${deployed.version}');
        } catch (e) {
          debugPrint(
              '[TFLiteService] Failed loading deployed model, falling back to asset: $e');
          _interpreter = null;
        }
      }

      // 2. Fallback to the bundled asset model.
      if (_interpreter == null) {
        try {
          _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
          debugPrint('[TFLiteService] Loaded model from asset: ${AppConstants.modelPath}');
        } catch (e1) {
          debugPrint('[TFLiteService] Failed loading ${AppConstants.modelPath}, trying fallback model.tflite: $e1');
          _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
        }
      }

      // 3. Log tensor shape and type details
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint('[TFLiteService] Input Tensor Shape: ${inputTensor.shape}, Type: ${inputTensor.type}');
      debugPrint('[TFLiteService] Output Tensor Shape: ${outputTensor.shape}, Type: ${outputTensor.type}');

      // Derive input size and class count from the model's actual tensor shapes
      // so the app stays correct even if the model file is replaced.
      if (inputTensor.shape.length == 4) {
        final h = inputTensor.shape[1];
        final w = inputTensor.shape[2];
        _inputSize = (h != 1 && h != 3) ? h : ((w != 1 && w != 3) ? w : h);
      }
      if (outputTensor.shape.length == 2) {
        _numClasses = outputTensor.shape[1];
      }
      debugPrint('[TFLiteService] Using input size: $_inputSize, class count: $_numClasses');

      // 4. Load labels and strip index prefix numbers (e.g. "0 Bacterial Leaf Blight" -> "Bacterial Leaf Blight")
      if (deployedLabels != null) {
        _labels = deployedLabels;
      } else {
        final labelsData = await rootBundle.loadString(AppConstants.labelsPath);
        _labels = _parseLabels(labelsData);
      }
      debugPrint('[TFLiteService] Loaded ${_labels!.length} labels: $_labels');

      // 5. Guard against silent mislabeling: every model output class needs a label.
      if (_labels!.length != _numClasses) {
        // A mismatched deployed model must not break scanning: fall back to the asset model.
        if (deployedLabels != null) {
          debugPrint('[TFLiteService] Deployed model label mismatch (${_labels!.length} labels, $_numClasses classes); falling back to asset.');
          _interpreter?.close();
          _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
          final inT = _interpreter!.getInputTensor(0);
          final outT = _interpreter!.getOutputTensor(0);
          if (inT.shape.length == 4) {
            final h = inT.shape[1];
            final w = inT.shape[2];
            _inputSize = (h != 1 && h != 3) ? h : ((w != 1 && w != 3) ? w : h);
          }
          if (outT.shape.length == 2) {
            _numClasses = outT.shape[1];
          }
          final assetLabels = await rootBundle.loadString(AppConstants.labelsPath);
          _labels = _parseLabels(assetLabels);
          debugPrint('[TFLiteService] Reloaded asset model: input $_inputSize, $_numClasses classes, ${_labels!.length} labels.');
        }
        if (_labels!.length != _numClasses) {
          throw StateError(
            'Label count mismatch: model outputs $_numClasses classes but '
            'labels have ${_labels!.length} entries. '
            'Fix labels.txt so it matches the model class order.',
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TFLiteService] Error initializing model: $e');
      throw Exception('Failed to initialize TFLite model: $e');
    }
  }

  static List<String> _parseLabels(String content) {
    return content
        .split('\n')
        .map((label) => label.replaceAll(RegExp(r'^\d+\s*'), '').trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> predict(dynamic imageInput) async {
    if (!_isInitialized) {
      debugPrint('[TFLiteService] Model not initialized yet. Calling initialize()...');
      await initialize();
    }

    try {
      debugPrint('[TFLiteService] Starting prediction pipeline for input: ${imageInput.runtimeType}');

      // 1. Extract raw image bytes
      final Uint8List imageBytes;
      if (imageInput is File) {
        imageBytes = await imageInput.readAsBytes();
      } else if (imageInput is Uint8List) {
        imageBytes = imageInput;
      } else if (imageInput is String) {
        imageBytes = await File(imageInput).readAsBytes();
      } else if (imageInput != null && imageInput.toString().contains('XFile')) {
        imageBytes = await File(imageInput.path).readAsBytes();
      } else {
        throw Exception('Unsupported image input type: ${imageInput.runtimeType}');
      }

      debugPrint('[TFLiteService] Image byte size: ${imageBytes.length} bytes');

      // 2. Preprocess & Decode Image
      var image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image bytes into Image object');
      }

      image = img.bakeOrientation(image);
      debugPrint('[TFLiteService] Decoded Image dimensions: ${image.width}x${image.height}');

      // 3. Center-crop to square then resize to model input size.
      //    This matches Teachable Machine's preprocessing (square thumbnails)
      //    and avoids squashing the leaf, which distorts lesions.
      final resized = img.copyResizeCropSquare(image, size: _inputSize);

      // 4. Construct normalized Tensor input shape [1, 224, 224, 3]
      // Teachable Machine Float32 models normalize pixel values to [0, 1]
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (h) => List.generate(_inputSize, (w) {
            final pixel = resized.getPixel(w, h);
            return [
              pixel.r.toDouble() / 255.0, // R
              pixel.g.toDouble() / 255.0, // G
              pixel.b.toDouble() / 255.0, // B
            ];
          }),
        ),
      );

      // 5. Output shape allocation: [1, num_classes]
      final output = List.generate(1, (_) => List.filled(_numClasses, 0.0));

      debugPrint('[TFLiteService] Running TFLite inference...');
      _interpreter!.run(input, output);
      debugPrint('[TFLiteService] Inference finished. Raw output probabilities: ${output[0]}');

      // 6. Find max probability class
      final List<double> predictions = List<double>.from(output[0]);
      int maxIndex = 0;
      double maxConfidence = -1.0;

      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          maxIndex = i;
        }
      }

      String diseaseName = (maxIndex < _labels!.length)
          ? _labels![maxIndex]
          : 'invalid';

      // Report the model's actual top class. 'invalid' stays 'invalid' so the
      // app can guide the user to retake the photo (never silently shown as Healthy).
      final bool isInvalid = diseaseName.toLowerCase() == 'invalid';
      final bool isLowConfidence = !isInvalid && maxConfidence < _confidenceThreshold;

      // Top-3 predictions (index -> label -> probability) for diagnostics and
      // for verifying that labels.txt ordering matches the model class order.
      final sortedIndices = List<int>.generate(predictions.length, (i) => i)
        ..sort((a, b) => predictions[b].compareTo(predictions[a]));
      final topPredictions = sortedIndices
          .take(3)
          .map((i) => {
                'index': i,
                'label': i < _labels!.length ? _labels![i] : 'unknown',
                'confidence': predictions[i],
              })
          .toList();

      debugPrint('[TFLiteService] Selected Prediction: "$diseaseName" with confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%');
      debugPrint('[TFLiteService] Top-3: $topPredictions');

      final allPredictions = <String, double>{};
      for (int i = 0; i < _labels!.length && i < predictions.length; i++) {
        allPredictions[_labels![i]] = predictions[i];
      }

      return {
        'disease': diseaseName,
        'confidence': maxConfidence,
        'allPredictions': allPredictions,
        'topPredictions': topPredictions,
        'isLowConfidence': isLowConfidence,
      };
    } catch (e, stack) {
      debugPrint('[TFLiteService] Prediction Error: $e\n$stack');
      throw Exception('TFLite inference failed: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    debugPrint('[TFLiteService] Interpreter disposed.');
  }
}
