import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage(Theme.storageKey) private var themeRaw = Theme.neon.rawValue
    @AppStorage(Mascot.storageKey) private var mascotRaw = Mascot.coin.rawValue
    @AppStorage(Currency.storageKey) private var currencyRaw = Currency.code
    @Query private var expenses: [Expense]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PixelTitle(text: "SETTINGS", size: 26)
                Text("MASCOT").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Mascot.allCases) { mascotCell($0) }
                }
                Text("CURRENCY").font(Pixel.font(13)).foregroundStyle(Pixel.heading).padding(.top, 4)
                currencyRow
                Text("LOOK").font(Pixel.font(13)).foregroundStyle(Pixel.heading).padding(.top, 4)
                ForEach(Theme.allCases) { theme in
                    themeRow(theme)
                }
                Text("DATA").font(Pixel.font(13)).foregroundStyle(Pixel.heading).padding(.top, 4)
                if let url = CSVExport.file(for: expenses) {
                    ShareLink(item: url) {
                        HStack {
                            Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .black)).foregroundStyle(Pixel.heading)
                            Text("EXPORT CSV").font(Pixel.font(12)).foregroundStyle(Pixel.ink)
                            Spacer()
                            Text("\(expenses.count) EXPENSES").font(Pixel.font(10)).foregroundStyle(Pixel.dim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .pixelPanel()
                    }
                    .buttonStyle(.plain)
                }
                Button("DONE") { dismiss() }
                    .buttonStyle(PixelButtonStyle())
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .id(themeRaw + mascotRaw + currencyRaw)
    }

    private var currencyRow: some View {
        let codes = Currency.common.contains(currencyRaw) ? Currency.common : [currencyRaw] + Currency.common
        return Menu {
            Picker("Currency", selection: $currencyRaw) {
                ForEach(codes, id: \.self) { Text("\($0) · \(Currency.name($0))").tag($0) }
            }
        } label: {
            HStack {
                Text(currencyRaw).font(Pixel.font(16)).foregroundStyle(Pixel.heading)
                Text(Currency.name(currencyRaw).uppercased()).font(Pixel.font(11)).foregroundStyle(Pixel.ink).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 13, weight: .black)).foregroundStyle(Pixel.dim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelPanel()
        }
    }

    private func mascotCell(_ mascot: Mascot) -> some View {
        let selected = mascotRaw == mascot.rawValue
        return Button { mascotRaw = mascot.rawValue } label: {
            VStack(spacing: 6) {
                PixelSprite(rows: mascot.rows(.happy), palette: mascot.palette())
                    .frame(height: 56)
                Text(mascot.title.uppercased()).font(Pixel.font(10)).foregroundStyle(Pixel.ink)
                    .minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .pixelPanel(fill: Pixel.parchmentDark, border: selected ? Pixel.green : nil)
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .black))
                        .foregroundStyle(Pixel.green).padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func themeRow(_ theme: Theme) -> some View {
        let p = theme.palette
        let selected = themeRaw == theme.rawValue
        return Button { themeRaw = theme.rawValue } label: {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach([p.bg, p.panel, p.frameDark, p.accent, p.good], id: \.self) { c in
                        Rectangle().fill(c).frame(width: 18, height: 28)
                    }
                }
                .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 2))
                Text(theme.title.uppercased()).font(Pixel.font(12)).foregroundStyle(Pixel.ink)
                    .minimumScaleFactor(0.7).lineLimit(1)
                Spacer()
                if selected { Image(systemName: "checkmark").font(.system(size: 14, weight: .black)).foregroundStyle(Pixel.green) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelPanel(border: selected ? Pixel.gold : nil)
        }
        .buttonStyle(.plain)
    }
}
