# Troubleshooting

Common issues and expected behavior when parsing/formatting fractions.

## Input returns nil

`double(from:)` and `string(from:)` intentionally return `nil` for malformed strings:

- empty input
- unsupported characters
- malformed built-up forms like `1/`, `/2`, or `1//2`
- division by zero forms like `1/0`

## Locale confusion

If users enter localized decimals (for example `1,5`) and parsing fails:

1. Set ``FractionFormatter/parsingLocale``
2. Ensure ``FractionFormatter/allowsLocaleAwareParsing`` is `true`

## Unexpected denominator size

If output has very large denominators, set
``FractionFormatter/reductionPolicy`` to
``FractionFormatter/ReductionPolicy/maxDenominator(_:)``.

## Negative display style

Use ``FractionFormatter/negativeFormatStyle`` and
``FractionFormatter/negativeSignSymbol`` to match product conventions.

## Measurement pluralization

`MeasurementFormatter` pluralization behavior can differ by locale/runtime.
Use ``FractionFormatter/string(from:with:preferSingularUnitForProperFractions:)`` if you want a practical fallback for proper fractions.
