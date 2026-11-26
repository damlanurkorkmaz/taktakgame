import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

/// Tasarım tuvalindeki renkler.
enum Palette {
    static let bg = UIColor(hex: 0x2A1F1A)
    static let darkest = UIColor(hex: 0x17110E)
    static let panel = UIColor(hex: 0x3D2E26)
    static let panelHi = UIColor(hex: 0x4A3628)
    static let panelLine = UIColor(hex: 0x5A463A)
    static let cream = UIColor(hex: 0xFFF4E2)
    static let muted = UIColor(hex: 0xD9C6AE)
    static let yellow = UIColor(hex: 0xFFC531)
    static let yellowDeep = UIColor(hex: 0xD99A12)
    static let yellowShadow = UIColor(hex: 0xB9830F)
    static let brownShadow = UIColor(hex: 0x7A4A12)
    static let orange = UIColor(hex: 0xFF8A3D)
    static let green = UIColor(hex: 0x5FD3A4)
    static let greenShadow = UIColor(hex: 0x2E8A66)
    static let red = UIColor(hex: 0xFF7A5C)
    static let redShadow = UIColor(hex: 0x6B2416)
    static let meterGood = UIColor(hex: 0x7A5A2A)
    static let outline = UIColor(hex: 0x1A1310)
}

extension Color {
    static let tkBg = Color(uiColor: Palette.bg)
    static let tkDarkest = Color(uiColor: Palette.darkest)
    static let tkPanel = Color(uiColor: Palette.panel)
    static let tkPanelHi = Color(uiColor: Palette.panelHi)
    static let tkPanelLine = Color(uiColor: Palette.panelLine)
    static let tkCream = Color(uiColor: Palette.cream)
    static let tkMuted = Color(uiColor: Palette.muted)
    static let tkYellow = Color(uiColor: Palette.yellow)
    static let tkYellowDeep = Color(uiColor: Palette.yellowDeep)
    static let tkYellowShadow = Color(uiColor: Palette.yellowShadow)
    static let tkBrownShadow = Color(uiColor: Palette.brownShadow)
    static let tkOrange = Color(uiColor: Palette.orange)
    static let tkGreen = Color(uiColor: Palette.green)
    static let tkGreenShadow = Color(uiColor: Palette.greenShadow)
    static let tkRed = Color(uiColor: Palette.red)
    static let tkRedShadow = Color(uiColor: Palette.redShadow)
    static let tkOutline = Color(uiColor: Palette.outline)
}

/// Uygulamaya gömülü fontlar (Info.plist > UIAppFonts).
enum TKFont {
    static let displayName = "Baloo2-ExtraBold"
    static let blackName = "Nunito-Black"
    static let extraBoldName = "Nunito-ExtraBold"

    static func display(_ size: CGFloat) -> Font { .custom(displayName, fixedSize: size) }
    static func black(_ size: CGFloat) -> Font { .custom(blackName, fixedSize: size) }
    static func extraBold(_ size: CGFloat) -> Font { .custom(extraBoldName, fixedSize: size) }
}

extension Int {
    /// 1250 -> "1.250"
    var tk: String {
        Self.formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: Lang.localeID)
        return f
    }()
}
