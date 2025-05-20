import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'core/models/thumbnail/key_frames_configs.model.dart';
import '/core/models/video/editor_video_model.dart';
import '/core/models/video/export_video_model.dart';
import '/core/models/video/video_information_model.dart';
import 'core/models/thumbnail/thumbnail_configs.model.dart';
import 'pro_video_editor_method_channel.dart';

/// An abstract class that defines the platform interface for the
/// Pro Video Editor plugin.
abstract class ProVideoEditorPlatform extends PlatformInterface {
  /// Constructs a ProVideoEditorPlatform.
  ProVideoEditorPlatform() : super(token: _token);

  static final Object _token = Object();

  static ProVideoEditorPlatform _instance = MethodChannelProVideoEditor();

  /// The default instance of [ProVideoEditorPlatform] to use.
  ///
  /// Defaults to [MethodChannelProVideoEditor].
  static ProVideoEditorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ProVideoEditorPlatform] when
  /// they register themselves.
  static set instance(ProVideoEditorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves the platform version.
  ///
  /// Throws an [UnimplementedError] if not implemented.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Fetches information about a video.
  ///
  /// Throws an [UnimplementedError] if not implemented.
  Future<VideoInformation> getVideoInformation(EditorVideo value) {
    throw UnimplementedError('getVideoInformation() has not been implemented.');
  }

  Future<List<Uint8List>> getThumbnails(ThumbnailConfigs value) {
    throw UnimplementedError('getThumbnails() has not been implemented.');
  }

  Future<List<Uint8List>> getKeyFrames(KeyFramesConfigs value) {
    throw UnimplementedError('getKeyFrames() has not been implemented.');
  }

  /// Exports a video using the given [value] configuration.
  ///
  /// Delegates the export to the platform-specific implementation and returns
  /// the resulting video bytes.
  Future<Uint8List> exportVideo(ExportVideoModel value) {
    throw UnimplementedError('exportVideo() has not been implemented.');
  }

  /// A stream that emits export progress updates as a double from 0.0 to 1.0.
  ///
  /// Useful for showing progress indicators during the export process.
  Stream<double> get exportProgressStream {
    throw UnimplementedError('exportProgressStream has not been implemented.');
  }
}
