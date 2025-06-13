//
//  TransactionTests.swift
//  YaschoolTests
//
//  Created by Ivan Isaev on 13.06.2025.
//

import XCTest
@testable import Yaschool

final class TransactionParsingTests: XCTestCase {
    private var testDateFormatter: ISO8601DateFormatter!
    
    override func setUp() {
        super.setUp()
        testDateFormatter = ISO8601DateFormatter()
    }
    
    override func tearDown() {
        testDateFormatter = nil
        super.tearDown()
    }
    
    // MARK: - Вспомогательные методы для создания тестовых данных
    
    private let baseCategoryDict: [String: Any] = [
        "id": 1,
        "name": "Зарплата",
        "emoji": "💰",
        "isIncome": true
    ]
    
    private func makeTransactionDict(
        id: Int = 1,
        amount: String = "500.00",
        transactionDate: Date = Date(),
        comment: String? = "Зарплата за месяц",
        categoryDict: [String: Any]? = nil
    ) -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "amount": amount,
            "transactionDate": testDateFormatter.string(from: transactionDate)
        ]
        
        if let comment {
            dict["comment"] = comment
        }
        
        if let categoryDict {
            dict["category"] = categoryDict
        }
        
        return dict
    }
    
    // MARK: - Успешный парсинг
    func testValidTransactionParsing() {
        let transactionDict: [String: Any] = makeTransactionDict(categoryDict: baseCategoryDict)
        
        guard let transaction = Transaction.parse(jsonObject: transactionDict) else {
            XCTFail("Должна быть успешно распарсена транзакция")
            return
        }
        
        XCTAssertEqual(transaction.id, 1)
        XCTAssertEqual(transaction.amount, Decimal(string: "500.00"))
        XCTAssertEqual(transaction.comment, "Зарплата за месяц")
        XCTAssertEqual(transaction.category.id, 1)
        XCTAssertEqual(transaction.category.name, "Зарплата")
        XCTAssertEqual(transaction.category.emoji, "💰")
        XCTAssertTrue(transaction.category.isIncome)
    }
    
    // MARK: - Отсутствующие обязательные поля
    func testMissingRequiredFields() {
        let testCases: [(String, [String: Any])] = [
            ("Отсутствует id", [:]),
            ("Отсутствует amount", ["id": 1]),
            ("Отсутствует transactionDate", ["id": 1, "amount": "500.00"]),
            ("Отсутствует category", ["id": 1, "amount": "500.00", "transactionDate": testDateFormatter.string(from: Date())])
        ]
        
        for (testCaseName, transactionDict) in testCases {
            XCTAssertNil(Transaction.parse(jsonObject: transactionDict), testCaseName)
        }
    }
    
    // MARK: - Неверные типы данных
    func testInvalidTypes() {
        let testCases: [(String, [String: Any])] = [
            ("Неверный тип id", ["id": "not a number", "amount": "500.00", "transactionDate": testDateFormatter.string(from: Date()), "category": baseCategoryDict]),
            ("Неверный тип amount", ["id": 1, "amount": 123, "transactionDate": testDateFormatter.string(from: Date()), "category": baseCategoryDict]),
            ("Неверный тип transactionDate", ["id": 1, "amount": "500.00", "transactionDate": 123, "category": baseCategoryDict]),
            ("Неверный тип category", ["id": 1, "amount": "500.00", "transactionDate": testDateFormatter.string(from: Date()), "category": "not a dictionary"])
        ]
        
        for (testCaseName, transactionDict) in testCases {
            XCTAssertNil(Transaction.parse(jsonObject: transactionDict), testCaseName)
        }
    }
    
    // MARK: - Некорректные значения
    func testInvalidValues() {
        let testCases: [(String, [String: Any])] = [
            ("Некорректная сумма", ["id": 1, "amount": "not a decimal", "transactionDate": testDateFormatter.string(from: Date()), "category": baseCategoryDict]),
            ("Некорректная дата", ["id": 1, "amount": "500.00", "transactionDate": "invalid date", "category": baseCategoryDict]),
            ("Некорректный id категории", ["id": 1, "amount": "500.00", "transactionDate": testDateFormatter.string(from: Date()), "category": ["id": "not a number", "name": "Зарплата", "emoji": "💰", "isIncome": true]]),
            ("Некорректный isIncome", ["id": 1, "amount": "500.00", "transactionDate": testDateFormatter.string(from: Date()), "category": ["id": 1, "name": "Зарплата", "emoji": "💰", "isIncome": "not a boolean"]])
        ]
        
        for (testCaseName, transactionDict) in testCases {
            XCTAssertNil(Transaction.parse(jsonObject: transactionDict), testCaseName)
        }
    }
    
    // MARK: - Опциональные поля
    func testOptionalFields() {
        let transactionDict: [String: Any] = makeTransactionDict(
            comment: nil,
            categoryDict: baseCategoryDict
        )
        
        guard let transaction = Transaction.parse(jsonObject: transactionDict) else {
            XCTFail("Должна быть успешно распарсена транзакция")
            return
        }
        
        XCTAssertEqual(transaction.comment, nil)
    }
    
    // MARK: - Опциональные поля в категории
    func testInvalidCategoryFields() {
        let categoryDict: [String: Any] = [
            "id": 1,
            "name": "", // Пустое имя
            "emoji": "",
            "isIncome": true
        ]
        
        let transactionDict: [String: Any] = makeTransactionDict(categoryDict: categoryDict)
        
        XCTAssertNil(Transaction.parse(jsonObject: transactionDict), "Некорректный emoji")
        
        // TODO: Мб использовать значение по умолчанию при парсинге?
//        XCTAssertEqual(transaction.category.name, "Без названия")
    }
}
