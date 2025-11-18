// (c) 2024 and onwards Pizza Studio (AGPL v3.0 License or later).
// ====================
// This code is released under the SPDX-License-Identifier: `AGPL-3.0-or-later`.

import Foundation
import SFSafeSymbols
import SwiftUI

#if canImport(UIKit)
  import UIKit
  typealias PlatformImage = UIImage
#elseif canImport(AppKit)
  import AppKit
  import QuickLookThumbnailing
  typealias PlatformImage = NSImage
#endif

// MARK: - SendableImagePtr

public final class SendableImagePtr: Sendable {
  // MARK: Lifecycle

  public init(img: Image) { self.img = img }

  // MARK: Public

  public let img: Image
}

// MARK: - SVGIconAsset

@available(iOS 16.2, macCatalyst 16.2, *)
public enum SVGIconAsset: String, CaseIterable, Identifiable, Sendable {
  case infoUnavailable = "icon.info.unavailable"
  case resin = "icon.resin"
  case trailblazePower = "icon.trailblazePower"
  case zzzBattery = "icon.zzzBattery"
  case dailyTaskGI = "icon.dailyTask.gi"
  case dailyTaskHSR = "icon.dailyTask.hsr"
  case dailyTaskZZZ = "icon.dailyTask.zzz"
  case expeditionGI = "icon.expedition.gi"
  case expeditionHSR = "icon.expedition.hsr"
  case transformer = "icon.transformer"
  case homeCoin = "icon.homeCoin"
  case trounceBlossom = "icon.trounceBlossom"
  case echoOfWar = "icon.echoOfWar"
  case simulatedUniverse = "icon.simulatedUniverse"
  case zzzVHSStore = "icon.zzzVHSStore"
  case zzzScratch = "icon.zzzScratch"
  case zzzBounty = "icon.zzzBounty"
  case zzzInvestigation = "icon.zzzInvestigation"

  @MainActor private static var svgURLCache: [SVGIconAsset: URL] = [:]
  @MainActor private static var cleanedSVGCache: [SVGIconAsset: Data] = [:]
  @MainActor private static var cleanedFileCache: [SVGIconAsset: URL] = [:]

  // MARK: Public

  public var id: String { rawValue }

  public var fallbackSymbol: SFSymbol {
    switch self {
    case .infoUnavailable: .questionmark
    case .resin: .moonFill
    case .trailblazePower: .line3CrossedSwirlCircleFill
    case .zzzBattery: .minusPlusBatteryblock
    case .dailyTaskGI, .dailyTaskHSR, .dailyTaskZZZ: .listStar
    case .expeditionGI, .expeditionHSR: .flag
    case .transformer: .arrowLeftArrowRightSquare
    case .homeCoin: .dollarsignCircle
    case .trounceBlossom: .leaf
    case .echoOfWar: .headphones
    case .simulatedUniverse: .pc
    case .zzzVHSStore: .film
    case .zzzScratch: .giftcard
    case .zzzBounty: .scope
    case .zzzInvestigation: .magnifyingglass
    }
  }

  @MainActor
  func svgDocumentURL() -> URL? {
    if let cached = Self.svgURLCache[self] { return cached }
    guard let baseURL = Bundle.module.resourceURL?
      .appendingPathComponent("Media.xcassets", isDirectory: true)
      .appendingPathComponent("Icons4EmbeddedWidgets", isDirectory: true)
      .appendingPathComponent("\(rawValue).symbolset", isDirectory: true)
    else {
      return nil
    }
    let contentsURL = baseURL.appendingPathComponent("Contents.json", isDirectory: false)
    guard let data = try? Data(contentsOf: contentsURL),
      let contents = try? JSONDecoder().decode(SymbolSetContents.self, from: data),
      let filename = contents.symbols.first?.filename
    else {
      return nil
    }
    let svgURL = baseURL.appendingPathComponent(filename, isDirectory: false)
    Self.svgURLCache[self] = svgURL
    return svgURL
  }

  @MainActor
  func cleanedSymbolDocumentURL(fileManager: FileManager = .default) -> URL? {
    if let cached = Self.cleanedFileCache[self], fileManager.fileExists(atPath: cached.path) {
      return cached
    }
    guard let data = cleanedSymbolDocumentData() else { return nil }
    let directory = fileManager.temporaryDirectory.appendingPathComponent("SVGAssetConverter", isDirectory: true)
    do {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      let fileURL = directory.appendingPathComponent("\(rawValue).svg")
      try data.write(to: fileURL, options: .atomic)
      Self.cleanedFileCache[self] = fileURL
      return fileURL
    } catch {
      return nil
    }
  }

  @MainActor
  private func cleanedSymbolDocumentData() -> Data? {
    if let cached = Self.cleanedSVGCache[self] { return cached }
    guard let sourceURL = svgDocumentURL(), let rawData = try? Data(contentsOf: sourceURL),
      let cleaned = try? Self.extractSymbolsDocument(from: rawData)
    else {
      return nil
    }
    Self.cleanedSVGCache[self] = cleaned
    return cleaned
  }

  @MainActor
  public func resolvedImage() -> Image {
    requestPrecompilationIfNeeded()
    let cache = SVGIconImageCache.shared
    guard !shouldDisableSVG(cache: cache), let image = cache.image(for: self) else {
      return Image(systemSymbol: fallbackSymbol)
    }
    return image
  }

  @MainActor
  public func inlineText() -> Text {
    Text(Image(rawValue, bundle: .module).renderingMode(.template))
  }

  // MARK: Internal

  @MainActor
  func shouldDisableSVG(cache: SVGIconImageCache = .shared) -> Bool {
    #if os(watchOS)
      if #unavailable(watchOS 10.0) {
        return true
      }
    #endif
    return cache.hasImage(for: self) == false
  }

  // MARK: Private

  @MainActor
  private func requestPrecompilationIfNeeded() {
    if SVGIconImageCache.shared.hasImage(for: self) {
      return
    }
    SVGIconsCompiler.shared.precompile(icon: self)
  }
}

// MARK: - Symbol Metadata

private struct SymbolSetContents: Decodable {
  struct SymbolRecord: Decodable {
    let filename: String
  }

  let symbols: [SymbolRecord]
}

extension SVGIconAsset {
  private static func extractSymbolsDocument(from data: Data) throws -> Data {
    let document = try XMLDocument(data: data, options: [.nodePreserveWhitespace])
    guard let root = document.rootElement() else {
      throw SVGSymbolExtractionError.missingRoot
    }
    guard let symbolsNode = root.elements(forName: "g").first(where: { $0.attribute(forName: "id")?.stringValue == "Symbols" }) else {
      throw SVGSymbolExtractionError.missingSymbolGroup
    }
    let newRoot = XMLElement(name: root.name ?? "svg")
    if let attributes = root.attributes {
      for attribute in attributes {
        newRoot.addAttribute(attribute.copy() as! XMLNode)
      }
    }
    if let children = root.children {
      for child in children {
        guard let element = child as? XMLElement else { continue }
        if element.name == "style" || element.name == "defs" {
          newRoot.addChild(element.copy() as! XMLElement)
        }
      }
    }
    newRoot.addChild(symbolsNode.copy() as! XMLElement)
    let cleanedDocument = XMLDocument(rootElement: newRoot)
    cleanedDocument.characterEncoding = "utf-8"
    cleanedDocument.isStandalone = true
    return cleanedDocument.xmlData(options: [.nodeCompactEmptyElement])
  }
}

enum SVGSymbolExtractionError: Error {
  case missingRoot
  case missingSymbolGroup
}

// MARK: - SVGIconImageCache

@available(iOS 16.2, macCatalyst 16.2, *)
@MainActor
final class SVGIconImageCache {
  // MARK: Lifecycle

  private init() {}

  // MARK: Internal

  static let shared = SVGIconImageCache()

  func image(for icon: SVGIconAsset) -> Image? {
    storage[icon]?.img
  }

  func store(_ image: SendableImagePtr, for icon: SVGIconAsset) {
    storage[icon] = image
  }

  func hasImage(for icon: SVGIconAsset) -> Bool {
    storage[icon] != nil
  }

  // MARK: Private

  private var storage: [SVGIconAsset: SendableImagePtr] = [:]
}

// MARK: - SVGIconsCompiler

@available(iOS 16.2, macCatalyst 16.2, *)
@MainActor
public final class SVGIconsCompiler {
  // MARK: Public

  public static let shared = SVGIconsCompiler()

  public func precompileAllIfNeeded() {
    // 這些任務得逐一完成。
    for icon in SVGIconAsset.allCases {
      precompile(icon: icon)
    }
  }

  public func precompile(icon: SVGIconAsset) {
    let cache = SVGIconImageCache.shared
    if cache.hasImage(for: icon) {
      return
    }
    guard let rendered = Self.renderImage(for: icon) else {
      return
    }
    cache.store(rendered, for: icon)
  }

  // MARK: Private

  @MainActor
  private static func renderImage(for icon: SVGIconAsset) -> SendableImagePtr? {
    guard let platformImage = renderPlatformImage(for: icon) else {
      return nil
    }
    #if canImport(UIKit)
      let templated = Image(uiImage: platformImage).renderingMode(.template)
    #elseif canImport(AppKit)
      let templated = Image(nsImage: platformImage).renderingMode(.template)
    #else
      return nil
    #endif
    return SendableImagePtr(img: templated)
  }

  @MainActor
  static func renderPlatformImage(for icon: SVGIconAsset) -> PlatformImage? {
    SVGSymbolRenderer.platformImage(for: icon)
  }
}

// MARK: - SVGIconPrewarmCoordinator

@available(iOS 16.2, macCatalyst 16.2, *)
@MainActor
public final class SVGIconPrewarmCoordinator {
  // MARK: Public

  public static let shared = SVGIconPrewarmCoordinator()

  public func ensurePrecompiled() {
    guard hasCompletedPrewarm == false else { return }
    SVGIconsCompiler.shared.precompileAllIfNeeded()
    hasCompletedPrewarm = true
  }

  // MARK: Private

  private var hasCompletedPrewarm = false
}
