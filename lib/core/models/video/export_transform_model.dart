/// Represents a set of transformations to apply during video export.
///
/// This includes resizing, rotation, flipping, and positional offsets.
class ExportTransform {
  /// Creates an [ExportTransform] with optional transformations.
  ///
  /// If [width] and [height] are provided, the output will be resized.
  /// [rotateTurns] defines clockwise 90° rotation steps (0–3).
  /// x and y allow shifting the video/image position using FFmpeg
  /// expressions.
  /// [flipX] and [flipY] control horizontal and vertical flipping.
  const ExportTransform({
    this.width,
    this.height,
    this.rotateTurns = 0,
    this.x,
    this.y,
    this.flipX = false,
    this.flipY = false,
  });

  /// Output width in pixels. If null, original width is used.
  final int? width;

  /// Output height in pixels. If null, original height is used.
  final int? height;

  /// Number of clockwise 90° rotations to apply (0 = no rotation).
  final int rotateTurns;

  /// Horizontal offset (FFmpeg expression, e.g., `'main_w/2'`).
  final String? x;

  /// Vertical offset (FFmpeg expression, e.g., `'main_h/2'`).
  final String? y;

  /// Whether to flip horizontally.
  final bool flipX;

  /// Whether to flip vertically.
  final bool flipY;

  /// Returns a copy of this config with the given fields replaced.
  ExportTransform copyWith({
    int? width,
    int? height,
    int? rotateTurns,
    String? x,
    String? y,
    bool? flipX,
    bool? flipY,
  }) {
    return ExportTransform(
      width: width ?? this.width,
      height: height ?? this.height,
      rotateTurns: rotateTurns ?? this.rotateTurns,
      x: x ?? this.x,
      y: y ?? this.y,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExportTransform &&
        other.width == width &&
        other.height == height &&
        other.rotateTurns == rotateTurns &&
        other.x == x &&
        other.y == y &&
        other.flipX == flipX &&
        other.flipY == flipY;
  }

  @override
  int get hashCode {
    return width.hashCode ^
        height.hashCode ^
        rotateTurns.hashCode ^
        x.hashCode ^
        y.hashCode ^
        flipX.hashCode ^
        flipY.hashCode;
  }
}
