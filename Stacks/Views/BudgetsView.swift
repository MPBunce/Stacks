import SwiftData
import SwiftUI

struct BudgetRow: View {
    let budget: Budget

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: budget.category.icon)
                    .foregroundStyle(budget.category.color)
                    .frame(width: 24)
                Text(budget.name.uppercased()).font(Pixel.font(15)).foregroundStyle(Pixel.ink)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(budget.fractionSpent > 1
                         ? "\((budget.spentThisMonth - budget.limit).money) OVER"
                         : "\((budget.limit - budget.spentThisMonth).money) LEFT")
                        .font(Pixel.font(13))
                        .foregroundStyle(budget.fractionSpent > 1 ? Pixel.red : (budget.fractionSpent > 0.8 ? Pixel.amber : Pixel.green))
                    Text("\(budget.spentThisMonth.money) of \(budget.limit.money)")
                        .font(Pixel.font(9, weight: .bold))
                        .foregroundStyle(Pixel.dim)
                }
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            }
            PixelBar(progress: budget.fractionSpent)
        }
        .pixelPanel(border: budget.fractionSpent > 1 ? Pixel.red : budget.category.color)
    }
}

struct BudgetsView: View {
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Query(sort: \RecurringExpense.startDate) private var recurring: [RecurringExpense]
    @Environment(\.modelContext) private var context
    @State private var showNew = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                                IncomeCard()
                Button("+ NEW BUDGET") { showNew = true }
                    .buttonStyle(PixelButtonStyle())

                if budgets.isEmpty {
                    Text("No budgets yet. Add one or pick a template!")
                        .font(Pixel.font(13, weight: .semibold))
                        .foregroundStyle(Pixel.heading)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                }
                ForEach(budgets) { budget in
                    NavigationLink(value: budget) { BudgetRow(budget: budget) }
                        .buttonStyle(.plain)
                }

                if !recurring.isEmpty {
                    HStack {
                        Text("RECURRING").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                        Spacer()
                    }
                    .padding(.top, 8)
                    ForEach(recurring) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(item.budget?.category.color ?? Pixel.dim)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title.isEmpty ? (item.budget?.name ?? "Recurring") : item.title)
                                    .font(Pixel.font(14)).foregroundStyle(Pixel.ink)
                                Text("\(item.frequency.title.uppercased()) · NEXT \(item.nextDue.formatted(date: .abbreviated, time: .omitted).uppercased())")
                                    .font(Pixel.font(9, weight: .semibold)).foregroundStyle(Pixel.dim)
                            }
                            Spacer()
                            Text(item.amount.money).font(Pixel.font(13)).foregroundStyle(Pixel.red)
                            Button { context.delete(item) } label: {
                                Image(systemName: "xmark").font(.system(size: 12, weight: .black)).foregroundStyle(Pixel.dim).padding(8)
                            }
                            .accessibilityLabel("Stop repeating")
                        }
                        .pixelPanel()
                    }
                }
            }
            .padding(16)
        }
        .background(PixelBackground())
        .navigationDestination(for: Budget.self) { BudgetDetailView(budget: $0) }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNew) {
            NewBudgetView().presentationBackground { PixelBackground() }
        }
    }
}

// MARK: - New budget

struct NewBudgetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(IncomeStore.key) private var income: Double = 0

    @State private var category: BudgetCategory = .expenses
    @State private var name = ""
    @State private var limitText = ""
    @State private var incomeText = ""

    private var limit: Double? { limitText.moneyValue }
    private var newIncome: Double? {
        guard let v = incomeText.moneyValue, v > 0 else { return nil }
        return v
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PixelTitle(text: "NEW BUDGET", size: 26)

                if income <= 0 {
                    incomePrompt
                } else {
                    templates
                }

                Text("CUSTOM").font(Pixel.font(13)).foregroundStyle(Pixel.heading).padding(.top, 8)
                CategoryChips(selection: $category)
                PixelField(placeholder: "Name (\(category.title))", text: $name)
                PixelField(placeholder: "Monthly limit", text: $limitText, keyboard: .decimalPad)
                if let limit, income > 0 {
                    Text("That's \(Int((limit / income * 100).rounded()))% of your income.")
                        .font(Pixel.font(12, weight: .semibold))
                        .foregroundStyle(Pixel.heading)
                }
                Button("CREATE") {
                    guard let limit else { return }
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    context.insert(Budget(name: trimmed.isEmpty ? category.title : trimmed, category: category, limit: limit))
                    dismiss()
                }
                .buttonStyle(PixelButtonStyle())
                .disabled(limit == nil || (limit ?? 0) <= 0)
            }
            .padding(16)
        }
    }

    private var incomePrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TEMPLATES NEED INCOME").font(Pixel.font(13)).foregroundStyle(Pixel.ink)
            Text("Enter your monthly income and templates will split it for you.")
                .font(Pixel.font(12, weight: .semibold)).foregroundStyle(Pixel.dim)
            PixelField(placeholder: "Monthly income", text: $incomeText, keyboard: .decimalPad)
            Button("SET INCOME") {
                if let newIncome { income = newIncome }
            }
            .buttonStyle(PixelButtonStyle())
            .disabled(newIncome == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
    }

    private var templates: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("TEMPLATES").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
            ForEach(BudgetTemplate.all) { template in
                Button {
                    template.apply(in: context, income: income)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(template.name.uppercased()).font(Pixel.font(15)).foregroundStyle(Pixel.amber)
                            Spacer()
                            Text(template.items.map { "\($0.1)" }.joined(separator: "/"))
                                .font(Pixel.font(12)).foregroundStyle(Pixel.ink)
                        }
                        Text(template.blurb).font(Pixel.font(12, weight: .semibold)).foregroundStyle(Pixel.dim)
                        ForEach(template.items, id: \.0) { category, percent in
                            HStack {
                                Image(systemName: category.icon).foregroundStyle(category.color).frame(width: 20)
                                Text(category.title).font(Pixel.font(11)).foregroundStyle(Pixel.ink)
                                Spacer()
                                Text(template.limit(for: percent, income: income).money)
                                    .font(Pixel.font(11)).foregroundStyle(Pixel.dim)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pixelPanel()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CategoryChips: View {
    @Binding var selection: BudgetCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BudgetCategory.allCases) { cat in
                    Button { selection = cat } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                            Text(cat.title.uppercased()).font(Pixel.font(11))
                        }
                        .foregroundStyle(selection == cat ? Color.white : Pixel.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(selection == cat ? cat.color : Pixel.parchment)
                        .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 3))
                    }
                }
            }
            .padding(.trailing, 4)
        }
    }
}

// MARK: - Detail

struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var showAddSub = false
    @Query(sort: \Subcategory.createdAt) private var allSubs: [Subcategory]
    private var subs: [Subcategory] { allSubs.filter { $0.budget == budget } }

    private var expenses: [Expense] {
        budget.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 12, weight: .black))
                            Text("BACK").font(Pixel.font(12))
                        }
                        .foregroundStyle(Pixel.ink)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Pixel.parchment)
                        .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 2))
                    }
                    Spacer()
                }
                BudgetRow(budget: budget)

                HStack {
                    Text("CATEGORIES").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    Spacer()
                    Button { showAddSub = true } label: {
                        Text("+ ADD")
                            .font(Pixel.font(12))
                            .foregroundStyle(Pixel.onAccent)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Pixel.gold)
                            .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 2))
                    }
                }
                if subs.isEmpty {
                    Text("Split \(budget.name) into smaller pieces, like \(Subcategory.suggestions(for: budget.category).prefix(2).joined(separator: " or ")).")
                        .font(Pixel.font(12, weight: .semibold))
                        .foregroundStyle(Pixel.heading)
                }
                ForEach(subs) { sub in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(sub.name.uppercased()).font(Pixel.font(14)).foregroundStyle(Pixel.ink)
                            Spacer()
                            Text(sub.limit > 0 ? "\(sub.spentThisMonth.money) / \(sub.limit.money)" : sub.spentThisMonth.money)
                                .font(Pixel.font(11, weight: .bold))
                                .foregroundStyle(sub.limit > 0 && sub.spentThisMonth > sub.limit ? Pixel.red : Pixel.dim)
                            Button { context.delete(sub) } label: {
                                Image(systemName: "xmark").font(.system(size: 12, weight: .black)).foregroundStyle(Pixel.dim).padding(6)
                            }
                            .accessibilityLabel("Delete category")
                        }
                        if sub.limit > 0 { PixelBar(progress: sub.spentThisMonth / sub.limit) }
                    }
                    .pixelPanel(border: budget.category.color)
                }

                HStack {
                    Text("HISTORY").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    Spacer()
                }
                if expenses.isEmpty {
                    Text("No spending yet. Nice.")
                        .font(Pixel.font(13, weight: .semibold))
                        .foregroundStyle(Pixel.heading)
                }
                ForEach(expenses) { expense in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(expense.title.isEmpty ? "Expense" : expense.title)
                                .font(Pixel.font(14)).foregroundStyle(Pixel.ink)
                            Text(expense.date.formatted(date: .abbreviated, time: .omitted) + (expense.subcategory.map { " · " + $0.name } ?? ""))
                                .font(Pixel.font(10, weight: .semibold)).foregroundStyle(Pixel.dim)
                            if !expense.note.isEmpty {
                                Text(expense.note).font(Pixel.font(11, weight: .semibold)).foregroundStyle(Pixel.dim).lineLimit(2)
                            }
                        }
                        Spacer()
                        Text("-" + expense.amount.money).font(Pixel.font(14)).foregroundStyle(Pixel.red)
                        Button { context.delete(expense) } label: {
                            Image(systemName: "xmark").font(.system(size: 12, weight: .black)).foregroundStyle(Pixel.dim)
                                .padding(8)
                        }
                    }
                    .pixelPanel()
                }

                Button("DELETE BUDGET") { confirmDelete = true }
                    .buttonStyle(PixelButtonStyle(fill: Pixel.red, textColor: .white))
                    .padding(.top, 12)
            }
            .padding(16)
        }
        .background(PixelBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddSub) {
            AddSubcategoryView(budget: budget).presentationBackground { PixelBackground() }
        }
        .confirmationDialog("Delete this budget and its history?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(budget)
                dismiss()
            }
        }
    }
}

// MARK: - Subcategories

struct AddSubcategoryView: View {
    let budget: Budget
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var limitText = ""
    @Query private var allSubs: [Subcategory]

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var limit: Double { limitText.moneyValue ?? 0 }
    private var existing: Set<String> { Set(allSubs.filter { $0.budget == budget }.map { $0.name.lowercased() }) }
    private var suggestions: [String] {
        Subcategory.suggestions(for: budget.category).filter { !existing.contains($0.lowercased()) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PixelTitle(text: "NEW CATEGORY", size: 24)
                Text("Inside \(budget.name.uppercased())").font(Pixel.font(13)).foregroundStyle(Pixel.heading)

                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(suggestions, id: \.self) { s in
                                Button { name = s } label: {
                                    Text(s.uppercased()).font(Pixel.font(11))
                                        .foregroundStyle(name == s ? Pixel.parchment : Pixel.ink)
                                        .padding(.horizontal, 10).padding(.vertical, 8)
                                        .background(name == s ? Pixel.green : Pixel.parchment)
                                        .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 3))
                                }
                            }
                        }
                        .padding(.trailing, 4)
                    }
                }
                PixelField(placeholder: "Name", text: $name)
                Text("MONTHLY LIMIT (OPTIONAL)").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                PixelField(placeholder: "No limit", text: $limitText, keyboard: .decimalPad)

                Button("CREATE") {
                    context.insert(Subcategory(name: trimmed, limit: limit, budget: budget))
                    dismiss()
                }
                .buttonStyle(PixelButtonStyle())
                .disabled(trimmed.isEmpty || existing.contains(trimmed.lowercased()))
            }
            .padding(16)
        }
    }
}
