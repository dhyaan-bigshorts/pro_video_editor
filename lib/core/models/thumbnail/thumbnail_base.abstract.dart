import 'package:flutter/widgets.dart';

import '../../../pro_video_editor_platform_interface.dart';
import '../video/editor_video_model.dart';
import '../video/progress_model.dart';
import 'thumbnail_box_fit.model.dart';
import 'thumbnail_format.model.dart';

/// Base model for thumbnail generation tasks.
///
/// Defines the video input, output size, image format, and box fit options.
abstract class ThumbnailBase {
  /// Creates a base thumbnail model.
  ThumbnailBase({
    required this.video,
    required this.outputSize,
    this.outputFormat = ThumbnailFormat.jpeg,
    this.boxFit = ThumbnailBoxFit.cover,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Unique ID for the task, useful when running multiple tasks at once.
  final String id;

  /// The video from which thumbnails will be generated.
  final EditorVideo video;

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

  /// Converts the model into a serializable map.
  Map<String, dynamic> toMap();

  /// Returns a [Stream] of [ProgressModel] objects that provides updates on
  /// the progress of the generation associated with this model's [id].
  ///
  /// The stream is obtained from the [ProVideoEditor] singleton instance and
  /// is specific to the current video's identifier.
  Stream<ProgressModel> get progressStream {
    return ProVideoEditor.instance.progressStreamById(id);
  }
}
