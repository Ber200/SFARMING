import 'dart:typed_data';

void saveFileWeb(Uint8List bytes, String fileName) {
  // No-op on mobile/desktop platforms (handled via File/path_provider)
}

void saveTextWeb(String content, String fileName) {
  // No-op on mobile/desktop platforms (handled via File/path_provider)
}
