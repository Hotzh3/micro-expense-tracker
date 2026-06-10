import XCTest
@testable import JTap

final class ExpenseTextParserTests: XCTestCase {
    private let parser = ExpenseTextParser()

    private struct ParseCase {
        let text: String
        let amount: Double?
        let merchant: String?
        let category: ExpenseCategory?
    }

    func testParsesAndNormalizesStarbucksReforma() {
        let result = parser.parse("BBVA COMPRA APROBADA STARBUCKS $85.50", categories: ExpenseCategory.allDefaults)

        XCTAssertEqual(result?.amount ?? -1, 85.50, accuracy: 0.001)
        XCTAssertEqual(result?.merchant, "Starbucks")
        XCTAssertEqual(result?.category, .coffee)
        XCTAssertNotNil(result?.rawMerchant)
    }

    func testParsesUberTripWithMXNCurrencySuffix() {
        let result = parser.parse("NU: UBER TRIP MXN 65", categories: ExpenseCategory.allDefaults)

        XCTAssertEqual(result?.amount ?? -1, 65, accuracy: 0.001)
        XCTAssertEqual(result?.merchant, "Uber")
        XCTAssertEqual(result?.category, .transport)
        XCTAssertGreaterThan(result?.confidence ?? 0, 0.6)
    }

    func testParsesAmazonThroughMercadoPagoCharge() {
        let result = parser.parse("Mercado Pago cargo de $220 en Amazon", categories: ExpenseCategory.allDefaults)

        XCTAssertEqual(result?.amount ?? -1, 220, accuracy: 0.001)
        XCTAssertEqual(result?.merchant, "Amazon")
        XCTAssertEqual(result?.category, .shopping)
    }

    func testParsesToksWithTrailingCurrency() {
        let result = parser.parse("Pago en Restaurante Toks 430.00 MXN", categories: ExpenseCategory.allDefaults)

        XCTAssertEqual(result?.amount ?? -1, 430, accuracy: 0.001)
        XCTAssertEqual(result?.merchant, "Toks")
        XCTAssertEqual(result?.category, .food)
    }

    func testParsesOxxoBeforeAndAfterAmount() {
        let before = parser.parse("OXXO 89", categories: ExpenseCategory.allDefaults)
        let after = parser.parse("89 OXXO", categories: ExpenseCategory.allDefaults)

        XCTAssertEqual(before?.merchant, "OXXO")
        XCTAssertEqual(after?.merchant, "OXXO")
        XCTAssertEqual(before?.category, .convenience)
        XCTAssertEqual(after?.category, .convenience)
    }

    func testParsesAppleBillWithDomainStyleMerchant() {
        let result = parser.parse("Apple.com/bill $199", categories: ExpenseCategory.allDefaults)

        XCTAssertEqual(result?.amount ?? -1, 199, accuracy: 0.001)
        XCTAssertEqual(result?.merchant, "Apple")
        XCTAssertEqual(result?.category, .shopping)
    }

    func testParsesRealWorldNotificationExamplesWithoutCrashing() {
        let cases: [ParseCase] = [
            ParseCase(text: "Compra por $129 en OXXO", amount: 129, merchant: "OXXO", category: .convenience),
            ParseCase(text: "BBVA: Compra aprobada por $85.50 en STARBUCKS", amount: 85.50, merchant: "Starbucks", category: .coffee),
            ParseCase(text: "NU: UBER TRIP MXN 65", amount: 65, merchant: "Uber", category: .transport),
            ParseCase(text: "OXXO 89", amount: 89, merchant: "OXXO", category: .convenience),
            ParseCase(text: "89 OXXO", amount: 89, merchant: "OXXO", category: .convenience),
            ParseCase(text: "Apple.com/bill $199", amount: 199, merchant: "Apple", category: .shopping),
            ParseCase(text: "Pago en Restaurante Toks 430.00 MXN", amount: 430, merchant: "Toks", category: .food),
            ParseCase(text: "texto sin monto", amount: nil, merchant: nil, category: nil),
            ParseCase(text: "hola mundo", amount: nil, merchant: nil, category: nil),
            ParseCase(text: "💸 compra $50 oxxo", amount: 50, merchant: "OXXO", category: .convenience),
            ParseCase(text: "Linea uno\nLinea dos\nCompra $42.75 en Uber", amount: 42.75, merchant: "Uber", category: .transport),
            ParseCase(text: "$1,299.00 Amazon", amount: 1299, merchant: "Amazon", category: .shopping),
            ParseCase(text: "MXN 75.50 en 7-Eleven", amount: 75.50, merchant: "7-Eleven", category: .convenience)
        ]

        for testCase in cases {
            let result = parser.parse(testCase.text, categories: ExpenseCategory.allDefaults)

            if let amount = testCase.amount {
                XCTAssertEqual(result?.amount ?? -1, amount, accuracy: 0.001, "Failed for input: \(testCase.text)")
            } else {
                XCTAssertNil(result?.amount, "Failed for input: \(testCase.text)")
            }

            if let merchant = testCase.merchant {
                XCTAssertEqual(result?.merchant, merchant, "Failed for input: \(testCase.text)")
            }

            if let category = testCase.category {
                XCTAssertEqual(result?.category, category, "Failed for input: \(testCase.text)")
            }
        }
    }

    func testParserHandlesArbitraryInputWithoutCrashing() {
        let samples = [
            "",
            "   ",
            "💸💸💸",
            "line one\nline two\nline three",
            "!!! ??? ###",
            "Compra por $",
            "MXN",
            "1,2,3,4",
            "OXXO #%@ 75",
            "Random text with emoji 🚀 and symbols ©®™"
        ]

        for text in samples {
            _ = parser.parse(text, categories: ExpenseCategory.allDefaults)
        }
    }
}
