import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Environment(\.modelContext) private var context
    @AppStorage(IncomeStore.key) private var income: Double = 0
    @State private var incomeText = ""
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @State private var dropTrigger = 0
    @State private var squash = false
    @Environment(\.viewMonth) private var month

    private var totalLimit: Double { budgets.reduce(0) { $0 + $1.limit } }
    private var totalSpent: Double { budgets.reduce(0) { $0 + $1.spent(in: month) } }
    /// What the tower is measured against: monthly income if set, otherwise the sum of budget limits.
    private var base: Double { income > 0 ? income : totalLimit }
    private var remaining: Double { base - totalSpent }
    private var fraction: Double { base > 0 ? totalSpent / base : 0 }
    private var overBudget: Bool { base > 0 && totalSpent > base }
    private var coins: Int { fraction >= 1 ? 0 : max(1, Int(ceil((1 - fraction) * 7))) }

    private var isCurrentMonth: Bool { ViewMonth.isCurrent(month) }

    private var daysLeft: Int {
        let cal = Calendar.current
        let total = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        return max(total - cal.component(.day, from: .now) + 1, 1)
    }

    private var mood: MascotMood { overBudget ? .crumbled : (fraction > 0.8 ? .worried : .happy) }

    private var status: (pill: String, color: Color) {
        switch mood {
        case .crumbled: ("CRUMBLED", Pixel.red)
        case .worried: ("WOBBLY", Pixel.amber)
        case .happy: ("SAFE", Pixel.green)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if budgets.isEmpty {
                    emptyState
                } else {
                    MonthSwitcher()
                    towerCard
                    recentPanel
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUESTS").font(Pixel.font(14)).foregroundStyle(Pixel.heading)
                        ForEach(budgets) { budget in
                            NavigationLink(value: budget) { BudgetRow(budget: budget) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(PixelBackground())
        .navigationDestination(for: Budget.self) { BudgetDetailView(budget: $0) }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: totalSpent) { old, new in
            guard new > old else { return }
            dropTrigger += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.35)) { squash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { squash = false }
                }
            }
        }
    }

    private var recentPanel: some View {
        let recent = Array(allExpenses.filter { $0.date.isInMonth(of: month) }.prefix(3))
        return VStack(alignment: .leading, spacing: 10) {
            Text("RECENT").font(Pixel.font(12)).foregroundStyle(Pixel.dim)
            if recent.isEmpty {
                Text(isCurrentMonth ? "No spending yet. Tap + to log a coin." : "No spending logged this month.")
                    .font(Pixel.font(12, weight: .semibold))
                    .foregroundStyle(Pixel.dim)
            } else {
                ForEach(recent) { e in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text((e.title.isEmpty ? (e.budget?.name ?? "Expense") : e.title).uppercased())
                                .font(Pixel.font(12)).foregroundStyle(Pixel.ink).lineLimit(1)
                            Text(e.date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
                                 + (e.budget.map { " · " + $0.name.uppercased() } ?? ""))
                                .font(Pixel.font(9, weight: .bold)).foregroundStyle(Pixel.dim).lineLimit(1)
                        }
                        Spacer()
                        Text("-" + e.amount.money).font(Pixel.font(13)).foregroundStyle(Pixel.red)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
    }

    private var towerCard: some View {
        VStack(spacing: 14) {
            Text(status.pill)
                .font(Pixel.font(11))
                .foregroundStyle(Pixel.parchment)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(status.color)
            SpeechBubble(text: Mascot.current.message(mood))
            CoinTower(coins: coins, overBudget: overBudget, worried: mood == .worried)
                .scaleEffect(x: squash ? 1.06 : 1, y: squash ? 0.93 : 1, anchor: .bottom)
                .frame(height: 250, alignment: .bottom)
                .overlay(alignment: .bottom) { CoinDrop(trigger: dropTrigger).padding(.bottom, 120) }
            VStack(spacing: 4) {
                Text(abs(remaining).money)
                    .font(Pixel.font(44))
                    .foregroundStyle(overBudget ? Pixel.red : Pixel.green)
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text(overBudget
                     ? "OVER YOUR \(income > 0 ? "INCOME" : "BUDGET")"
                     : (isCurrentMonth
                        ? "LEFT · \((max(remaining, 0) / Double(daysLeft)).money) PER DAY"
                        : "LEFT IN \(month.formatted(.dateTime.month(.abbreviated)).uppercased())"))
                    .font(Pixel.font(11))
                    .foregroundStyle(Pixel.dim)
            }
            PixelBar(progress: fraction)
            Text("SPENT \(totalSpent.money) OF \(base.money)")
                .font(Pixel.font(10))
                .foregroundStyle(Pixel.dim)
        }
        .frame(maxWidth: .infinity)
        .pixelPanel(border: status.color)
    }

    private var newIncome: Double? {
        guard let v = incomeText.moneyValue, v > 0 else { return nil }
        return v
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            PixelSprite(rows: Mascot.current.rows(.happy), palette: Mascot.current.palette()).frame(width: 96)
            Text("NEW GAME").font(Pixel.font(20)).foregroundStyle(Pixel.amber)
            Text(income > 0
                 ? "Pick a loadout to start stacking coins."
                 : "Tell us your monthly income and we'll split it into Expenses, Fun Money and Savings.")
                .font(Pixel.font(13, weight: .semibold))
                .foregroundStyle(Pixel.dim)
                .multilineTextAlignment(.center)
            if income <= 0 {
                PixelField(placeholder: "Monthly income", text: $incomeText, keyboard: .decimalPad)
            }
            Button("START QUEST") {
                let amount = income > 0 ? income : (newIncome ?? 0)
                guard amount > 0 else { return }
                income = amount
                BudgetTemplate.all[0].apply(in: context, income: amount)
            }
            .buttonStyle(PixelButtonStyle())
            .disabled(income <= 0 && newIncome == nil)
            Text("More templates live in BUDGETS.")
                .font(Pixel.font(11, weight: .semibold))
                .foregroundStyle(Pixel.dim)
        }
        .frame(maxWidth: .infinity)
        .pixelPanel()
    }
}

/// A coin that drops onto the tower whenever spending is logged.
private struct CoinDrop: View {
    let trigger: Int
    @State private var fall = false
    @State private var visible = false

    var body: some View {
        PixelSprite(rows: Sprites.coin, palette: Sprites.gold)
            .frame(width: 44)
            .offset(y: fall ? 0 : -220)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, _ in
                fall = false
                visible = true
                withAnimation(.easeIn(duration: 0.5)) { fall = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { visible = false }
            }
    }
}
