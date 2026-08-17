import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/detection_model.dart';
import '../models/disease_info_model.dart';
import '../utils/download_helper.dart';

class PhotoDownloadService {
  /// Download scanned image from [imageUrl] with graceful error handling and cross-platform download support.
  static Future<bool> downloadPhoto({
    required BuildContext context,
    required String imageUrl,
    String? fileName,
  }) async {
    if (imageUrl.trim().isEmpty) {
      if (context.mounted) {
        _showSnackBar(context, 'No photo URL available for download.', isError: true);
      }
      return false;
    }

    final name = fileName ?? 'sfarm_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      if (context.mounted) {
        _showSnackBar(context, 'Starting photo download...');
      }

      if (kIsWeb) {
        // Web platform: Fetch image bytes and save via browser blob
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            saveFileWeb(response.bodyBytes, name);
            if (context.mounted) {
              _showSnackBar(context, 'Photo downloaded successfully: $name');
            }
            return true;
          }
        } catch (_) {}

        if (context.mounted) {
          _showSnackBar(context, 'Opening image in browser for download: $name');
        }
        return true;
      } else {
        // Mobile / Desktop platform: fetch bytes and save to disk
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          throw Exception('HTTP response code ${response.statusCode}');
        }

        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        dir ??= await getTemporaryDirectory();

        final filePath = '${dir.path}/$name';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          _showSnackBar(context, 'Photo saved to Downloads: $name');
        }
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Failed to download photo: ${e.toString()}', isError: true);
      }
      return false;
    }
  }

  /// Download associated detection results as a comprehensive text report file.
  static Future<bool> downloadDetectionReport({
    required BuildContext context,
    required DetectionModel detection,
    required String farmerName,
  }) async {
    try {
      final info = DiseaseInfoModel.getDiseaseInfo(detection.disease);
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(detection.timestamp);
      final name = 'detection_report_${detection.disease.replaceAll(' ', '_')}_${detection.id}.txt';

      final StringBuffer buffer = StringBuffer();
      buffer.writeln('===================================================');
      buffer.writeln('          SFARMING DETECTION RESULT REPORT         ');
      buffer.writeln('===================================================');
      buffer.writeln('Detection ID     : ${detection.id}');
      buffer.writeln('Date & Time      : $formattedDate');
      buffer.writeln('Farmer Name      : $farmerName');
      buffer.writeln('User ID          : ${detection.userId}');
      buffer.writeln('---------------------------------------------------');
      buffer.writeln('DISEASE RESULT   : ${detection.disease}');
      buffer.writeln('CONFIDENCE SCORE : ${(detection.confidence * 100).toStringAsFixed(1)}%');
      buffer.writeln('LOCATION STATUS  : ${detection.locationStatus}');
      if (detection.latitude != null && detection.longitude != null) {
        buffer.writeln('COORDINATES      : Lat ${detection.latitude!.toStringAsFixed(6)}, Lng ${detection.longitude!.toStringAsFixed(6)}');
      }
      buffer.writeln('ARCHIVE STATUS   : ${detection.isArchived ? "Archived" : "Active"}');
      buffer.writeln('IMAGE URL        : ${detection.imageUrl.isNotEmpty ? detection.imageUrl : "N/A"}');
      if (detection.notes != null && detection.notes!.isNotEmpty) {
        buffer.writeln('NOTES            : ${detection.notes}');
      }
      buffer.writeln('---------------------------------------------------');
      if (info != null) {
        buffer.writeln('DISEASE DESCRIPTION:');
        buffer.writeln(info.description);
        buffer.writeln('\nSYMPTOMS:');
        for (var s in info.symptoms) {
          buffer.writeln('- $s');
        }
        buffer.writeln('\nTREATMENT PROTOCOL:');
        buffer.writeln(info.treatmentProtocol);
      } else {
        buffer.writeln('ADDITIONAL INFO  : No specific protocol database record found.');
      }
      buffer.writeln('===================================================');

      final content = buffer.toString();

      if (kIsWeb) {
        saveTextWeb(content, name);
        if (context.mounted) {
          _showSnackBar(context, 'Detection report downloaded: $name');
        }
        return true;
      } else {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        dir ??= await getTemporaryDirectory();

        final filePath = '${dir.path}/$name';
        final file = File(filePath);
        await file.writeAsString(content);

        if (context.mounted) {
          _showSnackBar(context, 'Detection report saved: $name');
        }
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Failed to download report: $e', isError: true);
      }
      return false;
    }
  }

  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
