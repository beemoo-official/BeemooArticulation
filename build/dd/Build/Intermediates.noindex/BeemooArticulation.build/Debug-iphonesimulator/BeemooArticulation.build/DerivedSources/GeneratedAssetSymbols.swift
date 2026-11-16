import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "avatar" asset catalog image resource.
    static let avatar = DeveloperToolsSupport.ImageResource(name: "avatar", bundle: resourceBundle)

    /// The "beemoo_fly" asset catalog image resource.
    static let beemooFly = DeveloperToolsSupport.ImageResource(name: "beemoo_fly", bundle: resourceBundle)

    /// The "ico_putting" asset catalog image resource.
    static let icoPutting = DeveloperToolsSupport.ImageResource(name: "ico_putting", bundle: resourceBundle)

    /// The "ico_social" asset catalog image resource.
    static let icoSocial = DeveloperToolsSupport.ImageResource(name: "ico_social", bundle: resourceBundle)

    /// The "ico_speech" asset catalog image resource.
    static let icoSpeech = DeveloperToolsSupport.ImageResource(name: "ico_speech", bundle: resourceBundle)

    /// The "ico_words" asset catalog image resource.
    static let icoWords = DeveloperToolsSupport.ImageResource(name: "ico_words", bundle: resourceBundle)

    /// The "logo" asset catalog image resource.
    static let logo = DeveloperToolsSupport.ImageResource(name: "logo", bundle: resourceBundle)

    /// The "p10_0" asset catalog image resource.
    static let p100 = DeveloperToolsSupport.ImageResource(name: "p10_0", bundle: resourceBundle)

    /// The "p10_1" asset catalog image resource.
    static let p101 = DeveloperToolsSupport.ImageResource(name: "p10_1", bundle: resourceBundle)

    /// The "p10_2" asset catalog image resource.
    static let p102 = DeveloperToolsSupport.ImageResource(name: "p10_2", bundle: resourceBundle)

    /// The "p11_0" asset catalog image resource.
    static let p110 = DeveloperToolsSupport.ImageResource(name: "p11_0", bundle: resourceBundle)

    /// The "p11_1" asset catalog image resource.
    static let p111 = DeveloperToolsSupport.ImageResource(name: "p11_1", bundle: resourceBundle)

    /// The "p11_2" asset catalog image resource.
    static let p112 = DeveloperToolsSupport.ImageResource(name: "p11_2", bundle: resourceBundle)

    /// The "p12_0" asset catalog image resource.
    static let p120 = DeveloperToolsSupport.ImageResource(name: "p12_0", bundle: resourceBundle)

    /// The "p12_1" asset catalog image resource.
    static let p121 = DeveloperToolsSupport.ImageResource(name: "p12_1", bundle: resourceBundle)

    /// The "p12_2" asset catalog image resource.
    static let p122 = DeveloperToolsSupport.ImageResource(name: "p12_2", bundle: resourceBundle)

    /// The "p17_0" asset catalog image resource.
    static let p170 = DeveloperToolsSupport.ImageResource(name: "p17_0", bundle: resourceBundle)

    /// The "p17_1" asset catalog image resource.
    static let p171 = DeveloperToolsSupport.ImageResource(name: "p17_1", bundle: resourceBundle)

    /// The "p18_0" asset catalog image resource.
    static let p180 = DeveloperToolsSupport.ImageResource(name: "p18_0", bundle: resourceBundle)

    /// The "p18_1" asset catalog image resource.
    static let p181 = DeveloperToolsSupport.ImageResource(name: "p18_1", bundle: resourceBundle)

    /// The "p19_0" asset catalog image resource.
    static let p190 = DeveloperToolsSupport.ImageResource(name: "p19_0", bundle: resourceBundle)

    /// The "p19_1" asset catalog image resource.
    static let p191 = DeveloperToolsSupport.ImageResource(name: "p19_1", bundle: resourceBundle)

    /// The "p20_0" asset catalog image resource.
    static let p200 = DeveloperToolsSupport.ImageResource(name: "p20_0", bundle: resourceBundle)

    /// The "p20_1" asset catalog image resource.
    static let p201 = DeveloperToolsSupport.ImageResource(name: "p20_1", bundle: resourceBundle)

    /// The "p24_0" asset catalog image resource.
    static let p240 = DeveloperToolsSupport.ImageResource(name: "p24_0", bundle: resourceBundle)

    /// The "p24_1" asset catalog image resource.
    static let p241 = DeveloperToolsSupport.ImageResource(name: "p24_1", bundle: resourceBundle)

    /// The "p24_2" asset catalog image resource.
    static let p242 = DeveloperToolsSupport.ImageResource(name: "p24_2", bundle: resourceBundle)

    /// The "p25_0" asset catalog image resource.
    static let p250 = DeveloperToolsSupport.ImageResource(name: "p25_0", bundle: resourceBundle)

    /// The "p25_1" asset catalog image resource.
    static let p251 = DeveloperToolsSupport.ImageResource(name: "p25_1", bundle: resourceBundle)

    /// The "p25_2" asset catalog image resource.
    static let p252 = DeveloperToolsSupport.ImageResource(name: "p25_2", bundle: resourceBundle)

    /// The "p26_0" asset catalog image resource.
    static let p260 = DeveloperToolsSupport.ImageResource(name: "p26_0", bundle: resourceBundle)

    /// The "p26_1" asset catalog image resource.
    static let p261 = DeveloperToolsSupport.ImageResource(name: "p26_1", bundle: resourceBundle)

    /// The "p26_2" asset catalog image resource.
    static let p262 = DeveloperToolsSupport.ImageResource(name: "p26_2", bundle: resourceBundle)

    /// The "p27_0" asset catalog image resource.
    static let p270 = DeveloperToolsSupport.ImageResource(name: "p27_0", bundle: resourceBundle)

    /// The "p27_1" asset catalog image resource.
    static let p271 = DeveloperToolsSupport.ImageResource(name: "p27_1", bundle: resourceBundle)

    /// The "p27_2" asset catalog image resource.
    static let p272 = DeveloperToolsSupport.ImageResource(name: "p27_2", bundle: resourceBundle)

    /// The "p31_0" asset catalog image resource.
    static let p310 = DeveloperToolsSupport.ImageResource(name: "p31_0", bundle: resourceBundle)

    /// The "p31_1" asset catalog image resource.
    static let p311 = DeveloperToolsSupport.ImageResource(name: "p31_1", bundle: resourceBundle)

    /// The "p31_2" asset catalog image resource.
    static let p312 = DeveloperToolsSupport.ImageResource(name: "p31_2", bundle: resourceBundle)

    /// The "p32_0" asset catalog image resource.
    static let p320 = DeveloperToolsSupport.ImageResource(name: "p32_0", bundle: resourceBundle)

    /// The "p32_1" asset catalog image resource.
    static let p321 = DeveloperToolsSupport.ImageResource(name: "p32_1", bundle: resourceBundle)

    /// The "p32_2" asset catalog image resource.
    static let p322 = DeveloperToolsSupport.ImageResource(name: "p32_2", bundle: resourceBundle)

    /// The "p33_0" asset catalog image resource.
    static let p330 = DeveloperToolsSupport.ImageResource(name: "p33_0", bundle: resourceBundle)

    /// The "p33_1" asset catalog image resource.
    static let p331 = DeveloperToolsSupport.ImageResource(name: "p33_1", bundle: resourceBundle)

    /// The "p33_2" asset catalog image resource.
    static let p332 = DeveloperToolsSupport.ImageResource(name: "p33_2", bundle: resourceBundle)

    /// The "p34_0" asset catalog image resource.
    static let p340 = DeveloperToolsSupport.ImageResource(name: "p34_0", bundle: resourceBundle)

    /// The "p34_1" asset catalog image resource.
    static let p341 = DeveloperToolsSupport.ImageResource(name: "p34_1", bundle: resourceBundle)

    /// The "p34_2" asset catalog image resource.
    static let p342 = DeveloperToolsSupport.ImageResource(name: "p34_2", bundle: resourceBundle)

    /// The "p7_0" asset catalog image resource.
    static let p70 = DeveloperToolsSupport.ImageResource(name: "p7_0", bundle: resourceBundle)

    /// The "p7_1" asset catalog image resource.
    static let p71 = DeveloperToolsSupport.ImageResource(name: "p7_1", bundle: resourceBundle)

    /// The "p7_2" asset catalog image resource.
    static let p72 = DeveloperToolsSupport.ImageResource(name: "p7_2", bundle: resourceBundle)

    /// The "p8_0" asset catalog image resource.
    static let p80 = DeveloperToolsSupport.ImageResource(name: "p8_0", bundle: resourceBundle)

    /// The "p8_1" asset catalog image resource.
    static let p81 = DeveloperToolsSupport.ImageResource(name: "p8_1", bundle: resourceBundle)

    /// The "p8_2" asset catalog image resource.
    static let p82 = DeveloperToolsSupport.ImageResource(name: "p8_2", bundle: resourceBundle)

    /// The "p9_0" asset catalog image resource.
    static let p90 = DeveloperToolsSupport.ImageResource(name: "p9_0", bundle: resourceBundle)

    /// The "p9_1" asset catalog image resource.
    static let p91 = DeveloperToolsSupport.ImageResource(name: "p9_1", bundle: resourceBundle)

    /// The "p9_2" asset catalog image resource.
    static let p92 = DeveloperToolsSupport.ImageResource(name: "p9_2", bundle: resourceBundle)

    /// The "scene14" asset catalog image resource.
    static let scene14 = DeveloperToolsSupport.ImageResource(name: "scene14", bundle: resourceBundle)

    /// The "scene15" asset catalog image resource.
    static let scene15 = DeveloperToolsSupport.ImageResource(name: "scene15", bundle: resourceBundle)

    /// The "scene16" asset catalog image resource.
    static let scene16 = DeveloperToolsSupport.ImageResource(name: "scene16", bundle: resourceBundle)

    /// The "scene2" asset catalog image resource.
    static let scene2 = DeveloperToolsSupport.ImageResource(name: "scene2", bundle: resourceBundle)

    /// The "scene21" asset catalog image resource.
    static let scene21 = DeveloperToolsSupport.ImageResource(name: "scene21", bundle: resourceBundle)

    /// The "scene22" asset catalog image resource.
    static let scene22 = DeveloperToolsSupport.ImageResource(name: "scene22", bundle: resourceBundle)

    /// The "scene23" asset catalog image resource.
    static let scene23 = DeveloperToolsSupport.ImageResource(name: "scene23", bundle: resourceBundle)

    /// The "scene28" asset catalog image resource.
    static let scene28 = DeveloperToolsSupport.ImageResource(name: "scene28", bundle: resourceBundle)

    /// The "scene29" asset catalog image resource.
    static let scene29 = DeveloperToolsSupport.ImageResource(name: "scene29", bundle: resourceBundle)

    /// The "scene3" asset catalog image resource.
    static let scene3 = DeveloperToolsSupport.ImageResource(name: "scene3", bundle: resourceBundle)

    /// The "scene30" asset catalog image resource.
    static let scene30 = DeveloperToolsSupport.ImageResource(name: "scene30", bundle: resourceBundle)

    /// The "scene4" asset catalog image resource.
    static let scene4 = DeveloperToolsSupport.ImageResource(name: "scene4", bundle: resourceBundle)

    /// The "scene5" asset catalog image resource.
    static let scene5 = DeveloperToolsSupport.ImageResource(name: "scene5", bundle: resourceBundle)

    /// The "scene6" asset catalog image resource.
    static let scene6 = DeveloperToolsSupport.ImageResource(name: "scene6", bundle: resourceBundle)

    /// The "star" asset catalog image resource.
    static let star = DeveloperToolsSupport.ImageResource(name: "star", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "avatar" asset catalog image.
    static var avatar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .avatar)
#else
        .init()
#endif
    }

    /// The "beemoo_fly" asset catalog image.
    static var beemooFly: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .beemooFly)
#else
        .init()
#endif
    }

    /// The "ico_putting" asset catalog image.
    static var icoPutting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icoPutting)
#else
        .init()
#endif
    }

    /// The "ico_social" asset catalog image.
    static var icoSocial: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icoSocial)
#else
        .init()
#endif
    }

    /// The "ico_speech" asset catalog image.
    static var icoSpeech: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icoSpeech)
#else
        .init()
#endif
    }

    /// The "ico_words" asset catalog image.
    static var icoWords: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .icoWords)
#else
        .init()
#endif
    }

    /// The "logo" asset catalog image.
    static var logo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .logo)
#else
        .init()
#endif
    }

    /// The "p10_0" asset catalog image.
    static var p100: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p100)
#else
        .init()
#endif
    }

    /// The "p10_1" asset catalog image.
    static var p101: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p101)
#else
        .init()
#endif
    }

    /// The "p10_2" asset catalog image.
    static var p102: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p102)
#else
        .init()
#endif
    }

    /// The "p11_0" asset catalog image.
    static var p110: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p110)
#else
        .init()
#endif
    }

    /// The "p11_1" asset catalog image.
    static var p111: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p111)
#else
        .init()
#endif
    }

    /// The "p11_2" asset catalog image.
    static var p112: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p112)
#else
        .init()
#endif
    }

    /// The "p12_0" asset catalog image.
    static var p120: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p120)
#else
        .init()
#endif
    }

    /// The "p12_1" asset catalog image.
    static var p121: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p121)
#else
        .init()
#endif
    }

    /// The "p12_2" asset catalog image.
    static var p122: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p122)
#else
        .init()
#endif
    }

    /// The "p17_0" asset catalog image.
    static var p170: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p170)
#else
        .init()
#endif
    }

    /// The "p17_1" asset catalog image.
    static var p171: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p171)
#else
        .init()
#endif
    }

    /// The "p18_0" asset catalog image.
    static var p180: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p180)
#else
        .init()
#endif
    }

    /// The "p18_1" asset catalog image.
    static var p181: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p181)
#else
        .init()
#endif
    }

    /// The "p19_0" asset catalog image.
    static var p190: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p190)
#else
        .init()
#endif
    }

    /// The "p19_1" asset catalog image.
    static var p191: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p191)
#else
        .init()
#endif
    }

    /// The "p20_0" asset catalog image.
    static var p200: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p200)
#else
        .init()
#endif
    }

    /// The "p20_1" asset catalog image.
    static var p201: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p201)
#else
        .init()
#endif
    }

    /// The "p24_0" asset catalog image.
    static var p240: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p240)
#else
        .init()
#endif
    }

    /// The "p24_1" asset catalog image.
    static var p241: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p241)
#else
        .init()
#endif
    }

    /// The "p24_2" asset catalog image.
    static var p242: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p242)
#else
        .init()
#endif
    }

    /// The "p25_0" asset catalog image.
    static var p250: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p250)
#else
        .init()
#endif
    }

    /// The "p25_1" asset catalog image.
    static var p251: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p251)
#else
        .init()
#endif
    }

    /// The "p25_2" asset catalog image.
    static var p252: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p252)
#else
        .init()
#endif
    }

    /// The "p26_0" asset catalog image.
    static var p260: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p260)
#else
        .init()
#endif
    }

    /// The "p26_1" asset catalog image.
    static var p261: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p261)
#else
        .init()
#endif
    }

    /// The "p26_2" asset catalog image.
    static var p262: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p262)
#else
        .init()
#endif
    }

    /// The "p27_0" asset catalog image.
    static var p270: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p270)
#else
        .init()
#endif
    }

    /// The "p27_1" asset catalog image.
    static var p271: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p271)
#else
        .init()
#endif
    }

    /// The "p27_2" asset catalog image.
    static var p272: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p272)
#else
        .init()
#endif
    }

    /// The "p31_0" asset catalog image.
    static var p310: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p310)
#else
        .init()
#endif
    }

    /// The "p31_1" asset catalog image.
    static var p311: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p311)
#else
        .init()
#endif
    }

    /// The "p31_2" asset catalog image.
    static var p312: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p312)
#else
        .init()
#endif
    }

    /// The "p32_0" asset catalog image.
    static var p320: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p320)
#else
        .init()
#endif
    }

    /// The "p32_1" asset catalog image.
    static var p321: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p321)
#else
        .init()
#endif
    }

    /// The "p32_2" asset catalog image.
    static var p322: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p322)
#else
        .init()
#endif
    }

    /// The "p33_0" asset catalog image.
    static var p330: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p330)
#else
        .init()
#endif
    }

    /// The "p33_1" asset catalog image.
    static var p331: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p331)
#else
        .init()
#endif
    }

    /// The "p33_2" asset catalog image.
    static var p332: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p332)
#else
        .init()
#endif
    }

    /// The "p34_0" asset catalog image.
    static var p340: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p340)
#else
        .init()
#endif
    }

    /// The "p34_1" asset catalog image.
    static var p341: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p341)
#else
        .init()
#endif
    }

    /// The "p34_2" asset catalog image.
    static var p342: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p342)
#else
        .init()
#endif
    }

    /// The "p7_0" asset catalog image.
    static var p70: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p70)
#else
        .init()
#endif
    }

    /// The "p7_1" asset catalog image.
    static var p71: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p71)
#else
        .init()
#endif
    }

    /// The "p7_2" asset catalog image.
    static var p72: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p72)
#else
        .init()
#endif
    }

    /// The "p8_0" asset catalog image.
    static var p80: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p80)
#else
        .init()
#endif
    }

    /// The "p8_1" asset catalog image.
    static var p81: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p81)
#else
        .init()
#endif
    }

    /// The "p8_2" asset catalog image.
    static var p82: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p82)
#else
        .init()
#endif
    }

    /// The "p9_0" asset catalog image.
    static var p90: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p90)
#else
        .init()
#endif
    }

    /// The "p9_1" asset catalog image.
    static var p91: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p91)
#else
        .init()
#endif
    }

    /// The "p9_2" asset catalog image.
    static var p92: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .p92)
#else
        .init()
#endif
    }

    /// The "scene14" asset catalog image.
    static var scene14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene14)
#else
        .init()
#endif
    }

    /// The "scene15" asset catalog image.
    static var scene15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene15)
#else
        .init()
#endif
    }

    /// The "scene16" asset catalog image.
    static var scene16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene16)
#else
        .init()
#endif
    }

    /// The "scene2" asset catalog image.
    static var scene2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene2)
#else
        .init()
#endif
    }

    /// The "scene21" asset catalog image.
    static var scene21: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene21)
#else
        .init()
#endif
    }

    /// The "scene22" asset catalog image.
    static var scene22: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene22)
#else
        .init()
#endif
    }

    /// The "scene23" asset catalog image.
    static var scene23: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene23)
#else
        .init()
#endif
    }

    /// The "scene28" asset catalog image.
    static var scene28: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene28)
#else
        .init()
#endif
    }

    /// The "scene29" asset catalog image.
    static var scene29: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene29)
#else
        .init()
#endif
    }

    /// The "scene3" asset catalog image.
    static var scene3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene3)
#else
        .init()
#endif
    }

    /// The "scene30" asset catalog image.
    static var scene30: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene30)
#else
        .init()
#endif
    }

    /// The "scene4" asset catalog image.
    static var scene4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene4)
#else
        .init()
#endif
    }

    /// The "scene5" asset catalog image.
    static var scene5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene5)
#else
        .init()
#endif
    }

    /// The "scene6" asset catalog image.
    static var scene6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .scene6)
#else
        .init()
#endif
    }

    /// The "star" asset catalog image.
    static var star: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .star)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "avatar" asset catalog image.
    static var avatar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .avatar)
#else
        .init()
#endif
    }

    /// The "beemoo_fly" asset catalog image.
    static var beemooFly: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .beemooFly)
#else
        .init()
#endif
    }

    /// The "ico_putting" asset catalog image.
    static var icoPutting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icoPutting)
#else
        .init()
#endif
    }

    /// The "ico_social" asset catalog image.
    static var icoSocial: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icoSocial)
#else
        .init()
#endif
    }

    /// The "ico_speech" asset catalog image.
    static var icoSpeech: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icoSpeech)
#else
        .init()
#endif
    }

    /// The "ico_words" asset catalog image.
    static var icoWords: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .icoWords)
#else
        .init()
#endif
    }

    /// The "logo" asset catalog image.
    static var logo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .logo)
#else
        .init()
#endif
    }

    /// The "p10_0" asset catalog image.
    static var p100: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p100)
#else
        .init()
#endif
    }

    /// The "p10_1" asset catalog image.
    static var p101: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p101)
#else
        .init()
#endif
    }

    /// The "p10_2" asset catalog image.
    static var p102: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p102)
#else
        .init()
#endif
    }

    /// The "p11_0" asset catalog image.
    static var p110: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p110)
#else
        .init()
#endif
    }

    /// The "p11_1" asset catalog image.
    static var p111: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p111)
#else
        .init()
#endif
    }

    /// The "p11_2" asset catalog image.
    static var p112: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p112)
#else
        .init()
#endif
    }

    /// The "p12_0" asset catalog image.
    static var p120: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p120)
#else
        .init()
#endif
    }

    /// The "p12_1" asset catalog image.
    static var p121: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p121)
#else
        .init()
#endif
    }

    /// The "p12_2" asset catalog image.
    static var p122: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p122)
#else
        .init()
#endif
    }

    /// The "p17_0" asset catalog image.
    static var p170: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p170)
#else
        .init()
#endif
    }

    /// The "p17_1" asset catalog image.
    static var p171: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p171)
#else
        .init()
#endif
    }

    /// The "p18_0" asset catalog image.
    static var p180: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p180)
#else
        .init()
#endif
    }

    /// The "p18_1" asset catalog image.
    static var p181: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p181)
#else
        .init()
#endif
    }

    /// The "p19_0" asset catalog image.
    static var p190: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p190)
#else
        .init()
#endif
    }

    /// The "p19_1" asset catalog image.
    static var p191: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p191)
#else
        .init()
#endif
    }

    /// The "p20_0" asset catalog image.
    static var p200: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p200)
#else
        .init()
#endif
    }

    /// The "p20_1" asset catalog image.
    static var p201: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p201)
#else
        .init()
#endif
    }

    /// The "p24_0" asset catalog image.
    static var p240: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p240)
#else
        .init()
#endif
    }

    /// The "p24_1" asset catalog image.
    static var p241: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p241)
#else
        .init()
#endif
    }

    /// The "p24_2" asset catalog image.
    static var p242: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p242)
#else
        .init()
#endif
    }

    /// The "p25_0" asset catalog image.
    static var p250: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p250)
#else
        .init()
#endif
    }

    /// The "p25_1" asset catalog image.
    static var p251: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p251)
#else
        .init()
#endif
    }

    /// The "p25_2" asset catalog image.
    static var p252: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p252)
#else
        .init()
#endif
    }

    /// The "p26_0" asset catalog image.
    static var p260: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p260)
#else
        .init()
#endif
    }

    /// The "p26_1" asset catalog image.
    static var p261: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p261)
#else
        .init()
#endif
    }

    /// The "p26_2" asset catalog image.
    static var p262: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p262)
#else
        .init()
#endif
    }

    /// The "p27_0" asset catalog image.
    static var p270: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p270)
#else
        .init()
#endif
    }

    /// The "p27_1" asset catalog image.
    static var p271: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p271)
#else
        .init()
#endif
    }

    /// The "p27_2" asset catalog image.
    static var p272: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p272)
#else
        .init()
#endif
    }

    /// The "p31_0" asset catalog image.
    static var p310: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p310)
#else
        .init()
#endif
    }

    /// The "p31_1" asset catalog image.
    static var p311: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p311)
#else
        .init()
#endif
    }

    /// The "p31_2" asset catalog image.
    static var p312: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p312)
#else
        .init()
#endif
    }

    /// The "p32_0" asset catalog image.
    static var p320: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p320)
#else
        .init()
#endif
    }

    /// The "p32_1" asset catalog image.
    static var p321: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p321)
#else
        .init()
#endif
    }

    /// The "p32_2" asset catalog image.
    static var p322: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p322)
#else
        .init()
#endif
    }

    /// The "p33_0" asset catalog image.
    static var p330: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p330)
#else
        .init()
#endif
    }

    /// The "p33_1" asset catalog image.
    static var p331: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p331)
#else
        .init()
#endif
    }

    /// The "p33_2" asset catalog image.
    static var p332: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p332)
#else
        .init()
#endif
    }

    /// The "p34_0" asset catalog image.
    static var p340: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p340)
#else
        .init()
#endif
    }

    /// The "p34_1" asset catalog image.
    static var p341: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p341)
#else
        .init()
#endif
    }

    /// The "p34_2" asset catalog image.
    static var p342: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p342)
#else
        .init()
#endif
    }

    /// The "p7_0" asset catalog image.
    static var p70: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p70)
#else
        .init()
#endif
    }

    /// The "p7_1" asset catalog image.
    static var p71: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p71)
#else
        .init()
#endif
    }

    /// The "p7_2" asset catalog image.
    static var p72: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p72)
#else
        .init()
#endif
    }

    /// The "p8_0" asset catalog image.
    static var p80: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p80)
#else
        .init()
#endif
    }

    /// The "p8_1" asset catalog image.
    static var p81: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p81)
#else
        .init()
#endif
    }

    /// The "p8_2" asset catalog image.
    static var p82: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p82)
#else
        .init()
#endif
    }

    /// The "p9_0" asset catalog image.
    static var p90: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p90)
#else
        .init()
#endif
    }

    /// The "p9_1" asset catalog image.
    static var p91: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p91)
#else
        .init()
#endif
    }

    /// The "p9_2" asset catalog image.
    static var p92: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .p92)
#else
        .init()
#endif
    }

    /// The "scene14" asset catalog image.
    static var scene14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene14)
#else
        .init()
#endif
    }

    /// The "scene15" asset catalog image.
    static var scene15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene15)
#else
        .init()
#endif
    }

    /// The "scene16" asset catalog image.
    static var scene16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene16)
#else
        .init()
#endif
    }

    /// The "scene2" asset catalog image.
    static var scene2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene2)
#else
        .init()
#endif
    }

    /// The "scene21" asset catalog image.
    static var scene21: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene21)
#else
        .init()
#endif
    }

    /// The "scene22" asset catalog image.
    static var scene22: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene22)
#else
        .init()
#endif
    }

    /// The "scene23" asset catalog image.
    static var scene23: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene23)
#else
        .init()
#endif
    }

    /// The "scene28" asset catalog image.
    static var scene28: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene28)
#else
        .init()
#endif
    }

    /// The "scene29" asset catalog image.
    static var scene29: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene29)
#else
        .init()
#endif
    }

    /// The "scene3" asset catalog image.
    static var scene3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene3)
#else
        .init()
#endif
    }

    /// The "scene30" asset catalog image.
    static var scene30: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene30)
#else
        .init()
#endif
    }

    /// The "scene4" asset catalog image.
    static var scene4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene4)
#else
        .init()
#endif
    }

    /// The "scene5" asset catalog image.
    static var scene5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene5)
#else
        .init()
#endif
    }

    /// The "scene6" asset catalog image.
    static var scene6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .scene6)
#else
        .init()
#endif
    }

    /// The "star" asset catalog image.
    static var star: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .star)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

