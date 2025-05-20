import 'package:flutter/widgets.dart';

import '/core/models/video/editor_video_model.dart';
import 'thumbnail_box_fit.model.dart';
import 'thumbnail_format.model.dart';

class KeyFramesConfigs {
  KeyFramesConfigs({
    required this.video,
    required this.outputSize,
    int? maxOutputFrames,
    this.outputFormat = ThumbnailFormat.jpeg,
    this.boxFit = ThumbnailBoxFit.cover,
  }) : maxOutputFrames = maxOutputFrames ??= double.infinity.toInt();

  /// The video from which thumbnails will be generated.
  final EditorVideo video;

  /// The maximum number of frames to extract as thumbnails.
  final int maxOutputFrames;

  final Size outputSize;

  final ThumbnailFormat outputFormat;

  final ThumbnailBoxFit boxFit;
}
