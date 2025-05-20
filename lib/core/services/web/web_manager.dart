import 'dart:typed_data';
import 'dart:ui';

import '../../models/thumbnail/key_frames_configs.model.dart';
import '/core/models/video/editor_video_model.dart';
import '/core/models/video/video_information_model.dart';
import '/core/services/web/web_thumbnail_generator.dart';
import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';
import 'web_video_info_reader.dart';

/// A platform-specific implementation for handling video operations on web.
///
/// This class provides methods to extract metadata and generate thumbnails
/// using browser capabilities.
class WebManager {
  /// Retrieves metadata from the provided [EditorVideo] on the web.
  ///
  /// Loads the video using an HTML video element and extracts duration,
  /// resolution, file size, and format.
  ///
  /// Returns a [VideoInformation] object.
  Future<VideoInformation> getVideoInformation(EditorVideo value) async {
    var result =
        await WebVideoInfoReader().processVideoWeb(await value.safeByteArray());

    return VideoInformation(
      duration: Duration(milliseconds: safeParseInt(result['duration'])),
      extension: result['format'] ?? 'unknown',
      fileSize: safeParseInt(result['fileSize']),
      resolution: Size(
        safeParseDouble(result['width']),
        safeParseDouble(result['height']),
      ),
    );
  }

  /// Generates thumbnails from a video using web-based processing.
  ///
  /// Accepts a [KeyFramesConfigs] configuration and returns a list
  /// of [Uint8List] image bytes representing the generated thumbnails.
  Future<List<Uint8List>> createVideoThumbnails(
    KeyFramesConfigs value,
  ) async {
    return await WebThumbnailGenerator().generateThumbnails(value);
  }
}
