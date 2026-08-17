import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:typed_data';
import '../core/config/cloudinary_config.dart';

class CloudinaryService {
  Future<String> uploadImage(dynamic imageFile, String userId) async {
    try {
      // Get image bytes (works for Uint8List, File, or web)
      Uint8List bytes;
      if (imageFile is Uint8List) {
        bytes = imageFile;
      } else {
        bytes = await imageFile.readAsBytes();
      }

      // Compress image
      final compressedBytes = await _compressImageBytes(bytes);

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${userId}_$timestamp.jpg';

      // Upload to Cloudinary
      final url = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', url)
        ..fields.addAll({
          'upload_preset': CloudinaryConfig.uploadPreset,
          'public_id': filename,
        })
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            compressedBytes,
            filename: filename,
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final url = jsonResponse['secure_url'] ?? jsonResponse['url'];
        if (url == null) throw Exception('No URL returned from Cloudinary response: $responseBody');
        return url as String;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }

  Future<Uint8List> _compressImageBytes(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return imageBytes;
      }

      // Resize if too large (max 1024px on longest side)
      img.Image resized = image;
      if (image.width > 1024 || image.height > 1024) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 1024 : null,
          height: image.height > image.width ? 1024 : null,
          maintainAspect: true,
        );
      }

      // Encode as JPEG with quality 85
      final compressedBytes = img.encodeJpg(resized, quality: 85);

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // If compression fails, return original
      return imageBytes;
    }
  }
}
