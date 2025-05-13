import '/core/models/video/editor_video_model.dart';

/// A configuration model for generating video thumbnails.
///
/// Contains information about the video source, desired timestamps,
/// thumbnail image width, and output image format.
class CreateVideoThumbnail {
  /// Creates a [CreateVideoThumbnail] configuration.
  ///
  /// [video] is the source video.
  /// [thumbnailLimit] defines the maximum number of frames to extract as
  /// thumbnails.
  /// [imageWidth] is the target width for each thumbnail in pixels.
  /// [format] specifies the output image format (defaults to [jpeg]).
  CreateVideoThumbnail({
    required this.video,
    required this.thumbnailLimit,
    required this.imageWidth,
    this.format = ThumbnailFormat.jpeg,
  });

  /// The video from which thumbnails will be generated.
  final EditorVideo video;

  /// The maximum number of frames to extract as thumbnails.
  final int thumbnailLimit;

  /// The width of each generated thumbnail image, in pixels.
  final double imageWidth;

  /// The preferred image format for the thumbnails.
  ///
  /// If the selected [format] isn't supported by the platform, the
  /// default format will be used instead.
  final ThumbnailFormat format;
}

/// Supported image formats for video thumbnails.
enum ThumbnailFormat {
  /// JPEG format (typically smaller file size, lossy compression).
  jpeg,

  /// PNG format (lossless compression, larger file size).
  png,

  /// WebP format (modern, efficient, may not be supported on all platforms).
  webp,
}
