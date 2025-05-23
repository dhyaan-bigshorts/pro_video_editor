import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:video_player/video_player.dart';

import '/core/constants/example_constants.dart';
import '/features/editor/widgets/video_initializing_widget.dart';
import 'widgets/preview_video.dart';
import 'widgets/video_progress_alert.dart';

/// A sample page demonstrating how to use the video-editor.
class VideoEditorPage extends StatefulWidget {
  /// Creates a [VideoEditorPage] widget.
  const VideoEditorPage({super.key});

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  /// The target format for the exported video.
  final _outputFormat = VideoOutputFormat.mp4;

  /// Video editor configuration settings.
  late final VideoEditorConfigs _videoConfigs = const VideoEditorConfigs(
    initialMuted: true,
    initialPlay: false,
    isAudioSupported: true,
    minTrimDuration: Duration(seconds: 7),
  );

  /// Indicates whether a seek operation is in progress.
  bool _isSeeking = false;

  /// Stores the currently selected trim duration span.
  TrimDurationSpan? _durationSpan;

  /// Temporarily stores a pending trim duration span.
  TrimDurationSpan? _tempDurationSpan;

  /// Controls video playback and trimming functionalities.
  ProVideoController? _proVideoController;

  /// Stores generated thumbnails for the trimmer bar and filter background.
  List<ImageProvider>? _thumbnails;

  /// Holds information about the selected video.
  ///
  /// This will be populated via [setMetadata].
  late VideoMetadata _videoMetadata;

  /// Number of thumbnails to generate across the video timeline.
  final int _thumbnailCount = 10;

  /// The video currently loaded in the editor.
  final _video = EditorVideo(assetPath: kVideoEditorExampleAssetPath);

  /// The result of the video export process, if completed.
  Uint8List? _exportedVideo;

  /// The duration it took to generate the exported video.
  Duration _videoGenerationTime = Duration.zero;
  late VideoPlayerController _videoController;

  String _taskId = DateTime.now().toString();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  /// Loads and sets [_videoMetadata] for the given [_video].
  Future<void> setMetadata() async {
    _videoMetadata = await VideoUtilsService.instance.getMetadata(_video);
  }

  /// Generates thumbnails for the given [_video].
  void generateThumbnails() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      var imageWidth = MediaQuery.sizeOf(context).width /
          _thumbnailCount *
          MediaQuery.devicePixelRatioOf(context);

      /// `getKeyFrames` is faster than `getThumbnails` but the timestamp is
      /// more "random".
      var thumbnailList = await VideoUtilsService.instance.getKeyFrames(
        KeyFramesConfigs(
          video: _video,
          outputSize: Size.square(imageWidth),
          boxFit: ThumbnailBoxFit.cover,
          maxOutputFrames: _thumbnailCount,
          outputFormat: ThumbnailFormat.jpeg,
        ),
      );

      List<ImageProvider> temporaryThumbnails =
          thumbnailList.map(MemoryImage.new).toList();

      /// Optional precache every thumbnail
      var cacheList =
          temporaryThumbnails.map((item) => precacheImage(item, context));
      await Future.wait(cacheList);
      _thumbnails = temporaryThumbnails;

      if (_proVideoController != null) {
        _proVideoController!.thumbnails = _thumbnails;
      }
    });
  }

  void _initializePlayer() async {
    generateThumbnails();

    _videoController =
        VideoPlayerController.asset(kVideoEditorExampleAssetPath);

    await Future.wait([
      setMetadata(),
      _videoController.initialize(),
      _videoController.setLooping(false),
      _videoController.setVolume(_videoConfigs.initialMuted ? 0 : 100),
      _videoConfigs.initialPlay
          ? _videoController.play()
          : _videoController.pause(),
    ]);
    if (!mounted) return;

    _proVideoController = ProVideoController(
      videoPlayer: _buildVideoPlayer(),
      initialResolution: _videoMetadata.resolution,
      videoDuration: _videoMetadata.duration,
      fileSize: _videoMetadata.fileSize,
      thumbnails: _thumbnails,
    );

    _videoController.addListener(_onDurationChange);

    setState(() {});
  }

  void _onDurationChange() {
    var totalVideoDuration = _videoMetadata.duration;
    var duration = _videoController.value.position;
    _proVideoController!.setPlayTime(duration);

    if (_durationSpan != null && duration >= _durationSpan!.end) {
      _seekToPosition(_durationSpan!);
    } else if (duration >= totalVideoDuration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalVideoDuration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;

    if (_isSeeking) {
      _tempDurationSpan = span; // Store the latest seek request
      return;
    }
    _isSeeking = true;

    _proVideoController!.pause();
    _proVideoController!.setPlayTime(_durationSpan!.start);

    await _videoController.pause();
    await _videoController.seekTo(span.start);

    _isSeeking = false;

    // Check if there's a pending seek request
    if (_tempDurationSpan != null) {
      TrimDurationSpan nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null; // Clear the pending seek
      await _seekToPosition(nextSeek); // Process the latest request
    }
  }

  /// Generates the final video based on the given [parameters].
  ///
  /// Applies blur, color filters, cropping, rotation, flipping, and trimming
  /// before exporting using FFmpeg. Measures and stores the generation time.
  Future<void> generateVideo(CompleteParameters parameters) async {
    final stopwatch = Stopwatch()..start();

    var videoBytes = await _video.safeByteArray();
    _taskId = DateTime.now().toString();

    unawaited(_videoController.pause());

    var exportModel = RenderVideoModel(
      id: _taskId,
      videoBytes: videoBytes,
      outputFormat: _outputFormat,
      enableAudio: _proVideoController?.isAudioEnabled ?? true,
      imageBytes: parameters.image,
      blur: parameters.blur,
      colorMatrixList: parameters.colorFilters,
      startTime: parameters.startTime,
      endTime: parameters.endTime,
      transform: ExportTransform(
        width: parameters.cropWidth,
        height: parameters.cropHeight,
        rotateTurns: 4 - parameters.rotateTurns,
        x: parameters.cropX,
        y: parameters.cropY,
        flipX: parameters.flipX,
        flipY: parameters.flipY,
      ),
      bitrate: _videoMetadata.bitrate,
    );
    _exportedVideo = await VideoUtilsService.instance.renderVideo(exportModel);
    _videoGenerationTime = stopwatch.elapsed;
  }

  /// Closes the video editor and opens a preview screen if a video was
  /// exported.
  ///
  /// If [_exportedVideo] is available, it navigates to [PreviewVideo].
  /// Afterwards, it pops the current editor page.
  void onCloseEditor(EditorMode editorMode) async {
    if (editorMode != EditorMode.main) return Navigator.pop(context);
    if (_exportedVideo != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewVideo(
            bytes: _exportedVideo!,
            generationTime: _videoGenerationTime,
          ),
        ),
      );
      _exportedVideo = null;
    } else {
      return Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _proVideoController == null
          ? const VideoInitializingWidget()
          : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return ProImageEditor.video(
      _proVideoController!,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: generateVideo,
        onCloseEditor: onCloseEditor,
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController.pause,
          onPlay: _videoController.play,
          onMuteToggle: (isMuted) {
            _videoController.setVolume(isMuted ? 0 : 100);
          },
          onTrimSpanUpdate: (durationSpan) {
            if (_videoController.value.isPlaying) {
              _proVideoController!.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
      ),
      configs: ProImageEditorConfigs(
        dialogConfigs: DialogConfigs(
          widgets: DialogWidgets(
            loadingDialog: (message, configs) => VideoProgressAlert(
              taskId: _taskId,
            ),
          ),
        ),
        mainEditor: MainEditorConfigs(
          widgets: MainEditorWidgets(
            removeLayerArea: (removeAreaKey, editor, rebuildStream) =>
                VideoEditorRemoveArea(
              removeAreaKey: removeAreaKey,
              editor: editor,
              rebuildStream: rebuildStream,
            ),
          ),
        ),
        paintEditor: const PaintEditorConfigs(
          /// Blur and pixelate are not supported.
          enableModePixelate: false,
          enableModeBlur: false,
        ),
        videoEditor: _videoConfigs.copyWith(
          playTimeSmoothingDuration: const Duration(milliseconds: 600),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController.value.size.aspectRatio,
        child: VideoPlayer(
          _videoController,
        ),
      ),
    );
  }
}
