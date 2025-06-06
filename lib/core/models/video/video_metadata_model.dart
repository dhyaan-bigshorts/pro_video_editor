import 'dart:ui';

import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';

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
    this.title = '',
    this.artist = '',
    this.author = '',
    this.album = '',
    this.albumArtist = '',
    this.date,
  });

  /// Creates a [VideoMetadata] instance from a map of data.
  ///
  /// The [value] map contains metadata values such as duration, resolution,
  /// file size, and others.
  /// The [extension] is the video file format (e.g., 'mp4').
  factory VideoMetadata.fromMap(Map<dynamic, dynamic> value, String extension) {
    return VideoMetadata(
      duration: Duration(milliseconds: safeParseInt(value['duration'])),
      extension: extension,
      fileSize: value['fileSize'] ?? 0,
      resolution: Size(
        safeParseDouble(value['width']),
        safeParseDouble(value['height']),
      ),
      rotation: safeParseInt(value['rotation']),
      bitrate: safeParseInt(value['bitrate']),
      title: value['title'] ?? '',
      artist: value['artist'] ?? '',
      author: value['author'] ?? '',
      album: value['album'] ?? '',
      albumArtist: value['albumArtist'] ?? '',
      date:
          (value['date'] ?? '') != '' ? DateTime.tryParse(value['date']) : null,
    );
  }

  /// The title of the video (e.g., the name of the movie or video).
  final String title;

  /// The artist associated with the video (e.g., the creator or performer).
  final String artist;

  /// The author of the video content.
  final String author;

  /// The album the video belongs to (if applicable).
  final String album;

  /// The album artist, typically used when the album contains works from
  /// multiple artists.
  final String albumArtist;

  /// The date when the video was created or released.
  final DateTime? date;

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
