import UIKit

/// Çivilerin aktığı konveyör bant. Tasarımdaki Bant bileşeni (390x160).
/// y = 40 tahtanın üst yüzeyi, 84–102 kauçuk bant, 100–144 metal gövde, 144–156 uyarı şeridi.
enum BeltArt {
    static let unitWidth: CGFloat = 390
    static let fullHeight: CGFloat = 160
    static let compactHeight: CGFloat = 110
    static let surfaceY: CGFloat = 40

    private static var cache: [String: UIImage] = [:]

    struct NailSpot {
        var x: CGFloat
        var state: NailState
        var tint: NailTint = .steel
    }

    // MARK: - Oyun için parçalar

    /// Sabit kısım: metal gövde, makaralar, uyarı şeridi ve (isteğe bağlı) vuruş oku.
    static func frameImage(marker: Bool) -> UIImage {
        let key = "frame-\(marker)"
        if let img = cache[key] { return img }
        let img = Art.render(size: CGSize(width: unitWidth, height: fullHeight)) { ctx in
            drawFrame(ctx, marker: marker)
        }
        cache[key] = img
        return img
    }

    /// Kayan kısım: kauçuk bant + tahta kalaslar. Yatayda 390'lık periyotla kesintisiz tekrar eder.
    static func trackImage() -> UIImage {
        let key = "track"
        if let img = cache[key] { return img }
        let img = Art.render(size: CGSize(width: unitWidth, height: fullHeight)) { ctx in
            drawTrack(ctx)
        }
        cache[key] = img
        return img
    }

    // MARK: - Menü / oyun sonu için hazır sahne

    /// Bandı ve üzerindeki çivileri tek görsel olarak çizer.
    /// Görselin alt kenarı bandın alt kenarıdır; üstte çiviler için boşluk bırakılır.
    static func sceneImage(width: CGFloat, compact: Bool, nails: [NailSpot], nailSize: CGFloat) -> UIImage {
        let key = "scene-\(width)-\(compact)-\(nailSize)-" + nails.map { "\($0.x)\($0.state)\($0.tint)" }.joined(separator: ",")
        if let img = cache[key] { return img }

        let s = width / unitWidth
        let beltH = (compact ? compactHeight : fullHeight) * s
        let headroom = max(0, nailSize - surfaceY * s) + 4
        let size = CGSize(width: width, height: beltH + headroom)

        let img = Art.render(size: size) { ctx in
            ctx.saveGState()
            ctx.translateBy(x: 0, y: headroom)
            ctx.clip(to: CGRect(x: 0, y: 0, width: width, height: beltH))
            ctx.scaleBy(x: s, y: s)
            drawFrame(ctx, marker: false)
            drawTrack(ctx)
            ctx.restoreGState()

            for n in nails {
                ctx.saveGState()
                ctx.translateBy(x: n.x * s - nailSize / 2, y: headroom + surfaceY * s - nailSize)
                ctx.scaleBy(x: nailSize / 100, y: nailSize / 100)
                NailArt.draw(ctx, n.state, n.tint)
                ctx.restoreGState()
            }
        }
        cache[key] = img
        return img
    }

    // MARK: - Çizim

    private static func drawFrame(_ ctx: CGContext, marker: Bool) {
        let metal = Art.gradient([UIColor(hex: 0x7C8693), UIColor(hex: 0x4E5662), UIColor(hex: 0x2C3139)], [0, 0.5, 1])
        let roll = Art.gradient([UIColor(hex: 0xD5DBE2), UIColor(hex: 0x7C8693)])

        Art.shape(ctx, Art.rect(-10, 100, 410, 44), metal, .vertical, stroke: 4)
        Art.fill(ctx, Art.rect(-10, 104, 410, 4), Art.white(0.18))

        var spokes = [CGPoint]()
        for i in 0..<5 {
            let cx = 35 + CGFloat(i) * 80
            let circle = CGPath(ellipseIn: CGRect(x: cx - 12, y: 112, width: 24, height: 24), transform: nil)
            Art.shape(ctx, circle, roll, .vertical, stroke: 3.5)
            spokes += [Art.pt(cx - 6, 124), Art.pt(cx + 6, 124), Art.pt(cx, 118), Art.pt(cx, 130)]
        }
        ctx.saveGState()
        ctx.setStrokeColor(Art.outline.cgColor)
        ctx.setLineWidth(2.5)
        ctx.setLineCap(.round)
        ctx.strokeLineSegments(between: spokes)
        ctx.restoreGState()

        // Sarı-siyah uyarı şeridi
        let hazard = CGRect(x: -10, y: 144, width: 410, height: 12)
        ctx.saveGState()
        ctx.clip(to: hazard)
        ctx.setFillColor(Palette.yellow.cgColor)
        ctx.fill(hazard)
        ctx.setFillColor(Art.outline.cgColor)
        var x: CGFloat = -10
        while x < 400 {
            let stripe = Art.path { p in
                p.addLines(between: [Art.pt(x, 156), Art.pt(x + 7, 144), Art.pt(x + 14, 144), Art.pt(x + 7, 156)])
                p.closeSubpath()
            }
            ctx.addPath(stripe)
            ctx.fillPath()
            x += 20
        }
        ctx.restoreGState()
        Art.stroke(ctx, CGPath(rect: hazard, transform: nil), Art.outline, 3.5)

        if marker {
            let tri = Art.path { p in
                p.addLines(between: [Art.pt(183, 118), Art.pt(207, 118), Art.pt(195, 104)])
                p.closeSubpath()
            }
            Art.fill(ctx, tri, Palette.yellow)
            Art.stroke(ctx, tri, Art.outline, 3)
        }
    }

    private static func drawTrack(_ ctx: CGContext) {
        // Kauçuk bant (yatayda kesintisiz)
        Art.fill(ctx, Art.rect(0, 84, unitWidth, 18), UIColor(hex: 0x2B2B31))
        let edges = Art.path { p in
            p.move(to: Art.pt(0, 84)); p.addLine(to: Art.pt(unitWidth, 84))
            p.move(to: Art.pt(0, 102)); p.addLine(to: Art.pt(unitWidth, 102))
        }
        Art.stroke(ctx, edges, Art.outline, 4, cap: .butt)

        // Akış yönünü gösteren oklar (sağdan sola)
        let treads = Art.path { p in
            for i in 0..<20 {
                let x = CGFloat(i) * 19.5 + 4
                p.move(to: Art.pt(x + 7, 88))
                p.addLine(to: Art.pt(x, 93))
                p.addLine(to: Art.pt(x + 7, 98))
            }
        }
        Art.stroke(ctx, treads, UIColor(hex: 0x4B4B55), 3)

        // Tahta kalaslar: 122 genişlik, 8 boşluk, periyot 390
        let woodA = Art.gradient([UIColor(hex: 0xEBB273), UIColor(hex: 0xC98A4B), UIColor(hex: 0x95602F)], [0, 0.5, 1])
        let woodB = Art.gradient([UIColor(hex: 0xE2A566), UIColor(hex: 0xBC7D40), UIColor(hex: 0x8A5628)], [0, 0.5, 1])
        let grainColor = UIColor(hex: 0x7E4B20, alpha: 0.45)
        let starts: [CGFloat] = [4, 134, 264]

        for (i, x) in starts.enumerated() {
            Art.shape(ctx, Art.rect(x, 40, 122, 48, r: 5), i == 1 ? woodB : woodA, .vertical, stroke: 4)

            let top = Art.path { p in
                p.move(to: Art.pt(x + 6, 45)); p.addLine(to: Art.pt(x + 116, 45))
            }
            Art.stroke(ctx, top, UIColor(hex: 0xFFD9A8, alpha: 0.7), 3)

            let shift = CGFloat(i) * 4
            let grain = Art.path { p in
                p.move(to: Art.pt(x + 6, 62 - shift / 2))
                p.addCurve(to: Art.pt(x + 112, 61), control1: Art.pt(x + 36, 57 + shift), control2: Art.pt(x + 70, 69 - shift))
                p.move(to: Art.pt(x + 14, 76))
                p.addCurve(to: Art.pt(x + 110, 74 + shift / 2), control1: Art.pt(x + 44, 72), control2: Art.pt(x + 76, 81 - shift))
            }
            Art.stroke(ctx, grain, grainColor, 2)

            Art.fill(ctx, Art.rect(x + 2, 42, 5, 44), Art.white(0.12))
            Art.fill(ctx, Art.rect(x + 115, 42, 5, 44), Art.black(0.18))
        }

        // Budaklar
        let knot1 = CGPath(ellipseIn: CGRect(x: 134 + 74 - 7, y: 66 - 3.5, width: 14, height: 7), transform: nil)
        Art.fill(ctx, knot1, UIColor(hex: 0x8A5628, alpha: 0.8))
        Art.stroke(ctx, knot1, UIColor(hex: 0x7E4B20), 1.5)
        let knot2 = CGPath(ellipseIn: CGRect(x: 4 + 58 - 5, y: 70 - 2.5, width: 10, height: 5), transform: nil)
        Art.fill(ctx, knot2, UIColor(hex: 0x8A5628, alpha: 0.6))
    }
}
