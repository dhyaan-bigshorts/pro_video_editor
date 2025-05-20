import 'package:flutter/material.dart';
import 'package:pro_video_editor/core/models/video/editor_video_model.dart';
import 'package:pro_video_editor/core/models/video/video_information_model.dart';
import 'package:pro_video_editor/core/services/video_utils_service.dart';
import 'package:pro_video_editor_example/core/constants/example_constants.dart';

import '../../shared/utils/bytes_formatter.dart';

class VideoInformationExamplePage extends StatefulWidget {
  const VideoInformationExamplePage({super.key});

  @override
  State<VideoInformationExamplePage> createState() =>
      _VideoInformationExamplePageState();
}

class _VideoInformationExamplePageState
    extends State<VideoInformationExamplePage> {
  VideoInformation? _informations;

  Future<void> _setVideoInformation() async {
    _informations = await VideoUtilsService.instance.getVideoInformation(
      EditorVideo(assetPath: kVideoEditorExampleAssetPath),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video-Informations')),
      body: ListView(
        children: [
          ListTile(
            onTap: _setVideoInformation,
            leading: const Icon(Icons.find_in_page_outlined),
            title: const Text('Read video informations'),
          ),
          if (_informations != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FlexColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text('FileSize:'),
                      ),
                      Text(formatBytes(_informations!.fileSize)),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text('Format:'),
                      ),
                      Text(_informations!.extension),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text('Resolution:'),
                      ),
                      Text(_informations!.resolution.toString()),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Text('Duration:'),
                      ),
                      Text('${_informations!.duration.inSeconds}s'),
                    ],
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}
