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
    String? id,
  })  : id = id ?? DateTime.now().toString(),
        assert(
          startTime == null || endTime == null || startTime < endTime,
          'startTime must be before endTime',
        ),
        assert(
          blur == null || blur >= 0,
          'Blur must be greater than or equal to 0',
        );

  /// Unique ID for the task, useful when running multiple tasks at once.
  final String id;

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
      'id': id,
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

  /// Creates a copy with updated values.
  RenderVideoModel copyWith({
    String? id,
    VideoOutputFormat? outputFormat,
    Uint8List? videoBytes,
    Uint8List? imageBytes,
    ExportTransform? transform,
    bool? enableAudio,
    double? playbackSpeed,
    Duration? startTime,
    Duration? endTime,
    List<List<double>>? colorMatrixList,
    double? blur,
  }) {
    return RenderVideoModel(
      id: id ?? this.id,
      outputFormat: outputFormat ?? this.outputFormat,
      videoBytes: videoBytes ?? this.videoBytes,
      imageBytes: imageBytes ?? this.imageBytes,
      transform: transform ?? this.transform,
      enableAudio: enableAudio ?? this.enableAudio,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorMatrixList: colorMatrixList ?? this.colorMatrixList,
      blur: blur ?? this.blur,
    );
  }
}

/// Supported video output formats for export.
enum VideoOutputFormat {
  /// MPEG-4 Part 14, widely supported.
  mp4,

  /// WebM format, optimized for web use.
  webm,
}
