import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '/core/models/video/editor_video_model.dart';
import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';
import 'core/models/thumbnail/key_frames_configs.model.dart';
import 'core/models/thumbnail/thumbnail_base.abstract.dart';
import 'core/models/thumbnail/thumbnail_configs.model.dart';
import 'core/models/video/progress_model.dart';
import 'core/models/video/render_video_model.dart';
import 'core/models/video/video_information_model.dart';
import 'pro_video_editor_platform_interface.dart';

/// An implementation of [ProVideoEditorPlatform] that uses method channels.
class MethodChannelProVideoEditor extends ProVideoEditorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pro_video_editor');
  final _progressChannel = const EventChannel('pro_video_editor_progress');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<VideoMetadata> getMetadata(EditorVideo value) async {
    var videoBytes = await value.safeByteArray();

    var extension = _getFileExtension(videoBytes);

    final response =
        await methodChannel.invokeMethod<Map<dynamic, dynamic>>('getMetadata', {
              'videoBytes': videoBytes,
              'extension': extension,
            }) ??
            {};

    return VideoMetadata(
      duration: Duration(milliseconds: safeParseInt(response['duration'])),
      extension: extension,
      fileSize: response['fileSize'] ?? 0,
      resolution: Size(
        safeParseDouble(response['width']),
        safeParseDouble(response['height']),
      ),
      rotation: safeParseInt(response['rotation']),
    );
  }

  Future<List<Uint8List>> _extractThumbnails(ThumbnailBase value) async {
    var videoBytes = await value.video.safeByteArray();

    final response = await methodChannel.invokeMethod<List<dynamic>>(
      'getThumbnails',
      {
        'videoBytes': videoBytes,
        'extension': _getFileExtension(videoBytes),
        ...value.toMap(),
      },
    );
    final List<Uint8List> result = response?.cast<Uint8List>() ?? [];

    return result;
  }

  @override
  Future<List<Uint8List>> getThumbnails(ThumbnailConfigs value) async {
    return await _extractThumbnails(value);
  }

  @override
  Future<List<Uint8List>> getKeyFrames(KeyFramesConfigs value) async {
    return await _extractThumbnails(value);
  }

  @override
  Future<Uint8List> renderVideo(RenderVideoModel value) async {
    var extension = lookupMimeType('', headerBytes: value.videoBytes);
    String inputFormat = 'mp4';
    List<String>? sp = extension?.split('/');
    if (sp?.length == 1) inputFormat = sp![1];

    final Uint8List? result = await methodChannel.invokeMethod<Uint8List>(
      'renderVideo',
      {
        ...value.toMap(),
        'inputFormat': inputFormat,
      },
    );

    if (result == null) {
      throw ArgumentError('Failed to export the video');
    }

    return result;
  }

  @override
  void initializeStream() {
    _progressChannel.receiveBroadcastStream().map((event) {
      try {
        return ProgressModel.fromMap(event);
      } catch (e, stack) {
        debugPrint('Error in fromMap: $e\n$stack');
        return const ProgressModel(id: 'error', progress: 0);
      }
    }).listen(progressCtrl.add);
  }

  String _getFileExtension(Uint8List videoBytes) {
    var mimeType = lookupMimeType('', headerBytes: videoBytes);
    var mimeSp = mimeType?.split('/') ?? [];
    var extension = mimeSp.length == 2 ? mimeSp[1] : 'mp4';

    return extension;
  }
}
