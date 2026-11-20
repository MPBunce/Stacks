import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Query private var expenses: [Expense]

    private var byCategory: [(BudgetCategory, Double)] {
        Dictionary(grouping: budgets, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.spentThisMonth }) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    private var lastSevenDays: [(date: Date, total: Double)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: .now) ?? .now
            let total = expenses.filter { cal.isDate($0.date, inSameDayAs: day) }.reduce(0) { $0 + $1.amount }
            return (day, total)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                                weekChart
                categoryBreakdown
            }
            .padding(16)
        }
        .background(PixelBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var weekChart: some View {
        let days = lastSevenDays
        let maxValue = max(days.map(\.total).max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("LAST 7 DAYS").font(Pixel.font(13)).foregroundStyle(Pixel.ink)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 6) {
                        Text(day.total > 0 ? "\(Int(day.total))" : "")
                            .font(Pixel.font(9)).foregroundStyle(Pixel.dim)
                            .frame(height: 12)
                        Rectangle()
                            .fill(Pixel.green)
                            .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 2))
                            .frame(height: max(day.total / maxValue * 110, day.total > 0 ? 6 : 2))
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(Pixel.font(10)).foregroundStyle(Pixel.dim)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 160, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
    }

    private var categoryBreakdown: some View {
        let rows = byCategory
        let maxValue = max(rows.map(\.1).max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 14) {
            Text("THIS MONTH").font(Pixel.font(13)).foregroundStyle(Pixel.ink)
            if rows.isEmpty {
                Text("Log some spending to see where your coins go.")
                    .font(Pixel.font(12, weight: .semibold)).foregroundStyle(Pixel.dim)
            }
            ForEach(rows, id: \.0) { cat, total in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: cat.icon).foregroundStyle(cat.color)
                        Text(cat.title.uppercased()).font(Pixel.font(12)).foregroundStyle(Pixel.ink)
                        Spacer()
                        Text(total.money).font(Pixel.font(12)).foregroundStyle(cat.color)
                    }
                    GeometryReader { geo in
                        Rectangle().fill(cat.color)
                            .frame(width: max(geo.size.width * total / maxValue, 6))
                    }
                    .frame(height: 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
    }
}
