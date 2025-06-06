import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor/pro_video_editor_method_channel.dart';

import 'pro_video_editor_method_channel_test.mocks.dart';

@GenerateMocks([
  EditorVideo,
  ThumbnailConfigs,
  KeyFramesConfigs,
  RenderVideoModel,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelProVideoEditor platform = MethodChannelProVideoEditor();
  const MethodChannel channel = MethodChannel('pro_video_editor');
  final mockBytes = Uint8List.fromList([0x00, 0x01]);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getPlatformVersion':
          return '42';
        case 'getMetadata':
          return {
            'duration': 1200,
            'width': 1920,
            'height': 1080,
            'rotation': 90,
            'extension': 'mp4',
          };
        case 'getThumbnails':
          return [mockBytes, mockBytes];
        case 'renderVideo':
          return Uint8List(10);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getMetadata returns correct metadata', () async {
    final mockVideo = MockEditorVideo();
    when(mockVideo.safeByteArray()).thenAnswer((_) async => mockBytes);

    final result = await platform.getMetadata(mockVideo);

    expect(result.duration.inMilliseconds, 1200);
    expect(result.resolution.width, 1920);
    expect(result.resolution.height, 1080);
    expect(result.rotation, 90);
    expect(result.extension, 'mp4');
  });

  test('getThumbnails returns list of Uint8List', () async {
    final mockConfig = MockThumbnailConfigs();
    final mockVideo = MockEditorVideo();

    when(mockConfig.video).thenReturn(mockVideo);
    when(mockConfig.toMap()).thenReturn({});
    when(mockVideo.safeByteArray()).thenAnswer((_) async => mockBytes);

    final thumbnails = await platform.getThumbnails(mockConfig);
    expect(thumbnails.length, 2);
    expect(thumbnails[0], isA<Uint8List>());
  });

  test('getKeyFrames returns list of Uint8List', () async {
    final mockConfig = MockKeyFramesConfigs();
    final mockVideo = MockEditorVideo();

    when(mockConfig.video).thenReturn(mockVideo);
    when(mockConfig.toMap()).thenReturn({});
    when(mockVideo.safeByteArray()).thenAnswer((_) async => mockBytes);

    final keyframes = await platform.getKeyFrames(mockConfig);
    expect(keyframes.length, 2);
    expect(keyframes[1], isA<Uint8List>());
  });

  test('renderVideo returns rendered video bytes', () async {
    final mockModel = MockRenderVideoModel();
    final mockVideo = MockEditorVideo();

    when(mockModel.video).thenReturn(mockVideo);
    when(mockModel.toAsyncMap()).thenAnswer((_) async => {});
    when(mockVideo.safeByteArray()).thenAnswer((_) async => mockBytes);

    final result = await platform.renderVideo(mockModel);
    expect(result, isA<Uint8List>());
    expect(result.length, 10);
  });

  test('renderVideo throws if result is null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });

    final mockModel = MockRenderVideoModel();
    final mockVideo = MockEditorVideo();

    when(mockModel.video).thenReturn(mockVideo);
    when(mockModel.toAsyncMap()).thenAnswer((_) async => {});
    when(mockVideo.safeByteArray()).thenAnswer((_) async => mockBytes);

    expect(
        () async => await platform.renderVideo(mockModel), throwsArgumentError);
  });
}
