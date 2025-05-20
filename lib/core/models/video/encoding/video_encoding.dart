import 'avi_encoding_config.dart';
import 'gif_encoding_config.dart';
import 'mkv_encoding_config.dart';
import 'mov_encoding_config.dart';
import 'mp4_encoding_config.dart';
import 'webm_encoding_config.dart';

export 'avi_encoding_config.dart';
export 'base_encoding_config.dart';
export 'gif_encoding_config.dart';
export 'mkv_encoding_config.dart';
export 'mov_encoding_config.dart';
export 'mp4_encoding_config.dart';
export 'webm_encoding_config.dart';

/// Holds encoding configurations for various video output formats.
///
/// This class provides format-specific settings (e.g., MP4, MOV, GIF)
/// and generates corresponding FFmpeg arguments.
class VideoEncoding {
  /// Creates a [VideoEncoding] with optional custom configurations for each
  /// format.
  const VideoEncoding({
    this.mp4EncodingConfig = const Mp4EncodingConfig(),
    this.movEncodingConfig = const MovEncodingConfig(),
    this.mkvEncodingConfig = const MkvEncodingConfig(),
    this.webMEncodingConfig = const WebMEncodingConfig(),
    this.gifEncodingConfig = const GifEncodingConfig(),
    this.aviEncodingConfig = const AviEncodingConfig(),
  });

  /// Encoding configuration for MP4 output.
  final Mp4EncodingConfig mp4EncodingConfig;

  /// Encoding configuration for MOV output.
  final MovEncodingConfig movEncodingConfig;

  /// Encoding configuration for MKV output.
  final MkvEncodingConfig mkvEncodingConfig;

  /// Encoding configuration for WebM output.
  final WebMEncodingConfig webMEncodingConfig;

  /// Encoding configuration for GIF output.
  final GifEncodingConfig gifEncodingConfig;

  /// Encoding configuration for AVI output.
  final AviEncodingConfig aviEncodingConfig;

  /// Returns the FFmpeg arguments for the specified [outputFormat].
/*   List<String> toFFmpegArgs({
    required VideoOutputFormat outputFormat,
    required bool enableAudio,
  }) {
    return getEncodingConfig(outputFormat).toFFmpegArgs(enableAudio);
  }

  /// Returns the encoding configuration matching the given [outputFormat].
  VideoEncodingConfig getEncodingConfig(VideoOutputFormat outputFormat) {
    switch (outputFormat) {
      case VideoOutputFormat.mp4:
        return mp4EncodingConfig;
      case VideoOutputFormat.mkv:
        return mkvEncodingConfig;
      case VideoOutputFormat.webm:
        return webMEncodingConfig;
      case VideoOutputFormat.avi:
        return aviEncodingConfig;
      case VideoOutputFormat.gif:
        return gifEncodingConfig;
    }
  } */

  /// Returns a copy of this config with the given fields replaced.
  VideoEncoding copyWith({
    Mp4EncodingConfig? mp4EncodingConfig,
    MovEncodingConfig? movEncodingConfig,
    MkvEncodingConfig? mkvEncodingConfig,
    WebMEncodingConfig? webMEncodingConfig,
    GifEncodingConfig? gifEncodingConfig,
    AviEncodingConfig? aviEncodingConfig,
  }) {
    return VideoEncoding(
      mp4EncodingConfig: mp4EncodingConfig ?? this.mp4EncodingConfig,
      movEncodingConfig: movEncodingConfig ?? this.movEncodingConfig,
      mkvEncodingConfig: mkvEncodingConfig ?? this.mkvEncodingConfig,
      webMEncodingConfig: webMEncodingConfig ?? this.webMEncodingConfig,
      gifEncodingConfig: gifEncodingConfig ?? this.gifEncodingConfig,
      aviEncodingConfig: aviEncodingConfig ?? this.aviEncodingConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoEncoding &&
        other.mp4EncodingConfig == mp4EncodingConfig &&
        other.movEncodingConfig == movEncodingConfig &&
        other.mkvEncodingConfig == mkvEncodingConfig &&
        other.webMEncodingConfig == webMEncodingConfig &&
        other.gifEncodingConfig == gifEncodingConfig &&
        other.aviEncodingConfig == aviEncodingConfig;
  }

  @override
  int get hashCode {
    return mp4EncodingConfig.hashCode ^
        movEncodingConfig.hashCode ^
        mkvEncodingConfig.hashCode ^
        webMEncodingConfig.hashCode ^
        gifEncodingConfig.hashCode ^
        aviEncodingConfig.hashCode;
  }
}
