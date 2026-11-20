import SwiftUI

enum MascotMood { case happy, worried, crumbled }

/// The character on top of the coin tower. Colors are derived from the active theme.
enum Mascot: String, CaseIterable, Identifiable {
    case coin, bar, pig, gem, chest, slime
    var id: String { rawValue }
    static let storageKey = "mascot"

    /// Widgets set this from the shared snapshot; the app reads the user's choice from defaults.
    static var override: Mascot?

    static var current: Mascot {
        override ?? Mascot(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .coin
    }

    var title: String {
        switch self {
        case .coin: "Coiny"
        case .bar: "Ingot"
        case .pig: "Penny"
        case .gem: "Gemma"
        case .chest: "Chesty"
        case .slime: "Goo"
        }
    }

    func message(_ mood: MascotMood) -> String {
        let m: (String, String, String)
        switch self {
        case .coin: m = ("ALL STACKED UP!", "WOBBLY... EASY NOW", "TIMBER! COINS EVERYWHERE")
        case .bar: m = ("SOLID GOLD, BABY", "CRACKS ARE SHOWING", "MELTED DOWN")
        case .pig: m = ("OINK! PENNY IS PLEASED", "PENNY IS SWEATING", "PIGGY IS EMPTY")
        case .gem: m = ("SHINING BRIGHT", "FLAWS APPEARING", "SHATTERED!")
        case .chest: m = ("LOCKED AND LOADED", "LID'S RATTLING", "LOOTED!")
        case .slime: m = ("SQUISHY AND SAFE", "WIGGLY... WATCH IT", "SPLAT!")
        }
        switch mood {
        case .happy: return m.0
        case .worried: return m.1
        case .crumbled: return m.2
        }
    }

    // MARK: Sprite data (o outline, y body, w shine, d shade, K features, p blush, L clasp, b sweat)

    private var body: [String] {
        switch self {
        case .coin:
            ["...oooooo...", "..oyyyyyyo..", ".oyywyyyyyo.", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oyyyyyyyyyyo",
             "oyyyyyyyyyyo", "oyyyyyyyyyyo", ".oyyyyyyyyo.", "..oyyyyyyo..", "...oooooo..."]
        case .bar:
            ["..oooooooo..", ".oyyyyyyyyo.", "oywwyyyyyyyo", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oyyyyyyyyyyo",
             "oyyyyyyyyyyo", "oddddddddddo", "oooooooooooo"]
        case .pig:
            ["..oo....oo..", ".oyyooooyyo.", ".oyyyyyyyyo.", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oyyyooooooyo",
             "oyyyodKKdoyo", "oyyyooooooyo", ".oyyyyyyyyo.", "..oooooooo.."]
        case .gem:
            ["...oooooo...", "..oyywyyyo..", ".oyyyyyyyyo.", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oyyyyyyyyyyo",
             ".oyyyyyyyyo.", "..oyyyyyyo..", "...oyyyyo...", "....oooo...."]
        case .chest:
            [".oooooooooo.", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "ooooLLLLoooo", "oyyyyyyyyyyo",
             "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oddddddddddo", "oooooooooooo"]
        case .slime:
            ["............", "....oooo....", "..ooyyyyoo..", ".oyyyyyyyyo.", ".oyywyyyyyo.", "oyyyyyyyyyyo",
             "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oyyyyyyyyyyo", "oooooooooooo"]
        }
    }

    private var face: (ex: [Int], ey: Int, mx: Int, my: Int, mw: Int) {
        switch self {
        case .coin: ([3, 8], 3, 3, 7, 6)
        case .bar: ([3, 8], 3, 4, 6, 4)
        case .pig: ([2, 9], 3, 0, 0, 0)
        case .gem: ([3, 8], 3, 4, 6, 4)
        case .chest: ([3, 8], 2, 4, 7, 4)
        case .slime: ([3, 8], 4, 4, 7, 4)
        }
    }

    /// Character grid with the facial expression for `mood` drawn in.
    func rows(_ mood: MascotMood) -> [String] {
        var g = body.map { Array($0) }
        func put(_ x: Int, _ y: Int, _ c: Character, force: Bool = false) {
            guard y >= 0, y < g.count, x >= 0, x < g[y].count else { return }
            if force || g[y][x] != "." { g[y][x] = c }
        }
        let f = face
        for x in f.ex {
            if mood == .crumbled { put(x, f.ey + 1, "K"); put(x + 1, f.ey + 1, "K") }
            else { put(x, f.ey, "K"); put(x, f.ey + 1, "K") }
        }
        if mood == .happy { put(f.ex[0] - 1, f.ey + 2, "p"); put(f.ex[1] + 1, f.ey + 2, "p") }
        if f.mw > 0 {
            for i in 0..<f.mw {
                let edge = i == 0 || i == f.mw - 1
                if mood == .worried && edge { continue }
                var y = f.my
                if mood == .happy && edge { y -= 1 }
                if mood == .crumbled && edge { y += 1 }
                put(f.mx + i, y, "K")
            }
        }
        if mood == .worried { put(min(f.ex[1] + 2, 11), f.ey - 1, "b", force: true); put(min(f.ex[1] + 2, 11), f.ey, "b", force: true) }
        return g.map { String($0) }
    }

    // MARK: Themed colors

    private func tint(_ t: Theme) -> Color {
        switch (self, t) {
        case (.pig, .neon): return Color(red: 1, green: 0.24, blue: 0.65)
        case (.pig, .candy): return Color(red: 1, green: 0.48, blue: 0.72)
        case (.pig, .sky): return Color(red: 1, green: 0.56, blue: 0.66)
        case (.pig, .synth): return Color(red: 1, green: 0.31, blue: 0.85)
        case (.pig, .ice): return Color(red: 0.86, green: 0.93, blue: 0.97)
        case (.pig, .reef): return Color(red: 1, green: 0.44, blue: 0.35)
        case (.pig, .farm): return Color(red: 1, green: 0.62, blue: 0.72)
        case (.slime, .neon): return Color(red: 0.24, green: 0.95, blue: 0.54)
        case (.slime, .candy): return Color(red: 0.55, green: 0.89, blue: 0.78)
        case (.slime, .sky): return Color(red: 0.48, green: 0.88, blue: 0.75)
        case (.slime, .synth): return Color(red: 0, green: 0.94, blue: 0.71)
        case (.slime, .ice): return Color(red: 0.66, green: 0.78, blue: 0.87)
        case (.slime, .reef): return Color(red: 0.18, green: 0.77, blue: 0.71)
        case (.slime, .farm): return Color(red: 0.55, green: 0.85, blue: 0.30)
        case (.gem, .neon): return Color(red: 0.30, green: 0.88, blue: 1)
        case (.gem, .candy): return Color(red: 0.73, green: 0.64, blue: 1)
        case (.gem, .sky): return Color(red: 0.48, green: 0.42, blue: 1)
        case (.gem, .synth): return Color(red: 0, green: 0.94, blue: 1)
        case (.gem, .ice): return Color(red: 0.50, green: 0.64, blue: 0.78)
        case (.gem, .reef): return Color(red: 1, green: 0.82, blue: 0.25)
        case (.gem, .farm): return Color(red: 0.37, green: 0.78, blue: 1)
        default: return t.palette.frameLight
        }
    }

    func palette(for theme: Theme = .current) -> [Character: Color] {
        let p = theme.palette
        var pal = p.coin
        pal["b"] = p.frameDark
        pal["L"] = p.accent
        if self == .coin || self == .bar { return pal }
        let c = tint(theme)
        pal["y"] = c
        pal["o"] = c.shaded(0.38)
        pal["d"] = c.shaded(0.78)
        pal["w"] = c.lightened(0.65)
        pal["K"] = c.shaded(0.22)
        pal["p"] = c.lightened(0.35)
        return pal
    }
}

extension Color {
    func shaded(_ factor: CGFloat) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: min(1, s * 1.1), brightness: b * factor)
    }

    func lightened(_ amount: CGFloat) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(red: r + (1 - r) * amount, green: g + (1 - g) * amount, blue: b + (1 - b) * amount)
    }
}

/// Speech bubble with a tail pointing down at the mascot.
struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Pixel.font(14))
            .foregroundStyle(Pixel.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Pixel.field)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Pixel.field)
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(45))
                    .offset(y: 5)
            }
            .padding(.bottom, 8)
    }
}
