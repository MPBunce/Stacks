import SwiftUI

/// Draws a sprite from rows of characters. Each character maps to a color in `palette`;
/// anything not in the palette (like ".") is transparent.
struct PixelSprite: View {
    let rows: [String]
    let palette: [Character: Color]

    var body: some View {
        let w = rows.map(\.count).max() ?? 1
        let h = rows.count
        Canvas { ctx, size in
            let unit = max(min(size.width / CGFloat(w), size.height / CGFloat(h)).rounded(.down), 1)
            let ox = ((size.width - unit * CGFloat(w)) / 2).rounded()
            let oy = ((size.height - unit * CGFloat(h)) / 2).rounded()
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let color = palette[ch] else { continue }
                    let rect = CGRect(x: ox + CGFloat(x) * unit, y: oy + CGFloat(y) * unit, width: unit, height: unit)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .aspectRatio(CGFloat(w) / CGFloat(h), contentMode: .fit)
    }
}

enum Sprites {
    // o = outline, y = body, w = shine, d = shade, K = face features, p = blush
    static let coin = [
        "..oooooooo..",
        ".oyyyyyyyyo.",
        "oywwyyyyyyyo",
        "oyyyyyyyyyyo",
        "oyyyyyyyyydo",
        ".oddddddddo.",
        "..oooooooo..",
    ]

    static let faceHappy = [
        "...oooooo...",
        "..oyyyyyyo..",
        ".oyyyyyyyyo.",
        "oyyKyyyyKyyo",
        "oyyKyyyyKyyo",
        "oypyyyyyypyo",
        "oyKyyyyyyKyo",
        "oyyKKKKKKyyo",
        ".oyyyyyyyyo.",
        "..oyyyyyyo..",
        "...oooooo...",
    ]

    static let faceSad = [
        "...oooooo...",
        "..oyyyyyyo..",
        ".oyyyyyyyyo.",
        "oyyKyyyyKyyo",
        "oyyKyyyyKyyo",
        "oyyyyyyyyyyo",
        "oyyKKKKKKyyo",
        "oyKyyyyyyKyo",
        ".oyyyyyyyyo.",
        "..oyyyyyyo..",
        "...oooooo...",
    ]

    /// A tiny two-leaf seedling that sits on the mascot's head.
    static let sprout = [
        "...gg..gg...",
        "..gggggggg..",
        "...gGggGg...",
        ".....GG.....",
        ".....GG.....",
    ]

    static var gold: [Character: Color] { Pixel.coin }

    static let ash: [Character: Color] = [
        "o": Color(white: 0.18),
        "y": Color(white: 0.55),
        "w": Color(white: 0.75),
        "d": Color(white: 0.38),
        "K": Color(white: 0.1),
        "p": Color(white: 0.5),
        "b": Color(white: 0.5),
        "L": Color(white: 0.5),
        "g": Color(white: 0.5),
        "G": Color(white: 0.4),
    ]
}

/// The coin tower: a sprout-topped mascot on a stack of coins that shrinks as you spend.
/// When over budget the tower collapses into a pile of ash-grey coins.
struct CoinTower: View {
    let coins: Int
    let overBudget: Bool
    var worried = false

    var body: some View {
        VStack(spacing: 0) {
            if overBudget {
                collapsed
            } else {
                standing
            }
            ground
        }
        .animation(.linear(duration: 0.2), value: coins)
    }

    private var ground: some View {
        HStack(spacing: 4) {
            Rectangle().fill(Pixel.groundTop).frame(width: 130, height: 6)
            Rectangle().fill(Pixel.groundTop).frame(width: 36, height: 6).opacity(0.5)
        }
    }

    private var standing: some View {
        VStack(spacing: -28) {
            PixelSprite(rows: Mascot.current.rows(worried ? .worried : .happy), palette: Mascot.current.palette())
                .frame(width: 84)
                .rotationEffect(.degrees(worried ? 4 : 0))
                .zIndex(Double(coins + 1))
            ForEach(0..<coins, id: \.self) { i in
                PixelSprite(rows: Sprites.coin, palette: Sprites.gold)
                    .frame(width: 96)
                    .zIndex(Double(coins - i))
            }
        }
    }

    private var collapsed: some View {
        VStack(spacing: -14) {
            PixelSprite(rows: Mascot.current.rows(.crumbled), palette: Sprites.ash)
                .frame(width: 72)
                .rotationEffect(.degrees(-14))
                .offset(x: 28)
            HStack(spacing: -10) {
                PixelSprite(rows: Sprites.coin, palette: Sprites.ash).frame(width: 60)
                    .rotationEffect(.degrees(12))
                PixelSprite(rows: Sprites.coin, palette: Sprites.ash).frame(width: 72)
                PixelSprite(rows: Sprites.coin, palette: Sprites.ash).frame(width: 48)
                    .rotationEffect(.degrees(-20))
                    .offset(y: 8)
            }
        }
    }
}
