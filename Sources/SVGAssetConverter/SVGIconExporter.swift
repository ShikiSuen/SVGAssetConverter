// (c) 2024 and onwards Pizza Studio (AGPL v3.0 License or later).
// ====================
// This code is released under the SPDX-License-Identifier: `AGPL-3.0-or-later`.

import Foundation
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

@available(iOS 16.2, macCatalyst 16.2, *)
enum SVGIconExporterError: LocalizedError {
  case renderFailed(SVGIconAsset)
  case pngEncodingFailed(SVGIconAsset)

  var errorDescription: String? {
    switch self {
    case let .renderFailed(icon):
      return "Unable to render platform image for \(icon.rawValue)."
    case let .pngEncodingFailed(icon):
      return "Failed to encode PNG data for \(icon.rawValue)."
    }
  }
}

@available(iOS 16.2, macCatalyst 16.2, *)
enum SVGIconExporter {
  @discardableResult
  @MainActor
  static func exportAll(to directory: URL) throws -> [URL] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var outputs: [URL] = []
    for icon in SVGIconAsset.allCases {
      let url = try export(icon: icon, to: directory)
      outputs.append(url)
    }
    return outputs
  }

  @MainActor
  @discardableResult
  static func export(icon: SVGIconAsset, to directory: URL) throws -> URL {
    let destination = directory.appendingPathComponent("\(icon.rawValue).png", isDirectory: false)
    guard let platformImage = SVGIconsCompiler.renderPlatformImage(for: icon) else {
      throw SVGIconExporterError.renderFailed(icon)
    }
    guard let data = pngData(from: platformImage) else {
      throw SVGIconExporterError.pngEncodingFailed(icon)
    }
    try data.write(to: destination, options: .atomic)
    return destination
  }

  // MARK: Private

  @MainActor
  private static func pngData(from image: PlatformImage) -> Data? {
    #if canImport(UIKit)
      image.pngData()
    #elseif canImport(AppKit)
      guard let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff)
      else {
        return nil
      }
      return bitmap.representation(using: .png, properties: [.compressionFactor: 1])
    #else
      return nil
    #endif
  }
}
