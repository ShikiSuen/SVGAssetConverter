import Foundation
import CoreGraphics
#if canImport(AppKit)
  import AppKit
  @preconcurrency import QuickLookThumbnailing

  private final class CGImageBox: @unchecked Sendable {
    var value: CGImage?
  }
#endif

@MainActor
enum SVGSymbolRenderer {
  static func platformImage(for icon: SVGIconAsset) -> PlatformImage? {
    #if canImport(AppKit)
      guard let cleanedURL = icon.cleanedSymbolDocumentURL() else { return nil }
      guard let rasterized = rasterizeSVG(at: cleanedURL, dimension: renderSurfaceDimension) else { return nil }
      guard let trimmed = trimTransparentPixels(in: rasterized) else { return nil }
      guard let scaled = scaleImage(trimmed, to: targetSize) else { return nil }
      let image = NSImage(cgImage: scaled, size: NSSize(width: targetSize.width, height: targetSize.height))
      image.isTemplate = true
      return image
    #else
      return nil
    #endif
  }

  private static let renderSurfaceDimension: CGFloat = 1024
  private static let targetSize = CGSize(width: 96, height: 96)

  #if canImport(AppKit)
    private static func rasterizeSVG(at url: URL, dimension: CGFloat) -> CGImage? {
      let size = CGSize(width: dimension, height: dimension)
      let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 1, representationTypes: .thumbnail)
      request.iconMode = false
      let semaphore = DispatchSemaphore(value: 0)
      let box = CGImageBox()
      DispatchQueue.global(qos: .userInitiated).async {
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, _, _ in
          box.value = thumbnail?.cgImage
          semaphore.signal()
        }
      }
      semaphore.wait()
      return box.value
    }

    private static func trimTransparentPixels(in image: CGImage) -> CGImage? {
      let bitmap = NSBitmapImageRep(cgImage: image)
      guard let data = bitmap.bitmapData else {
        return image
      }
      let width = bitmap.pixelsWide
      let height = bitmap.pixelsHigh
      let bytesPerPixel = bitmap.bitsPerPixel / 8
      let bytesPerRow = bitmap.bytesPerRow
      var minX = width
      var minY = height
      var maxX = -1
      var maxY = -1
      for y in 0 ..< height {
        for x in 0 ..< width {
          let offset = y * bytesPerRow + x * bytesPerPixel
          let alpha = data[offset + bytesPerPixel - 1]
          if alpha > 0 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
          }
        }
      }
      guard maxX >= minX, maxY >= minY else { return image }
      let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
      return image.cropping(to: cropRect)
    }

    private static func scaleImage(_ image: CGImage, to size: CGSize) -> CGImage? {
      let width = Int(size.width)
      let height = Int(size.height)
      guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
        return nil
      }
      context.setFillColor(NSColor.clear.cgColor)
      context.fill(CGRect(origin: .zero, size: size))
      context.interpolationQuality = .high
      let scale = min(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
      let scaledSize = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
      let drawRect = CGRect(
        x: (size.width - scaledSize.width) / 2,
        y: (size.height - scaledSize.height) / 2,
        width: scaledSize.width,
        height: scaledSize.height
      )
      context.draw(image, in: drawRect)
      return context.makeImage()
    }
  #endif
}
