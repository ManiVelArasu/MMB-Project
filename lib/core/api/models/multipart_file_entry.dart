/// Represents a file to be uploaded in a multipart request.
///
/// Usage inside [ApiRequestConfig.body]:
/// ```dart
/// body: {
///   'profile_image': MultipartFileEntry.fromPath('/path/to/image.jpg'),
///   'name': 'John',
/// }
/// ```
class MultipartFileEntry {
  const MultipartFileEntry._({
    this.filePath,
    this.bytes,
    required this.filename,
    this.contentType,
  });

  /// Create from a file-system path.
  factory MultipartFileEntry.fromPath(
    String filePath, {
    String? filename,
    String? contentType,
  }) {
    return MultipartFileEntry._(
      filePath: filePath,
      filename: filename ?? filePath.split('/').last,
      contentType: contentType,
    );
  }

  /// Create from raw bytes (e.g. picked from gallery).
  factory MultipartFileEntry.fromBytes(
    List<int> bytes, {
    required String filename,
    String? contentType,
  }) {
    return MultipartFileEntry._(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  final String? filePath;
  final List<int>? bytes;
  final String filename;

  /// MIME type, e.g. `image/jpeg`. Inferred by dio when `null`.
  final String? contentType;
}
