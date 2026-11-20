import Foundation

/// Builds a CSV of every expense and writes it to a temporary file for sharing.
enum CSVExport {
    static func csv(for expenses: [Expense]) -> String {
        func esc(_ s: String) -> String {
            s.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" })
                ? "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : s
        }
        let day = ISO8601DateFormatter()
        day.formatOptions = [.withFullDate]
        var lines = ["Date,Name,Note,Budget,Subcategory,Amount,Currency"]
        for e in expenses.sorted(by: { $0.date < $1.date }) {
            lines.append([
                day.string(from: e.date),
                esc(e.title),
                esc(e.note),
                esc(e.budget?.name ?? ""),
                esc(e.subcategory?.name ?? ""),
                String(format: "%.2f", e.amount),
                Currency.code,
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func file(for expenses: [Expense]) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("stacks-expenses.csv")
        do {
            try csv(for: expenses).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch { return nil }
    }
}
