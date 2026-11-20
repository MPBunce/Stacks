import SwiftUI
import WidgetKit

// MARK: - Timeline

struct StacksEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isPlaceholder: Bool
}

struct StacksProvider: TimelineProvider {
    func placeholder(in context: Context) -> StacksEntry {
        StacksEntry(date: .now, snapshot: .sample, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (StacksEntry) -> Void) {
        completion(StacksEntry(date: .now, snapshot: WidgetSnapshot.load() ?? .sample, isPlaceholder: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StacksEntry>) -> Void) {
        let entry = StacksEntry(date: .now, snapshot: WidgetSnapshot.load() ?? .sample, isPlaceholder: false)
        // "Per day" changes at midnight; the app also reloads us whenever spending changes.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Shared bits

private extension WidgetSnapshot {
    var statusColor: Color {
        switch mood {
        case .crumbled: Pixel.red
        case .worried: Pixel.amber
        case .happy: Pixel.green
        }
    }

    func barColor(_ f: Double) -> Color { f > 1 ? Pixel.red : (f > 0.8 ? Pixel.gold : Pixel.green) }
}

/// Applies the user's chosen theme and mascot before anything reads `Pixel` tokens.
private func applyLook(_ s: WidgetSnapshot) {
    Theme.override = Theme(rawValue: s.theme) ?? .neon
    Mascot.override = Mascot(rawValue: s.mascot) ?? .coin
    Currency.override = s.currency
}

private struct StatusChip: View {
    let text: String
    let color: Color
    var size: CGFloat = 10
    var body: some View {
        Text(text)
            .font(Pixel.font(size))
            .foregroundStyle(Pixel.parchment)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color)
    }
}

/// A compact version of the coin tower: mascot on a few coins, or ash when crumbled.
private struct MiniTower: View {
    let snapshot: WidgetSnapshot
    var maxCoins = 3
    var mascotWidth: CGFloat = 58

    var body: some View {
        let mascot = Mascot.current
        if snapshot.isOver {
            VStack(spacing: -8) {
                PixelSprite(rows: mascot.rows(.crumbled), palette: Sprites.ash)
                    .frame(width: mascotWidth * 0.9)
                    .rotationEffect(.degrees(-14))
                    .offset(x: 10)
                HStack(spacing: -6) {
                    PixelSprite(rows: Sprites.coin, palette: Sprites.ash).frame(width: 26).rotationEffect(.degrees(12))
                    PixelSprite(rows: Sprites.coin, palette: Sprites.ash).frame(width: 32)
                    PixelSprite(rows: Sprites.coin, palette: Sprites.ash).frame(width: 22).rotationEffect(.degrees(-20)).offset(y: 4)
                }
            }
        } else {
            let worried = snapshot.mood == .worried
            let n = min(snapshot.coins, maxCoins)
            VStack(spacing: -mascotWidth * 0.3) {
                PixelSprite(rows: mascot.rows(worried ? .worried : .happy), palette: mascot.palette())
                    .frame(width: mascotWidth)
                    .rotationEffect(.degrees(worried ? 5 : 0))
                    .zIndex(Double(n + 1))
                ForEach(0..<n, id: \.self) { i in
                    PixelSprite(rows: Sprites.coin, palette: Sprites.gold)
                        .frame(width: mascotWidth * 1.1)
                        .zIndex(Double(n - i))
                }
            }
        }
    }
}

private struct PixelMeter: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 9
    var body: some View {
        GeometryReader { geo in
            let p = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Rectangle().fill(Pixel.dim.opacity(0.22))
                Rectangle().fill(color).frame(width: (geo.size.width * p / 3).rounded() * 3)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Small

private struct SmallView: View {
    let s: WidgetSnapshot
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                StatusChip(text: s.statusText, color: s.statusColor)
                Spacer(minLength: 0)
            }
            MiniTower(snapshot: s)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            Rectangle().fill(Pixel.groundTop).frame(height: 4)
            HStack(alignment: .firstTextBaseline) {
                Text(s.isOver ? "OVER" : "LEFT").font(Pixel.font(10)).foregroundStyle(Pixel.dim)
                Spacer(minLength: 2)
                Text(abs(s.remaining).money.replacingOccurrences(of: ".00", with: ""))
                    .font(Pixel.font(17))
                    .foregroundStyle(s.isOver ? Pixel.red : Pixel.green)
                    .minimumScaleFactor(0.6).lineLimit(1)
            }
        }
    }
}

// MARK: - Medium

private struct MediumView: View {
    let s: WidgetSnapshot
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                StatusChip(text: s.statusText, color: s.statusColor)
                MiniTower(snapshot: s, maxCoins: 2, mascotWidth: 46)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                Rectangle().fill(Pixel.groundTop).frame(height: 4)
                Text("\(s.perDay.money.replacingOccurrences(of: ".00", with: ""))/DAY")
                    .font(Pixel.font(10)).foregroundStyle(Pixel.dim)
                    .minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(width: 100)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(s.isOver ? "OVER BY" : "LEFT").font(Pixel.font(10)).foregroundStyle(Pixel.dim)
                    Spacer()
                    Text(abs(s.remaining).money.replacingOccurrences(of: ".00", with: ""))
                        .font(Pixel.font(18))
                        .foregroundStyle(s.isOver ? Pixel.red : Pixel.green)
                        .minimumScaleFactor(0.6).lineLimit(1)
                }
                ForEach(s.items.prefix(4)) { item in
                    VStack(spacing: 2) {
                        HStack {
                            Text(item.name.uppercased()).font(Pixel.font(9)).foregroundStyle(Pixel.ink).lineLimit(1)
                            Spacer()
                            Text("\(Int((item.fraction * 100).rounded()))%").font(Pixel.font(9)).foregroundStyle(Pixel.dim)
                        }
                        PixelMeter(progress: item.fraction, color: s.barColor(item.fraction), height: 8)
                    }
                }
            }
        }
    }
}

// MARK: - Lock screen

private struct CircularView: View {
    let s: WidgetSnapshot
    var body: some View {
        Gauge(value: min(max(s.fraction, 0), 1)) {
            Text("SPENT")
        } currentValueLabel: {
            Text("\(Int((s.fraction * 100).rounded()))%").font(.system(size: 14, weight: .heavy, design: .monospaced))
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

private struct RectangularView: View {
    let s: WidgetSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("STACKS · \(s.statusText)").font(.system(size: 12, weight: .heavy, design: .monospaced))
                Spacer(minLength: 0)
            }
            Text("\(abs(s.remaining).money.replacingOccurrences(of: ".00", with: "")) \(s.isOver ? "over" : "left")")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
            Gauge(value: min(max(s.fraction, 0), 1)) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
        }
    }
}

private struct InlineView: View {
    let s: WidgetSnapshot
    var body: some View {
        Text("\(s.statusText) · \(abs(s.remaining).money.replacingOccurrences(of: ".00", with: "")) \(s.isOver ? "over" : "left")")
    }
}

// MARK: - Entry view

struct StacksWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StacksEntry

    var body: some View {
        let s = entry.snapshot
        let _ = applyLook(s)
        switch family {
        case .accessoryCircular:
            CircularView(s: s).containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            RectangularView(s: s).containerBackground(.clear, for: .widget)
        case .accessoryInline:
            InlineView(s: s)
        case .systemMedium:
            MediumView(s: s)
                .padding(.horizontal, 18).padding(.vertical, 16)
                .containerBackground(for: .widget) { framed }
        default:
            SmallView(s: s)
                .padding(16)
                .containerBackground(for: .widget) { framed }
        }
    }

    /// Flat HUD: solid themed fill with a pixel-cap rule across the top, no box.
    private var framed: some View {
        Pixel.parchment
            .overlay(alignment: .top) {
                HStack(spacing: 2) {
                    Rectangle().fill(Pixel.woodDark).frame(width: 16, height: 4)
                    Rectangle().fill(Pixel.woodDark.opacity(0.45)).frame(height: 2)
                    Rectangle().fill(Pixel.woodDark).frame(width: 4, height: 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 2)
            }
    }
}

// MARK: - Widget

struct StacksWidget: Widget {
    let kind = "StacksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StacksProvider()) { entry in
            StacksWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "stacks://home"))
        }
        .configurationDisplayName("Stacks")
        .description("Your mascot, your tower, and how much you have left this month.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

@main
struct StacksWidgetBundle: WidgetBundle {
    var body: some Widget {
        StacksWidget()
    }
}
