import SwiftData
import SwiftUI

/// The three default buckets every budget falls into.
enum BudgetCategory: String, CaseIterable, Identifiable {
    case expenses, fun, savings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expenses: "Expenses"
        case .fun: "Fun Money"
        case .savings: "Savings"
        }
    }

    var icon: String {
        switch self {
        case .expenses: "house.fill"
        case .fun: "gamecontroller.fill"
        case .savings: "banknote.fill"
        }
    }

    var color: Color {
        switch self {
        case .expenses: Color(red: 0.35, green: 0.45, blue: 0.85)
        case .fun: Color(red: 0.65, green: 0.30, blue: 0.80)
        case .savings: Pixel.green
        }
    }
}

@Model
final class Budget {
    var name: String
    var categoryRaw: String
    var limit: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Expense.budget)
    var expenses: [Expense] = []

    @Relationship(deleteRule: .cascade, inverse: \RecurringExpense.budget)
    var recurring: [RecurringExpense] = []

    @Relationship(deleteRule: .cascade, inverse: \Subcategory.budget)
    var subcategories: [Subcategory] = []

    var sortedSubcategories: [Subcategory] { subcategories.sorted { $0.createdAt < $1.createdAt } }

    init(name: String, category: BudgetCategory, limit: Double) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.limit = limit
        self.createdAt = .now
    }

    var category: BudgetCategory { BudgetCategory(rawValue: categoryRaw) ?? .expenses }

    var spentThisMonth: Double {
        let cal = Calendar.current
        return expenses
            .filter { cal.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var fractionSpent: Double { limit > 0 ? spentThisMonth / limit : 0 }
}

@Model
final class Expense {
    var title: String
    var amount: Double
    var date: Date
    var budget: Budget?
    var subcategory: Subcategory?
    var note: String = ""

    init(title: String, amount: Double, date: Date = .now, budget: Budget?, subcategory: Subcategory? = nil, note: String = "") {
        self.note = note
        self.title = title
        self.amount = amount
        self.date = date
        self.budget = budget
        self.subcategory = subcategory
    }
}

/// A slice of a budget, like "Emergency" or "Investments" inside Savings. `limit` of 0 means no cap.
@Model
final class Subcategory {
    var name: String
    var limit: Double
    var createdAt: Date
    var budget: Budget?

    @Relationship(deleteRule: .nullify, inverse: \Expense.subcategory)
    var expenses: [Expense] = []

    @Relationship(deleteRule: .nullify, inverse: \RecurringExpense.subcategory)
    var recurring: [RecurringExpense] = []

    init(name: String, limit: Double = 0, budget: Budget?) {
        self.name = name
        self.limit = limit
        self.createdAt = .now
        self.budget = budget
    }

    var spentThisMonth: Double {
        let cal = Calendar.current
        return expenses
            .filter { cal.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    static func suggestions(for category: BudgetCategory) -> [String] {
        switch category {
        case .expenses: ["Rent", "Groceries", "Bills", "Transport"]
        case .fun: ["Eating Out", "Games", "Hobbies", "Trips"]
        case .savings: ["Emergency", "Investments", "Goals", "Retirement"]
        }
    }
}

// MARK: - Recurring

enum RepeatFrequency: String, CaseIterable, Identifiable {
    case weekly, biweekly, monthly
    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: "Weekly"
        case .biweekly: "Every 2 weeks"
        case .monthly: "Monthly"
        }
    }

    /// The nth occurrence counted from `start` (n = 0 is the start date itself).
    /// Computed from the start date each time so month-end dates (e.g. the 31st) don't drift.
    func occurrence(_ n: Int, from start: Date) -> Date {
        let cal = Calendar.current
        switch self {
        case .weekly: return cal.date(byAdding: .day, value: 7 * n, to: start) ?? start
        case .biweekly: return cal.date(byAdding: .day, value: 14 * n, to: start) ?? start
        case .monthly: return cal.date(byAdding: .month, value: n, to: start) ?? start
        }
    }
}

/// A repeating charge (rent, subscriptions). Real `Expense`s are generated from it as each due date passes.
@Model
final class RecurringExpense {
    var title: String
    var amount: Double
    var frequencyRaw: String
    var startDate: Date
    /// How many occurrences have already been turned into expenses.
    var generatedCount: Int
    var budget: Budget?
    var subcategory: Subcategory?
    var note: String = ""

    init(title: String, amount: Double, frequency: RepeatFrequency, startDate: Date = .now, budget: Budget?, subcategory: Subcategory? = nil, note: String = "") {
        self.note = note
        self.title = title
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.generatedCount = 0
        self.budget = budget
        self.subcategory = subcategory
    }

    var frequency: RepeatFrequency { RepeatFrequency(rawValue: frequencyRaw) ?? .monthly }
    var nextDue: Date { frequency.occurrence(generatedCount, from: startDate) }
}

enum RecurringEngine {
    /// Creates an expense for every occurrence that has come due. Safe to call repeatedly.
    static func process(in context: ModelContext, now: Date = .now) {
        guard let items = try? context.fetch(FetchDescriptor<RecurringExpense>()) else { return }
        for item in items {
            var created = 0
            while item.nextDue <= now, created < 400 {
                context.insert(Expense(title: item.title, amount: item.amount, date: item.nextDue, budget: item.budget, subcategory: item.subcategory, note: item.note))
                item.generatedCount += 1
                created += 1
            }
        }
        try? context.save()
    }
}

// MARK: - Templates

/// A split of monthly income across the three buckets, as whole percentages (sums to 100).
struct BudgetTemplate: Identifiable {
    let id = UUID()
    let name: String
    let blurb: String
    let items: [(BudgetCategory, Int)]

    static let all: [BudgetTemplate] = [
        BudgetTemplate(
            name: "Starter Quest",
            blurb: "The classic 50/30/20 split.",
            items: [(.expenses, 50), (.fun, 30), (.savings, 20)]
        ),
        BudgetTemplate(
            name: "Student Mode",
            blurb: "Tight budget, max XP.",
            items: [(.expenses, 65), (.fun, 20), (.savings, 15)]
        ),
        BudgetTemplate(
            name: "Hardcore Saver",
            blurb: "Big savings goal. No mercy.",
            items: [(.expenses, 50), (.fun, 10), (.savings, 40)]
        ),
    ]

    func limit(for percent: Int, income: Double) -> Double {
        (income * Double(percent) / 100).rounded()
    }

    func apply(in context: ModelContext, income: Double) {
        for (category, percent) in items {
            context.insert(Budget(name: category.title, category: category, limit: limit(for: percent, income: income)))
        }
    }
}
