import CoreTransferable
import Foundation
import UIKit
import UniformTypeIdentifiers

enum ExpensePDFReportType: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case allData

    var id: String { rawValue }
}

struct ExpensePDFCategorySummary: Equatable {
    let category: ExpenseCategory
    let total: Double
    let count: Int
}

struct ExpensePDFGoalSummary: Equatable {
    let title: String
    let spent: Double
    let remaining: Double
    let limit: Double
    let statusText: String
    let motivationText: String
}

struct ExpensePDFInsightSummary: Equatable {
    let title: String
    let message: String
    let type: SmartInsightType
}

struct ExpensePDFReportData: Equatable {
    let reportType: ExpensePDFReportType
    let reportTitle: String
    let reportTypeLabel: String
    let periodLabel: String
    let exportedOnLabel: String
    let totalSpentLabel: String
    let expenseCountLabel: String
    let topCategoryLabel: String
    let categoryBreakdownLabel: String
    let goalSummaryLabel: String
    let smartInsightsLabel: String
    let recentExpensesLabel: String
    let emptyStateMessage: String
    let footerText: String
    let generatedAt: Date
    let totalSpent: Double
    let expenseCount: Int
    let topCategory: ExpenseCategory?
    let categoryBreakdown: [ExpensePDFCategorySummary]
    let goalSummaries: [ExpensePDFGoalSummary]
    let smartInsights: [ExpensePDFInsightSummary]
    let recentExpenses: [Expense]

    var signature: String {
        let categorySignature = categoryBreakdown
            .map { "\($0.category.id.uuidString):\($0.total):\($0.count)" }
            .joined(separator: ",")

        let goalSignature = goalSummaries
            .map { "\($0.title):\($0.spent):\($0.remaining):\($0.limit):\($0.statusText)" }
            .joined(separator: ",")

        let insightSignature = smartInsights
            .map { "\($0.title):\($0.message):\($0.type.rawValue)" }
            .joined(separator: ",")

        let expenseSignature = recentExpenses
            .map { "\($0.id.uuidString):\($0.amount):\($0.date.timeIntervalSince1970):\($0.category.id.uuidString):\($0.merchant):\($0.note)" }
            .joined(separator: ",")

        return [
            reportType.rawValue,
            reportTitle,
            reportTypeLabel,
            periodLabel,
            exportedOnLabel,
            totalSpentLabel,
            expenseCountLabel,
            topCategoryLabel,
            categoryBreakdownLabel,
            goalSummaryLabel,
            smartInsightsLabel,
            recentExpensesLabel,
            emptyStateMessage,
            footerText,
            String(format: "%.2f", totalSpent),
            "\(expenseCount)",
            topCategory?.id.uuidString ?? "none",
            categorySignature,
            goalSignature,
            insightSignature,
            expenseSignature
        ]
        .joined(separator: "|")
    }
}

struct ExpensePDFExport: Transferable, Equatable {
    let fileName: String
    let fileURL: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf, shouldAllowToOpenInPlace: false) { export in
            SentTransferredFile(export.fileURL, allowAccessingOriginalFile: false)
        }
    }
}

@MainActor
final class ExpensePDFExportService {
    private var cache: [String: ExpensePDFExport] = [:]

    func export(report: ExpensePDFReportData) -> ExpensePDFExport? {
        let key = report.signature
        if let cached = cache[key], FileManager.default.fileExists(atPath: cached.fileURL.path) {
            return cached
        }

        let fileName = fileName(for: report)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let success = render(report: report, to: fileURL)

        guard success else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        let export = ExpensePDFExport(fileName: fileName, fileURL: fileURL)
        cache[key] = export
        return export
    }

    private func render(report: ExpensePDFReportData, to fileURL: URL) -> Bool {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: fileURL, withActions: { context in
                var layout = PDFLayout(pageRect: pageRect)
                beginPage(context: context, layout: &layout)

                drawHeader(report: report, layout: &layout, context: context)
                drawSummaryGrid(report: report, layout: &layout, context: context)
                drawCategoryBreakdown(report: report, layout: &layout, context: context)
                drawGoalSummaries(report: report, layout: &layout, context: context)
                drawSmartInsights(report: report, layout: &layout, context: context)
                drawRecentExpenses(report: report, layout: &layout, context: context)
                drawFooter(report: report, layout: &layout, context: context)
            })
            return true
        } catch {
            return false
        }
    }

    private func drawHeader(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)

        drawText(report.reportTitle, font: titleFont, color: .label, in: &layout, context: context, bottomPadding: 6)
        drawText(report.reportTypeLabel, font: subtitleFont, color: .secondaryLabel, in: &layout, context: context, bottomPadding: 4)
        drawText("\(report.exportedOnLabel): \(dateString(report.generatedAt))", font: bodyFont, color: .secondaryLabel, in: &layout, context: context, bottomPadding: 3)
        drawText("\(report.periodLabel)", font: bodyFont, color: .secondaryLabel, in: &layout, context: context, bottomPadding: 6)
        drawDivider(in: &layout, context: context)
    }

    private func drawSummaryGrid(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        let cardHeight: CGFloat = 76
        ensureSpace(cardHeight + 18, layout: &layout, context: context)

        let gap: CGFloat = 12
        let cardWidth = (layout.contentWidth - gap) / 2
        let leftX = layout.margin
        let rightX = layout.margin + cardWidth + gap
        let topY = layout.y

        drawMetricCard(
            title: report.totalSpentLabel,
            value: currency(report.totalSpent),
            subtitle: report.periodLabel,
            frame: CGRect(x: leftX, y: topY, width: cardWidth, height: cardHeight)
        )

        drawMetricCard(
            title: report.topCategoryLabel,
            value: report.topCategory?.displayName ?? "—",
            subtitle: "\(report.expenseCountLabel): \(report.expenseCount)",
            frame: CGRect(x: rightX, y: topY, width: cardWidth, height: cardHeight)
        )

        layout.y += cardHeight + 18
    }

    private func drawCategoryBreakdown(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        drawSectionTitle(report.categoryBreakdownLabel, layout: &layout, context: context)

        if report.categoryBreakdown.isEmpty {
            drawParagraph(
                report.emptyStateMessage,
                font: UIFont.systemFont(ofSize: 11, weight: .regular),
                color: .secondaryLabel,
                in: &layout,
                context: context,
                bottomPadding: 14
            )
            return
        }

        for item in report.categoryBreakdown {
            let rowHeight: CGFloat = 40
            ensureSpace(rowHeight + 8, layout: &layout, context: context)

            let rowRect = CGRect(x: layout.margin, y: layout.y, width: layout.contentWidth, height: rowHeight)
            drawRowBackground(in: rowRect)

            let nameFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let metaFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let amountFont = UIFont.systemFont(ofSize: 11, weight: .semibold)

            drawText(item.category.displayName, font: nameFont, color: .label, rect: CGRect(x: rowRect.minX + 10, y: rowRect.minY + 6, width: rowRect.width * 0.5, height: 14))
            drawText("\(item.count)", font: metaFont, color: .secondaryLabel, rect: CGRect(x: rowRect.minX + 10, y: rowRect.minY + 21, width: rowRect.width * 0.5, height: 12))
            drawText(currency(item.total), font: amountFont, color: .label, rect: CGRect(x: rowRect.maxX - 120, y: rowRect.minY + 12, width: 110, height: 16), alignment: .right)

            layout.y += rowHeight + 8
        }

        layout.y += 6
    }

    private func drawGoalSummaries(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        drawSectionTitle(report.goalSummaryLabel, layout: &layout, context: context)

        if report.goalSummaries.isEmpty {
            drawParagraph(
                report.emptyStateMessage,
                font: UIFont.systemFont(ofSize: 11, weight: .regular),
                color: .secondaryLabel,
                in: &layout,
                context: context,
                bottomPadding: 14
            )
            return
        }

        for goal in report.goalSummaries {
            let blockHeight: CGFloat = 58
            ensureSpace(blockHeight + 10, layout: &layout, context: context)

            let blockRect = CGRect(x: layout.margin, y: layout.y, width: layout.contentWidth, height: blockHeight)
            drawRowBackground(in: blockRect)

            let titleFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let metaFont = UIFont.systemFont(ofSize: 10, weight: .regular)

            drawText(goal.title, font: titleFont, color: .label, rect: CGRect(x: blockRect.minX + 10, y: blockRect.minY + 8, width: blockRect.width * 0.65, height: 14))
            drawText(goal.statusText, font: metaFont, color: .secondaryLabel, rect: CGRect(x: blockRect.minX + 10, y: blockRect.minY + 24, width: blockRect.width * 0.65, height: 12))
            drawText(currency(goal.spent), font: titleFont, color: .label, rect: CGRect(x: blockRect.maxX - 120, y: blockRect.minY + 8, width: 110, height: 14), alignment: .right)
            drawText(currency(goal.remaining), font: metaFont, color: .secondaryLabel, rect: CGRect(x: blockRect.maxX - 120, y: blockRect.minY + 24, width: 110, height: 12), alignment: .right)
            drawParagraph(goal.motivationText, font: metaFont, color: .secondaryLabel, rect: CGRect(x: blockRect.minX + 10, y: blockRect.minY + 38, width: blockRect.width - 20, height: 14))

            layout.y += blockHeight + 10
        }

        layout.y += 6
    }

    private func drawSmartInsights(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        drawSectionTitle(report.smartInsightsLabel, layout: &layout, context: context)

        if report.smartInsights.isEmpty {
            drawParagraph(
                report.emptyStateMessage,
                font: UIFont.systemFont(ofSize: 11, weight: .regular),
                color: .secondaryLabel,
                in: &layout,
                context: context,
                bottomPadding: 14
            )
            return
        }

        for insight in report.smartInsights {
            let estimatedHeight: CGFloat = 54
            ensureSpace(estimatedHeight + 8, layout: &layout, context: context)

            let blockRect = CGRect(x: layout.margin, y: layout.y, width: layout.contentWidth, height: estimatedHeight)
            drawRowBackground(in: blockRect)

            let titleFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let iconColor = insight.type.uiColor

            let iconRect = CGRect(x: blockRect.minX + 10, y: blockRect.minY + 10, width: 16, height: 16)
            drawIcon(in: iconRect, tint: iconColor)

            drawText(insight.title, font: titleFont, color: .label, rect: CGRect(x: blockRect.minX + 34, y: blockRect.minY + 8, width: blockRect.width - 44, height: 14))
            drawParagraph(insight.message, font: bodyFont, color: .secondaryLabel, rect: CGRect(x: blockRect.minX + 34, y: blockRect.minY + 24, width: blockRect.width - 44, height: 20))

            layout.y += estimatedHeight + 8
        }

        layout.y += 6
    }

    private func drawRecentExpenses(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        drawSectionTitle(report.recentExpensesLabel, layout: &layout, context: context)

        if report.recentExpenses.isEmpty {
            drawParagraph(
                report.emptyStateMessage,
                font: UIFont.systemFont(ofSize: 11, weight: .regular),
                color: .secondaryLabel,
                in: &layout,
                context: context,
                bottomPadding: 14
            )
            return
        }

        for expense in report.recentExpenses.prefix(10) {
            let rowHeight: CGFloat = expense.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 46 : 62
            ensureSpace(rowHeight + 8, layout: &layout, context: context)

            let rowRect = CGRect(x: layout.margin, y: layout.y, width: layout.contentWidth, height: rowHeight)
            drawRowBackground(in: rowRect)

            let titleFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)

            let merchant = expense.merchant.isEmpty ? expense.category.displayName : expense.merchant
            drawText(merchant, font: titleFont, color: .label, rect: CGRect(x: rowRect.minX + 10, y: rowRect.minY + 8, width: rowRect.width * 0.62, height: 14))
            drawText(PocketLeakFormatters.pdfDateFormatter.string(from: expense.date), font: bodyFont, color: .secondaryLabel, rect: CGRect(x: rowRect.minX + 10, y: rowRect.minY + 24, width: rowRect.width * 0.62, height: 12))

            drawText(currency(expense.amount), font: titleFont, color: .label, rect: CGRect(x: rowRect.maxX - 120, y: rowRect.minY + 8, width: 110, height: 14), alignment: .right)
            drawText(expense.category.displayName, font: bodyFont, color: .secondaryLabel, rect: CGRect(x: rowRect.maxX - 120, y: rowRect.minY + 24, width: 110, height: 12), alignment: .right)

            if !expense.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawParagraph(
                    expense.note,
                    font: bodyFont,
                    color: .secondaryLabel,
                    rect: CGRect(x: rowRect.minX + 10, y: rowRect.minY + 38, width: rowRect.width - 20, height: 16)
                )
            }

            layout.y += rowHeight + 8
        }
    }

    private func drawFooter(report: ExpensePDFReportData, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        ensureSpace(20, layout: &layout, context: context)
        let footerRect = CGRect(x: layout.margin, y: layout.y + 4, width: layout.contentWidth, height: 12)
        drawText(report.footerText, font: UIFont.systemFont(ofSize: 9, weight: .regular), color: .secondaryLabel, rect: footerRect, alignment: .center)
        layout.y += 16
    }

    private func drawMetricCard(title: String, value: String, subtitle: String, frame: CGRect) {
        drawRowBackground(in: frame)
        drawText(title, font: UIFont.systemFont(ofSize: 10, weight: .semibold), color: .secondaryLabel, rect: CGRect(x: frame.minX + 10, y: frame.minY + 10, width: frame.width - 20, height: 12))
        drawText(value, font: UIFont.systemFont(ofSize: 16, weight: .bold), color: .label, rect: CGRect(x: frame.minX + 10, y: frame.minY + 26, width: frame.width - 20, height: 20))
        drawText(subtitle, font: UIFont.systemFont(ofSize: 9, weight: .regular), color: .secondaryLabel, rect: CGRect(x: frame.minX + 10, y: frame.minY + 48, width: frame.width - 20, height: 12))
    }

    private func drawSectionTitle(_ title: String, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        ensureSpace(24, layout: &layout, context: context)
        drawText(title, font: UIFont.systemFont(ofSize: 14, weight: .bold), color: .label, rect: CGRect(x: layout.margin, y: layout.y, width: layout.contentWidth, height: 18))
        layout.y += 22
    }

    private func drawDivider(in layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        ensureSpace(8, layout: &layout, context: context)
        let path = UIBezierPath(rect: CGRect(x: layout.margin, y: layout.y + 3, width: layout.contentWidth, height: 1))
        UIColor.separator.setFill()
        path.fill()
        layout.y += 12
    }

    private func drawRowBackground(in rect: CGRect) {
        let rounded = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        UIColor.secondarySystemBackground.setFill()
        rounded.fill()
        UIColor.tertiaryLabel.withAlphaComponent(0.18).setStroke()
        rounded.lineWidth = 0.5
        rounded.stroke()
    }

    private func drawIcon(in rect: CGRect, tint: UIColor) {
        tint.setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        path.fill()
    }

    private func drawText(_ text: String, font: UIFont, color: UIColor, in layout: inout PDFLayout, context: UIGraphicsPDFRendererContext, bottomPadding: CGFloat = 0) {
        let height = measuredHeight(for: text, font: font, width: layout.contentWidth)
        ensureSpace(height + bottomPadding, layout: &layout, context: context)
        let rect = CGRect(x: layout.margin, y: layout.y, width: layout.contentWidth, height: height)
        drawText(text, font: font, color: color, rect: rect)
        layout.y += height + bottomPadding
    }

    private func drawParagraph(_ text: String, font: UIFont, color: UIColor, in layout: inout PDFLayout, context: UIGraphicsPDFRendererContext, bottomPadding: CGFloat = 0) {
        drawText(text, font: font, color: color, in: &layout, context: context, bottomPadding: bottomPadding)
    }

    private func drawParagraph(_ text: String, font: UIFont, color: UIColor, rect: CGRect) {
        drawText(text, font: font, color: color, rect: rect)
    }

    private func drawText(_ text: String, font: UIFont, color: UIColor, rect: CGRect, alignment: NSTextAlignment = .left) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }

    private func measuredHeight(for text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.height)
    }

    private func ensureSpace(_ neededHeight: CGFloat, layout: inout PDFLayout, context: UIGraphicsPDFRendererContext) {
        if layout.y + neededHeight > layout.pageRect.height - layout.bottomMargin {
            beginPage(context: context, layout: &layout)
        }
    }

    private func beginPage(context: UIGraphicsPDFRendererContext, layout: inout PDFLayout) {
        context.beginPage()
        layout.y = layout.margin
    }

    private func currency(_ amount: Double) -> String {
        PocketLeakFormatters.pdfCurrencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
    }

    private func dateString(_ date: Date) -> String {
        PocketLeakFormatters.pdfDateFormatter.string(from: date)
    }

    private func fileName(for report: ExpensePDFReportData) -> String {
        let suffix = report.reportType.rawValue
        return "Pocket-Leak-\(suffix)-Report-\(PocketLeakFormatters.pdfExportFileDateFormatter.string(from: .now)).pdf"
    }

    private struct PDFLayout {
        let pageRect: CGRect
        let margin: CGFloat = 36
        var y: CGFloat = 36

        var contentWidth: CGFloat {
            pageRect.width - (margin * 2)
        }

        var bottomMargin: CGFloat {
            margin
        }
    }
}

private extension SmartInsightType {
    var uiColor: UIColor {
        switch self {
        case .spendingIncrease, .goalRisk:
            return .systemRed
        case .spendingDecrease, .positiveTrend:
            return .systemGreen
        case .topCategory:
            return .systemBlue
        case .dailyAverage:
            return .systemOrange
        case .neutral:
            return .systemGray
        }
    }
}
