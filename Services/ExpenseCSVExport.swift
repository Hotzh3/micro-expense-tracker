import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct ExpenseCSVExport: Transferable {
    let fileName: String
    let csv: String
    let fileURL: URL

    init(expenses: [Expense], fileName: String? = nil) {
        self.fileName = fileName ?? Self.defaultFileName()
        self.csv = Self.makeCSV(from: expenses)
        self.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(self.fileName)
        try? self.csv.data(using: .utf8)?.write(to: self.fileURL, options: [.atomic])
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText, shouldAllowToOpenInPlace: false) { export in
            SentTransferredFile(export.fileURL, allowAccessingOriginalFile: false)
        }
    }

    private static func makeCSV(from expenses: [Expense]) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let sortedExpenses = expenses.sorted { $0.date > $1.date }
        var rows = [
            ["date", "amount", "category", "merchant", "note", "source"].joined(separator: ",")
        ]

        rows.append(contentsOf: sortedExpenses.map { expense in
            [
                csvField(formatter.string(from: expense.date)),
                csvField(String(format: "%.2f", expense.amount)),
                csvField(expense.category.displayName),
                csvField(expense.merchant),
                csvField(expense.note),
                csvField(expense.source.rawValue)
            ]
            .joined(separator: ",")
        })

        return rows.joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") || escaped.hasPrefix(" ") || escaped.hasSuffix(" ") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private static func defaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return "Pocket-Leak-Export-\(formatter.string(from: .now)).csv"
    }
}
