import 'dart:typed_data';

import 'package:pro_video_editor/core/models/video/render_video_model.dart';

import '/core/models/video/editor_video_model.dart';
import '/core/models/video/video_information_model.dart';
import '/pro_video_editor_platform_interface.dart';
import '../models/thumbnail/key_frames_configs.model.dart';
import '../models/thumbnail/thumbnail_configs.model.dart';

/// A utility service for video-related operations.
///
/// This service provides a singleton interface for accessing platform-level
/// functionality such as retrieving video metadata and generating thumbnails.
class VideoUtilsService {
  /// Private constructor for singleton pattern.
  VideoUtilsService._();

  /// The singleton instance of [VideoUtilsService].
  static final VideoUtilsService instance = VideoUtilsService._();

  /// Gets the platform version from the underlying implementation.
  ///
  /// Useful for debugging or displaying platform-specific information.
  Future<String?> getPlatformVersion() {
    return ProVideoEditorPlatform.instance.getPlatformVersion();
  }

  /// Retrieves detailed information about the given video.
  ///
  /// [value] is an [EditorVideo] instance that can point to a file, memory,
  /// network URL, or asset.
  ///
  /// Returns a [Future] containing [VideoMetadata] about the video.
  Future<VideoMetadata> getMetadata(EditorVideo value) {
    return ProVideoEditorPlatform.instance.getMetadata(value);
  }

  /// Generates a list of thumbnails from the given [ThumbnailConfigs].
  Future<List<Uint8List>> getThumbnails(ThumbnailConfigs value) {
    return ProVideoEditorPlatform.instance.getThumbnails(value);
  }

  /// Extracts key frames from a video using the given [KeyFramesConfigs].
  Future<List<Uint8List>> getKeyFrames(KeyFramesConfigs value) {
    return ProVideoEditorPlatform.instance.getKeyFrames(value);
  }

  /// Renders a video using the provided [RenderVideoModel] configuration.
  Future<Uint8List> renderVideo(RenderVideoModel value) {
    return ProVideoEditorPlatform.instance.renderVideo(value);
  }

  /// A stream that emits export progress updates as a double from 0.0 to 1.0.
  ///
  /// Useful for showing progress indicators during the export process.
  Stream<double> get exportProgressStream {
    return ProVideoEditorPlatform.instance.renderProgressStream;
  }
}
