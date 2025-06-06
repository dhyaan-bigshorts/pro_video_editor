import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor_example/core/constants/example_constants.dart';
import 'package:pro_video_editor_example/core/constants/example_filters.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final inputVideo = EditorVideo.asset(kVideoEditorExampleAssetPath);
  final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

  Future<VideoMetadata> testRender({
    required String description,
    required RenderVideoModel renderModel,
  }) async {
    final result = await ProVideoEditor.instance.renderVideo(renderModel);
    expect(result, isNotNull, reason: '$description failed — result is null');
    expect(result.lengthInBytes, greaterThan(100000),
        reason: '$description failed — video is too small');

    // Optionally validate resulting metadata
    final meta = await ProVideoEditor.instance.getMetadata(
      EditorVideo.memory(result),
    );
    expect(
      meta.extension,
      equals(renderModel.outputFormat.name),
      reason: '$description — wrong format',
    );

    return meta;
  }

  Future<void> testFormat({
    required VideoOutputFormat format,
    required String description,
  }) async {
    final result = await ProVideoEditor.instance.renderVideo(
      RenderVideoModel(
        video: inputVideo,
        outputFormat: format,
      ),
    );

    expect(result, isNotNull, reason: '$description failed — result is null');
    expect(result.lengthInBytes, greaterThan(100000),
        reason: '$description failed — video too small');

    final meta = await ProVideoEditor.instance.getMetadata(
      EditorVideo.memory(result),
    );

    expect(meta.extension, equals(format.name),
        reason: '$description — unexpected file format');
  }

  testWidgets('Export in mp4', (_) async {
    await testFormat(format: VideoOutputFormat.mp4, description: 'mp4 export');
  });

  /* testWidgets('Export in webm (Android)', (_) async {
    await testFormat(
        format: VideoOutputFormat.webm, description: 'Android webm export');
  }, skip: !isAndroid); */

  testWidgets('Export in mov (Apple)', (_) async {
    await testFormat(
        format: VideoOutputFormat.mov, description: 'iOS/macOS mov export');
  }, skip: !isIOS && !isMacOS);

  testWidgets('rotate 90°', (tester) async {
    var meta = await testRender(
      description: 'Rotate 90°',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        transform: const ExportTransform(rotateTurns: 1),
      ),
    );
    expect(meta.rotation, 90);
  });

  testWidgets('flip horizontally and vertically', (tester) async {
    await testRender(
      description: 'Flip X/Y',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        transform: const ExportTransform(flipX: true, flipY: true),
      ),
    );
  });

  testWidgets('crop video', (tester) async {
    var size = const Size(700, 300);
    var meta = await testRender(
      description: 'Crop (700x300)',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        transform: ExportTransform(
          x: 100,
          y: 250,
          width: size.width.toInt(),
          height: size.height.toInt(),
        ),
      ),
    );
    expect(meta.resolution, size);
  });

  testWidgets('scale video down', (tester) async {
    const factor = 5.0;

    final originalMeta = await ProVideoEditor.instance.getMetadata(inputVideo);
    var meta = await testRender(
      description: 'Scale 0.2x',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        transform:
            const ExportTransform(scaleX: 1 / factor, scaleY: 1 / factor),
      ),
    );
    expect(originalMeta.resolution / factor, meta.resolution);
  });

  testWidgets('trim video (7s - 20s)', (tester) async {
    var meta = await testRender(
      description: 'Trim 7s to 20s',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        startTime: const Duration(seconds: 7),
        endTime: const Duration(seconds: 20),
      ),
    );
    expect(meta.duration.inSeconds, 13);
  });

  testWidgets('change speed to 2x', (tester) async {
    const speed = 2.0;

    final originalMeta = await ProVideoEditor.instance.getMetadata(inputVideo);
    var meta = await testRender(
      description: 'Speed x2',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        playbackSpeed: speed,
      ),
    );
    expect(
      meta.duration.inSeconds,
      (originalMeta.duration.inSeconds / speed).floor(),
    );
  });

  testWidgets('remove audio', (tester) async {
    await testRender(
      description: 'Audio removed',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        enableAudio: false,
      ),
    );
  });

  testWidgets('apply color matrix', (tester) async {
    await testRender(
      description: 'Color filter applied',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        colorMatrixList: kComplexFilterMatrix,
      ),
    );
  });

  testWidgets('apply blur', (tester) async {
    await testRender(
      description: 'Apply blur',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        blur: 5,
      ),
    );
  });

  testWidgets('set bitrate', (tester) async {
    await testRender(
      description: 'Bitrate set to 1Mbps',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        bitrate: 1000000,
      ),
    );
  });

  testWidgets('combine multiple changes', (tester) async {
    await testRender(
      description: 'Multiple transformations',
      renderModel: RenderVideoModel(
        video: inputVideo,
        outputFormat: VideoOutputFormat.mp4,
        transform: const ExportTransform(flipX: true),
        colorMatrixList: kBasicFilterMatrix,
        enableAudio: false,
        endTime: const Duration(seconds: 20),
      ),
    );
  });

  testWidgets('progress stream updates during rendering', (tester) async {
    final List<double> progressValues = [];

    var task = RenderVideoModel(
      video: inputVideo,
      outputFormat: VideoOutputFormat.mp4,
      // Using something non-trivial to make rendering take time
      playbackSpeed: 0.5,
    );

    final sub = task.progressStream.listen((progress) {
      progressValues.add(progress.progress);
    });

    await ProVideoEditor.instance.renderVideo(task);

    await sub.cancel();

    expect(progressValues, isNotEmpty, reason: 'No progress updates received');
    expect(progressValues.first, lessThanOrEqualTo(0.1),
        reason: 'Progress didn’t start at low value');
    expect(progressValues.last, closeTo(1.0, 0.05),
        reason: 'Progress didn’t reach 100%');
    expect(progressValues, isA<List<double>>());
    expect(
      List.from(progressValues)..sort(),
      progressValues,
      reason: 'Progress should be monotonically increasing',
    );
  });
}
