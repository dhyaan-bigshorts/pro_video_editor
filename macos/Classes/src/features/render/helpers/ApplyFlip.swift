import CoreGraphics

func applyFlip(
  config: inout VideoCompositorConfig,
  flipX: Bool,
  flipY: Bool
) {
  config.flipX = flipX
  config.flipY = flipY

  if !flipX && !flipY { return }

  print("[\(Tags.render)] Applying flip: flipX=\(flipX), flipY=\(flipY)")
}
