# Quick Start

Build a formatter, parse user input, and render Unicode or built-up fractions.

## Create a formatter

```swift
let formatter = FractionFormatter()
```

## Parse common inputs

```swift
formatter.double(from: "1½")      // 1.5
formatter.double(from: "1 1/2")   // 1.5
formatter.double(from: "0.125")   // 0.125
```

## Render output styles

```swift
formatter.string(from: NSNumber(value: 1.5))                 // "1½"
formatter.string(from: NSNumber(value: 1.5), as: .BuiltUp)   // "1 1/2"
```

## Configure reduction policy

Use ``FractionFormatter/ReductionPolicy/maxDenominator(_:)`` for practical denominators.

```swift
formatter.reductionPolicy = .maxDenominator(16)
formatter.string(from: NSNumber(value: 2.2), as: .BuiltUp)   // "2 1/5"
```

## Configure sign behavior

```swift
formatter.negativeFormatStyle = .parenthesized
formatter.string(from: NSNumber(value: -1.5)) // "(1½)"
```

## Next steps

- Learn locale/measurement behavior in <doc:LocalizationAndMeasurements>
- Review edge cases in <doc:Troubleshooting>
