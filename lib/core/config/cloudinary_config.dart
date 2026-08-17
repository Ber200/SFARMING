/// Cloudinary configuration for image storage.
///
/// Replace the placeholders with your Cloudinary credentials:
/// 1. Go to https://console.cloudinary.com
/// 2. Copy Cloud name, API Key, API Secret from Dashboard
/// 3. Create an Upload preset: Settings → Upload → Add upload preset
///    - For unsigned uploads, set "Signing Mode" to "Unsigned"
///    - Use that preset name below
class CloudinaryConfig {
  /// Your Cloudinary cloud name (from Dashboard)
  static const String cloudName = 'dfdlo9szs';

  /// API Key (from Dashboard) - needed for signed uploads
  static const String apiKey = '225132239351675';

  /// API Secret (from Dashboard) - keep secure, server-side only
  static const String apiSecret = 'wuIvMD8_cYEJ0WdWcJSciKrM1sI';

  /// Upload preset name (from Settings → Upload)
  /// For client-side uploads, use an "Unsigned" preset
  static const String uploadPreset = 'itogbrix';

  /// Base upload URL - do not modify unless using a custom Cloudinary setup
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Returns true when credentials are configured (not placeholders)
  static bool get isConfigured =>
      cloudName.isNotEmpty &&
      cloudName != 'dfdlo9szs' &&
      uploadPreset.isNotEmpty &&
      uploadPreset != 'itogbrix';
}
