//
//  FractionFormatter.swift
//
//  Created by David W. Keith on 14/Sept/20.
//  Copyright © 2020 dwk. All rights reserved.
//

import Foundation

public class FractionFormatter: NumberFormatter {
    
    /**
     Allows us to use vulgar Unicode fractions glyphs when availible
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
     A union of our superscript, subscript, and the fraction slash characters
     */
    var formattedFractionCharacterSet: CharacterSet {
        var characterSet = CharacterSet.init(charactersIn:Array(FractionFormatter.unicodeSuperscript.values).joined())
        characterSet.insert(charactersIn: Array(FractionFormatter.unicodeSuperscript.values).joined())
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
    Convert from super/subscript representation to normal ASCII for the digit
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
     Normalize string as an ASCII fraction
     eg "1¹²³⁄₁₀₀₀" becomes "1 123/1000"
     */
    internal func convertToASCII(_ string: String) -> String? {
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
     Converts the unicode fraction into an integer and a slash seperated fraction
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
        for (decimal, fraction) in FractionFormatter.vulgarFractions {
            if string == fraction {
                return decimal
            }
            if string.contains(fraction) {
                if let integerPart = number(from: string
                                                .replacingOccurrences(of: fraction, with: "")
                                                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
                    return Double(truncating: integerPart) + decimal
                }
                return nil
            }
        }
        return nil
    }

    /**
     Return a double from a string with valid fractions
     Assumes the string is number-like. e.g. "1 1/2" would return 1.5
     */
    public func double(from input: String) -> Double? {
        var string = input
        
        // Check if decimal
        let nsNumber = number(from: string)
        if nsNumber != nil {
            return Double(truncating: nsNumber!)
        }
        
        // Check if vulgar fraction
        let parsed = parseVulgarFraction(string)
        if parsed != nil {
            return parsed
        }

        // standardize as ASCII fraction
        if string.contains(fractionSlash) {
            let ascii = convertToASCII(string)
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
                let subParts = part.split(separator: "/")
                let numerator = Double(subParts[0])
                let denominator = Double(subParts[1])
                if (numerator == nil || denominator == nil) {
                    return nil
                }
                quantity += numerator!/denominator!
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
     Return a unicode string from a string with valid fractions
     Assumes the string is number-like. e.g. "1 1/2" would return "1½"
     */
    public func string(from string: String) -> String? {
        let decimal = self.double(from: string)
        return (decimal == nil) ? nil : self.string(from: NSNumber(value: decimal!))
    }
    
    /**
     Return a unicode string from a NSNumber
     e.g. 1.5 would return "1½"
     */
    public override func string(from number: NSNumber) -> String? {
        let wholeUnits = Int(floor(Double(truncating: number)))
        let fractionalPart = Double(truncating: number) - Double(wholeUnits)
        let denominator = Double(truncating:pow(10.0, String(fractionalPart).count) as NSNumber)
        let numerator = fractionalPart * denominator
        let divisor = greatestCommonDenominator(x: numerator, y: denominator)
        let numeratorInt = Int(floor(numerator/divisor))
        let denominatorInt = Int(floor(denominator/divisor))
        var ret = ""
        if wholeUnits > 0 {
            ret += NumberFormatter().string(from: NSNumber(value: wholeUnits))!
        }
        if numeratorInt > 0 {
            let sup = superscrpt(numeratorInt)
            let sub = subscrpt(denominatorInt)
            if sub == nil || sup == nil {
                return nil
            }
            ret += FractionFormatter.vulgarFractions[fractionalPart] ?? [sup!, String(fractionSlash), sub!].joined()
        }
        return ret
    }
}
