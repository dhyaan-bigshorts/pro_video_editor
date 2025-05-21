## 🚧 Under Development 🚧

`pro_video_editor` is an upcoming Flutter package designed to provide advanced video editing capabilities. This package will serve as an extension to [pro_image_editor](https://pub.dev/packages/pro_image_editor), bringing powerful video manipulation tools to Flutter applications.


### Platform Support

| Platform       | `metadata`  | `thumbnails` | `transformations` | `layers` | `colorMatrix 4x5 "filters"` | `background-blur` | `censorLayers` |
|----------------|-------------|--------------|-------------------|----------|-----------------------------|-------------------|----------------|
| Android        | ✅          | ✅          | ✅                | ✅      | ✅                         | 🧪                | ❌            |
| iOS            | ✅          | ❌          | ❌                | ❌      | ❌                         | ❌                | ❌            |
| macOS          | ✅          | ❌          | ❌                | ❌      | ❌                         | ❌                | ❌            |
| Windows        | ✅          | ❌          | ❌                | ❌      | ❌                         | ❌                | ❌            |
| Linux          | ✅          | ❌          | ❌                | ❌      | ❌                         | ❌                | ❌            |
| Web            | ✅          | ❌          | 🚫                | 🚫      | 🚫                         | 🚫                | 🚫            |



#### Legend
- ✅ Supported with Native-Code 
- 🧪 Supported but visual output can differs from Flutter
- ⚠️ Supported but depend on ffmpeg
- ❌ Not supported but planned
- 🚫 Not supported and currently not planned

<br/>

### ❗ Important Note

This plugin uses [FFmpegKit](https://github.com/arthenica/ffmpeg-kit), specifically the `ffmpeg-kit-full-gpl` build, which includes components licensed under the **GNU General Public License (GPL v3)**.

By using this plugin, you agree to comply with the terms of the GPL license.

> [Read more about GPL licensing here](https://www.gnu.org/licenses/gpl-3.0.en.html)

⚠️ **Future Licensing Plan**:  
To allow more flexible and permissive use (including closed-source commercial apps), a future version of this plugin will switch to an alternative solution using **LGPL-compliant FFmpeg builds** or **native platform APIs** (such as `MediaCodec`, `AVFoundation`, or `Media Foundation`) to avoid GPL restrictions entirely.