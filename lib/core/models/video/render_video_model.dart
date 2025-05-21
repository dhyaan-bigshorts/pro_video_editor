import 'package:flutter/foundation.dart';

import '/core/models/video/export_transform_model.dart';

/// A model describing settings for rendering or exporting a video.
///
/// Includes input video data, optional overlays, transformations,
/// color filters, audio options, playback settings, and output format.
class RenderVideoModel {
  /// Creates a [RenderVideoModel] with the given parameters.
  RenderVideoModel({
    required this.outputFormat,
    required this.videoBytes,
    this.imageBytes,
    this.transform = const ExportTransform(),
    this.enableAudio = true,
    this.playbackSpeed,
    this.startTime,
    this.endTime,
    this.blur,
    this.colorMatrixList = const [],
  })  : assert(
          startTime == null || endTime == null || startTime < endTime,
          'startTime must be before endTime',
        ),
        assert(
          blur == null || blur >= 0,
          'Blur must be greater than or equal to 0',
        );

  /// The target format for the exported video.
  final VideoOutputFormat outputFormat;

  /// The original video data in bytes.
  final Uint8List videoBytes;

  /// A transparent image which will overlay the video.
  final Uint8List? imageBytes;

  /// Transformation settings like resize, rotation, offset, and flipping.
  ///
  /// Used to control how the video or image is positioned and modified during
  /// export.
  final ExportTransform transform;

  /// Whether to include audio in the exported video.
  ///
  /// **Default**: `true`
  final bool enableAudio;

  /// Playback speed of the exported video.
  ///
  /// For example, `0.5` for half speed, `2.0` for double speed.
  final double? playbackSpeed;

  /// Optional start time for trimming the video.
  final Duration? startTime;

  /// Optional end time for trimming the video.
  final Duration? endTime;

  /// A 4x5 matrix used to apply color filters (e.g., saturation, brightness).
  final List<List<double>> colorMatrixList;

  /// Amount of blur to apply.
  ///
  /// Higher values result in a stronger blur effect.
  final double? blur;

  /// Converts the model into a serializable map.
  Map<String, dynamic> toMap() {
    return {
      'videoBytes': videoBytes,
      'imageBytes': imageBytes,
      'rotateTurns': transform.rotateTurns,
      'flipX': transform.flipX,
      'flipY': transform.flipY,
      'enableAudio': enableAudio,
      'playbackSpeed': playbackSpeed,
      'startTime': startTime?.inMicroseconds,
      'endTime': endTime?.inMicroseconds,
      'cropWidth': transform.width,
      'cropHeight': transform.height,
      'cropX': transform.x,
      'cropY': transform.y,
      'scaleX': transform.scaleX,
      'scaleY': transform.scaleY,
      'colorMatrixList': colorMatrixList,
      'outputFormat': outputFormat.name,
      'blur': blur,
    };
  }
}

/// Supported video output formats for export.
///
/// These formats are passed to FFmpeg using the appropriate container flags.
/// The compatibility of each format may vary by platform and codec support.
enum VideoOutputFormat {
  /// MPEG-4 Part 14, widely supported.
  mp4,

  /// WebM format, optimized for web use.
  webm,
}
