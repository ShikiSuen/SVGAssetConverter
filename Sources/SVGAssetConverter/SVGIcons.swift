// (c) 2024 and onwards Pizza Studio (AGPL v3.0 License or later).
// ====================
// This code is released under the SPDX-License-Identifier: `AGPL-3.0-or-later`.

import Foundation
import SFSafeSymbols
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
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
    Task.detached(priority: .utility) {
      await SVGIconsCompiler.shared.precompile(icon: self)
    }
  }
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
public actor SVGIconsCompiler {
  // MARK: Public

  public static let shared = SVGIconsCompiler()

  public func precompileAllIfNeeded() async {
    // 這些任務得逐一完成。
    for icon in SVGIconAsset.allCases {
      await precompile(icon: icon)
    }
  }

  public func precompile(icon: SVGIconAsset) async {
    _ = await Task { @MainActor in
      let cache = SVGIconImageCache.shared
      if cache.hasImage(for: icon) {
        return
      }
      guard let rendered = Self.renderImage(for: icon) else {
        return
      }
      await MainActor.run {
        cache.store(rendered, for: icon)
      }
    }
    .value
  }

  // MARK: Private

  @MainActor
  private static func renderImage(for icon: SVGIconAsset) -> SendableImagePtr? {
    let content = Image(icon.rawValue, bundle: .module)
      .renderingMode(.template)
      .resizable()
      .aspectRatio(contentMode: .fit)
    let renderer = ImageRenderer(content: content)
    renderer.scale = 1
    renderer.isOpaque = false
    renderer.proposedSize = ProposedViewSize(width: 96, height: 96)
    #if canImport(UIKit)
      guard let platformImage = renderer.uiImage else { return nil }
      let templated = Image(uiImage: platformImage).renderingMode(.template)
    #elseif canImport(AppKit)
      guard let platformImage = renderer.nsImage else { return nil }
      let templated = Image(nsImage: platformImage).renderingMode(.template)
    #else
      return nil
    #endif
    return SendableImagePtr(img: templated)
  }
}

// MARK: - SVGIconPrewarmCoordinator

@available(iOS 16.2, macCatalyst 16.2, *)
public actor SVGIconPrewarmCoordinator {
  // MARK: Public

  public static let shared = SVGIconPrewarmCoordinator()

  public func ensurePrecompiled() async {
    if hasCompletedPrewarm {
      return
    }
    if let task = inFlightTask {
      await task.value
      return
    }
    let task = Task(priority: .userInitiated) {
      await SVGIconsCompiler.shared.precompileAllIfNeeded()
    }
    inFlightTask = task
    await task.value
    hasCompletedPrewarm = true
    inFlightTask = nil
  }

  // MARK: Private

  private var inFlightTask: Task<(), Never>?
  private var hasCompletedPrewarm = false
}
