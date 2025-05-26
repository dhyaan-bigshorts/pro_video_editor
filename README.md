<img src="https://github.com/hm21/pro_video_editor/blob/stable/assets/logo.jpg?raw=true" alt="Logo" />

<p>
    <a href="https://pub.dartlang.org/packages/pro_video_editor">
        <img src="https://img.shields.io/pub/v/pro_video_editor.svg" alt="pub package">
    </a>
    <a href="https://github.com/sponsors/hm21">
        <img src="https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23f5372a" alt="Sponsor">
    </a>
    <a href="https://img.shields.io/github/license/hm21/pro_video_editor">
        <img src="https://img.shields.io/github/license/hm21/pro_video_editor" alt="License">
    </a>
    <a href="https://github.com/hm21/pro_video_editor/issues">
        <img src="https://img.shields.io/github/issues/hm21/pro_video_editor" alt="GitHub issues">
    </a> 
</p>

`pro_video_editor` is an upcoming Flutter package designed to provide advanced video editing capabilities. This package will serve as an extension for the [pro_image_editor](https://pub.dev/packages/pro_image_editor).


## Table of contents

- **[📷 Preview](#preview)**
- **[✨ Features](#features)**
- **[🔧 Setup](#setup)**
- **[❓ Usage](#usage)**
- **[💖 Sponsors](#sponsors)**
- **[📦 Included Packages](#included-packages)**
- **[🤝 Contributors](#contributors)**
- **[📜 License](LICENSE)**
- **[📜 Notices](NOTICES)**

## Preview
<table>
  <thead>
    <tr>
      <th align="center">Main-Editor</th>
      <th align="center">Paint-Editor</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center" width="50%">
        <img src="https://github.com/hm21/pro_video_editor/blob/stable/assets/preview/main_editor.jpg?raw=true" alt="Main-Editor" />
      </td>
      <td align="center" width="50%">
        <img src="https://github.com/hm21/pro_video_editor/blob/stable/assets/preview/paint_editor.jpg?raw=true" alt="Paint-Editor" />
      </td>
    </tr>
  </tbody>
</table>


### Features

| Method                     | Android | iOS  | macOS  | Windows  | Linux  | Web   |
|----------------------------|---------|------|--------|----------|--------|-------|
| `Metadata`                 | ✅      | ❌  | ✅     | ✅      | ❌     | ✅   |
| `Thumbnails`               | ✅      | ❌  | ✅     | ❌      | ❌     | ✅   |
| `KeyFrames`                | ✅      | ❌  | ✅     | ❌      | ❌     | ✅   |
| `Rotate`                   | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Flip`                     | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Crop`                     | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Scale`                    | ✅      | ❌  | ✅     | ❌      | ❌     | 🚫   |
| `Trim`                     | ✅      | ❌  | ✅     | ❌      | ❌     | 🚫   |
| `Playback-Speed`           | ✅      | ❌  | ✅     | ❌      | ❌     | 🚫   |
| `Remove-Audio`             | ✅      | ❌  | ✅     | ❌      | ❌     | 🚫   |
| `Overlay Layers`           | ✅      | ❌  | ✅     | ❌      | ❌     | 🚫   |
| `Multiple ColorMatrix 4x5` | ✅      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Blur background`          | 🧪      | ❌  | 🧪     | ❌      | ❌     | 🚫   |
| `Custom Audio Tracks`      | ❌      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Merge Videos`             | ❌      | ❌  | ❌     | ❌      | ❌     | 🚫   |
| `Censor-Layers "Pixelate"` | ❌      | ❌  | ❌     | ❌      | ❌     | 🚫   |



#### Legend
- ✅ Supported with Native-Code 
- 🧪 Supported but visual output can differs from Flutter
- ❌ Not supported but planned
- 🚫 Not supported and currently not planned

## Setup

#### Android, iOS, macOS, Linux, Windows, Web

No additional setup required.

## Usage
#### Metadata
```dart
VideoMetadata result = await VideoUtilsService.instance.getMetadata(
    EditorVideo(
        assetPath: 'assets/my-video.mp4',
        /// byteArray: ,
        /// file: ,
        /// networkUrl: ,
        ),
);
```

#### Thumbnails 

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

#### Keyframes

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

#### Render
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


## Sponsors 
<p align="center">
  <a href="https://github.com/sponsors/hm21">
    <img src='https://raw.githubusercontent.com/hm21/sponsors/main/sponsorkit/sponsors.svg'/>
  </a>
</p>

## Included Packages

A big thanks to the authors of these amazing packages.

- Packages created by the Dart team:
  - [http](https://pub.dev/packages/http)
  - [mime](https://pub.dev/packages/mime)
  - [plugin_platform_interface](https://pub.dev/packages/plugin_platform_interface)
  - [web](https://pub.dev/packages/web)


## Contributors
<a href="https://github.com/hm21/pro_video_editor/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hm21/pro_video_editor" />
</a>

Made with [contrib.rocks](https://contrib.rocks).