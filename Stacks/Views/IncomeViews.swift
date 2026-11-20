import SwiftData
import SwiftUI

extension String {
    /// Parses typed money: "3200", "3,200.50", or a decimal-comma like "12,50".
    var moneyValue: Double? {
        var s = trimmingCharacters(in: .whitespaces)
        if s.contains(","), !s.contains(".") {
            let parts = s.split(separator: ",", omittingEmptySubsequences: false)
            s = (parts.count == 2 && parts[1].count <= 2)
                ? s.replacingOccurrences(of: ",", with: ".")
                : s.replacingOccurrences(of: ",", with: "")
        } else {
            s = s.replacingOccurrences(of: ",", with: "")
        }
        return Double(s)
    }
}

extension Double {
    /// "3200" or "3200.50" without currency symbols, for pre-filling a text field.
    var plainText: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%.2f", self)
    }
}

/// Where the user's monthly income is stored. Budgets and the tower are measured against it.
enum IncomeStore {
    static let key = "monthlyIncome"
}

// MARK: - Editor

struct IncomeEditorView: View {
    @AppStorage(IncomeStore.key) private var income: Double = 0
    @Environment(\.dismiss) private var dismiss
    @Query private var budgets: [Budget]
    @State private var text = ""

    private var value: Double? {
        guard let v = text.moneyValue, v > 0 else { return nil }
        return v
    }

    /// Keeps each budget's share of income the same when income changes.
    private func rescaleBudgets(to newIncome: Double) {
        guard income > 0, newIncome != income else { return }
        let factor = newIncome / income
        for budget in budgets {
            budget.limit = (budget.limit * factor * 100).rounded() / 100
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PixelTitle(text: "MONTHLY INCOME", size: 24)
            Text("Your take-home pay each month. If you change it, your budgets scale to match.")
                .font(Pixel.font(12, weight: .semibold))
                .foregroundStyle(Pixel.heading)
            PixelField(placeholder: "0.00", text: $text, keyboard: .decimalPad)
            Button("SAVE") {
                if let value {
                    rescaleBudgets(to: value)
                    income = value
                    dismiss()
                }
            }
            .buttonStyle(PixelButtonStyle())
            .disabled(value == nil)
            Spacer()
        }
        .padding(16)
        .onAppear { if income > 0 { text = income.plainText } }
    }
}

// MARK: - Card

/// Income plus how much of it the budgets have claimed.
struct IncomeCard: View {
    @AppStorage(IncomeStore.key) private var income: Double = 0
    @Query private var budgets: [Budget]
    @State private var showEditor = false

    private var allocated: Double { budgets.reduce(0) { $0 + $1.limit } }
    private var unassigned: Double { income - allocated }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MONTHLY INCOME").font(Pixel.font(12)).foregroundStyle(Pixel.dim)
                Spacer()
                Button { showEditor = true } label: {
                    Text(income > 0 ? "EDIT" : "SET")
                        .font(Pixel.font(12))
                        .foregroundStyle(Pixel.onAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Pixel.gold)
                        .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 2))
                }
            }
            Text(income > 0 ? income.money : "Not set yet")
                .font(Pixel.font(26))
                .foregroundStyle(income > 0 ? Pixel.green : Pixel.dim)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if income > 0 {
                PixelBar(progress: allocated / income, neutral: true)
                HStack {
                    Text("ALLOCATED \(allocated.money)")
                        .foregroundStyle(Pixel.dim)
                    Spacer()
                    if unassigned >= 0 {
                        Text("UNASSIGNED \(unassigned.money)").foregroundStyle(Pixel.green)
                    } else {
                        Text("OVER BY \(abs(unassigned).money)").foregroundStyle(Pixel.red)
                    }
                }
                .font(Pixel.font(10))
            } else {
                Text("Set your income and Stacks will size your budgets from it.")
                    .font(Pixel.font(12, weight: .semibold))
                    .foregroundStyle(Pixel.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel()
        .sheet(isPresented: $showEditor) {
            IncomeEditorView()
                .presentationDetents([.medium])
                .presentationBackground { PixelBackground() }
        }
    }
}
