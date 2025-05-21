import 'package:flutter/widgets.dart';

import '/core/models/video/editor_video_model.dart';
import 'thumbnail_box_fit.model.dart';
import 'thumbnail_format.model.dart';

/// Configuration model for generating video thumbnails.
///
/// Defines the video source, output size, desired timestamps,
/// and thumbnail rendering options.
class ThumbnailConfigs {
  /// Creates a [ThumbnailConfigs] instance with the given parameters.
  ///
  /// Requires a video source, output size, and at least one timestamp.
  ThumbnailConfigs({
    required this.video,
    required this.outputSize,
    required this.timestamps,
    this.outputFormat = ThumbnailFormat.jpeg,
    this.boxFit = ThumbnailBoxFit.cover,
  });

  /// The video from which thumbnails will be generated.
  final EditorVideo video;

  /// A list of timestamps to capture thumbnails from.
  final List<Duration> timestamps;

  /// The desired size of each generated thumbnail.
  final Size outputSize;

  /// The format used for thumbnail images.
  ///
  /// Defaults to [ThumbnailFormat.jpeg].
  final ThumbnailFormat outputFormat;

  /// Determines how the video content is fit into the thumbnail size.
  ///
  /// Defaults to [ThumbnailBoxFit.cover].
  final ThumbnailBoxFit boxFit;
}
