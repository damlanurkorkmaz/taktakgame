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
    /// Kırmızı çivi: vurulmamalı (kırmızı baş, üstünde beyaz çizgi)
    case red
    /// Metal levhalı çivi: yalnızca mükemmel vuruş işe yarar
    case plate
    /// Yaylı çivi: vurulunca geri zıplar
    case spring
    /// Buz çivisi: bant üstünde kayar
    case ice
    /// Bomba çivi: tam vurulunca patlar
    case bomb
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

    private static let steel = [UIColor(hex: 0xF7FAFC), UIColor(hex: 0xAEB7C2), UIColor(hex: 0x5E6875)]

    private static func headColors(_ tint: NailTint) -> [UIColor] {
        switch tint {
        case .steel, .plate, .bomb: return steel
        case .gold: return [UIColor(hex: 0xFFF3B8), UIColor(hex: 0xF5B82E), UIColor(hex: 0x9C5F08)]
        case .hard: return [UIColor(hex: 0xB8C0CA), UIColor(hex: 0x5B6470), UIColor(hex: 0x262B33)]
        case .red: return [UIColor(hex: 0xFFB3A6), UIColor(hex: 0xE0503F), UIColor(hex: 0x8E2018)]
        case .spring: return [UIColor(hex: 0xC8F5DA), UIColor(hex: 0x5FD3A4), UIColor(hex: 0x2E8A66)]
        case .ice: return [UIColor(hex: 0xF2FCFF), UIColor(hex: 0x9FDCF5), UIColor(hex: 0x3F8DB8)]
        }
    }

    private static func shaftColors(_ tint: NailTint) -> [UIColor] {
        switch tint {
        case .gold, .hard, .ice: return headColors(tint)
        default: return steel
        }
    }

    /// 100x100 kutuya çizer.
    static func draw(_ ctx: CGContext, _ state: NailState, _ tint: NailTint) {
        let colors = headColors(tint)
        let sColors = shaftColors(tint)
        let headG = Art.gradient(colors, [0, 0.5, 1])
        let shaftG = Art.gradient(sColors, [0, 0.45, 1])

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

        if tint == .plate {
            // Tahtanın üstünde, çivinin altında metal levha
            let plateG = Art.gradient([UIColor(hex: 0xE9EEF3), UIColor(hex: 0x7C8693)])
            Art.shape(ctx, Art.rect(-10, 91, 80, 9, r: 2), plateG, .vertical, stroke: 3)
            ctx.setFillColor(Art.outline.cgColor)
            ctx.fillEllipse(in: CGRect(x: -4.8, y: 93.7, width: 3.6, height: 3.6))
            ctx.fillEllipse(in: CGRect(x: 61.2, y: 93.7, width: 3.6, height: 3.6))
        }

        if state == .bent {
            let shaft = Art.path { p in
                p.move(to: Art.pt(30, 100))
                p.addLine(to: Art.pt(30, 80))
                p.addQuadCurve(to: Art.pt(39, 63), control: Art.pt(30, 70))
                p.addLine(to: Art.pt(50, 54))
            }
            Art.stroke(ctx, shaft, Art.outline, shaftW + 4)
            Art.stroke(ctx, shaft, sColors[1], shaftW - 2.5)
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
            ctx.restoreGState()
            return
        }

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
            } else if tint != .spring {
                let rings = Art.path { p in
                    for y in stride(from: CGFloat(76), through: 92, by: 8) where y > shaftY + 2 {
                        p.move(to: Art.pt(shaftX + 2, y)); p.addLine(to: Art.pt(shaftX + shaftW - 2, y - 3))
                    }
                }
                Art.stroke(ctx, rings, Art.outline.withAlphaComponent(0.35), 1.5)
            }
            if tint == .spring && state == .up {
                let coil = Art.path { p in
                    p.addLines(between: [Art.pt(22, 44), Art.pt(38, 50), Art.pt(22, 56), Art.pt(38, 62),
                                         Art.pt(22, 68), Art.pt(38, 74), Art.pt(22, 80)])
                }
                Art.stroke(ctx, coil, Art.outline, 6)
                Art.stroke(ctx, coil, Palette.green, 3)
            }
            if tint == .ice {
                ctx.setFillColor(UIColor.white.cgColor)
                let dots: [(CGFloat, CGFloat, CGFloat)] = [(27, 52, 1.6), (32, 66, 1.3), (28, 82, 1.6)]
                for (x, y, r) in dots where y > shaftY + 2 {
                    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                }
            }
            Art.fill(ctx, Art.rect(shaftX + 2.5, shaftY, 2.5, h), Art.white(0.5))
        }

        if tint == .bomb && state == .up {
            drawBomb(ctx, centerY: headY + 4)
        } else {
            Art.shape(ctx, Art.rect(headX, headY, headW, headH, r: headH / 2), headG, .vertical, stroke: 3.5)
            Art.fill(ctx, Art.rect(headX + 7, headY + 3, 24, 3, r: 1.5), Art.white(0.75))
            if hard {
                Art.fill(ctx, Art.rect(headX + headW - 14, headY + 4, 6, headH - 8, r: 2), stripe)
            }
            if tint == .red {
                // "Vurma" işareti: başın ortasında beyaz çizgi
                Art.fill(ctx, Art.rect(18, headY + (headH - 5) / 2, 24, 5, r: 2.5), .white)
            }
            if tint == .ice {
                let marks = Art.path { p in
                    p.addLines(between: [Art.pt(18, headY + 8), Art.pt(22, headY + 5), Art.pt(26, headY + 8)])
                    p.addLines(between: [Art.pt(34, headY + 8), Art.pt(38, headY + 5), Art.pt(42, headY + 8)])
                }
                Art.stroke(ctx, marks, .white, 1.8)
            }
        }

        ctx.restoreGState()
    }

    /// Bomba çivinin başı: siyah küre, fitil ve kıvılcım.
    private static func drawBomb(_ ctx: CGContext, centerY cy: CGFloat) {
        let fuse = Art.path { p in
            p.move(to: Art.pt(38, cy - 12))
            p.addQuadCurve(to: Art.pt(50, cy - 22), control: Art.pt(46, cy - 26))
        }
        Art.stroke(ctx, fuse, Art.outline, 5)
        Art.stroke(ctx, fuse, UIColor(hex: 0xC98A4B), 2.5)

        let ball = CGPath(ellipseIn: CGRect(x: 15, y: cy - 15, width: 30, height: 30), transform: nil)
        ctx.saveGState()
        ctx.addPath(ball)
        ctx.clip()
        let g = Art.gradient([UIColor(hex: 0x6A6A6A), UIColor(hex: 0x111111)])
        ctx.drawRadialGradient(g, startCenter: Art.pt(25, cy - 6), startRadius: 0,
                               endCenter: Art.pt(28, cy - 2), endRadius: 22, options: [.drawsAfterEndLocation])
        ctx.restoreGState()
        Art.stroke(ctx, ball, Art.outline, 3.5)
        ctx.setFillColor(Art.white(0.45).cgColor)
        ctx.fillEllipse(in: CGRect(x: 20, y: cy - 9, width: 10, height: 6))

        let sx: CGFloat = 51
        let sy = cy - 27
        let spark = Art.path { p in
            p.addLines(between: [Art.pt(sx, sy), Art.pt(sx + 2, sy - 6), Art.pt(sx + 4, sy), Art.pt(sx + 10, sy + 2),
                                 Art.pt(sx + 4, sy + 4), Art.pt(sx + 2, sy + 10), Art.pt(sx, sy + 4), Art.pt(sx - 6, sy + 2)])
            p.closeSubpath()
        }
        Art.fill(ctx, spark, Palette.yellow)
        Art.stroke(ctx, spark, Art.outline, 1.2)
    }
}
