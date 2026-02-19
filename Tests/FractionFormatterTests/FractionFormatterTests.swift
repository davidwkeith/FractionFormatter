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

    func testStringBuiltUp() {
        let fractionExamples = [
            "1¹²³⁄₁₀₀₀": "1 123/1000",
            "¹²³⁄₁₀₀₀": "123/1000",
            "¹²³⁄₋₁₀₀₀": "123/-1000",
        ]
        for (unicode, ascii) in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: unicode, as: .builtUp), ascii)
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
        ]
        for (decimal, fraction) in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: NSNumber(value: decimal)), fraction)
            XCTAssertEqual(fractionFormatter.string(from: String(decimal)), fraction)
            XCTAssertEqual(fractionFormatter.double(from: fraction), decimal)
        }

        let custom = fractionFormatter.string(from: NSNumber(value: 3.14))
        XCTAssertNotNil(custom)
        XCTAssertTrue(custom?.contains("⁄") ?? false)
        XCTAssertEqual(fractionFormatter.double(from: custom ?? ""), 3.14)
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

    func testInvalidBuiltUpFractions() {
        let invalidFractions = [
            "1/",
            "/2",
            "/",
            "1//2",
            "1/0",
            "0/0",
        ]
        for fraction in invalidFractions {
            XCTAssertNil(fractionFormatter.double(from: fraction))
            XCTAssertNil(fractionFormatter.string(from: fraction))
        }
    }

    func testNegativeMixedFractionParsing() {
        let fractionExamples = [
            "-1 1/2": -1.5,
            "-1½": -1.5,
            "-½": -0.5,
        ]
        for (fraction, expectedDecimal) in fractionExamples {
            XCTAssertEqual(fractionFormatter.double(from: fraction), expectedDecimal)
        }
    }

    func testNegativeAndZeroFormatting() {
        let fractionExamples = [
            -2.875: "-2⅞",
            -1.5: "-1½",
            -0.5: "-½",
            0.0: "0",
        ]
        for (decimal, fraction) in fractionExamples {
            XCTAssertEqual(fractionFormatter.string(from: NSNumber(value: decimal)), fraction)
        }
    }

    func testLocaleAwareParsing() {
        let formatter = FractionFormatter()
        formatter.parsingLocale = Locale(identifier: "fr_FR")
        XCTAssertEqual(formatter.double(from: "1,5"), 1.5)
        XCTAssertEqual(formatter.double(from: "1 1/2"), 1.5)
    }

    func testReductionPolicyMaxDenominator() {
        let formatter = FractionFormatter()
        formatter.reductionPolicy = .maxDenominator(16)
        XCTAssertEqual(formatter.string(from: NSNumber(value: 0.3333)), "⅓")
        XCTAssertEqual(formatter.string(from: NSNumber(value: 2.2), as: .builtUp), "2 1/5")
    }

    func testNegativeFormattingOptions() {
        let formatter = FractionFormatter()
        formatter.negativeFormatStyle = .parenthesized
        XCTAssertEqual(formatter.string(from: NSNumber(value: -1.5)), "(1½)")
        XCTAssertEqual(formatter.string(from: NSNumber(value: -1.5), as: .builtUp), "(1 1/2)")
    }

    func testTypographyOptions() {
        let formatter = FractionFormatter()
        formatter.unicodeFormattingStyle = .inline
        formatter.unicodeWholeFractionSeparator = " "
        formatter.unicodeDivisionSeparator = "/"
        XCTAssertEqual(formatter.string(from: NSNumber(value: 1.123)), "1 123/1000")
    }

    func testCustomVulgarFractions() {
        let formatter = FractionFormatter()
        formatter.vulgarFractionGlyphs = [0.5: "⯪"]
        XCTAssertEqual(formatter.string(from: NSNumber(value: 0.5)), "⯪")
        XCTAssertEqual(formatter.double(from: "⯪"), 0.5)
    }

    func testMeasurementHelper() {
        let formatter = FractionFormatter()
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .long
        measurementFormatter.unitOptions = [.providedUnit]

        let normal = formatter.string(
            from: Measurement(value: 0.5, unit: UnitLength.feet),
            with: measurementFormatter,
            preferSingularUnitForProperFractions: false
        )

        let rendered = formatter.string(
            from: Measurement(value: 0.5, unit: UnitLength.feet),
            with: measurementFormatter,
            preferSingularUnitForProperFractions: true
        )

        XCTAssertFalse(rendered.isEmpty)
        if normal != rendered {
            XCTAssertTrue(rendered.contains("foot") || rendered.contains("ft") || rendered.contains("′"))
        }
    }

    func testRoundTripFuzz() {
        let formatter = FractionFormatter()
        let values: [Double] = stride(from: -5.0, through: 5.0, by: 0.125).map { $0 }
        for value in values {
            guard let rendered = formatter.string(from: NSNumber(value: value)),
                  let parsed = formatter.double(from: rendered) else {
                XCTFail("Failed round trip for \(value)")
                continue
            }
            XCTAssertEqual(parsed, value, accuracy: 0.000000001)
        }
    }

    func testPerformanceFormatting() {
        let formatter = FractionFormatter()
        measure {
            for i in 0...5000 {
                _ = formatter.string(from: NSNumber(value: Double(i) / 37.0))
            }
        }
    }
    
    static var allTests = [
        ("testScripted", testScripted),
        ("testRemoveFormatting", testRemoveFormatting),
        ("testStringBuiltUp", testStringBuiltUp),
        ("testParseVulgarFraction", testParseVulgarFraction),
        ("testVulgarFractions", testVulgarFractions),
        ("testCustomUnicodeFractions", testCustomUnicodeFractions),
        ("testComplexVulgarFractions", testComplexVulgarFractions),
        ("testExpectedNils", testExpectedNils),
        ("testInvalidBuiltUpFractions", testInvalidBuiltUpFractions),
        ("testNegativeMixedFractionParsing", testNegativeMixedFractionParsing),
        ("testNegativeAndZeroFormatting", testNegativeAndZeroFormatting),
        ("testLocaleAwareParsing", testLocaleAwareParsing),
        ("testReductionPolicyMaxDenominator", testReductionPolicyMaxDenominator),
        ("testNegativeFormattingOptions", testNegativeFormattingOptions),
        ("testTypographyOptions", testTypographyOptions),
        ("testCustomVulgarFractions", testCustomVulgarFractions),
        ("testMeasurementHelper", testMeasurementHelper),
        ("testRoundTripFuzz", testRoundTripFuzz),
        ("testPerformanceFormatting", testPerformanceFormatting),
    ]
}
