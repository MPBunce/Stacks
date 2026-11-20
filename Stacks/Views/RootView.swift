import SwiftData
import SwiftUI

private enum Tab: CaseIterable {
    case budgets, home, insights

    var title: String {
        switch self {
        case .budgets: "BUDGETS"
        case .home: "HOME"
        case .insights: "STATS"
        }
    }

    var headerTitle: String {
        switch self {
        case .budgets: "BUDGETS"
        case .home: "STACKS"
        case .insights: "STATS"
        }
    }

    var icon: String {
        switch self {
        case .budgets: "list.bullet.rectangle.fill"
        case .home: "house.fill"
        case .insights: "chart.bar.fill"
        }
    }
}

struct RootView: View {
    @State private var tab: Tab = .home
    @State private var showAdd = false
    @State private var showSettings = false
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Theme.storageKey) private var themeRaw = Theme.neon.rawValue
    @AppStorage(Mascot.storageKey) private var mascotRaw = Mascot.coin.rawValue
    @AppStorage(Currency.storageKey) private var currencyRaw = Currency.code
    @AppStorage(IncomeStore.key) private var income: Double = 0
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Query private var expenses: [Expense]

    /// Changes whenever something the widgets show changes.
    private var widgetKey: String {
        let cal = Calendar.current
        let spent = expenses.filter { cal.isDate($0.date, equalTo: .now, toGranularity: .month) }.reduce(0) { $0 + $1.amount }
        return "\(themeRaw)|\(mascotRaw)|\(currencyRaw)|\(income)|\(spent)|\(budgets.map { "\($0.name):\($0.limit)" })"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                PixelBackground()
                Group {
                    switch tab {
                    case .budgets: NavigationStack { BudgetsView() }
                    case .home: NavigationStack { HomeView() }
                    case .insights: NavigationStack { InsightsView() }
                    }
                }
                .frame(maxWidth: 680)   // keeps iPad layouts phone-width instead of stretched
            }
            tabBar
        }
        .id(themeRaw + mascotRaw + currencyRaw)   // rebuild everything when the theme changes
        .tint(Pixel.gold)
        .preferredColorScheme((Theme(rawValue: themeRaw) ?? .neon).isLight ? .light : .dark)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            DemoData.seedIfRequested(in: context)
            RecurringEngine.process(in: context)
        }
        .task(id: widgetKey) {
            SnapshotWriter.write(budgets: budgets, expenses: expenses, income: income, theme: themeRaw, mascot: mascotRaw, currency: currencyRaw)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { RecurringEngine.process(in: context) }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().presentationBackground { PixelBackground() }
        }
        .sheet(isPresented: $showAdd) {
            AddExpenseView()
                .presentationBackground { PixelBackground() }
        }
    }

    /// Fixed header: settings, screen title and add button. Content scrolls underneath it, never over it.
    private var header: some View {
        HStack {
            settingsButton
            Spacer()
            PixelTitle(text: tab.headerTitle, size: 22)
            Spacer()
            addButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Pixel.grass.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) {
            HStack(spacing: 2) {
                Rectangle().fill(Pixel.woodDark).frame(width: 16, height: 4)
                Rectangle().fill(Pixel.woodDark.opacity(0.45)).frame(height: 2)
                Rectangle().fill(Pixel.woodDark).frame(width: 4, height: 4)
            }
        }
        .zIndex(1)
    }

    /// Gold "+" for logging spending.
    private var addButton: some View {
        Button { showAdd = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(Pixel.onAccent)
                .frame(width: 36, height: 36)
                .background(Pixel.gold)
                .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.3)).frame(height: 3) }
        }
        .accessibilityLabel("Add expense")
    }

    /// Gear in the top-left corner for settings.
    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Pixel.heading)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel("Settings")
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases, id: \.self) { tabButton($0) }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(Pixel.wood.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(_ t: Tab) -> some View {
        let selected = tab == t
        return Button { tab = t } label: {
            VStack(spacing: 3) {
                Image(systemName: t.icon).font(.system(size: 17, weight: .heavy))
                Text(t.title).font(Pixel.font(9))
            }
            .foregroundStyle(selected ? Pixel.onFrame : Pixel.onFrame.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .overlay(alignment: .top) {
                Rectangle().fill(selected ? Pixel.gold : Color.clear).frame(width: 28, height: 4)
                    .offset(y: -8)
            }
        }
    }
}
