import UIKit

enum NailState {
    case up, half, driven, bent
}

enum NailTint {
    /// Normal çelik çivi
    case steel
    /// Altın çivi: bonus para
    case gold
    /// Zorlu çivi: kalın, koyu, turuncu çizgili; iki tam vuruş ister
    case hard
}

/// Çivi çizimi. Tasarımdaki Nail bileşeni (60x100) 100x100'lük kare bir kutunun ortasına çizilir;
/// böylece eğilmiş çivinin başı da kutunun içinde kalır.
/// Kutunun alt kenarı = tahtanın yüzeyi, yatay orta = çivinin ekseni.
enum NailArt {
    private static var cache: [String: UIImage] = [:]

    /// Çivi başının üst kenarının yüzeyden yüksekliği (kutu yüksekliğinin oranı).
    static func headTopRatio(_ state: NailState) -> CGFloat {
        switch state {
        case .up: return 0.80
        case .half: return 0.44
        case .driven: return 0.12
        case .bent: return 0.55
        }
    }

    static func image(_ state: NailState, _ tint: NailTint, size: CGFloat) -> UIImage {
        let key = "\(state)-\(tint)-\(size)"
        if let img = cache[key] { return img }
        let img = Art.render(size: CGSize(width: size, height: size)) { ctx in
            ctx.scaleBy(x: size / 100, y: size / 100)
            draw(ctx, state, tint)
        }
        cache[key] = img
        return img
    }

    /// 100x100 kutuya çizer.
    static func draw(_ ctx: CGContext, _ state: NailState, _ tint: NailTint) {
        let colors: [UIColor]
        switch tint {
        case .steel: colors = [UIColor(hex: 0xF7FAFC), UIColor(hex: 0xAEB7C2), UIColor(hex: 0x5E6875)]
        case .gold: colors = [UIColor(hex: 0xFFF3B8), UIColor(hex: 0xF5B82E), UIColor(hex: 0x9C5F08)]
        case .hard: colors = [UIColor(hex: 0xB8C0CA), UIColor(hex: 0x5B6470), UIColor(hex: 0x262B33)]
        }
        let headG = Art.gradient(colors, [0, 0.5, 1])
        let shaftG = Art.gradient(colors, [0, 0.45, 1])

        // Zorlu çivi daha kalın: gövde 14, baş 54 genişliğinde.
        let hard = tint == .hard
        let shaftW: CGFloat = hard ? 14 : 10
        let shaftX: CGFloat = 30 - shaftW / 2
        let headW: CGFloat = hard ? 54 : 48
        let headX: CGFloat = 30 - headW / 2
        let headH: CGFloat = hard ? 14 : 12
        let stripe = Palette.orange

        ctx.saveGState()
        ctx.translateBy(x: 20, y: 0)

        if state == .bent {
            let shaft = Art.path { p in
                p.move(to: Art.pt(30, 100))
                p.addLine(to: Art.pt(30, 80))
                p.addQuadCurve(to: Art.pt(39, 63), control: Art.pt(30, 70))
                p.addLine(to: Art.pt(50, 54))
            }
            Art.stroke(ctx, shaft, Art.outline, shaftW + 4)
            Art.stroke(ctx, shaft, colors[1], shaftW - 2.5)
            let shine = Art.path { p in
                p.move(to: Art.pt(28, 98))
                p.addLine(to: Art.pt(28, 80))
                p.addQuadCurve(to: Art.pt(35, 66), control: Art.pt(28, 72))
            }
            Art.stroke(ctx, shine, Art.white(0.5), 2)

            ctx.saveGState()
            ctx.translateBy(x: 54, y: 50)
            ctx.rotate(by: -50 * .pi / 180)
            ctx.translateBy(x: -54, y: -50)
            Art.shape(ctx, Art.rect(54 - headW / 2, 50 - headH / 2, headW, headH, r: headH / 2), headG, .vertical, stroke: 3.5)
            Art.fill(ctx, Art.rect(54 - headW / 2 + 7, 50 - headH / 2 + 3, 24, 3, r: 1.5), Art.white(0.75))
            ctx.restoreGState()
        } else {
            let headY: CGFloat
            switch state {
            case .half: headY = 56
            case .driven: headY = 100 - headH
            default: headY = 20
            }
            let shaftY = headY + headH - 2
            if state != .driven {
                let h = 100 - shaftY
                Art.shape(ctx, Art.rect(shaftX, shaftY, shaftW, h), shaftG, .horizontal, stroke: 3.5)

                if hard {
                    // Turuncu uyarı bantları: "bu çivi farklı" işareti
                    for y in [CGFloat(72), 86] where y > shaftY + 2 {
                        Art.fill(ctx, Art.rect(shaftX + 1.5, y, shaftW - 3, 6), stripe)
                    }
                } else {
                    let rings = Art.path { p in
                        for y in stride(from: CGFloat(76), through: 92, by: 8) where y > shaftY + 2 {
                            p.move(to: Art.pt(shaftX + 2, y)); p.addLine(to: Art.pt(shaftX + shaftW - 2, y - 3))
                        }
                    }
                    Art.stroke(ctx, rings, Art.outline.withAlphaComponent(0.35), 1.5)
                }
                Art.fill(ctx, Art.rect(shaftX + 2.5, shaftY, 2.5, h), Art.white(0.5))
            }
            Art.shape(ctx, Art.rect(headX, headY, headW, headH, r: headH / 2), headG, .vertical, stroke: 3.5)
            Art.fill(ctx, Art.rect(headX + 7, headY + 3, 24, 3, r: 1.5), Art.white(0.75))
            if hard {
                // Başın üstünde turuncu halka
                Art.fill(ctx, Art.rect(headX + headW - 14, headY + 4, 6, headH - 8, r: 2), stripe)
            }
        }

        ctx.restoreGState()
    }
}
