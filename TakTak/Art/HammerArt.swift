import UIKit

/// Çekiç çizimi. Tasarımdaki Hammer bileşeninin (200x200 SVG) birebir karşılığı.
enum HammerArt {
    private static var cache: [String: UIImage] = [:]

    /// Döndürme pivotu: dik çizimde sapın alt ucu (200'lük kutuda).
    static let pivot = CGPoint(x: 100, y: 174.7)

    /// - Parameters:
    ///   - angle: derece; negatif = sola yatık (SVG rotate gibi saat yönünün tersi).
    static func image(_ variant: HammerVariant, size: CGFloat, angle: CGFloat = -25, shadow: Bool = true) -> UIImage {
        let key = "\(variant.rawValue)-\(size)-\(angle)-\(shadow)"
        if let img = cache[key] { return img }
        let img = Art.render(size: CGSize(width: size, height: size)) { ctx in
            ctx.scaleBy(x: size / 200, y: size / 200)
            draw(ctx, variant, angle: angle, shadow: shadow)
        }
        cache[key] = img
        return img
    }

    static func draw(_ ctx: CGContext, _ variant: HammerVariant, angle: CGFloat, shadow: Bool) {
        let p = variant.palette
        let head = Art.gradient(p.head, [0, 0.45, 1])
        let wood = Art.gradient(p.wood, [0, 0.5, 1])
        let grip = Art.gradient(p.grip)

        if shadow {
            ctx.setFillColor(Art.black(0.28).cgColor)
            ctx.fillEllipse(in: CGRect(x: 60, y: 178, width: 96, height: 12))
        }

        ctx.saveGState()
        ctx.translateBy(x: 100, y: 105)
        ctx.rotate(by: angle * .pi / 180)
        ctx.scaleBy(x: 0.82, y: 0.82)
        ctx.translateBy(x: -100, y: -105)

        drawHandle(ctx, p, wood: wood, grip: grip, head: head)

        switch p.shape {
        case .claw: drawClaw(ctx, p, head: head, wood: wood)
        case .sledge: drawSledge(ctx, head: head, wood: wood)
        case .mallet: drawMallet(ctx, head: head)
        case .crystal: drawCrystal(ctx, head: head)
        }

        ctx.restoreGState()
    }

    // MARK: - Parçalar

    private static func handleOutline(top: CGFloat) -> CGPath {
        Art.path { p in
            p.move(to: Art.pt(89, top))
            p.addLine(to: Art.pt(111, top))
            p.addLine(to: Art.pt(115, 176))
            p.addQuadCurve(to: Art.pt(100, 190), control: Art.pt(115, 190))
            p.addQuadCurve(to: Art.pt(85, 176), control: Art.pt(85, 190))
            p.closeSubpath()
        }
    }

    private static func drawHandle(_ ctx: CGContext, _ p: HammerPalette, wood: CGGradient, grip: CGGradient, head: CGGradient) {
        Art.shape(ctx, handleOutline(top: 74), wood, .horizontal, stroke: 5)

        let grain = Art.path { g in
            g.move(to: Art.pt(95, 86)); g.addLine(to: Art.pt(96.5, 120))
            g.move(to: Art.pt(104, 92)); g.addLine(to: Art.pt(105, 116))
        }
        Art.stroke(ctx, grain, Art.white(0.35), 2)

        let gripPath = Art.path { g in
            g.move(to: Art.pt(86.5, 136))
            g.addLine(to: Art.pt(113.5, 136))
            g.addLine(to: Art.pt(115, 176))
            g.addQuadCurve(to: Art.pt(100, 190), control: Art.pt(115, 190))
            g.addQuadCurve(to: Art.pt(85, 176), control: Art.pt(85, 190))
            g.closeSubpath()
        }
        Art.shape(ctx, gripPath, grip, .horizontal, stroke: 5)

        let wraps = Art.path { g in
            g.move(to: Art.pt(88, 150)); g.addLine(to: Art.pt(113, 143))
            g.move(to: Art.pt(88, 162)); g.addLine(to: Art.pt(113.5, 155))
            g.move(to: Art.pt(88, 174)); g.addLine(to: Art.pt(114, 167))
        }
        Art.stroke(ctx, wraps, p.gripLine, 3)

        Art.shape(ctx, Art.rect(83, 128, 34, 10, r: 5), head, .vertical, stroke: 4)

        if p.glow {
            Art.stroke(ctx, wraps, p.gripLine.withAlphaComponent(0.3), 8)
        }
    }

    private static func wedge(_ ctx: CGContext, y: CGFloat, wood: CGGradient) {
        Art.shape(ctx, Art.rect(90, y, 20, 9, r: 2), wood, .horizontal, stroke: 4)
    }

    private static func drawClaw(_ ctx: CGContext, _ p: HammerPalette, head: CGGradient, wood: CGGradient) {
        let claw = Art.path { c in
            c.move(to: Art.pt(120, 40))
            c.addCurve(to: Art.pt(177, 86), control1: Art.pt(147, 40), control2: Art.pt(167, 55))
            c.addLine(to: Art.pt(162, 90))
            c.addCurve(to: Art.pt(120, 63), control1: Art.pt(154, 69), control2: Art.pt(140, 62))
            c.closeSubpath()
        }
        Art.shape(ctx, claw, head, .vertical, stroke: 5)

        let notch = Art.path { n in
            n.move(to: Art.pt(128, 51))
            n.addCurve(to: Art.pt(167, 83), control1: Art.pt(146, 53), control2: Art.pt(158, 65))
        }
        Art.stroke(ctx, notch, Art.outline, 3)

        Art.shape(ctx, Art.rect(48, 45, 30, 30), head, .vertical, stroke: 5)
        Art.shape(ctx, Art.rect(70, 32, 54, 50, r: 8), head, .vertical, stroke: 5)
        Art.shape(ctx, Art.rect(22, 35, 32, 48, r: 8), head, .vertical, stroke: 5)

        Art.fill(ctx, Art.rect(76, 38, 40, 6, r: 3), Art.white(0.6))
        Art.fill(ctx, Art.rect(28, 41, 6, 34, r: 3), Art.white(0.5))
        let shine = Art.path { s in
            s.move(to: Art.pt(126, 46))
            s.addCurve(to: Art.pt(162, 67), control1: Art.pt(142, 47), control2: Art.pt(154, 55))
        }
        Art.stroke(ctx, shine, Art.white(0.45), 3)

        if p.glow {
            let line = Art.path { l in
                l.move(to: Art.pt(30, 59)); l.addLine(to: Art.pt(118, 59))
            }
            Art.stroke(ctx, line, p.gripLine.withAlphaComponent(0.3), 10)
            Art.stroke(ctx, line, p.gripLine, 3)
        }

        wedge(ctx, y: 26, wood: wood)
    }

    private static func drawSledge(_ ctx: CGContext, head: CGGradient, wood: CGGradient) {
        Art.shape(ctx, Art.rect(40, 28, 120, 56, r: 8), head, .vertical, stroke: 5)
        Art.fill(ctx, Art.rect(62, 28, 8, 56), Art.outline.withAlphaComponent(0.25))
        Art.fill(ctx, Art.rect(130, 28, 8, 56), Art.outline.withAlphaComponent(0.25))
        Art.shape(ctx, Art.rect(24, 33, 22, 46, r: 6), head, .vertical, stroke: 5)
        Art.shape(ctx, Art.rect(154, 33, 22, 46, r: 6), head, .vertical, stroke: 5)
        Art.fill(ctx, Art.rect(48, 34, 104, 7, r: 3.5), Art.white(0.5))
        Art.fill(ctx, Art.rect(29, 39, 5, 30, r: 2.5), Art.white(0.45))
        wedge(ctx, y: 22, wood: wood)
    }

    private static func drawMallet(_ ctx: CGContext, head: CGGradient) {
        let cap = Art.gradient([UIColor.white, UIColor(hex: 0xB9BEC4)])
        Art.shape(ctx, Art.rect(42, 30, 116, 54, r: 14), head, .vertical, stroke: 5)
        Art.shape(ctx, Art.rect(26, 30, 26, 54, r: 12), cap, .vertical, stroke: 5)
        Art.shape(ctx, Art.rect(148, 30, 26, 54, r: 12), cap, .vertical, stroke: 5)
        Art.fill(ctx, Art.rect(58, 36, 84, 7, r: 3.5), Art.white(0.28))
        Art.fill(ctx, Art.rect(32, 37, 6, 34, r: 3), Art.white(0.8))
    }

    private static func drawCrystal(_ ctx: CGContext, head: CGGradient) {
        func poly(_ pts: [CGPoint]) -> CGPath {
            Art.path { p in
                p.addLines(between: pts)
                p.closeSubpath()
            }
        }
        let body = poly([Art.pt(28, 57), Art.pt(48, 28), Art.pt(152, 28), Art.pt(172, 57), Art.pt(152, 86), Art.pt(48, 86)])
        Art.shape(ctx, body, head, .vertical, stroke: 5)
        Art.fill(ctx, poly([Art.pt(48, 28), Art.pt(100, 28), Art.pt(82, 57), Art.pt(28, 57)]), Art.white(0.5))
        Art.fill(ctx, poly([Art.pt(100, 28), Art.pt(152, 28), Art.pt(172, 57), Art.pt(118, 57)]), Art.white(0.2))
        Art.fill(ctx, poly([Art.pt(28, 57), Art.pt(82, 57), Art.pt(100, 86), Art.pt(48, 86)]), UIColor(hex: 0x0B2B4A, alpha: 0.15))
        let facets = Art.path { f in
            f.move(to: Art.pt(82, 57)); f.addLine(to: Art.pt(118, 57))
            f.move(to: Art.pt(100, 28)); f.addLine(to: Art.pt(82, 57)); f.addLine(to: Art.pt(100, 86))
            f.move(to: Art.pt(100, 28)); f.addLine(to: Art.pt(118, 57)); f.addLine(to: Art.pt(100, 86))
        }
        Art.stroke(ctx, facets, Art.outline.withAlphaComponent(0.45), 2)
        let sparkle = poly([Art.pt(60, 36), Art.pt(62, 42), Art.pt(68, 44), Art.pt(62, 46),
                            Art.pt(60, 52), Art.pt(58, 46), Art.pt(52, 44), Art.pt(58, 42)])
        Art.fill(ctx, sparkle, .white)
    }
}
