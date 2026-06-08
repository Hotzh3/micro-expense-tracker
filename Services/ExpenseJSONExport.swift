import Foundation

struct ExpenseJSONExport {
    let fileName: String
    let json: String
    let fileURL: URL

    init(expenses: [Expense], fileName: String? = nil) {
        self.fileName = fileName ?? Self.defaultFileName()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = (try? encoder.encode(expenses)) ?? Data("[]".utf8)
        self.json = String(data: data, encoding: .utf8) ?? "[]"
        self.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(self.fileName)
        try? data.write(to: self.fileURL, options: [.atomic])
    }

    private static func defaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return "Pocket-Leak-Export-\(formatter.string(from: .now)).json"
    }
}
