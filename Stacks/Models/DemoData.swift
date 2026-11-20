import Foundation
import SwiftData

/// Fills an empty store with sample spending. Only runs when the app is launched with STACKS_DEMO=1
/// (used to capture App Store screenshots); normal users never hit this.
enum DemoData {
    static func seedIfRequested(in context: ModelContext) {
        guard ProcessInfo.processInfo.environment["STACKS_DEMO"] == "1" else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Budget>())) ?? 0
        guard existing == 0 else { return }
        let income = 3200.0
        UserDefaults.standard.set(income, forKey: IncomeStore.key)
        BudgetTemplate.all[0].apply(in: context, income: income)
        let budgets = (try? context.fetch(FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        func b(_ c: BudgetCategory) -> Budget? { budgets.first { $0.category == c } }
        let cal = Calendar.current
        func day(_ ago: Int) -> Date { cal.date(byAdding: .day, value: -ago, to: .now) ?? .now }
        let items: [(String, Double, Int, BudgetCategory, String)] = [
            ("Rent", 980, 6, .expenses, "Due on the 1st"),
            ("Groceries", 142.30, 5, .expenses, "Weekly shop"),
            ("Electric", 64.20, 4, .expenses, ""),
            ("Gas", 48, 3, .expenses, ""),
            ("Phone", 55, 2, .expenses, ""),
            ("Games", 59.99, 3, .fun, "New release"),
            ("Dinner out", 62.40, 2, .fun, "With friends"),
            ("Coffee", 18.50, 1, .fun, ""),
            ("Emergency fund", 150, 4, .savings, ""),
        ]
        for (name, amount, ago, cat, note) in items {
            context.insert(Expense(title: name, amount: amount, date: day(ago), budget: b(cat), note: note))
        }
    }
}
