import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/pro_video_editor_platform_interface.dart';
import 'package:pro_video_editor_example/core/constants/example_constants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plugin getMetadata returns correct values', (tester) async {
    final video = EditorVideo.asset(kVideoEditorExampleAssetPath);

    // Ensure bytes are preloaded to exclude loading overhead from the trace
    await video.safeByteArray();

    final metadata = await ProVideoEditor.instance.getMetadata(video);

    expect(metadata.duration.inSeconds, equals(29));
    expect(metadata.resolution, equals(const Size(1280.0, 720.0)));
    expect(metadata.extension, equals('mp4'));
    expect(metadata.rotation, equals(0));
    expect(metadata.bitrate, equals(1421504));
    expect(metadata.fileSize, equals(5253880));
  });
}
