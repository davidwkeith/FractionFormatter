# Localization and Measurements

Use locale-aware parsing and measurement integration helpers.

## Locale-aware parsing

Enable localized decimal/grouping support for numeric input:

```swift
let formatter = FractionFormatter()
formatter.parsingLocale = Locale(identifier: "fr_FR")
formatter.allowsLocaleAwareParsing = true

formatter.double(from: "1,5")     // 1.5
formatter.double(from: "1 1/2")   // 1.5
```

`FractionFormatter` normalizes locale separators before strict parsing so invalid partial parses are rejected.

## Custom input separators

Accept both solidus and fraction slash by default through
``FractionFormatter/acceptedInputDivisionSeparators``.
You can customize this set for stricter parsing.

## MeasurementFormatter integration

Use ``FractionFormatter/string(from:with:preferSingularUnitForProperFractions:)`` to format the numeric portion through `FractionFormatter` while preserving unit formatting from `MeasurementFormatter`.

```swift
let fractionFormatter = FractionFormatter()
let measurementFormatter = MeasurementFormatter()
measurementFormatter.unitStyle = .long
measurementFormatter.unitOptions = [.providedUnit]

let rendered = fractionFormatter.string(
    from: Measurement(value: 0.5, unit: UnitLength.feet),
    with: measurementFormatter,
    preferSingularUnitForProperFractions: true
)
```

The `preferSingularUnitForProperFractions` option is a lightweight workaround for environments where pluralization output is undesirable for proper fractions.
