import SwiftData
import SwiftUI

struct AddExpenseView: View {
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Budget?
    @State private var amountText = ""
    @State private var title = ""
    @State private var noteText = ""
    @State private var date = Date()
    @Environment(\.viewMonth) private var viewMonth
    @State private var repeatFreq: RepeatFrequency?
    @State private var subSelected: Subcategory?
    @Query(sort: \Subcategory.createdAt) private var allSubs: [Subcategory]
    private var subsForSelected: [Subcategory] { allSubs.filter { $0.budget == selected } }

    private var amount: Double? { amountText.moneyValue }
    private var canSave: Bool { (amount ?? 0) > 0 && selected != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PixelTitle(text: "SPEND COINS", size: 26)

                if budgets.isEmpty {
                    Text("Create a budget first, then log spending here.")
                        .font(Pixel.font(13, weight: .semibold))
                        .foregroundStyle(Pixel.heading)
                } else {
                    Text("BUDGET").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(budgets) { budget in
                                Button { selected = budget; subSelected = nil } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: budget.category.icon)
                                        Text(budget.name.uppercased()).font(Pixel.font(11))
                                    }
                                    .foregroundStyle(selected == budget ? Color.white : Pixel.ink)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(selected == budget ? budget.category.color : Pixel.parchment)
                                    .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 3))
                                }
                            }
                        }
                        .padding(.trailing, 4)
                    }

                    if selected != nil, !subsForSelected.isEmpty {
                        Text("CATEGORY").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                subChip("NONE", nil)
                                ForEach(subsForSelected) { subChip($0.name.uppercased(), $0) }
                            }
                            .padding(.trailing, 4)
                        }
                    }

                    Text("AMOUNT").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    PixelField(placeholder: "0.00", text: $amountText, keyboard: .decimalPad)
                        .onChange(of: amountText) { _, new in
                            let clean = Self.numbersOnly(new)
                            if clean != new { amountText = clean }
                        }

                    Text("NAME").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    PixelField(placeholder: "Rent, Groceries, Coffee...", text: $title)

                    Text("NOTE").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    PixelField(placeholder: "Optional details", text: $noteText)

                    Text("DATE").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Pixel.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("REPEATS").font(Pixel.font(13)).foregroundStyle(Pixel.heading)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            repeatChip("ONE-TIME", nil)
                            ForEach(RepeatFrequency.allCases) { repeatChip($0.title.uppercased(), $0) }
                        }
                        .padding(.trailing, 4)
                    }
                    if let repeatFreq {
                        Text("Logged on the date above, then automatically \(repeatFreq.title.lowercased()). Manage it in BUDGETS.")
                            .font(Pixel.font(12, weight: .semibold))
                            .foregroundStyle(Pixel.heading)
                    }

                    Button("SAVE") {
                        guard let amount, let selected else { return }
                        let name = title.trimmingCharacters(in: .whitespaces)
                        let note = noteText.trimmingCharacters(in: .whitespaces)
                        if let repeatFreq {
                            context.insert(RecurringExpense(title: name, amount: amount, frequency: repeatFreq, startDate: date, budget: selected, subcategory: subSelected, note: note))
                            RecurringEngine.process(in: context)
                        } else {
                            context.insert(Expense(title: name, amount: amount, date: date, budget: selected, subcategory: subSelected, note: note))
                        }
                        dismiss()
                    }
                    .buttonStyle(PixelButtonStyle())
                    .disabled(!canSave)
                    .padding(.top, 8)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if selected == nil { selected = budgets.first }
            date = ViewMonth.defaultDate(in: viewMonth)
        }
    }

    /// Keeps digits and a single decimal point (a typed comma counts as the point).
    private static func numbersOnly(_ s: String) -> String {
        var out = "", seenPoint = false
        for ch in s {
            if ch.isASCII, ch.isNumber { out.append(ch) }
            else if (ch == "." || ch == ","), !seenPoint { out.append("."); seenPoint = true }
        }
        return out
    }

    private func subChip(_ label: String, _ sub: Subcategory?) -> some View {
        let on = subSelected == sub
        return Button { subSelected = sub } label: {
            Text(label)
                .font(Pixel.font(11))
                .foregroundStyle(on ? Pixel.parchment : Pixel.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(on ? Pixel.green : Pixel.parchment)
                .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 3))
        }
    }

    private func repeatChip(_ label: String, _ freq: RepeatFrequency?) -> some View {
        let on = repeatFreq == freq
        return Button { repeatFreq = freq } label: {
            Text(label)
                .font(Pixel.font(11))
                .foregroundStyle(on ? Pixel.parchment : Pixel.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(on ? Pixel.green : Pixel.parchment)
                .overlay(Rectangle().stroke(Pixel.woodDark, lineWidth: 3))
        }
    }
}
