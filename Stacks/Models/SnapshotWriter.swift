import Foundation
import WidgetKit

/// Pushes the current numbers to the widgets through the shared app group.
enum SnapshotWriter {
    static func write(budgets: [Budget], expenses: [Expense], income: Double, theme: String, mascot: String, currency: String) {
        let cal = Calendar.current
        let items = budgets.map { budget in
            let spent = expenses
                .filter { $0.budget == budget && cal.isDate($0.date, equalTo: .now, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            return WidgetSnapshot.Item(name: budget.name, spent: spent, limit: budget.limit)
        }
        WidgetSnapshot(theme: theme, mascot: mascot, income: income, currency: currency, items: items).save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
