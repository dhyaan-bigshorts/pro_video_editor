import 'package:flutter/widgets.dart';

import '/core/models/video/editor_video_model.dart';
import 'thumbnail_box_fit.model.dart';
import 'thumbnail_format.model.dart';

/// Configuration model for extracting key frames from a video.
///
/// Defines video input, output size, maximum number of key frames,
/// and rendering options for the resulting thumbnails.
class KeyFramesConfigs {
  /// Creates a [KeyFramesConfigs] instance with the given settings.
  ///
  /// If [maxOutputFrames] is not provided, it defaults to unlimited.
  KeyFramesConfigs({
    required this.video,
    required this.outputSize,
    int? maxOutputFrames,
    this.outputFormat = ThumbnailFormat.jpeg,
    this.boxFit = ThumbnailBoxFit.cover,
  }) : maxOutputFrames = maxOutputFrames ??= double.infinity.toInt();

  /// The video from which key frame thumbnails will be generated.
  final EditorVideo video;

  /// The maximum number of frames to extract as thumbnails.
  ///
  /// Defaults to no limit when not specified.
  final int maxOutputFrames;

  /// The desired size of each generated key frame thumbnail.
  final Size outputSize;

  /// The format used for key frame images.
  ///
  /// Defaults to [ThumbnailFormat.jpeg].
  final ThumbnailFormat outputFormat;

  /// Determines how the video content is fit into the output size.
  ///
  /// Defaults to [ThumbnailBoxFit.cover].
  final ThumbnailBoxFit boxFit;
}
