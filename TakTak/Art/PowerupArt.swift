import UIKit

/// Bantta yüzen güçlendirici baloncuğu.
enum PowerupArt {
    private static var cache: [String: UIImage] = [:]

    static func bubble(_ p: Powerup, size: CGFloat) -> UIImage {
        let key = "\(p.rawValue)-\(size)"
        if let img = cache[key] { return img }
        let img = Art.render(size: CGSize(width: size, height: size)) { ctx in
            let rect = CGRect(x: 3, y: 3, width: size - 6, height: size - 6)
            // Hafif hale
            ctx.setFillColor(p.uiColor.withAlphaComponent(0.18).cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
            // Gövde
            ctx.setFillColor(UIColor(hex: 0x1F2A2A).cgColor)
            ctx.fillEllipse(in: rect.insetBy(dx: 3, dy: 3))
            ctx.setStrokeColor(p.uiColor.cgColor)
            ctx.setLineWidth(size * 0.07)
            ctx.strokeEllipse(in: rect.insetBy(dx: 4, dy: 4))
            // Parlama
            ctx.setFillColor(UIColor(white: 1, alpha: 0.35).cgColor)
            ctx.fillEllipse(in: CGRect(x: size * 0.26, y: size * 0.18, width: size * 0.22, height: size * 0.12))
            // Simge
            let config = UIImage.SymbolConfiguration(pointSize: size * 0.4, weight: .heavy)
            if let icon = UIImage(systemName: p.icon, withConfiguration: config)?
                .withTintColor(p.uiColor, renderingMode: .alwaysOriginal) {
                let s = icon.size
                icon.draw(in: CGRect(x: (size - s.width) / 2, y: (size - s.height) / 2, width: s.width, height: s.height))
            }
        }
        cache[key] = img
        return img
    }
}
