/// Cloudinary unsigned-upload configuration.
/// Replace these values with your own from the Cloudinary dashboard.
class CloudinaryConfig {
  static const String cloudName = 'dm4qmmeal';

  /// Unsigned preset for profile avatar images.
  static const String uploadPreset = 'brewmaster_avatars';

  /// Unsigned preset for verification documents (images + PDFs).
  /// Create this preset in the Cloudinary dashboard:
  ///   Settings → Upload → Upload presets → Add preset
  ///   Mode: Unsigned, Resource type: Auto
  static const String docsUploadPreset = 'brewmaster_docs';

  /// Image upload endpoint (profile avatars, listing images).
  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Auto-type upload endpoint (documents: images or PDFs).
  static const String docsUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
}
