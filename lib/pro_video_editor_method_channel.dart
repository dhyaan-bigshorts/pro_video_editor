import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '/core/models/thumbnail/export_video_model.dart';
import '/core/models/video/editor_video_model.dart';
import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';
import 'core/models/thumbnail/create_video_thumbnail_model.dart';
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
  Future<VideoInformation> getVideoInformation(EditorVideo value) async {
    var videoBytes = await value.safeByteArray();

    var extension = _getFileExtension(videoBytes);

    final response = await methodChannel
            .invokeMethod<Map<dynamic, dynamic>>('getVideoInformation', {
          'videoBytes': videoBytes,
          'extension': extension,
        }) ??
        {};

    return VideoInformation(
      duration: Duration(milliseconds: safeParseInt(response['duration'])),
      extension: extension,
      fileSize: response['fileSize'] ?? 0,
      resolution: Size(
        safeParseDouble(response['width']),
        safeParseDouble(response['height']),
      ),
    );
  }

  @override
  Future<List<Uint8List>> createVideoThumbnails(
      CreateVideoThumbnail value) async {
    var videoBytes = await value.video.safeByteArray();

    final response = await methodChannel.invokeMethod<List<dynamic>>(
      'createVideoThumbnails',
      {
        'videoBytes': videoBytes,
        'timestamps': value.timestamps.map((el) => el.inMilliseconds).toList(),
        'imageWidth': value.imageWidth,
        'thumbnailFormat': value.format.name,
        'extension': _getFileExtension(videoBytes),
      },
    );
    final List<Uint8List> thumbnails = response?.cast<Uint8List>() ?? [];

    return thumbnails;
  }

  @override
  Future<Uint8List> exportVideo(ExportVideoModel value) async {
    final Uint8List? result = await methodChannel.invokeMethod<Uint8List>(
      'exportVideo',
      {
        'videoBytes': value.videoBytes,
        'imageBytes': value.imageBytes,
        'outputFormat': value.outputFormat.name,
        'videoDuration': value.videoDuration.inMilliseconds,
        'constantRateFactor': value.constantRateFactor,
        'encodingPreset': value.encodingPreset.name,
      },
    );

    if (result == null) {
      throw ArgumentError('Failed to export the video');
    }

    return result;
  }

  @override
  Stream<double> get exportProgressStream {
    return _progressChannel
        .receiveBroadcastStream()
        .map((event) => event as double);
  }

  String _getFileExtension(Uint8List videoBytes) {
    var mimeType = lookupMimeType('', headerBytes: videoBytes);
    var mimeSp = mimeType?.split('/') ?? [];
    var extension = mimeSp.length == 2 ? mimeSp[1] : 'mp4';

    return extension;
  }
}
