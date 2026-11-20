import SwiftUI

/// The month the whole app is looking at. Stored as the start of the month (0 = the current month).
enum ViewMonth {
    static let storageKey = "viewMonth"

    static var currentStart: Date {
        Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    static func resolve(_ raw: Double) -> Date {
        guard raw > 0 else { return currentStart }
        let cal = Calendar.current
        let start = cal.dateInterval(of: .month, for: Date(timeIntervalSince1970: raw))?.start ?? currentStart
        return min(start, currentStart)
    }

    static func raw(for month: Date) -> Double {
        month >= currentStart ? 0 : month.timeIntervalSince1970
    }

    static func isCurrent(_ month: Date) -> Bool { month >= currentStart }

    /// A sensible default date for a new expense in `month`: today if it's the current month, else the same day-of-month.
    static func defaultDate(in month: Date) -> Date {
        if isCurrent(month) { return .now }
        let cal = Calendar.current
        let days = cal.range(of: .day, in: .month, for: month)?.count ?? 28
        let day = min(cal.component(.day, from: .now), days)
        return cal.date(byAdding: .day, value: day - 1, to: month) ?? month
    }
}

private struct ViewMonthKey: EnvironmentKey {
    static let defaultValue = ViewMonth.currentStart
}

extension EnvironmentValues {
    var viewMonth: Date {
        get { self[ViewMonthKey.self] }
        set { self[ViewMonthKey.self] = newValue }
    }
}

extension Date {
    func isInMonth(of month: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: month, toGranularity: .month)
    }
}

/// "‹ NOVEMBER 2026 ›" bar. Changes the app-wide month; tap the title to jump back to this month.
struct MonthSwitcher: View {
    @AppStorage(ViewMonth.storageKey) private var raw: Double = 0

    var body: some View {
        let month = ViewMonth.resolve(raw)
        let current = ViewMonth.isCurrent(month)
        HStack {
            Button { shift(-1, from: month) } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .black))
                    .frame(width: 44, height: 36)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Button { raw = 0 } label: {
                VStack(spacing: 2) {
                    Text(month.formatted(.dateTime.month(.wide).year()).uppercased())
                        .font(Pixel.font(15)).foregroundStyle(Pixel.heading)
                    if !current {
                        Text("TAP FOR THIS MONTH").font(Pixel.font(8, weight: .bold)).foregroundStyle(Pixel.dim)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button { shift(1, from: month) } label: {
                Image(systemName: "chevron.right").font(.system(size: 18, weight: .black))
                    .frame(width: 44, height: 36)
            }
            .disabled(current)
            .opacity(current ? 0.25 : 1)
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Pixel.heading)
    }

    private func shift(_ delta: Int, from month: Date) {
        let next = Calendar.current.date(byAdding: .month, value: delta, to: month) ?? month
        raw = ViewMonth.raw(for: next)
    }
}
