import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_editor/core/models/thumbnail/key_frames_configs.model.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/export_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_information_model.dart';
import 'package:pro_video_editor/pro_video_editor_method_channel.dart';
import 'package:pro_video_editor/pro_video_editor_platform_interface.dart';

class MockProVideoEditorPlatform
    with MockPlatformInterfaceMixin
    implements ProVideoEditorPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<Uint8List>> createVideoThumbnails(KeyFramesConfigs value) {
    return Future.value([]);
  }

  @override
  Future<VideoInformation> getVideoInformation(EditorVideo value) {
    return Future.value(VideoInformation(
      duration: Duration.zero,
      extension: 'mp4',
      fileSize: 1,
      resolution: Size.zero,
    ));
  }

  @override
  Stream<double> get exportProgressStream => const Stream.empty();

  @override
  Future<Uint8List> exportVideo(ExportVideoModel value) {
    return Future.value(Uint8List(0));
  }
}

void main() {
  final ProVideoEditorPlatform initialPlatform =
      ProVideoEditorPlatform.instance;

  test('$MethodChannelProVideoEditor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelProVideoEditor>());
  });

  /*  test('getPlatformVersion', () async {
    ProVideoEditor proVideoEditorPlugin = ProVideoEditor();
    MockProVideoEditorPlatform fakePlatform = MockProVideoEditorPlatform();
    ProVideoEditorPlatform.instance = fakePlatform;

    expect(await proVideoEditorPlugin.getPlatformVersion(), '42');
  }); */
}
