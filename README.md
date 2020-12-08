# FractionFormatter

A simple extention to number formatter that outputs pretty printed Unicode fractions rather than decimal.

```swift
let fractionFormatter = FractionFormatter()
fractionFormatter.string(from: NSNumber(value: 0.5)) // ½
fractionFormatter.string(from: NSNumber(value: 0.123)) // ¹²³⁄₁₀₀₀
```

## Known Issues

### Radar FB7644708 - Pluarlization and number formatting

When combined with Apple's MeasurementFormatter there are issues with pluralization. For example, using the built in `NumberFormatter` to format fractional feet, it will output "0.5 feet", read as "zero point five feet", but if you substitute `FractionFormatter` then the output is "½ feet", which is not how it is normally written in English. Normally we say "half a foot", or more formally "one half of a foot".

The workaround it to pull the symbol from the measurement and substitue the pluralized symbol when the measurement is between -1 and 1.
