import SwiftData
import SwiftUI

struct InsightsView: View {
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Query private var expenses: [Expense]
    @Environment(\.viewMonth) private var month
    @AppStorage(ViewMonth.storageKey) private var rawMonth: Double = 0

    private var byCategory: [(BudgetCategory, Double)] {
        Dictionary(grouping: budgets, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.spent(in: month) }) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    /// Spending per day for the selected month.
    private var daily: [(day: Int, total: Double)] {
        let cal = Calendar.current
        let count = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        var totals = Array(repeating: 0.0, count: count)
        for e in expenses where e.date.isInMonth(of: month) {
            let d = cal.component(.day, from: e.date)
            if d >= 1, d <= count { totals[d - 1] += e.amount }
        }
        return totals.enumerated().map { ($0.offset + 1, $0.element) }
    }

    /// Totals for the last six months, oldest first, ending with the current month.
    private var lastSixMonths: [(start: Date, total: Double)] {
        let cal = Calendar.current
        return (0..<6).reversed().compactMap { back in
            guard let start = cal.date(byAdding: .month, value: -back, to: ViewMonth.currentStart) else { return nil }
            let total = expenses.filter { $0.date.isInMonth(of: start) }.reduce(0) { $0 + $1.amount }
            return (start, total)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthSwitcher()
                dayChart
                monthTrend
                categoryBreakdown
            }
            .padding(16)
        }
        .background(PixelBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var dayChart: some View {
        let days = daily
        let maxValue = max(days.map(\.total).max() ?? 0, 1)
        let total = days.reduce(0) { $0 + $1.total }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SPENT BY DAY").font(Pixel.font(13)).foregroundStyle(Pixel.ink)
                Spacer()
                Text(total.money).font(Pixel.font(13)).foregroundStyle(Pixel.green)
            }
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(days, id: \.day) { d in
                    Rectangle()
                        .fill(d.total > 0 ? Pixel.green : Pixel.dim.opacity(0.22))
                        .frame(height: max(d.total / maxValue * 110, d.total > 0 ? 6 : 2))
                        .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 120, alignment: .bottom)
            HStack {
                Text("1").font(Pixel.font(10)).foregroundStyle(Pixel.dim)
                Spacer()
                Text("\(days.count)").font(Pixel.font(10)).foregroundStyle(Pixel.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
    }

    private var monthTrend: some View {
        let months = lastSixMonths
        let maxValue = max(months.map(\.total).max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("LAST 6 MONTHS").font(Pixel.font(13)).foregroundStyle(Pixel.ink)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(months, id: \.start) { m in
                    let selected = m.start.isInMonth(of: month)
                    Button { rawMonth = ViewMonth.raw(for: m.start) } label: {
                        VStack(spacing: 6) {
                            Text(m.total > 0 ? "\(Int(m.total))" : "")
                                .font(Pixel.font(9)).foregroundStyle(Pixel.dim)
                                .minimumScaleFactor(0.6).lineLimit(1)
                                .frame(height: 12)
                            Rectangle()
                                .fill(selected ? Pixel.gold : Pixel.green.opacity(0.6))
                                .frame(height: max(m.total / maxValue * 90, m.total > 0 ? 6 : 2))
                            Text(m.start.formatted(.dateTime.month(.abbreviated)).uppercased())
                                .font(Pixel.font(9)).foregroundStyle(selected ? Pixel.heading : Pixel.dim)
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
    }

    private var categoryBreakdown: some View {
        let rows = byCategory
        let maxValue = max(rows.map(\.1).max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 14) {
            Text(month.formatted(.dateTime.month(.wide)).uppercased()).font(Pixel.font(13)).foregroundStyle(Pixel.ink)
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
