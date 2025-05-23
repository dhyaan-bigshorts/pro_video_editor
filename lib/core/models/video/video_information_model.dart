import 'dart:ui';

/// A class that holds metadata information about a video.
class VideoMetadata {
  /// Creates a [VideoMetadata] instance.
  VideoMetadata({
    required this.duration,
    required this.extension,
    required this.fileSize,
    required this.resolution,
    required this.rotation,
    required this.bitrate,
  });

  /// The size of the video file in bytes.
  final int fileSize;

  /// The resolution of the video, represented as a [Size] object.
  ///
  /// Example:
  /// ```dart
  /// Size(1920, 1080) // Full HD resolution
  /// ```
  final Size resolution;

  /// The rotation of the video.
  final int rotation;

  /// The duration of the video.
  ///
  /// Example:
  /// ```dart
  /// Duration(seconds: 120) // 2 minutes
  /// ```
  final Duration duration;

  /// The format of the video file, such as "mp4" or "avi".
  final String extension;

  /// The bitrate of the video in bits per second.
  ///
  /// This value represents the amount of data processed per unit of time in
  /// the video stream.
  /// Higher bitrate generally result in better video quality, but also
  /// larger file sizes.
  final int bitrate;

  /// Returns a copy of this config with the given fields replaced.
  VideoMetadata copyWith({
    int? fileSize,
    Size? resolution,
    Duration? duration,
    String? extension,
    int? rotation,
    int? bitrate,
  }) {
    return VideoMetadata(
      fileSize: fileSize ?? this.fileSize,
      resolution: resolution ?? this.resolution,
      duration: duration ?? this.duration,
      extension: extension ?? this.extension,
      rotation: rotation ?? this.rotation,
      bitrate: bitrate ?? this.bitrate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoMetadata &&
        other.fileSize == fileSize &&
        other.resolution == resolution &&
        other.duration == duration &&
        other.extension == extension &&
        other.rotation == rotation;
  }

  @override
  int get hashCode {
    return fileSize.hashCode ^
        resolution.hashCode ^
        duration.hashCode ^
        extension.hashCode ^
        rotation.hashCode;
  }
}
