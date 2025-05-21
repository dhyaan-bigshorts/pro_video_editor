/// Supported image formats for video thumbnails.
enum ThumbnailFormat {
  /// JPEG format (typically smaller file size, lossy compression).
  jpeg,

  /// PNG format (lossless compression, larger file size).
  png,

  /// WebP format (modern, efficient, may not be supported on all platforms).
  webp,
}
