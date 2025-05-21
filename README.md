## 🚧 Under Development 🚧

`pro_video_editor` is an upcoming Flutter package designed to provide advanced video editing capabilities. This package will serve as an extension to [pro_image_editor](https://pub.dev/packages/pro_image_editor), bringing powerful video manipulation tools to Flutter applications.


### Platform Support

| Method                     | Android | iOS  | macOS  | Windows  | Linux  | Web   |
|----------------------------|---------|------|--------|----------|--------|-------|
| `Metadata`                 | ✅      | ❌  | ✅     | ✅      | ❌     | ✅   |
| `Thumbnails`               | ✅      | ❌  | ✅     | ❌      | ❌     | ✅   |
| `KeyFrames`                | ✅      | ❌  | ❌     | ❌      | ❌     | ✅   |
| `Rotate`                   | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Flip`                     | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Crop`                     | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Scale`                    | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Trim`                     | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Playback-Speed`           | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Remove-Audio`             | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Overlay Layers`           | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Multiple ColorMatrix 4x5` | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Blur background`          | 🧪      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Censor-Layers "Pixelate"` | ❌      | ❌  | ❌     | ❌      | ❌     | 🚫   |




#### Legend
- ✅ Supported with Native-Code 
- 🧪 Supported but visual output can differs from Flutter
- ❌ Not supported but planned
- 🚫 Not supported and currently not planned


## Metadata

```dart
VideoMetadata result = await VideoUtilsService.instance.getVideoInformation(
    EditorVideo(
        assetPath: 'assets/my-video.mp4',
        /// byteArray: ,
        /// file: ,
        /// networkUrl: ,
        ),
);
```

## Thumbnails 

```dart
List<Uint8List> result = await VideoUtilsService.instance.getThumbnails(
    ThumbnailConfigs(
        video: EditorVideo(
            assetPath: 'assets/my-video.mp4',
            /// byteArray: ,
            /// file: ,
            /// networkUrl: ,
        ),
        outputFormat: ThumbnailFormat.jpeg,
        timestamps: const [
            Duration(seconds: 10),
            Duration(seconds: 15),
            Duration(seconds: 22),
        ],
        outputSize: const Size(200, 200),
        boxFit: ThumbnailBoxFit.cover,
    ),
);
```

## Keyframes

```dart
List<Uint8List> result = await VideoUtilsService.instance.getKeyFrames(
    KeyFramesConfigs(
        video: EditorVideo(
            assetPath: 'assets/my-video.mp4',
            /// byteArray: ,
            /// file: ,
            /// networkUrl: ,
        ),
        outputFormat: ThumbnailFormat.jpeg,
        maxOutputFrames: 20,
        outputSize: const Size(200, 200),
        boxFit: ThumbnailBoxFit.cover,
    ),
);
```

## Render

```dart
var video = EditorVideo(
    assetPath: 'assets/my-video.mp4',
    /// byteArray: ,
    /// file: ,
    /// networkUrl: ,
);

/// Every option except videoBytes is optional.
var data = RenderVideoModel(
    videoBytes: await video.safeByteArray(),

    /// A image "Layer" which will overlay the video.
    imageBytes: imageBytes,
    outputFormat: VideoOutputFormat.mp4,
    transform: const ExportTransform(
        flipX: true,
        flipY: true,
        x: 10,
        y: 20,
        width: 300,
        height: 400,
        rotateTurns: 3,
        scaleX: .5,
        scaleY: .5,
    ),
    colorMatrixList: [
         [ 1.0, 0.0, 0.0, 0.0, 50.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0 ],
         [ 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0 ],
    ],
    enableAudio: false,
    playbackSpeed: 2,
    startTime: const Duration(seconds: 5),
    endTime: const Duration(seconds: 20),
    blur: 10,
);

Uint8List result = await VideoUtilsService.instance.renderVideo(data);
```