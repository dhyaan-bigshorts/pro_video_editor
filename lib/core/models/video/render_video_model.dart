import 'package:flutter/foundation.dart';

import '/core/models/video/export_transform_model.dart';

class RenderVideoModel {
  RenderVideoModel({
    required this.outputFormat,
    required this.videoBytes,
    this.imageBytes,
    this.transform = const ExportTransform(),
    this.enableAudio = true,
    this.playbackSpeed,
    this.startTime,
    this.endTime,
    this.colorMatrixList = const [],
/*     
    required this.videoDuration,
    required this.devicePixelRatio,
    this.outputQuality = OutputQuality.medium,
    this.encodingPreset = EncodingPreset.fast,
    this.startTime,
    this.endTime,
    this.blur = 0,
    this.colorFilters = const [],
    this.customFilter = '',
    this.encoding = const VideoEncoding(), */
  }) : assert(
          startTime == null || endTime == null || startTime < endTime,
          'startTime must be before endTime',
        ); /*  ,
        assert(
          blur >= 0,
          'Blur must be greater than or equal to 0',
        ) */

  /// The target format for the exported video.
  final VideoOutputFormat outputFormat;

  /// The original video data in bytes.
  final Uint8List videoBytes;

  /// A transparent image which will overlay the video.
  final Uint8List? imageBytes;

  /// Transformation settings like resize, rotation, offset, and flipping.
  ///
  /// Used to control how the video or image is positioned and modified during
  /// export.
  final ExportTransform transform;

  /// Whether to include audio in the exported video.
  ///
  /// **Default**: `true`
  final bool enableAudio;

  final double? playbackSpeed;
  final Duration? startTime;
  final Duration? endTime;

  /// A 4x5 matrix used to apply color filters (e.g., saturation, brightness).
  final List<List<double>> colorMatrixList;

  /*
 

  /// Amount of blur to apply (in logical pixels).
  ///
  /// Higher values result in a stronger blur effect.
  final double blur;


  /// The FFmpeg constant rate factor (CRF) for the selected [outputQuality].
  ///
  /// Lower CRF means better quality and larger file size.
  int get constantRateFactor {
    switch (outputQuality) {
      case OutputQuality.lossless:
        return 0;
      case OutputQuality.ultraHigh:
        return 16;
      case OutputQuality.high:
        return 18;
      case OutputQuality.mediumHigh:
        return 20;
      case OutputQuality.medium:
        return 23;
      case OutputQuality.mediumLow:
        return 26;
      case OutputQuality.low:
        return 28;
      case OutputQuality.veryLow:
        return 32;
      case OutputQuality.potato:
        return 51;
    }
  }

  String get _blurFilter {
    if (blur <= 0) return '';
    double adaptiveKernelMultiplier() {
      if (blur < 5) return 1.2;
      if (blur < 15) return 1.35;
      if (blur < 30) return 1.4;
      return 1.5;
    }

    final ffmpegSigma = blur * devicePixelRatio * adaptiveKernelMultiplier();
    return 'gblur=sigma=$ffmpegSigma';
  }

  String get _cropFilter {
    if (transform == const ExportTransform()) return '';

    final rotateTurns = transform.rotateTurns % 4;
    final isSwapped = rotateTurns % 2 != 0;

    final rawWidth = transform.width;
    final rawHeight = transform.height;
    final x = transform.x;
    final y = transform.y;
    final flipX = transform.flipX;
    final flipY = transform.flipY;

    final rotate = switch (rotateTurns) {
      1 => 'transpose=1',
      2 => 'transpose=1,transpose=1',
      3 => 'transpose=2',
      _ => '',
    };

    String? crop;
    if (rawWidth != null && rawHeight != null) {
      // Swap if rotated
      final unsanitizedWidth = isSwapped ? rawHeight : rawWidth;
      final unsanitizedHeight = isSwapped ? rawWidth : rawHeight;

      // Ensure even dimensions
      final cropWidth = (unsanitizedWidth ~/ 2) * 2;
      final cropHeight = (unsanitizedHeight ~/ 2) * 2;

      // X and Y can remain null for centering or use as-is
      final xExpr = x ?? '(in_w-$cropWidth)/2';
      final yExpr = y ?? '(in_h-$cropHeight)/2';

      crop = 'crop=$cropWidth:$cropHeight:$xExpr:$yExpr';
    }

    final flips = <String>[
      if (flipX) 'hflip',
      if (flipY) 'vflip',
    ];

    final filters = <String>[
      if (rotate.isNotEmpty) rotate,
      if (crop != null) crop,
      ...flips,
    ];

    return filters.join(',');
  }

  /// Returns a combined FFmpeg complex filter string based on active filters.
  ///
  /// Includes blur and crop filters if defined. Filters are joined with a comma
  /// and empty filters are excluded.
  String get complexFilter {
    var filters = [_blurFilter, _cropFilter, customFilter]
      ..removeWhere((item) => item.isEmpty);

    return filters.join(',');
  }

  /// Returns a copy of this config with the given fields replaced.
  RenderVideoModel copyWith({
    VideoOutputFormat? outputFormat,
    Uint8List? videoBytes,
    Uint8List? imageBytes,
    Duration? videoDuration,
    OutputQuality? outputQuality,
    EncodingPreset? encodingPreset,
    Duration? startTime,
    Duration? endTime,
    List<List<double>>? colorFilters,
    double? blur,
    bool? enableAudio,
    double? devicePixelRatio,
    ExportTransform? transform,
    String? customFilter,
    VideoEncoding? encoding,
  }) {
    return RenderVideoModel(
      outputFormat: outputFormat ?? this.outputFormat,
      videoBytes: videoBytes ?? this.videoBytes,
      imageBytes: imageBytes ?? this.imageBytes,
      videoDuration: videoDuration ?? this.videoDuration,
      outputQuality: outputQuality ?? this.outputQuality,
      encodingPreset: encodingPreset ?? this.encodingPreset,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorFilters: colorFilters ?? this.colorFilters,
      blur: blur ?? this.blur,
      enableAudio: enableAudio ?? this.enableAudio,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      transform: transform ?? this.transform,
      customFilter: customFilter ?? this.customFilter,
      encoding: encoding ?? this.encoding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RenderVideoModel &&
        other.outputFormat == outputFormat &&
        other.videoBytes == videoBytes &&
        other.imageBytes == imageBytes &&
        other.videoDuration == videoDuration &&
        other.outputQuality == outputQuality &&
        other.encodingPreset == encodingPreset &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        listEquals(other.colorFilters, colorFilters) &&
        other.blur == blur &&
        other.enableAudio == enableAudio &&
        other.devicePixelRatio == devicePixelRatio &&
        other.transform == transform &&
        other.customFilter == customFilter &&
        other.encoding == encoding;
  }

  @override
  int get hashCode {
    return outputFormat.hashCode ^
        videoBytes.hashCode ^
        imageBytes.hashCode ^
        videoDuration.hashCode ^
        outputQuality.hashCode ^
        encodingPreset.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        colorFilters.hashCode ^
        blur.hashCode ^
        enableAudio.hashCode ^
        devicePixelRatio.hashCode ^
        transform.hashCode ^
        customFilter.hashCode ^
        encoding.hashCode;
  } */
}

/// Supported video output formats for export.
///
/// These formats are passed to FFmpeg using the appropriate container flags.
/// The compatibility of each format may vary by platform and codec support.
enum VideoOutputFormat {
  /// MPEG-4 Part 14, widely supported.
  mp4,

  /// WebM format, optimized for web use.
  webm,
}

/// Describes the desired output quality for exported videos.
///
/// Internally, this is mapped to FFmpeg's `-crf` (Constant Rate Factor) values.
/// Lower CRF means better quality and larger file size.
enum OutputQuality {
  /// 🔒 Lossless quality using `-crf 0`.
  /// Highest possible quality, but results in very large file sizes.
  lossless,

  /// 🥇 Ultra high quality using `-crf 16`.
  /// Slightly better than visually lossless; larger file size.
  ultraHigh,

  /// 🔍 High quality using `-crf 18`.
  /// Visually lossless and suitable for most high-quality exports.
  high,

  /// ✅ Good quality using `-crf 20`.
  /// Very close to high, but slightly more compressed.
  mediumHigh,

  /// ⚖️ Balanced quality using `-crf 23`.
  /// Reasonable trade-off between quality and file size (FFmpeg default).
  medium,

  /// 💡 Medium-low quality using `-crf 26`.
  /// Smaller file size with noticeable compression artifacts.
  mediumLow,

  /// 📦 Compressed quality using `-crf 28`.
  /// Suitable for quick exports or previews.
  low,

  /// 🪶 Very compressed using `-crf 32`.
  /// Lower quality, faster to process, smallest file size.
  veryLow,

  /// 🥔 Worst possible quality using `-crf 51`.
  /// Tiny file size, heavy artifacts — not recommended for final output.
  potato,
}

/// Determines the encoding speed vs. compression trade-off.
///
/// Used with FFmpeg's `-preset` option. Faster presets result in quicker
/// encoding but larger file sizes. Slower presets produce smaller files
/// but take more time.
enum EncodingPreset {
  /// 🚀 Ultrafast encoding, largest file size.
  ultrafast,

  /// ⚡ Superfast encoding.
  superfast,

  /// 🏃 Very fast encoding.
  veryfast,

  /// 🏃‍♂️ Faster encoding.
  faster,

  /// 🏎️ Fast encoding.
  fast,

  /// ⚖️ Balanced between speed and compression.
  medium,

  /// 🐢 Slower encoding, better compression.
  slow,

  /// 🐌 Very slow encoding, smaller file size.
  slower,

  /// 🧊 Extremely slow, high compression.
  veryslow,

  /// 🧪 Placebo — max compression, impractical speed.
  placebo,
}
