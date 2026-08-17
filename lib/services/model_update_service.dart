import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

/// A model that has been downloaded for use by the mobile app.
class DownloadedModel {
  final File modelFile;
  final String version;
  final List<String> labels;

  const DownloadedModel({
    required this.modelFile,
    required this.version,
    required this.labels,
  });
}

/// Checks the admin-deployed model (admin_settings/model) and, when a newer
/// version exists, downloads the `.tflite` + labels.txt for runtime use.
class ModelUpdateService {
  static const String _appliedVersionKey = 'applied_model_version';
  static const String _dirName = 'trained_models';
  static const String _modelFileName = 'model.tflite';
  static const String _labelsFileName = 'labels.txt';

  /// Downloads (or reuses) the active deployed model. Returns null when there
  /// is no deployed model, no network, or a failure occurs (caller falls back
  /// to the bundled asset model).
  static Future<DownloadedModel?> checkAndDownload() async {
    try {
      final active = await FirebaseService().getActiveModelOnce();
      if (active == null) return null;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_appliedVersionKey) == active.version) {
        return await _readLocal();
      }

      final modelResponse = await http.get(Uri.parse(active.modelUrl));
      final labelsResponse = await http.get(Uri.parse(active.labelsUrl));
      if (modelResponse.statusCode != 200 || labelsResponse.statusCode != 200) {
        return null;
      }

      final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/$_dirName',
      );
      await dir.create(recursive: true);
      final modelFile = File('${dir.path}/$_modelFileName');
      final labelsFile = File('${dir.path}/$_labelsFileName');
      await modelFile.writeAsBytes(modelResponse.bodyBytes, flush: true);
      await labelsFile.writeAsString(
        utf8.decode(labelsResponse.bodyBytes),
        flush: true,
      );
      await prefs.setString(_appliedVersionKey, active.version);

      return DownloadedModel(
        modelFile: modelFile,
        version: active.version,
        labels: _parseLabels(await labelsFile.readAsString()),
      );
    } catch (e) {
      debugPrint('[ModelUpdateService] Failed to check/download active model: $e');
      return null;
    }
  }

  /// Returns the last downloaded model from disk without network access.
  static Future<DownloadedModel?> getLocalModel() async {
    try {
      return await _readLocal();
    } catch (e) {
      debugPrint('[ModelUpdateService] Failed to read local model: $e');
      return null;
    }
  }

  static Future<DownloadedModel?> _readLocal() async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/$_dirName',
    );
    final modelFile = File('${dir.path}/$_modelFileName');
    final labelsFile = File('${dir.path}/$_labelsFileName');
    if (!await modelFile.exists() || !await labelsFile.exists()) return null;
    return DownloadedModel(
      modelFile: modelFile,
      version: '',
      labels: _parseLabels(await labelsFile.readAsString()),
    );
  }

  /// Strips index prefixes ("0 Bacterial Leaf Blight" -> "Bacterial Leaf Blight").
  static List<String> _parseLabels(String content) {
    return content
        .split('\n')
        .map((label) => label.replaceAll(RegExp(r'^\d+\s*'), '').trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }
}
