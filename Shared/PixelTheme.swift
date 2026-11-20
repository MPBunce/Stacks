import SwiftUI

// MARK: - Themes

enum Decor { case grass, grid, checker, clouds, sun, bubbles, dither }

struct Palette {
    var bg, bgDark, bgLight: Color
    var bgBottom: Color? = nil          // optional vertical gradient end
    var frame, frameDark, frameLight: Color
    var panel, panelDark, field: Color
    var ink, dim: Color
    var accent, accentDark, onAccent, amber: Color
    var good, bad, heading, track, titleShadow, groundTop: Color
    var coin: [Character: Color]
    var decor: Decor
}

private func hex(_ v: UInt32) -> Color {
    Color(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255)
}

private func coinPalette(_ o: UInt32, _ y: UInt32, _ w: UInt32, _ d: UInt32, _ K: UInt32, _ p: UInt32, _ g: UInt32, _ G: UInt32) -> [Character: Color] {
    ["o": hex(o), "y": hex(y), "w": hex(w), "d": hex(d), "K": hex(K), "p": hex(p), "g": hex(g), "G": hex(G)]
}

enum Theme: String, CaseIterable, Identifiable {
    case neon, candy, sky, synth, ice, reef, farm
    var id: String { rawValue }
    static let storageKey = "theme"

    /// Widgets set this from the shared snapshot; the app reads the user's choice from defaults.
    static var override: Theme?

    static var current: Theme {
        override ?? Theme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .neon
    }

    var title: String {
        switch self {
        case .neon: "Neon Arcade"
        case .candy: "Candy Pop"
        case .sky: "Sky High"
        case .synth: "Synthwave Sunset"
        case .ice: "Handheld Ice"
        case .reef: "Coral Reef"
        case .farm: "Farm Sim"
        }
    }

    /// Light backdrops need dark status-bar text.
    var isLight: Bool { self == .candy || self == .sky || self == .ice }

    var palette: Palette {
        switch self {
        case .neon:
            Palette(bg: hex(0x0d0b24), bgDark: hex(0x08071a), bgLight: hex(0x1a1848),
                    frame: hex(0x2b2a63), frameDark: hex(0x4de1ff), frameLight: hex(0x4a49a0),
                    panel: hex(0x1d1a45), panelDark: hex(0x2b2a63), field: hex(0x08071a),
                    ink: .white, dim: hex(0x9aa3d6),
                    accent: hex(0xffd23f), accentDark: hex(0xd98a00), onAccent: hex(0x2a1700), amber: hex(0xffd23f),
                    good: hex(0x3cf28a), bad: hex(0xff4f6d), heading: hex(0xe8ecff), track: hex(0x08071a),
                    titleShadow: hex(0xff3ea5), groundTop: hex(0x4de1ff),
                    coin: coinPalette(0x7a4a00, 0xffd23f, 0xffffff, 0xd98a00, 0x3a1a00, 0xff9db8, 0x5cff8a, 0x1fae55),
                    decor: .grid)
        case .candy:
            Palette(bg: hex(0xffe1ef), bgDark: hex(0xffd0e6), bgLight: hex(0xffeef6),
                    frame: hex(0xffb3d6), frameDark: hex(0xff7ab8), frameLight: hex(0xffd0e6),
                    panel: hex(0xfff8fc), panelDark: hex(0xf6dcec), field: .white,
                    ink: hex(0x5a2a64), dim: hex(0x7a4a86),
                    accent: hex(0xffd86b), accentDark: hex(0xffb35c), onAccent: hex(0x5a2a64), amber: hex(0x9a4d00),
                    good: hex(0x0b7a5c), bad: hex(0xc41e48), heading: hex(0x5a2a64), track: hex(0x5a2a64),
                    titleShadow: hex(0x6f3bd6), groundTop: hex(0x8be3c8),
                    coin: coinPalette(0xb8527f, 0xffd86b, 0xffffff, 0xffb35c, 0x5a2a64, 0xff8fb0, 0x8be3c8, 0x2fb58f),
                    decor: .checker)
        case .sky:
            Palette(bg: hex(0x58b6ff), bgDark: hex(0x4aa6f0), bgLight: hex(0xc4e8ff), bgBottom: hex(0xc4e8ff),
                    frame: hex(0x1f5fbf), frameDark: hex(0x123a7a), frameLight: hex(0x4f8fe0),
                    panel: .white, panelDark: hex(0xd9ecff), field: .white,
                    ink: hex(0x123a7a), dim: hex(0x3a5f99),
                    accent: hex(0xffd23f), accentDark: hex(0xe0a000), onAccent: hex(0x123a7a), amber: hex(0x9a5a00),
                    good: hex(0x15703c), bad: hex(0xc41e34), heading: hex(0x0b2d66), track: hex(0x123a7a),
                    titleShadow: hex(0x1f5fbf), groundTop: .white,
                    coin: coinPalette(0x8a5a00, 0xffd23f, 0xffffff, 0xe0a000, 0x3a2500, 0xff9db8, 0x6fdc6f, 0x2e9e4a),
                    decor: .clouds)
        case .synth:
            Palette(bg: hex(0x3b0f70), bgDark: hex(0x1b0a3d), bgLight: hex(0x5a1a9a), bgBottom: hex(0x6a1660),
                    frame: hex(0x2a1255), frameDark: hex(0xff4fd8), frameLight: hex(0x5a2a9a),
                    panel: hex(0x2a1255), panelDark: hex(0x1b0a3d), field: hex(0x12062b),
                    ink: hex(0xfff0ff), dim: hex(0xc9a6ff),
                    accent: hex(0x00f0ff), accentDark: hex(0x0aa7b5), onAccent: hex(0x1b0a3d), amber: hex(0xffcc33),
                    good: hex(0x00f0b4), bad: hex(0xff5c7a), heading: hex(0xfff0ff), track: hex(0x12062b),
                    titleShadow: hex(0xff4fd8), groundTop: hex(0x00f0ff),
                    coin: coinPalette(0x5b1060, 0xffe066, 0xffffff, 0xff9f43, 0x3b0f4d, 0xff7ab8, 0x00f0ff, 0x0aa7b5),
                    decor: .sun)
        case .ice:
            Palette(bg: hex(0x7fa3c7), bgDark: hex(0x6f93b7), bgLight: hex(0x8fb3d7),
                    frame: hex(0x2f4a6b), frameDark: hex(0x0f1b2d), frameLight: hex(0x4f6f95),
                    panel: hex(0xdcecf7), panelDark: hex(0xa9c6df), field: hex(0xeef6fb),
                    ink: hex(0x0f1b2d), dim: hex(0x1f3550),
                    accent: hex(0xdcecf7), accentDark: hex(0x7fa3c7), onAccent: hex(0x0f1b2d), amber: hex(0x0f1b2d),
                    good: hex(0x0f1b2d), bad: hex(0x0f1b2d), heading: hex(0x0f1b2d), track: hex(0x7fa3c7),
                    titleShadow: hex(0x0f1b2d), groundTop: hex(0xdcecf7),
                    coin: coinPalette(0x0f1b2d, 0xdcecf7, 0xffffff, 0x7fa3c7, 0x0f1b2d, 0x7fa3c7, 0x7fa3c7, 0x2f4a6b),
                    decor: .dither)
        case .reef:
            Palette(bg: hex(0x0b3c49), bgDark: hex(0x06252d), bgLight: hex(0x0e6e7e), bgBottom: hex(0x06252d),
                    frame: hex(0x072a33), frameDark: hex(0xff6f59), frameLight: hex(0x0e6e7e),
                    panel: hex(0xe6fbff), panelDark: hex(0xc3eaf1), field: .white,
                    ink: hex(0x0b3c49), dim: hex(0x2f6a78),
                    accent: hex(0xff6f59), accentDark: hex(0xc9452f), onAccent: hex(0x3b0d05), amber: hex(0x9a5800),
                    good: hex(0x08705f), bad: hex(0xd7263d), heading: hex(0xe6fbff), track: hex(0x06252d),
                    titleShadow: hex(0x06252d), groundTop: hex(0x2ec4b6),
                    coin: coinPalette(0x7a4a00, 0xffd23f, 0xffffff, 0xe0a000, 0x3a1a00, 0xff9db8, 0x2ec4b6, 0x0e8a80),
                    decor: .bubbles)
        case .farm:
            Palette(bg: Color(red: 0.42, green: 0.68, blue: 0.30), bgDark: Color(red: 0.33, green: 0.57, blue: 0.24), bgLight: Color(red: 0.52, green: 0.77, blue: 0.36),
                    frame: Color(red: 0.62, green: 0.38, blue: 0.17), frameDark: Color(red: 0.36, green: 0.20, blue: 0.09), frameLight: Color(red: 0.80, green: 0.55, blue: 0.27),
                    panel: Color(red: 0.98, green: 0.90, blue: 0.68), panelDark: Color(red: 0.90, green: 0.78, blue: 0.52), field: Color(red: 1.0, green: 0.96, blue: 0.82),
                    ink: Color(red: 0.33, green: 0.18, blue: 0.07), dim: Color(red: 0.45, green: 0.30, blue: 0.15),
                    accent: Color(red: 1.0, green: 0.80, blue: 0.20), accentDark: Color(red: 0.80, green: 0.52, blue: 0.10),
                    onAccent: Color(red: 0.33, green: 0.18, blue: 0.07), amber: Color(red: 0.58, green: 0.31, blue: 0.02),
                    good: Color(red: 0.14, green: 0.45, blue: 0.14), bad: Color(red: 0.68, green: 0.15, blue: 0.13),
                    heading: Color(red: 0.20, green: 0.10, blue: 0.04), track: Color(red: 0.25, green: 0.13, blue: 0.05),
                    titleShadow: Color(red: 0.36, green: 0.20, blue: 0.09), groundTop: Color(red: 0.52, green: 0.77, blue: 0.36),
                    coin: coinPalette(0x733f0d, 0xffcc33, 0xffffff, 0xcc8419, 0x401a00, 0xff8c80, 0x8cd94d, 0x408c33),
                    decor: .grass)
        }
    }
}

/// Color tokens. Everything reads the active theme, so changing it and rebuilding the view tree re-skins the app.
enum Pixel {
    private static var p: Palette { Theme.current.palette }

    // Background
    static var grass: Color { p.bg }
    static var grassDark: Color { p.bgDark }
    static var grassLight: Color { p.bgLight }

    // Frames
    static var wood: Color { p.frame }
    static var woodDark: Color { p.frameDark }
    static var woodLight: Color { p.frameLight }

    // Panels & ink
    static var parchment: Color { p.panel }
    static var parchmentDark: Color { p.panelDark }
    static var field: Color { p.field }
    static var ink: Color { p.ink }
    static var dim: Color { p.dim }

    // Accents
    static var gold: Color { p.accent }
    static var goldDark: Color { p.accentDark }
    static var onAccent: Color { p.onAccent }
    static var amber: Color { p.amber }
    static var green: Color { p.good }
    static var red: Color { p.bad }
    static var heading: Color { p.heading }
    static var track: Color { p.track }
    static var titleShadow: Color { p.titleShadow }
    static var groundTop: Color { p.groundTop }
    static var coin: [Character: Color] { p.coin }
    static var bg: Color { p.bg }

    private static func luminance(_ c: Color) -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    /// Flat sections sit straight on the background on dark/near-uniform themes. Where the backdrop is a mid-tone
    /// (sky blue, grass green, pink) or the panel ink was designed for a pale panel, sections get a soft tonal fill
    /// (no border) so every text and status colour keeps readable contrast.
    static var flatFill: Color {
        switch Theme.current {
        case .neon, .synth, .ice: .clear
        case .candy, .sky, .farm, .reef: p.panel.opacity(0.94)
        }
    }

    /// Text/icon color that reads on the frame color (tab bar): white on dark frames, ink on light ones.
    static var onFrame: Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(p.frame).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) < 0.5 ? .white : p.ink
    }

    static func font(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// The currency used everywhere money is shown. Chosen in Settings; widgets get it from the snapshot.
enum Currency {
    static let storageKey = "currency"
    static var override: String?
    static let common = ["USD", "EUR", "GBP", "CAD", "AUD", "NZD", "JPY", "CNY", "INR", "MXN", "BRL", "CHF", "SEK", "NOK", "DKK", "SGD", "HKD", "KRW", "ZAR", "AED"]

    static var code: String {
        override
            ?? UserDefaults.standard.string(forKey: storageKey)
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    static func name(_ code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }
}

extension Double {
    var money: String { formatted(.currency(code: Currency.code)) }
}

// MARK: - Background

/// Themed backdrop: grass, neon grid, checker, clouds, sunset, bubbles or dither, scattered deterministically.
struct PixelBackground: View {
    @AppStorage(Theme.storageKey) private var themeRaw = Theme.neon.rawValue

    var body: some View {
        let theme = Theme(rawValue: themeRaw) ?? .neon
        let pal = theme.palette
        return Canvas { ctx, size in
            let full = CGRect(origin: .zero, size: size)
            if let bottom = pal.bgBottom {
                ctx.fill(Path(full), with: .linearGradient(Gradient(colors: [pal.bg, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            } else {
                ctx.fill(Path(full), with: .color(pal.bg))
            }
            var seed: UInt64 = 7
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 10_000) / 10_000
            }
            func snap(_ v: CGFloat) -> CGFloat { (v / 4).rounded(.down) * 4 }
            func px(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
                ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c))
            }

            switch pal.decor {
            case .grass:
                for _ in 0..<90 {
                    let x = snap(next() * size.width), y = snap(next() * size.height)
                    px(x, y + 4, 4, 4, pal.bgDark); px(x + 8, y + 4, 4, 4, pal.bgDark)
                    px(x + 4, y, 4, 8, pal.bgDark); px(x + 4, y, 4, 4, pal.bgLight)
                }
                let petals: [Color] = [.white, Color(red: 1, green: 0.6, blue: 0.7), Color(red: 0.7, green: 0.8, blue: 1)]
                for i in 0..<16 {
                    let x = snap(next() * size.width), y = snap(next() * size.height)
                    let c = petals[i % petals.count]
                    px(x + 4, y, 4, 4, c); px(x, y + 4, 4, 4, c); px(x + 8, y + 4, 4, 4, c)
                    px(x + 4, y + 8, 4, 4, c); px(x + 4, y + 4, 4, 4, pal.accent)
                }
            case .grid:
                var x: CGFloat = 0
                while x < size.width { px(x, 0, 1, size.height, pal.frameDark.opacity(0.10)); x += 24 }
                var y: CGFloat = 0
                while y < size.height { px(0, y, size.width, 1, pal.frameDark.opacity(0.10)); y += 24 }
                let cols = [pal.frameDark, pal.titleShadow, pal.accent]
                for i in 0..<26 { px(snap(next() * size.width), snap(next() * size.height), 4, 4, cols[i % 3].opacity(0.55)) }
            case .checker:
                var row = 0, y: CGFloat = 0
                while y < size.height {
                    var col = 0, x: CGFloat = 0
                    while x < size.width {
                        if (row + col) % 2 == 0 { px(x, y, 32, 32, pal.bgDark) }
                        x += 32; col += 1
                    }
                    y += 32; row += 1
                }
                for i in 0..<14 { px(snap(next() * size.width), snap(next() * size.height), 8, 8, (i % 2 == 0 ? Color.white : pal.frameDark).opacity(0.7)) }
            case .clouds:
                for _ in 0..<7 {
                    let x = snap(next() * size.width), y = snap(next() * size.height)
                    px(x + 12, y, 24, 12, .white.opacity(0.9)); px(x + 4, y + 12, 40, 12, .white.opacity(0.9)); px(x, y + 24, 48, 12, .white.opacity(0.9))
                }
            case .sun:
                let cx = size.width * 0.78, cy = size.height * 0.16, cell: CGFloat = 8, r = 8
                for yy in -r...r {
                    for xx in -r...r where xx * xx + yy * yy <= r * r {
                        if yy > 1 && yy % 2 == 0 { continue }
                        let t = Double(yy + r) / Double(2 * r)
                        let c = t < 0.5 ? Color(red: 1, green: 0.88, blue: 0.4) : (t < 0.75 ? Color(red: 1, green: 0.62, blue: 0.26) : Color(red: 1, green: 0.31, blue: 0.6))
                        px(cx + CGFloat(xx) * cell, cy + CGFloat(yy) * cell, cell, cell, c.opacity(0.8))
                    }
                }
                for i in 0..<5 { px(0, size.height * 0.80 + CGFloat(i * i) * 3 + CGFloat(i) * 8, size.width, 2 + CGFloat(i), pal.frameDark.opacity(0.4)) }
            case .bubbles:
                for _ in 0..<18 {
                    let x = snap(next() * size.width), y = snap(next() * size.height), s = 8 + snap(next() * 12)
                    ctx.stroke(Path(CGRect(x: x, y: y, width: s, height: s)), with: .color(.white.opacity(0.3)), lineWidth: 2)
                }
            case .dither:
                var row = 0, y: CGFloat = 0
                while y < size.height {
                    var col = 0, x: CGFloat = 0
                    while x < size.width {
                        if (row + col) % 2 == 0 { px(x, y, 8, 8, pal.bgDark) }
                        x += 8; col += 1
                    }
                    y += 8; row += 1
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Panel

/// Wood frame around a parchment sheet, like a Stardew menu box.
/// `border` adds an optional colored inner trim (used to flag status or category).
/// Flat HUD section: no box, just a pixel-capped rule on top. `border` tints the rule (status color).
struct PixelPanel: ViewModifier {
    var fill: Color?
    var border: Color?

    func body(content: Content) -> some View {
        let c = border ?? Pixel.woodDark
        content
            .padding(.top, 16)
            .padding(.bottom, 8)
            .padding(.horizontal, (fill ?? Pixel.flatFill) == .clear ? 2 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill ?? Pixel.flatFill)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                HStack(spacing: 2) {
                    Rectangle().fill(c).frame(width: 12, height: 4)
                    Rectangle().fill(c.opacity(0.45)).frame(height: 2)
                    Rectangle().fill(c).frame(width: 4, height: 4)
                }
            }
    }
}

extension View {
    func pixelPanel(fill: Color? = nil, border: Color? = nil) -> some View {
        modifier(PixelPanel(fill: fill, border: border))
    }
}

// MARK: - Title

struct PixelTitle: View {
    let text: String
    var size: CGFloat = 34
    var color: Color { Pixel.gold }

    var body: some View {
        ZStack {
            Text(text).foregroundStyle(Pixel.titleShadow).offset(x: 3, y: 3)
            Text(text).foregroundStyle(Pixel.titleShadow).offset(x: -2, y: 0)
            Text(text).foregroundStyle(Pixel.titleShadow).offset(x: 2, y: 0)
            Text(text).foregroundStyle(Pixel.titleShadow).offset(x: 0, y: -2)
            Text(text).foregroundStyle(color)
        }
        .font(Pixel.font(size))
        .tracking(2)
    }
}

// MARK: - Button

struct PixelButtonStyle: ButtonStyle {
    var fill: Color = Pixel.gold
    var textColor: Color = Pixel.onAccent
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        configuration.label
            .font(Pixel.font(16))
            .foregroundStyle(isEnabled ? textColor : Pixel.dim)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? fill : Pixel.parchmentDark)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.3)).frame(height: 4) }
            .offset(y: pressed ? 2 : 0)
    }
}

// MARK: - Progress bar

/// Stardew energy-bar style: dark wood trough with chunky coloured segments.
struct PixelBar: View {
    /// Fraction of the budget spent. Values above 1 mean over budget.
    var progress: Double
    var segments = 16
    /// When true the bar stays green until it overflows (used for allocation, where "full" is fine).
    var neutral = false

    var body: some View {
        let p = min(max(progress, 0), 1)
        let color: Color = progress > 1 ? Pixel.red : ((p > 0.8 && !neutral) ? Pixel.gold : Pixel.green)
        let filled = p > 0 ? ceil(p * Double(segments)) : 0
        HStack(spacing: 3) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle().fill(Double(i) < filled ? color : Pixel.dim.opacity(0.22))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Text field

struct PixelField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Pixel.dim.opacity(0.7)))
            .font(Pixel.font(18))
            .foregroundStyle(Pixel.ink)
            .keyboardType(keyboard)
            .padding(12)
            .background(Pixel.field)
            .overlay(alignment: .bottom) { Rectangle().fill(Pixel.woodDark).frame(height: 3) }
    }
}
