import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_editor/core/models/thumbnail/key_frames_configs.model.dart';
import 'package:pro_video_editor/core/models/thumbnail/thumbnail_configs.model.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/render_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_information_model.dart';
import 'package:pro_video_editor/pro_video_editor_method_channel.dart';
import 'package:pro_video_editor/pro_video_editor_platform_interface.dart';

class MockProVideoEditorPlatform
    with MockPlatformInterfaceMixin
    implements ProVideoEditorPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<VideoMetadata> getMetadata(EditorVideo value) {
    return Future.value(VideoMetadata(
      duration: Duration.zero,
      extension: 'mp4',
      fileSize: 1,
      resolution: Size.zero,
      rotation: 0,
    ));
  }

  @override
  Stream<double> get renderProgressStream => const Stream.empty();

  @override
  Future<Uint8List> renderVideo(RenderVideoModel value) {
    return Future.value(Uint8List(0));
  }

  @override
  Future<List<Uint8List>> getKeyFrames(KeyFramesConfigs value) {
    return Future.value([]);
  }

  @override
  Future<List<Uint8List>> getThumbnails(ThumbnailConfigs value) {
    return Future.value([]);
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
