import 'dart:typed_data';

import '/core/platform/io/io_helper.dart';
import '/shared/utils/converters.dart';
import '/shared/utils/file_constructor_utils.dart';

/// A model that encapsulates various ways to load and represent a video.
///
/// This class supports videos from in-memory bytes, file system, network,
/// or asset bundle. It provides convenience methods for identifying the
/// source type and safely retrieving video bytes.
class EditorVideo {
  /// Creates an instance of the `EditorVideo` class with the specified
  /// properties.
  ///
  /// At least one of `byteArray`, `file`, `networkUrl`, or `assetPath`
  /// must not be null.
  EditorVideo._({
    this.byteArray,
    this.networkUrl,
    this.assetPath,
    dynamic file,
  })  : file = file == null ? null : ensureFileInstance(file),
        assert(
          byteArray != null ||
              file != null ||
              networkUrl != null ||
              assetPath != null,
          'At least one of bytes, file, networkUrl, or assetPath must not '
          'be null.',
        );

  /// Creates an [EditorVideo] instance from any supported source.
  ///
  /// Provide one of [byteArray], [networkUrl], [assetPath], or [file].
  /// Useful for dynamically choosing the video input at runtime.
  ///
  /// Example:
  /// ```dart
  /// final video = EditorVideo.autoSource(file: pickedFile);
  /// ```
  factory EditorVideo.autoSource({
    Uint8List? byteArray,
    String? networkUrl,
    String? assetPath,
    dynamic file,
  }) {
    return EditorVideo._(
      byteArray: byteArray,
      networkUrl: networkUrl,
      assetPath: assetPath,
      file: file,
    );
  }

  /// Creates an [EditorVideo] from in-memory bytes.
  ///
  /// Suitable when you already have the video content loaded as a [Uint8List],
  /// such as from a download or blob.
  ///
  /// Example:
  /// ```dart
  /// final video = EditorVideo.memory(videoBytes);
  /// ```
  factory EditorVideo.memory(Uint8List bytes) =>
      EditorVideo._(byteArray: bytes);

  /// Creates an [EditorVideo] from a bundled asset path.
  ///
  /// Ideal for loading videos packaged with the app, such as demo or template
  /// videos.
  ///
  /// Example:
  /// ```dart
  /// final video = EditorVideo.asset('assets/videos/sample.mp4');
  /// ```
  factory EditorVideo.asset(String name) => EditorVideo._(assetPath: name);

  /// Creates an [EditorVideo] from a local file.
  ///
  /// [file] can be a `File` or the path as string to the file.
  ///
  /// Example:
  /// ```dart
  /// final video = EditorVideo.file(File('/path/to/video.mp4'));
  /// final video = EditorVideo.file('/path/to/video.mp4');
  /// ```
  factory EditorVideo.file(dynamic file) => EditorVideo._(file: file);

  /// Creates an [EditorVideo] from a network URL.
  ///
  /// Useful for streaming or downloading video content from the web.
  ///
  /// Example:
  /// ```dart
  /// final video = EditorVideo.network('https://example.com/video.mp4');
  /// ```
  factory EditorVideo.network(String src) => EditorVideo._(networkUrl: src);

  /// A byte array representing the video data.
  Uint8List? byteArray;

  /// A `File` object representing the video file.
  final File? file;

  /// A URL string pointing to an video on the internet.
  final String? networkUrl;

  /// A string representing the asset path of an video.
  final String? assetPath;

  /// Indicates whether the `byteArray` property is not null.
  bool get hasBytes => byteArray != null;

  /// Indicates whether the `networkUrl` property is not null.
  bool get hasNetworkUrl => networkUrl != null;

  /// Indicates whether the `file` property is not null.
  bool get hasFile => file != null;

  /// Indicates whether the `assetPath` property is not null.
  bool get hasAssetPath => assetPath != null;

  /// A future that retrieves the image data as a `Uint8List` from the
  /// appropriate source based on the `EditorVideoType`.
  Future<Uint8List> safeByteArray() async {
    Uint8List bytes;
    switch (type) {
      case EditorVideoType.memory:
        return byteArray!;
      case EditorVideoType.asset:
        bytes = await loadAssetImageAsUint8List(assetPath!);
        break;
      case EditorVideoType.file:
        bytes = await readFileAsUint8List(file!);
        break;
      case EditorVideoType.network:
        bytes = await fetchImageAsUint8List(networkUrl!);
        break;
    }

    byteArray = bytes;

    return bytes;
  }

  /// Returns the type of the video source.
  ///
  /// This is determined by the first non-null source in the order:
  /// memory, file, network, asset.
  EditorVideoType get type {
    if (hasBytes) {
      return EditorVideoType.memory;
    } else if (hasFile) {
      return EditorVideoType.file;
    } else if (hasNetworkUrl) {
      return EditorVideoType.network;
    } else {
      return EditorVideoType.asset;
    }
  }

  /// Returns a copy of this config with the given fields replaced.
  EditorVideo copyWith({
    Uint8List? byteArray,
    File? file,
    String? networkUrl,
    String? assetPath,
  }) {
    return EditorVideo.autoSource(
      byteArray: byteArray ?? this.byteArray,
      file: file ?? this.file,
      networkUrl: networkUrl ?? this.networkUrl,
      assetPath: assetPath ?? this.assetPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is EditorVideo &&
        _areUint8ListsEqual(byteArray, other.byteArray) &&
        file?.path == other.file?.path &&
        networkUrl == other.networkUrl &&
        assetPath == other.assetPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      _hashUint8List(byteArray),
      file?.path,
      networkUrl,
      assetPath,
    );
  }

  bool _areUint8ListsEqual(Uint8List? a, Uint8List? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _hashUint8List(Uint8List? list) {
    if (list == null) return 0;
    return list.fold(0, (hash, byte) => hash * 31 + byte);
  }
}

/// Enum representing the type of source the video was loaded from.
enum EditorVideoType {
  /// Represents a video loaded from a file.
  file,

  /// Represents a video loaded from a network URL.
  network,

  /// Represents a video loaded from memory (byte array).
  memory,

  /// Represents a video loaded from an asset path.
  asset
}
