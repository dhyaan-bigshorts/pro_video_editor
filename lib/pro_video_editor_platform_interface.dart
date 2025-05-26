import 'dart:async';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '/core/models/video/editor_video_model.dart';
import 'core/models/thumbnail/key_frames_configs.model.dart';
import 'core/models/thumbnail/thumbnail_configs.model.dart';
import 'core/models/video/progress_model.dart';
import 'core/models/video/render_video_model.dart';
import 'core/models/video/video_metadata_model.dart';
import 'pro_video_editor_method_channel.dart';

/// An abstract class that defines the platform interface for the
/// Pro Video Editor plugin.
abstract class ProVideoEditorPlatform extends PlatformInterface {
  /// Constructs a ProVideoEditorPlatform.
  ProVideoEditorPlatform() : super(token: _token) {
    initializeStream();
  }

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

  /// Fetches metadata about the video.
  ///
  /// Throws an [UnimplementedError] if not implemented.
  Future<VideoMetadata> getMetadata(EditorVideo value) {
    throw UnimplementedError('getMetadata() has not been implemented.');
  }

  /// Returns a list of video thumbnails based on the provided
  /// [ThumbnailConfigs].
  Future<List<Uint8List>> getThumbnails(ThumbnailConfigs value) {
    throw UnimplementedError('getThumbnails() has not been implemented.');
  }

  /// Returns a list of key frames extracted from a video using
  /// [KeyFramesConfigs].
  Future<List<Uint8List>> getKeyFrames(KeyFramesConfigs value) {
    throw UnimplementedError('getKeyFrames() has not been implemented.');
  }

  /// Exports a video using the given [value] configuration.
  ///
  /// Delegates the export to the platform-specific implementation and returns
  /// the resulting video bytes.
  Future<Uint8List> renderVideo(RenderVideoModel value) {
    throw UnimplementedError('renderVideo() has not been implemented.');
  }

  /// Sets up the native progress stream connection.
  ///
  /// Must be implemented to receive progress updates from native code.
  void initializeStream() {
    throw UnimplementedError('[initializeStream()] has not been implemented.');
  }

  /// Emits progress updates for running tasks.
  final progressCtrl = StreamController<ProgressModel>.broadcast();

  /// Stream of progress updates.
  Stream<ProgressModel> get progressStream => progressCtrl.stream;
}
