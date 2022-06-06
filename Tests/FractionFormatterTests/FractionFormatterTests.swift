import XCTest
@testable import FractionFormatter

final class FractionFormatterTests: XCTestCase {
    let fractionFormatter = FractionFormatter()
    
    let superscriptExamples = [
        -100: "⁻¹⁰⁰",
        0: "⁰",
        100: "¹⁰⁰",
        200: "²⁰⁰",
        300: "³⁰⁰",
        400: "⁴⁰⁰",
        500: "⁵⁰⁰",
        600: "⁶⁰⁰",
        700: "⁷⁰⁰",
        800: "⁸⁰⁰",
        900: "⁹⁰⁰",
    ]
    
    let subscriptExamples = [
        -100: "₋₁₀₀",
        0: "₀",
        100: "₁₀₀",
        200: "₂₀₀",
        300: "₃₀₀",
        400: "₄₀₀",
        500: "₅₀₀",
        600: "₆₀₀",
        700: "₇₀₀",
        800: "₈₀₀",
        900: "₉₀₀",
    ]

    func testScripted() {
        for (integer, superInteger) in superscriptExamples {
            XCTAssertEqual(fractionFormatter.scripted(integer, scriptChars: FractionFormatter.unicodeSuperscript), superInteger)
        }
        for (integer, subInteger) in subscriptExamples {
            XCTAssertEqual(fractionFormatter.scripted(integer, scriptChars: FractionFormatter.unicodeSubscript), subInteger)
        }
    }

    func testRemoveFormatting() {
        for (integer, superInteger) in superscriptExamples {
            XCTAssertEqual(fractionFormatter.removeFormatting(superInteger.first!), String(integer).first)
        }
        for (integer, superInteger) in subscriptExamples {
            XCTAssertEqual(fractionFormatter.removeFormatting(superInteger.first!), String(integer).first)
        }
    }

    func testStringShilling() {
        let fractionExamples = [
            "1¹²³⁄₁₀₀₀": "1 123/1000",
            "¹²³⁄₁₀₀₀": "123/1000",
            "¹²³⁄₋₁₀₀₀": "123/-1000",
        ]
        for (unicode, ascii) in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: unicode, as: .Shilling), ascii)
        }
    }

    func testParseVulgarFraction() {
        let fractionExamples = [
            1.5: "1½",
            1000.6: "1000⅗",
            5.125: "5 ⅛", // Test that we accept otherwise valid fractions with extra space
        ]
        for (double, fraction) in FractionFormatter.vulgarFractions {
            XCTAssertEqual(fractionFormatter.parseVulgarFraction(fraction), double)
        }
        for (double, fraction) in fractionExamples {
            XCTAssertEqual(fractionFormatter.parseVulgarFraction(fraction), double)
        }
    }

    func testVulgarFractions() {
        for (decimal, fraction) in FractionFormatter.vulgarFractions {
            XCTAssertEqual(fractionFormatter.string(from: NSNumber(value: decimal)), fraction)
            XCTAssertEqual(fractionFormatter.string(from: String(decimal)), fraction)
            XCTAssertEqual(fractionFormatter.double(from: fraction), decimal)
        }
    }

    func testCustomUnicodeFractions() {
        let fractionExamples = [
            0.123 : "¹²³⁄₁₀₀₀",
            0.999 : "⁹⁹⁹⁄₁₀₀₀",
            3.14  : "3¹⁰⁹³⁷⁵⁰⁰⁰⁰⁰⁰⁰⁰⁰¹⁄₇₈₁₂₅₀₀₀₀₀₀₀₀₀₀₀",
        ]
        for (decimal, fraction) in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: NSNumber(value: decimal)), fraction)
            XCTAssertEqual(fractionFormatter.string(from: String(decimal)), fraction)
            XCTAssertEqual(fractionFormatter.double(from: fraction), decimal)
        }
    }
    
    func testComplexVulgarFractions() {
        let fractionExamples = [
            1.5 : "1½",
            2.875 : "2⅞",
            2  : "2",
            3.1428571428571428: "3⅐"
        ]
        for (decimal, fraction) in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: NSNumber(value: decimal)), fraction)
            XCTAssertEqual(fractionFormatter.string(from: String(decimal)), fraction)
            XCTAssertEqual(fractionFormatter.double(from: fraction), decimal)
        }
    }
    
    func testExpectedNils() {
        let fractionExamples = [
            "a",
            "11.5 inches",
            "1 1/2 10",
            "1½ inches",
        ]
        for fraction in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: fraction), nil)
        }
    }
    
    static var allTests = [
        ("testScripted", testScripted),
        ("testRemoveFormatting", testRemoveFormatting),
        ("testStringShilling", testStringShilling),
        ("testParseVulgarFraction", testParseVulgarFraction),
        ("testVulgarFractions", testVulgarFractions),
        ("testCustomUnicodeFractions", testCustomUnicodeFractions),
        ("testComplexVulgarFractions", testComplexVulgarFractions),
        ("testExpectedNils", testExpectedNils),
    ]
}
