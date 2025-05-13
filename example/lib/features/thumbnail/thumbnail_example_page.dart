import 'package:flutter/material.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor_example/core/constants/example_constants.dart';
import 'package:pro_video_editor_example/shared/utils/bytes_formatter.dart';

/// A sample page demonstrating video thumbnail generation on the web.
///
/// This widget is intended to showcase how to use the
/// [WebThumbnailGenerator] to extract and display video thumbnails.
class ThumbnailExamplePage extends StatefulWidget {
  /// Creates a [ThumbnailExamplePage].
  const ThumbnailExamplePage({super.key});

  @override
  State<ThumbnailExamplePage> createState() => _ThumbnailExamplePageState();
}

class _ThumbnailExamplePageState extends State<ThumbnailExamplePage> {
  List<MemoryImage> _thumbnails = [];

  final int _exampleImageCount = 10;
  final double _imageSize = 50;
  final ThumbnailFormat _thumbnailFormat = ThumbnailFormat.jpeg;
  VideoInformation? _informations;

  Future<void> _setVideoInformation() async {
    _informations = await VideoUtilsService.instance.getVideoInformation(
      EditorVideo(assetPath: kVideoEditorExampleAssetPath),
    );
    setState(() {});
  }

  void _generateThumbnails() async {
    if (_informations == null) {
      await _setVideoInformation();
    }
    var info = _informations!;

    if (!mounted) return;

    var raw = await VideoUtilsService.instance.createVideoThumbnails(
      CreateVideoThumbnail(
        video: EditorVideo(assetPath: kVideoEditorExampleAssetPath),
        format: _thumbnailFormat,
        thumbnailLimit: _exampleImageCount,
        imageWidth: _imageSize *
            MediaQuery.devicePixelRatioOf(context) *
            info.resolution.aspectRatio,
      ),
    );

    _thumbnails = raw.map(MemoryImage.new).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnails')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Center(
            child: FilledButton(
              onPressed: _setVideoInformation,
              child: const Text('Log video informations'),
            ),
          ),
          const SizedBox(height: 16),
          if (_informations != null)
            Column(
              children: [
                Text('FileSize: ${formatBytes(_informations!.fileSize)}'),
                Text('Format: ${_informations!.extension}'),
                Text('Resolution: ${_informations!.resolution}'),
                Text('Duration: ${_informations!.duration.inMilliseconds}ms'),
              ],
            ),
          const SizedBox(height: 40),
          Center(
            child: FilledButton(
              onPressed: _generateThumbnails,
              child: const Text('Generate Thumbnails'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _thumbnails
                .map(
                  (item) => Container(
                    width: _imageSize,
                    height: _imageSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Image(image: item, fit: BoxFit.cover),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
