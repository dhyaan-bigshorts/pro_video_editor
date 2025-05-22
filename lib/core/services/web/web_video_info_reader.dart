import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:web/web.dart' as web;

import '../../../shared/utils/parser/double_parser.dart';
import '../../../shared/utils/parser/int_parser.dart';
import '../../models/video/video_information_model.dart';
import '../../utils/web_blob_utils.dart';

/// A helper class that extracts video metadata in a Flutter Web environment.
///
/// This uses an [HTMLVideoElement] to read properties such as duration,
/// resolution, file size, and format directly in the browser.
class WebMetaDataReader {
  /// Reads metadata from the given [editorVideo].
  ///
  /// Optionally accepts a [fileName] (not required on web).
  /// Returns a [VideoMetadata] object containing duration, resolution,
  /// file size, and extension.
  Future<VideoMetadata> getMetaData(
    EditorVideo editorVideo, {
    String? fileName,
  }) async {
    var videoBytes = await editorVideo.safeByteArray();

    final blob = Blob.fromUint8List(videoBytes);

    final objectUrl = web.URL.createObjectURL(blob);
    final video = web.HTMLVideoElement()
      ..src = objectUrl
      ..preload = 'metadata';

    final completer = Completer<Map<String, dynamic>>();

    void cleanup() => web.URL.revokeObjectURL(objectUrl);

    var mimeType = lookupMimeType('', headerBytes: videoBytes);
    var sp = mimeType?.split('/') ?? [];
    var extension = sp.length == 2 ? sp[1] : 'mp4';

    video.onLoadedMetadata.listen((_) {
      final result = {
        'fileSize': videoBytes.length,
        'duration': video.duration * 1000, // ms
        'width': video.videoWidth,
        'height': video.videoHeight,
        'extension': extension,
        'rotation': 0,
      };
      cleanup();
      completer.complete(result);
    });

    video.onError.listen((_) {
      cleanup();
      completer.complete({'error': 'Failed to load video metadata'});
    });

    var result = await completer.future;

    return VideoMetadata(
      duration: Duration(milliseconds: safeParseInt(result['duration'])),
      extension: result['extension'] ?? 'unknown',
      fileSize: safeParseInt(result['fileSize']),
      resolution: Size(
        safeParseDouble(result['width']),
        safeParseDouble(result['height']),
      ),
      rotation: safeParseInt(result['rotation']),
    );
  }
}
