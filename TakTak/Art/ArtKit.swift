import UIKit

/// SVG tasarımlarını Core Graphics ile çizmek için küçük yardımcılar.
/// Koordinatlar SVG'deki gibi sol üstten başlar (y aşağı doğru artar).
enum Art {
    static let outline = Palette.outline

    enum Axis { case vertical, horizontal }

    static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    static func gradient(_ colors: [UIColor], _ locations: [CGFloat]? = nil) -> CGGradient {
        let locs: [CGFloat] = locations ?? colors.indices.map {
            colors.count == 1 ? 0 : CGFloat($0) / CGFloat(colors.count - 1)
        }
        return CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: locs
        )!
    }

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, r: CGFloat = 0) -> CGPath {
        let rr = CGRect(x: x, y: y, width: w, height: h)
        if r <= 0 { return CGPath(rect: rr, transform: nil) }
        let rad = min(r, w / 2, h / 2)
        return CGPath(roundedRect: rr, cornerWidth: rad, cornerHeight: rad, transform: nil)
    }

    static func path(_ build: (CGMutablePath) -> Void) -> CGPath {
        let p = CGMutablePath()
        build(p)
        return p
    }

    static func white(_ alpha: CGFloat) -> UIColor { UIColor(white: 1, alpha: alpha) }
    static func black(_ alpha: CGFloat) -> UIColor { UIColor(white: 0, alpha: alpha) }

    /// Yolu, kendi sınır kutusuna göre gradyanla doldurur (SVG objectBoundingBox gibi).
    static func fill(_ ctx: CGContext, _ path: CGPath, _ g: CGGradient, _ axis: Axis) {
        let b = path.boundingBox
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let start = CGPoint(x: b.minX, y: b.minY)
        let end = axis == .vertical ? CGPoint(x: b.minX, y: b.maxY) : CGPoint(x: b.maxX, y: b.minY)
        ctx.drawLinearGradient(g, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }

    static func fill(_ ctx: CGContext, _ path: CGPath, _ color: UIColor) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    static func stroke(_ ctx: CGContext, _ path: CGPath, _ color: UIColor, _ width: CGFloat,
                       cap: CGLineCap = .round, join: CGLineJoin = .round) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.setLineCap(cap)
        ctx.setLineJoin(join)
        ctx.strokePath()
        ctx.restoreGState()
    }

    /// Gradyan dolgu + koyu kontur: tüm çizimlerin temel parçası.
    static func shape(_ ctx: CGContext, _ path: CGPath, _ g: CGGradient, _ axis: Axis, stroke width: CGFloat) {
        fill(ctx, path, g, axis)
        stroke(ctx, path, outline, width)
    }

    static func render(size: CGSize, _ draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { draw($0.cgContext) }
    }
}
