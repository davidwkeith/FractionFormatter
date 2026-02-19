//
//  FractionFormatter.swift
//
//  Copyright © David W. Keith <git@dwk.io> All rights reserved.
//

import Foundation
/**
 # FractionFormatter
 A subclass of Apple's [`NumberFormatter`](https://developer.apple.com/documentation/foundation/numberformatter) that outputs pretty-printed Unicode fractions rather than decimals.

 ## Overview
 Instances of `FractionFormatter` format the textual representation of cells that contain `NSNumber` objects and convert textual representations of numeric values into `NSNumber` objects. The representation encompasses integers, floats, and doubles; floats and doubles can be formatted to a specified fractional type. Fractions are always output in their reduced form.
 Like `NumberFormatter`, instances are not thread-safe and should be confined to a single thread/queue.

 */
public class FractionFormatter: NumberFormatter, @unchecked Sendable {
    /**
        Parse a numeric string strictly, rejecting partial parses like "1/" -> 1.
     */
    private func strictNumber(from input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let pattern = #"^[+-]?((\d+(\.\d+)?)|(\.\d+))$"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }

        return Double(trimmed)
    }

    /**
     Allows us to use vulgar Unicode fractions glyphs when availible in Unicode.
     */
    static let vulgarFractions = [
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

    /**
     0-9 as super- and sub-scripts, when a Unicode fraction is not already a glyph, we will construct one
     using these dictionaries.
     */
    static let unicodeSuperscript = [
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
    static let unicodeSubscript = [
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
        A fraction can be output using either `.Unicode` or `.BuiltUp` formatting.
     
        Unicode fractions use Unicode [Number Forms](https://en.wikipedia.org/wiki/Number_Forms) to format the
        fractional parts with a fraction slash `⁄` for seperation.

        Built up fractions use ASCII numbers to format the fractional parts with a solidus character `/` for seperation.
     */
    public enum FractionType {

        /// Use Unicode number parts to output case fractions like "½"
        case Unicode

        /// Use slash and numbers to output built up fractions like "1/2"
        case BuiltUp

        // A fraction where the numerator and denominator are seperated by a fraction bar, with one on top of the other.
        // case Stack
    }

    /**
        A union of our superscript, subscript, and the fraction slash characters
     */
    var formattedFractionCharacterSet: CharacterSet {
        var characterSet = CharacterSet.init(charactersIn:Array(FractionFormatter.unicodeSuperscript.values).joined())
        characterSet.insert(charactersIn: Array(FractionFormatter.unicodeSubscript.values).joined())
        characterSet.insert(charactersIn: String(fractionSlash))
        return characterSet
    }

    /**
        The set of all characters that we can parse, if a string contains characters not in this set, we can't parse it for sure.
     */
    var fractionCharacterSet: CharacterSet {
        var characterSet = CharacterSet.init(charactersIn: Array(FractionFormatter.vulgarFractions.values).joined())
        characterSet.insert(" ")
        characterSet.insert(charactersIn: String(slash))
        characterSet.formUnion(formattedFractionCharacterSet)
        characterSet.formUnion(CharacterSet.decimalDigits)
        return characterSet
    }

    /**
        Convience, these can be hard to tell apart in complex strings
     */
    private let slash: Character = "/"
    private let fractionSlash: Character = "⁄"

    /**
        Given a pair of Doubles, return the greatest common denominator between them.
     */
    internal func greatestCommonDenominator(x: Double, y: Double) -> Double {
        if y < 0.0000001 {
            return x;
        }
        return greatestCommonDenominator(
            x: y,
            y: x.truncatingRemainder(dividingBy: y)
        )
    }

    /**
        Generic conversion of normal number strings to super- or sub-scripted unicode strings
     */
    internal func scripted(_ num: Int, scriptChars: [String: String]) -> String? {
        var ret: String = ""
        for digit in String(num) {
            ret += scriptChars[String(digit)] ?? "_"
        }
        return ret.contains("_") ? nil : ret
    }

    /**
        Return the specified Int as a superscripted String
     */
    private func superscrpt(_ num: Int) -> String? {
        return scripted(num, scriptChars: FractionFormatter.unicodeSuperscript)
    }

    /**
        Return the specified Int as a subscripted String
     */
    private func subscrpt(_ num: Int) -> String? {
        return scripted(num, scriptChars: FractionFormatter.unicodeSubscript)
    }

    /**
        Convert from super/subscript representation to normal ASCII for the digits.
     */
    internal func removeFormatting(_ scriptedNum: Character) -> Character? {
        for (digit, sup) in FractionFormatter.unicodeSuperscript {
            if sup == String(scriptedNum) {
                return digit.first
            }
        }
        for (digit, sub) in FractionFormatter.unicodeSubscript {
            if sub == String(scriptedNum) {
                return digit.first
            }
        }
        return nil
    }

    /**
     Converts a `.Unicode` fraction into an integer and a `.BuiltUp` fraction.

     eg "1¹²³⁄₁₀₀₀" becomes ("1", "123/1000")
     */
    internal func getPartsFromUnicodeFraction(_ str: String) -> (String, String?) {
        var integer = ""
        var fraction = ""
        for char in str {
            if CharacterSet.decimalDigits.contains(Unicode.Scalar(String(char)) ?? "_") {
                integer += String(char)
            } else if char == fractionSlash {
                fraction += String(slash)
            } else {
                fraction += String(removeFormatting(char) ?? "_")
            }
        }
        return (integer, fraction.contains("_") ? nil: fraction)
    }

    /**
        Attempt to parse the string as a vulgar fraction, otherwise return nil
     */
    internal func parseVulgarFraction(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        for (decimal, fraction) in FractionFormatter.vulgarFractions {
            if trimmed == fraction {
                return decimal
            }
            if trimmed == "-\(fraction)" {
                return -decimal
            }
            if trimmed.contains(fraction) {
                let remainder = trimmed
                    .replacingOccurrences(of: fraction, with: "")
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
        Normalize a `String` as a `.BuiltUp` fraction.

        e.g. "1¹²³⁄₁₀₀₀" becomes "1 123/1000"
     */
    private func builtUp(from string: String) -> String? {
        var integer = ""
        var fraction = ""
        for char in string {
            if CharacterSet.decimalDigits.contains(Unicode.Scalar(String(char)) ?? "_") {
                integer += String(char)
            } else if char == fractionSlash {
                fraction += String(slash)
            } else {
                fraction += String(removeFormatting(char) ?? "_")
            }
        }
        return [integer, fraction].joined(separator: " ")
            .trimmingCharacters(in:CharacterSet.whitespacesAndNewlines)
    }

    /**
     Creates a `double` from a fraction-like `String`.

     ```swift
         fractionFormatter.double(from: "1 1/2") // 1.5
     ```
     */
    public func double(from input: String) -> Double? {
        var string = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.isEmpty {
            return nil
        }

        // Check if decimal
        if let strict = strictNumber(from: string) {
            return strict
        }

        // Check if vulgar fraction
        let parsed = parseVulgarFraction(string)
        if parsed != nil {
            return parsed
        }

        // standardize as Built Up fraction
        if string.contains(fractionSlash) {
            let ascii = builtUp(from: string)
            if ascii == nil {
                return nil
            }
            string = ascii!
        }

        // Parse string
        var quantity: Double = 0.0
        var parts: [String] = []
        let substringParts = string.split(separator: " ")
        if substringParts.count > 2 {
            return nil
        }
        for part in substringParts {
            parts.append(String(part))
        }
        for part in parts {
            if part.contains(slash) {
                let subParts = part.split(separator: "/", omittingEmptySubsequences: false)
                if subParts.count != 2 {
                    return nil
                }
                let numerator = Double(subParts[0])
                let denominator = Double(subParts[1])
                if (numerator == nil || denominator == nil || denominator == 0) {
                    return nil
                }
                let fraction = numerator!/denominator!
                if !fraction.isFinite {
                    return nil
                }
                if parts.count == 2 && parts.first?.hasPrefix("-") == true && !part.hasPrefix("-") {
                    quantity -= fraction
                } else {
                    quantity += fraction
                }
            } else {
                let integerPart = Double(part)
                if integerPart == nil {
                    return nil
                }
                quantity += integerPart!
            }
        }
        return quantity
    }

    /**
        Format a `String` using Unicode number parts from a fraction-like `String`.

        ```swift
        fractionFormatter.string(from: "1 1/2") // "1½"
        fractionFormatter.string(from: "1½") // "1½"
        ```
     */
    public func string(from string: String) -> String? {
        let decimal = self.double(from: string)
        return (decimal == nil) ? nil : self.string(from: NSNumber(value: decimal!))
    }

    /**
        Fomat a `String` from a fraction-like `String` with the specificed fraction format.

        ```swift
        fractionFormatter.string(from: "1.5", as: .Unicode) // "1½"
        fractionFormatter.string(from: "1 1/2", as: .Unicode) // "1½"
        fractionFormatter.string(from: "1½", as: .BuiltUp) // "1 1/2"
        ```
     */
    public func string(from str: String, as fractionType: FractionType) -> String? {
        switch fractionType {
            case .Unicode:
                return string(from: str)
            case .BuiltUp:
                return builtUp(from: str)
        }
    }

    /**
        Format a `String` with the specificed fraction format from a `NSNumber`.

        ```swift
        fractionFormatter.string(from: NSNumber(value: 1.5), as: .Unicode) // "1½"
        fractionFormatter.string(from: NSNumber(value: 1.5), as: .BuiltUp) // "1 1/2"
        ```
     */
    public func string(from number: NSNumber, as fractionType: FractionType) -> String? {
        switch fractionType {
            case .Unicode:
                return string(from: number)
            case .BuiltUp:
                return builtUp(from: string(from: number) ?? "")
        }
    }

    /**
        Format a `String` using Unicode number parts from a `NSNumber`.

        ```swift
        fractionFormatter.string(from: NSNumber(value: 1.5)) // "1½"
         ```
     */
    public override func string(from number: NSNumber) -> String? {
        let value = Double(truncating: number)
        if !value.isFinite {
            return nil
        }
        let isNegative = value < 0
        let absoluteValue = abs(value)
        let wholeUnits = Int(floor(absoluteValue))
        let fractionalPart = absoluteValue - Double(wholeUnits)
        let denominator = Double(truncating:pow(10.0, String(fractionalPart).count) as NSNumber)
        let numerator = fractionalPart * denominator
        let divisor = greatestCommonDenominator(x: numerator, y: denominator)
        let numeratorInt = Int(floor(numerator/divisor))
        let denominatorInt = Int(floor(denominator/divisor))
        let wholeString = NumberFormatter().string(from: NSNumber(value: wholeUnits)) ?? String(wholeUnits)
        var ret = wholeUnits > 0 ? wholeString : ""
        if numeratorInt > 0 {
            let sup = superscrpt(numeratorInt)
            let sub = subscrpt(denominatorInt)
            if sub == nil || sup == nil {
                return nil
            }
            ret += FractionFormatter.vulgarFractions[fractionalPart] ?? [sup!, String(fractionSlash), sub!].joined()
        }
        if ret.isEmpty {
            return NumberFormatter().string(from: 0) ?? "0"
        }
        return isNegative ? "-\(ret)" : ret
    }
}
