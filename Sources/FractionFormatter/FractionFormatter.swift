//
//  FractionFormatter.swift
//
//  Copyright © David W. Keith <git@dwk.io> All rights reserved.
//

import Foundation
#if canImport(CoreText)
import CoreText
#endif

/**
 # FractionFormatter
 A subclass of Apple's [`NumberFormatter`](https://developer.apple.com/documentation/foundation/numberformatter) that outputs pretty-printed fractions rather than decimals.

 ## Overview
 Instances of `FractionFormatter` format the textual representation of `NSNumber` objects and convert textual representations of numeric values into `NSNumber` objects.
 Like `NumberFormatter`, instances are not thread-safe and should be confined to a single thread/queue.
 */
public class FractionFormatter: NumberFormatter, @unchecked Sendable {

    // MARK: - Configuration

    /// Strategy used to reduce fractional values.
    public enum ReductionPolicy: Equatable {
        /// Preserve all observed decimal digits (legacy behavior).
        case exactFromDecimalDigits

        /// Approximate to the nearest rational with a bounded denominator.
        case maxDenominator(Int)
    }

    /// Controls formatting of negative values.
    public enum NegativeFormatStyle: Equatable {
        /// Output like `-1½`.
        case prefixedSign

        /// Output like `(1½)`.
        case parenthesized
    }

    /// Controls how Unicode fractions are constructed when no single vulgar glyph exists.
    public enum UnicodeFormattingStyle: Equatable {
        /// Prefer vulgar fraction glyphs when available, otherwise superscript/subscript with fraction slash.
        case superscriptSubscript

        /// Render numerator and denominator as regular digits separated by a fraction slash.
        case inline
    }

    /// Controls how case-fraction typography is requested for attributed output.
    public enum CaseFractionStyle: Equatable {
        /// Uses diagonal fractions (OpenType `frac`).
        case diagonal

        /// Uses vertical/stacked fractions when supported by the active font.
        case vertical
    }

    /// Default Unicode vulgar fractions map.
    public static let defaultVulgarFractions: [Double: String] = [
        0.1: "⅒",
        0.111111111111111111111: "⅑",
        0.166666666666666666666: "⅙",
        0.125: "⅛",
        0.1428571428571428: "⅐",
        0.2: "⅕",
        0.25: "¼",
        0.333333333333333333333: "⅓",
        0.375: "⅜",
        0.4: "⅖",
        0.5: "½",
        0.6: "⅗",
        0.625: "⅝",
        0.666666666666666666666: "⅔",
        0.75: "¾",
        0.8: "⅘",
        0.833333333333333333333: "⅚",
        0.875: "⅞"
    ]

    /// Backwards-compatible static map.
    public static let vulgarFractions = defaultVulgarFractions

    /// Characters used to build formatted fractions.
    public static let unicodeSuperscript = [
        "-": "⁻",
        "0": "⁰",
        "1": "¹",
        "2": "²",
        "3": "³",
        "4": "⁴",
        "5": "⁵",
        "6": "⁶",
        "7": "⁷",
        "8": "⁸",
        "9": "⁹",
    ]

    public static let unicodeSubscript = [
        "-": "₋",
        "0": "₀",
        "1": "₁",
        "2": "₂",
        "3": "₃",
        "4": "₄",
        "5": "₅",
        "6": "₆",
        "7": "₇",
        "8": "₈",
        "9": "₉",
    ]

    /**
        A fraction can be output using either `.unicode` or `.builtUp` formatting.
     */
    public enum FractionType {
        /// Preferred lower-camel alias for ``FractionType/Unicode``.
        public static var unicode: FractionType { .Unicode }

        /// Preferred lower-camel alias for ``FractionType/BuiltUp``.
        public static var builtUp: FractionType { .BuiltUp }

        /// Preferred lower-camel alias for ``FractionType/CaseFraction``.
        public static var caseFraction: FractionType { .CaseFraction }

        case Unicode
        case BuiltUp
        case CaseFraction
    }

    /// Locale used for parsing plain decimal input. Defaults to formatter locale.
    public var parsingLocale: Locale?

    /// Whether localized decimal/grouping separators are accepted while parsing.
    public var allowsLocaleAwareParsing = true

    /// Per-instance vulgar fraction glyph map (extensibility).
    public var vulgarFractionGlyphs: [Double: String]

    /// Preferred reduction policy when formatting `NSNumber` values.
    public var reductionPolicy: ReductionPolicy = .exactFromDecimalDigits

    /// Style used for negative values.
    public var negativeFormatStyle: NegativeFormatStyle = .prefixedSign

    /// Sign used when `negativeFormatStyle == .prefixedSign`.
    public var negativeSignSymbol: String = "-"

    /// Unicode fallback style when a vulgar glyph is unavailable.
    public var unicodeFormattingStyle: UnicodeFormattingStyle = .superscriptSubscript

    /// Separator between whole and fraction for built-up output.
    public var builtUpWholeFractionSeparator: String = " "

    /// Separator between numerator and denominator for built-up output.
    public var builtUpDivisionSeparator: String = "/"

    /// Separator between whole and fraction for case-fraction source text.
    public var caseFractionWholeFractionSeparator: String = " "

    /// Separator between numerator and denominator for case-fraction source text.
    public var caseFractionDivisionSeparator: String = "/"

    /// Separator between whole and fraction for Unicode output.
    public var unicodeWholeFractionSeparator: String = ""

    /// Separator between numerator and denominator for Unicode output.
    public var unicodeDivisionSeparator: String = "⁄"

    /// Input separators accepted for numerator/denominator parsing.
    public var acceptedInputDivisionSeparators: Set<Character> = ["/", "⁄"]

    /// Typography style requested by attributed case-fraction rendering.
    public var caseFractionStyle: CaseFractionStyle = .diagonal

    private static let defaultSlash: Character = "/"
    private static let defaultFractionSlash: Character = "⁄"

    /// Creates a formatter with default configuration and default vulgar glyph mappings.
    public override init() {
        self.vulgarFractionGlyphs = FractionFormatter.defaultVulgarFractions
        super.init()
    }

    /// Creates a formatter from an archive/coder with default vulgar glyph mappings.
    required public init?(coder: NSCoder) {
        self.vulgarFractionGlyphs = FractionFormatter.defaultVulgarFractions
        super.init(coder: coder)
    }

    // MARK: - Character Sets

    var formattedFractionCharacterSet: CharacterSet {
        var characterSet = CharacterSet(charactersIn: Array(FractionFormatter.unicodeSuperscript.values).joined())
        characterSet.insert(charactersIn: Array(FractionFormatter.unicodeSubscript.values).joined())
        characterSet.insert(charactersIn: String(FractionFormatter.defaultFractionSlash))
        return characterSet
    }

    var fractionCharacterSet: CharacterSet {
        var characterSet = CharacterSet(charactersIn: Array(vulgarFractionGlyphs.values).joined())
        characterSet.insert(" ")
        characterSet.insert(charactersIn: String(FractionFormatter.defaultSlash))
        characterSet.insert(charactersIn: String(FractionFormatter.defaultFractionSlash))
        characterSet.formUnion(formattedFractionCharacterSet)
        characterSet.formUnion(CharacterSet.decimalDigits)
        return characterSet
    }

    // MARK: - Internal Helpers

    /// Computes the greatest common divisor for two positive floating-point values.
    internal func greatestCommonDenominator(x: Double, y: Double) -> Double {
        if y < 0.0000001 {
            return x
        }
        return greatestCommonDenominator(x: y, y: x.truncatingRemainder(dividingBy: y))
    }

    /// Converts an integer into a mapped script form using the supplied character table.
    internal func scripted(_ num: Int, scriptChars: [String: String]) -> String? {
        var ret = ""
        for digit in String(num) {
            ret += scriptChars[String(digit)] ?? "_"
        }
        return ret.contains("_") ? nil : ret
    }

    /// Converts an integer to its Unicode superscript representation.
    private func superscript(_ num: Int) -> String? {
        scripted(num, scriptChars: FractionFormatter.unicodeSuperscript)
    }

    /// Converts an integer to its Unicode subscript representation.
    private func subscripted(_ num: Int) -> String? {
        scripted(num, scriptChars: FractionFormatter.unicodeSubscript)
    }

    /// Backwards-compatible misspelling kept for source compatibility.
    @available(*, deprecated, renamed: "superscript")
    private func superscrpt(_ num: Int) -> String? {
        superscript(num)
    }

    /// Backwards-compatible misspelling kept for source compatibility.
    @available(*, deprecated, renamed: "subscripted")
    private func subscrpt(_ num: Int) -> String? {
        subscripted(num)
    }

    /// Converts a superscript/subscript digit character back to its plain digit.
    internal func removeFormatting(_ scriptedNum: Character) -> Character? {
        for (digit, sup) in FractionFormatter.unicodeSuperscript where sup == String(scriptedNum) {
            return digit.first
        }
        for (digit, sub) in FractionFormatter.unicodeSubscript where sub == String(scriptedNum) {
            return digit.first
        }
        return nil
    }

    /// Returns the locale used for parsing, falling back to formatter locale and then current locale.
    private func activeLocale() -> Locale {
        parsingLocale ?? locale ?? Locale.current
    }

    /// Normalizes locale-specific decimal/group separators into a parseable canonical number string.
    private func normalizeNumberString(_ input: String) -> String {
        var normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard allowsLocaleAwareParsing else {
            return normalized
        }

        let locale = activeLocale()
        let decimalSeparator = locale.decimalSeparator ?? "."
        let groupingSeparator = locale.groupingSeparator ?? ","

        normalized = normalized.replacingOccurrences(of: groupingSeparator, with: "")
        normalized = normalized.replacingOccurrences(of: "\u{00A0}", with: "")
        if decimalSeparator != "." {
            normalized = normalized.replacingOccurrences(of: decimalSeparator, with: ".")
        }
        return normalized
    }

    /**
        Parse a numeric string strictly, rejecting partial parses like `"1/" -> 1`.
     */
    private func strictNumber(from input: String) -> Double? {
        let normalized = normalizeNumberString(input)
        guard !normalized.isEmpty else {
            return nil
        }
        let pattern = #"^[+-]?((\d+(\.\d+)?)|(\.\d+))$"#
        guard normalized.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        return Double(normalized)
    }

    /// Finds a configured vulgar fraction glyph for a decimal value with tolerance for floating-point precision.
    private func vulgarGlyph(for value: Double) -> String? {
        for (decimal, glyph) in vulgarFractionGlyphs {
            if abs(decimal - value) < 0.000000000001 {
                return glyph
            }
        }
        return nil
    }

    /// Reduces a proper fraction according to the configured reduction policy.
    private func reducedFraction(for fraction: Double) -> (numerator: Int, denominator: Int)? {
        guard fraction >= 0 && fraction < 1 else {
            return nil
        }

        switch reductionPolicy {
        case .exactFromDecimalDigits:
            let asString = String(fraction)
            guard let decimalDigits = asString.split(separator: ".").last?.count else {
                return nil
            }
            if decimalDigits == 0 {
                return (0, 1)
            }
            let denominator = pow(10.0, Double(decimalDigits))
            let numerator = fraction * denominator
            let divisor = greatestCommonDenominator(x: numerator, y: denominator)
            return (Int(floor(numerator / divisor)), Int(floor(denominator / divisor)))

        case .maxDenominator(let maxDenominator):
            guard maxDenominator > 0 else {
                return nil
            }
            var bestNumerator = 0
            var bestDenominator = 1
            var bestError = Double.greatestFiniteMagnitude
            for denominator in 1...maxDenominator {
                let numerator = Int((fraction * Double(denominator)).rounded())
                let estimate = Double(numerator) / Double(denominator)
                let error = abs(estimate - fraction)
                if error < bestError {
                    bestError = error
                    bestNumerator = numerator
                    bestDenominator = denominator
                }
            }
            let divisor = Int(greatestCommonDenominator(x: Double(bestNumerator), y: Double(bestDenominator)))
            return (bestNumerator / max(1, divisor), bestDenominator / max(1, divisor))
        }
    }

    /// Rewrites accepted division separators into the canonical slash used by parsing internals.
    private func normalizeInputDivisionSeparators(_ input: String) -> String {
        var normalized = input
        for separator in acceptedInputDivisionSeparators where separator != FractionFormatter.defaultSlash {
            normalized = normalized.replacingOccurrences(of: String(separator), with: String(FractionFormatter.defaultSlash))
        }
        return normalized
    }

    /// Formats a mixed fraction in built-up form (for example `1 1/2`).
    private func formatBuiltUp(whole: Int, numerator: Int, denominator: Int) -> String {
        var components: [String] = []
        if whole > 0 {
            components.append(String(whole))
        }
        if numerator > 0 {
            components.append("\(numerator)\(builtUpDivisionSeparator)\(denominator)")
        }
        if components.isEmpty {
            return "0"
        }
        return components.joined(separator: builtUpWholeFractionSeparator)
    }

    /// Formats a mixed fraction as slash text intended for case-fraction typography.
    private func formatCaseFraction(whole: Int, numerator: Int, denominator: Int) -> String {
        var components: [String] = []
        if whole > 0 {
            components.append(String(whole))
        }
        if numerator > 0 {
            components.append("\(numerator)\(caseFractionDivisionSeparator)\(denominator)")
        }
        if components.isEmpty {
            return "0"
        }
        return components.joined(separator: caseFractionWholeFractionSeparator)
    }

    /// Formats a mixed fraction in Unicode form using vulgar glyphs or configured fallback rendering.
    private func formatUnicode(whole: Int, reducedFractionValue: Double, numerator: Int, denominator: Int) -> String? {
        var ret = whole > 0 ? String(whole) : ""
        if numerator > 0 {
            if let glyph = vulgarGlyph(for: reducedFractionValue) {
                if whole > 0 && !unicodeWholeFractionSeparator.isEmpty {
                    ret += unicodeWholeFractionSeparator
                }
                ret += glyph
            } else {
                if whole > 0 && !unicodeWholeFractionSeparator.isEmpty {
                    ret += unicodeWholeFractionSeparator
                }
                switch unicodeFormattingStyle {
                case .superscriptSubscript:
                    guard let sup = superscript(numerator), let sub = subscripted(denominator) else {
                        return nil
                    }
                    ret += [sup, unicodeDivisionSeparator, sub].joined()
                case .inline:
                    ret += "\(numerator)\(unicodeDivisionSeparator)\(denominator)"
                }
            }
        }
        return ret.isEmpty ? "0" : ret
    }

    /// Applies the configured negative-number display style to an already formatted absolute value.
    private func applyNegativeStyle(_ formattedAbsolute: String, isNegative: Bool) -> String {
        guard isNegative else {
            return formattedAbsolute
        }
        switch negativeFormatStyle {
        case .prefixedSign:
            return "\(negativeSignSymbol)\(formattedAbsolute)"
        case .parenthesized:
            return "(\(formattedAbsolute))"
        }
    }

    /// Splits mixed-number input into whitespace-separated components.
    private func splitMixedParts(_ input: String) -> [String] {
        input
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    // MARK: - Parsing

    /**
     Converts a `.unicode` fraction into an integer and a `.builtUp` fraction.

     e.g. `"1¹²³⁄₁₀₀₀"` becomes `( "1", "123/1000" )`
     */
    internal func getPartsFromUnicodeFraction(_ str: String) -> (String, String?) {
        var integer = ""
        var fraction = ""
        for char in str {
            if CharacterSet.decimalDigits.contains(Unicode.Scalar(String(char)) ?? "_") {
                integer += String(char)
            } else if acceptedInputDivisionSeparators.contains(char) {
                fraction += String(FractionFormatter.defaultSlash)
            } else {
                fraction += String(removeFormatting(char) ?? "_")
            }
        }
        return (integer, fraction.contains("_") ? nil : fraction)
    }

    /**
        Attempt to parse a vulgar fraction string, otherwise return `nil`.
     */
    internal func parseVulgarFraction(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        for (decimal, fraction) in vulgarFractionGlyphs {
            if trimmed == fraction {
                return decimal
            }
            if trimmed == "-\(fraction)" {
                return -decimal
            }
            if trimmed.contains(fraction) {
                let remainder = trimmed
                    .replacingOccurrences(of: fraction, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if remainder == "-" {
                    return -decimal
                }
                if let integerValue = strictNumber(from: remainder) {
                    if integerValue < 0 || remainder.hasPrefix("-") {
                        return integerValue - decimal
                    }
                    return integerValue + decimal
                }
                return nil
            }
        }
        return nil
    }

    /**
        Normalize a `String` as a `.builtUp` fraction.

        e.g. `"1¹²³⁄₁₀₀₀"` becomes `"1 123/1000"`
     */
    private func builtUp(from string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let decimal = strictNumber(from: trimmed) {
            return self.string(from: NSNumber(value: decimal), as: .builtUp)
        }

        if let decimal = parseVulgarFraction(trimmed) {
            return self.string(from: NSNumber(value: decimal), as: .builtUp)
        }

        let hasFormattedUnicodeFractions = trimmed.unicodeScalars.contains(where: { formattedFractionCharacterSet.contains($0) }) ||
            trimmed.contains(String(FractionFormatter.defaultFractionSlash))
        if hasFormattedUnicodeFractions {
            var integer = ""
            var fraction = ""

            for char in trimmed {
                if CharacterSet.decimalDigits.contains(Unicode.Scalar(String(char)) ?? "_") {
                    if fraction.isEmpty {
                        integer += String(char)
                    } else {
                        fraction += String(char)
                    }
                } else if char == "-" {
                    if integer.isEmpty && fraction.isEmpty {
                        integer += String(char)
                    } else if !fraction.isEmpty {
                        fraction += String(char)
                    } else {
                        return nil
                    }
                } else if acceptedInputDivisionSeparators.contains(char) {
                    fraction += String(FractionFormatter.defaultSlash)
                } else if let unformatted = removeFormatting(char) {
                    fraction += String(unformatted)
                } else if char.isWhitespace {
                    continue
                } else {
                    return nil
                }
            }

            guard !fraction.isEmpty else {
                return nil
            }
            let wholePart = integer.trimmingCharacters(in: .whitespacesAndNewlines)
            return wholePart.isEmpty ? fraction : "\(wholePart)\(builtUpWholeFractionSeparator)\(fraction)"
        }

        let normalizedInput = normalizeInputDivisionSeparators(trimmed)
        let parts = splitMixedParts(normalizedInput)
        if parts.count == 2 && parts[1].contains(String(FractionFormatter.defaultSlash)) {
            return "\(parts[0])\(builtUpWholeFractionSeparator)\(parts[1])"
        }
        if parts.count == 1 && parts[0].contains(String(FractionFormatter.defaultSlash)) {
            return parts[0]
        }
        return nil
    }

    /**
     Creates a `Double` from a fraction-like `String`.

     ```swift
     fractionFormatter.double(from: "1 1/2") // 1.5
     ```
     */
    public func double(from input: String) -> Double? {
        var string = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.isEmpty {
            return nil
        }

        // Check if strict decimal
        if let strict = strictNumber(from: string) {
            return strict
        }

        // Check if vulgar fraction
        if let parsed = parseVulgarFraction(string) {
            return parsed
        }

        // Normalize mixed unicode/built-up separators
        string = normalizeInputDivisionSeparators(string)

        // Convert superscript/subscript format to built-up when needed
        if string.contains(String(FractionFormatter.defaultFractionSlash)) || string.unicodeScalars.contains(where: { formattedFractionCharacterSet.contains($0) }) {
            guard let ascii = builtUp(from: string) else {
                return nil
            }
            string = ascii
        }

        let parts = splitMixedParts(string)
        if parts.count > 2 {
            return nil
        }

        var quantity: Double = 0.0
        for part in parts {
            if part.contains(String(FractionFormatter.defaultSlash)) {
                let subParts = part.split(separator: FractionFormatter.defaultSlash, omittingEmptySubsequences: false)
                if subParts.count != 2 {
                    return nil
                }
                guard let numerator = strictNumber(from: String(subParts[0])),
                      let denominator = strictNumber(from: String(subParts[1])),
                      denominator != 0 else {
                    return nil
                }
                let fraction = numerator / denominator
                if !fraction.isFinite {
                    return nil
                }
                if parts.count == 2 && parts[0].hasPrefix("-") && !part.hasPrefix("-") {
                    quantity -= fraction
                } else {
                    quantity += fraction
                }
            } else {
                guard let integerPart = strictNumber(from: part) else {
                    return nil
                }
                quantity += integerPart
            }
        }
        return quantity
    }

    // MARK: - Formatting

    /// Parses a fraction-like string and re-formats it in Unicode style.
    public func string(from string: String) -> String? {
        guard let decimal = double(from: string) else {
            return nil
        }
        return self.string(from: NSNumber(value: decimal))
    }

    /// Parses a fraction-like string and formats it as either Unicode or built-up output.
    public func string(from str: String, as fractionType: FractionType) -> String? {
        switch fractionType {
        case .Unicode:
            return string(from: str)
        case .BuiltUp:
            return builtUp(from: str)
        case .CaseFraction:
            guard let decimal = double(from: str) else {
                return nil
            }
            return self.string(from: NSNumber(value: decimal), as: .CaseFraction)
        }
    }

    /// Formats an `NSNumber` as either Unicode or built-up fraction output.
    public func string(from number: NSNumber, as fractionType: FractionType) -> String? {
        let value = Double(truncating: number)
        guard value.isFinite else {
            return nil
        }

        let isNegative = value < 0
        let absoluteValue = abs(value)
        let wholeUnits = Int(floor(absoluteValue))
        let fractionalPart = absoluteValue - Double(wholeUnits)

        guard let reduced = reducedFraction(for: fractionalPart) else {
            return nil
        }

        var formattedAbsolute: String?
        switch fractionType {
        case .Unicode:
            formattedAbsolute = formatUnicode(
                whole: wholeUnits,
                reducedFractionValue: Double(reduced.numerator) / Double(reduced.denominator),
                numerator: reduced.numerator,
                denominator: reduced.denominator
            )
        case .BuiltUp:
            formattedAbsolute = formatBuiltUp(
                whole: wholeUnits,
                numerator: reduced.numerator,
                denominator: reduced.denominator
            )
        case .CaseFraction:
            formattedAbsolute = formatCaseFraction(
                whole: wholeUnits,
                numerator: reduced.numerator,
                denominator: reduced.denominator
            )
        }

        guard let formattedAbsolute else {
            return nil
        }
        return applyNegativeStyle(formattedAbsolute, isNegative: isNegative)
    }

    /// Formats an `NSNumber` using Unicode fraction output.
    public override func string(from number: NSNumber) -> String? {
        string(from: number, as: .Unicode)
    }

    /// Returns an attributed fraction string and applies case-fraction OpenType features when requested.
#if canImport(CoreText) && canImport(ObjectiveC)
    @available(iOS 10.0, tvOS 10.0, watchOS 3.0, macOS 10.12, *)
    public func attributedString(
        from number: NSNumber,
        as fractionType: FractionType = .CaseFraction,
        attributes: [NSAttributedString.Key: Any] = [:]
    ) -> NSAttributedString? {
        guard let rendered = string(from: number, as: fractionType) else {
            return nil
        }

        var attrs = attributes
        if fractionType == .CaseFraction {
            let selector: Int = (caseFractionStyle == .vertical) ? kVerticalFractionsSelector : kDiagonalFractionsSelector
            let featureSettings: [[CFString: Any]] = [[
                kCTFontFeatureTypeIdentifierKey: kFractionsType,
                kCTFontFeatureSelectorIdentifierKey: selector
            ]]
            attrs[NSAttributedString.Key(rawValue: kCTFontFeatureSettingsAttribute as String)] = featureSettings
        }
        return NSAttributedString(string: rendered, attributes: attrs)
    }
#endif

    // MARK: - Measurement helper

#if canImport(ObjectiveC)
    /**
     Formats a measurement using this formatter for the numeric portion.

     Set `preferSingularUnitForProperFractions` to `true` to apply a lightweight FB7644708 workaround.
     */
    @available(iOS 10.0, tvOS 10.0, watchOS 3.0, macOS 10.12, *)
    public func string<UnitType: Dimension>(
        from measurement: Measurement<UnitType>,
        with measurementFormatter: MeasurementFormatter,
        preferSingularUnitForProperFractions: Bool = false
    ) -> String {
        let previousFormatter = measurementFormatter.numberFormatter
        measurementFormatter.numberFormatter = self
        defer { measurementFormatter.numberFormatter = previousFormatter }

        let rendered = measurementFormatter.string(from: measurement)
        guard preferSingularUnitForProperFractions,
              abs(measurement.value) < 1 else {
            return rendered
        }

        let singularRendered = measurementFormatter.string(from: Measurement(value: 1, unit: measurement.unit))
        let pluralRendered = measurementFormatter.string(from: Measurement(value: 2, unit: measurement.unit))
        let valueRendered = self.string(from: NSNumber(value: measurement.value)) ?? String(measurement.value)

        guard let singularUnit = trailingUnit(in: singularRendered, numberString: "1"),
              let pluralUnit = trailingUnit(in: pluralRendered, numberString: "2"),
              let currentUnit = trailingUnit(in: rendered, numberString: valueRendered),
              currentUnit == pluralUnit else {
            return rendered
        }

        return rendered.replacingOccurrences(of: pluralUnit, with: singularUnit, options: .backwards)
    }
#endif

    /// Extracts the unit suffix from a rendered measurement string by removing the numeric prefix.
#if canImport(ObjectiveC)
    private func trailingUnit(in rendered: String, numberString: String) -> String? {
        guard let range = rendered.range(of: numberString) else {
            return nil
        }
        let suffix = rendered[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return suffix.isEmpty ? nil : suffix
    }
#endif
}
