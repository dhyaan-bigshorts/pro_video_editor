import 'package:flutter/widgets.dart';

import '/core/models/video/editor_video_model.dart';
import 'thumbnail_box_fit.model.dart';
import 'thumbnail_format.model.dart';

class ThumbnailConfigs {
  ThumbnailConfigs({
    required this.video,
    required this.outputSize,
    required this.timestamps,
    this.outputFormat = ThumbnailFormat.jpeg,
    this.boxFit = ThumbnailBoxFit.cover,
  });

  /// The video from which thumbnails will be generated.
  final EditorVideo video;

  final List<Duration> timestamps;

  final Size outputSize;

  final ThumbnailFormat outputFormat;

  final ThumbnailBoxFit boxFit;
}
