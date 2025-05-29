import CoreGraphics

func applyFlip(flipX: Bool, flipY: Bool, ) {
  VideoCompositor.flipX = flipX
  VideoCompositor.flipY = flipY

  if !flipX && !flipY { return }

  print("[\(Tags.render)] Applying flip: flipX=\(flipX), flipY=\(flipY)")
}
