// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pro_video_editor/core/services/web/web_manager.dart';
import 'package:web/web.dart' as web;

import 'core/models/thumbnail/key_frames_configs.model.dart';
import 'core/models/video/editor_video_model.dart';
import 'core/models/video/video_information_model.dart';
import 'pro_video_editor_platform_interface.dart';

/// A web implementation of the ProVideoEditorPlatform of the ProVideoEditor
/// plugin.
class ProVideoEditorWeb extends ProVideoEditorPlatform {
  /// Constructs a ProVideoEditorWeb
  ProVideoEditorWeb();

  final WebManager _manager = WebManager();

  /// Registers the web implementation of the ProVideoEditor platform interface.
  static void registerWith(Registrar registrar) {
    ProVideoEditorPlatform.instance = ProVideoEditorWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<VideoInformation> getVideoInformation(EditorVideo value) async {
    return _manager.getVideoInformation(value);
  }

  @override
  Future<List<Uint8List>> createVideoThumbnails(KeyFramesConfigs value) {
    return _manager.createVideoThumbnails(value);
  }
}
