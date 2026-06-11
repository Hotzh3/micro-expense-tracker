import XCTest
@testable import JTap

final class DataBackupServiceTests: XCTestCase {
    func testBackupRoundTripPreservesExpectedData() throws {
        let service = DataBackupService()
        let settings = DataBackupSettingsSnapshot(
            appearance: AppAppearance.dark.rawValue,
            textSize: AppTextSize.medium.rawValue,
            language: AppLanguage.english.rawValue,
            hapticsEnabled: true,
            smartAlertsEnabled: true,
            localNotificationsEnabled: false,
            dailyCheckInEnabled: false,
            goalWarningsEnabled: false,
            weeklyDigestReminderEnabled: false,
            dailyCheckInHour: 18,
            dailyCheckInMinute: 0,
            weeklyDigestWeekday: 1,
            weeklyDigestHour: 9,
            weeklyDigestMinute: 0,
            hasSeenOnboarding: true
        )

        let document = DataBackupDocument(
            schemaVersion: DataBackupService.schemaVersion,
            exportedAt: .now,
            expenses: [
                Expense(amount: 42, category: .coffee, merchant: "Cafe", date: .now)
            ],
            goals: SpendingGoals(
                weekly: SpendingGoal(cadence: .weekly, limit: 100),
                monthly: SpendingGoal(cadence: .monthly, limit: 400)
            ),
            categoryBudgets: [
                CategoryBudget(category: .coffee, cadence: .monthly, limit: 80)
            ],
            recurringExpenses: [
                RecurringExpense(
                    merchant: "Spotify",
                    amount: 129,
                    category: .entertainment,
                    cadence: .monthly,
                    nextDueDate: .now
                )
            ],
            settings: settings
        )

        let export = service.makeExport(from: document)
        let imported = service.loadBackup(from: Data(export.json.utf8))

        XCTAssertNotNil(imported)
        XCTAssertEqual(imported?.schemaVersion, DataBackupService.schemaVersion)
        XCTAssertEqual(imported?.expenses.count, 1)
        XCTAssertEqual(imported?.goals.activeGoals.count, 2)
        XCTAssertEqual(imported?.categoryBudgets.count, 1)
        XCTAssertEqual(imported?.recurringExpenses.count, 1)
        XCTAssertEqual(imported?.settings, settings)
    }

    func testBackupImportIgnoresCorruptEntriesAndInvalidJSON() throws {
        let service = DataBackupService()

        XCTAssertNil(service.loadBackup(from: Data("not json".utf8)))

        let raw: [String: Any] = [
            "schemaVersion": DataBackupService.schemaVersion,
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "expenses": [
                [
                    "id": UUID().uuidString,
                    "amount": 10,
                    "category": [
                        "id": UUID().uuidString,
                        "displayName": "Coffee",
                        "symbolName": "cup.and.saucer.fill",
                        "keywords": []
                    ],
                    "merchant": "Cafe",
                    "note": "",
                    "date": ISO8601DateFormatter().string(from: .now),
                    "source": "manual",
                    "confidence": 1.0,
                    "createdAt": ISO8601DateFormatter().string(from: .now)
                ],
                [
                    "amount": "bad"
                ]
            ],
            "goals": [
                "weekly": [
                    "id": UUID().uuidString,
                    "cadence": "weekly",
                    "limit": 120,
                    "createdAt": ISO8601DateFormatter().string(from: .now),
                    "updatedAt": ISO8601DateFormatter().string(from: .now)
                ]
            ],
            "categoryBudgets": [],
            "recurringExpenses": [],
            "settings": [
                "appearance": "dark",
                "textSize": "medium",
                "language": "english",
                "hapticsEnabled": true,
                "smartAlertsEnabled": true,
                "localNotificationsEnabled": false,
                "dailyCheckInEnabled": false,
                "goalWarningsEnabled": false,
                "weeklyDigestReminderEnabled": false,
                "dailyCheckInHour": 18,
                "dailyCheckInMinute": 0,
                "weeklyDigestWeekday": 1,
                "weeklyDigestHour": 9,
                "weeklyDigestMinute": 0,
                "hasSeenOnboarding": false
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: raw)
        let imported = service.loadBackup(from: data)

        XCTAssertNotNil(imported)
        XCTAssertEqual(imported?.expenses.count, 1)
        XCTAssertEqual(imported?.goals.weekly?.cadence, .weekly)
    }
}
