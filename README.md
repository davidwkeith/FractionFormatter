# FractionFormatter

[![Swift Version Compatibility Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavidwkeith%2FFractionFormatter%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/davidwkeith/FractionFormatter)
[![Platform Compatibility Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavidwkeith%2FFractionFormatter%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/davidwkeith/FractionFormatter)

A subclass of Apple's [`NumberFormatter`](https://developer.apple.com/documentation/foundation/numberformatter) that outputs pretty-printed Unicode fractions rather than decimals.

## Requirements

- Swift 5+
- iOS 8+
- macOS 10.13+
- tvOS 9+
- watchOS 5+

## Installation

### Xcode

In Xcode, use `File > Add Package Dependencies...` and enter:

`https://gitlab.com/davidwkeith/fractionformatter.git`

### Swift Package Manager

Add `FractionFormatter` to your `Package.swift` dependencies:

```swift
.package(url: "https://gitlab.com/davidwkeith/fractionformatter.git", from: "1.0.1")
```

Then add it to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["FractionFormatter"]
)
```

## Usage

`FractionFormatter` is a direct replacement for `NumberFormatter`:

```swift
let fractionFormatter = FractionFormatter()

fractionFormatter.string(from: NSNumber(value: 0.5))   // "½"
fractionFormatter.string(from: NSNumber(value: 0.123)) // "¹²³⁄₁₀₀₀"
```

It can also parse and normalize fraction-like strings:

```swift
fractionFormatter.double(from: "1½")                  // 1.5
fractionFormatter.double(from: "1 1/2")               // 1.5
fractionFormatter.string(from: "1 1/2")               // "1½"
fractionFormatter.string(from: "1½", as: .BuiltUp)   // "1 1/2"
```

## Fraction Output Styles

`FractionFormatter.FractionType` supports:

- `.Unicode` for Unicode output (for example, `"1½"` or `"¹²³⁄₁₀₀₀"`)
- `.BuiltUp` for slash-separated output (for example, `"1 1/2"`)

## Filing Feature Requests and Issues

The source is hosted on GitLab and mirrored on GitHub. If you find an issue or have a feature request, file it [here](https://gitlab.com/davidwkeith/fractionformatter/-/issues/new).

## Known Issues

### Radar FB7644708 - Pluralization and Number Formatting

When combined with Apple's `MeasurementFormatter`, there are issues with pluralization. For example, using `NumberFormatter` to format fractional feet outputs `"0.5 feet"` ("zero point five feet"). Replacing it with `FractionFormatter` can produce `"½ feet"`, which is not the standard English form. Normally we say "half a foot" (or "one half of a foot"), so singular wording is preferred.

As of February 19, 2026 there is no public API on `MeasurementFormatter` to force singular unit words for fractional values while keeping full localized unit inflection.

#### Workarounds

1. Prefer `.short`/`.medium` unit styles (`ft`, `kg`, etc.) where singular/plural words are not shown.
2. For values where `abs(value) < 1`, use a custom localized phrase (`"half a foot"`, `"one half of a foot"`, etc.) from your app localization resources.
3. If you only need an English-style output path, post-process the unit word for that range.

Example (option 3):

```swift
import Foundation

func formatLength(_ value: Double, formatter: MeasurementFormatter) -> String {
    let measurement = Measurement(value: value, unit: UnitLength.feet)
    let formatted = formatter.string(from: measurement)

    guard abs(value) < 1 else { return formatted }

    // English-specific fallback for FB7644708.
    return formatted.replacingOccurrences(of: " feet", with: " foot")
}
```
