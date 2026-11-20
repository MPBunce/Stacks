import SwiftData
import SwiftUI

@main
struct StacksApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Budget.self, Expense.self, RecurringExpense.self, Subcategory.self])
    }
}
