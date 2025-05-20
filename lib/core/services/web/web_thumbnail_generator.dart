import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pro_video_editor/core/models/thumbnail/key_frames_configs.model.dart';
import 'package:pro_video_editor/core/utils/web_canvas_utils.dart';
import 'package:web/web.dart' as web;

import '../../utils/web_blob_utils.dart';

/// A utility class to generate video thumbnails in web environments.
///
/// Uses browser APIs to capture frames from a video file and return them
/// as image thumbnails.
class WebThumbnailGenerator {
  /// Generates thumbnails from a video using the given [value] parameters.
  ///
  /// The [value] should contain the video data and any configuration
  /// needed for extracting thumbnails, such as timestamps or frame count.
  ///
  /// Returns a [Future] that completes with a list of [Uint8List]
  /// objects, each representing an image thumbnail in bytes.
  Future<List<Uint8List>> generateThumbnails(KeyFramesConfigs value) async {
    var videoBytes = await value.video.safeByteArray();
    var width = value.outputSize.width.toInt();
    if (width == 0) return [];

    final blob = Blob.fromUint8List(videoBytes);
    final objectUrl = web.URL.createObjectURL(blob);

    final video = web.HTMLVideoElement()
      ..src = objectUrl
      ..crossOrigin = 'anonymous'
      ..preload = 'auto'
      ..style.display = 'none';

    web.document.body!.append(video);
    await video.onLoadedMetadata.first;

    final scale = width / video.videoWidth;
    final height = (video.videoHeight * scale).round();

    final canvas = web.HTMLCanvasElement()
      ..width = width
      ..height = height;
    final ctx = canvas.context2D;

    List<Uint8List> thumbnails = [];

    await video.onLoadedData.first;

    final totalDuration = Duration(seconds: video.duration.floor());

    /// Generate timestamps evenly spaced throughout the video
    final List<Duration> timestamps = List.generate(
      value.maxOutputFrames,
      (index) {
        final fraction = index / value.maxOutputFrames;
        return Duration(
            milliseconds: (totalDuration.inMilliseconds * fraction).round());
      },
    );

    for (final t in timestamps) {
      video.currentTime = t.inSeconds;

      await video.onSeeked.first;

      /// Short delay is important that the video frame is correctly loaded.
      /// Without that delay is the possibility high that the video frame from
      /// before is recorded again.
      await Future.delayed(const Duration(milliseconds: 1));

      ctx.drawImage(video, 0, 0, width.toDouble(), height.toDouble());

      final blob = await canvas.toBlobAsync('image/${value.outputFormat}');
      final data = await _blobToUint8List(blob);
      thumbnails.add(data);
    }

    video.remove();
    web.URL.revokeObjectURL(objectUrl);

    return thumbnails;
  }

  Future<Uint8List> _blobToUint8List(web.Blob blob) {
    final reader = web.FileReader();
    final completer = Completer<Uint8List>();

    reader.readAsArrayBuffer(blob as dynamic);
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result != null) {
        var nativeBuffer = reader.result as JSArrayBuffer;
        var dartBuffer = nativeBuffer.toDart;

        completer.complete(dartBuffer.asUint8List());
      } else {
        completer.completeError(Exception('Failed to read blob data'));
      }
    });

    return completer.future;
  }
}
