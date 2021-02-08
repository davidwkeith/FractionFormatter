# FractionFormatter

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavidwkeith%2FFractionFormatter%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/davidwkeith/FractionFormatter) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavidwkeith%2FFractionFormatter%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/davidwkeith/FractionFormatter)

A subclass of Apple's [`NumberFormatter`](https://developer.apple.com/documentation/foundation/numberformatter) that outputs pretty printed Unicode fractions rather than decimals.

## Adding FractionFormatter to your project

In Xcode, use the `File:Swift Packages:Add Package Dependency…` menu command and enter `https://gitlab.com/davidwkeith/fractionformatter.git`

## Usage

`FractionFormatter` is a direct replacement for `NumberFormatter` and is used the same way:

```swift
let fractionFormatter = FractionFormatter()
fractionFormatter.string(from: NSNumber(value: 0.5)) // "½"
fractionFormatter.string(from: NSNumber(value: 0.123)) // "¹²³⁄₁₀₀₀"
```

There are of course some connivance methods that make working with strings containing fractions easier:

```swift
fractionFormatter.double(from: "1 ½") // 1.5
fractionFormatter.double(from: "1 1/2") // 1.5
fractionFormatter.string(from: "1 1/2") // "1 ½"
fractionFormatter.string(from: "1 ½", as .Shilling) // 1 1/2
```

## Filing feature requests and issues

The source is hosted on GitLab and mirrored on GitHub. If you find an issues or have a feature request, you can file it [here[(https://gitlab.com/davidwkeith/fractionformatter/-/issues/new)]

## Known Issues

### Radar FB7644708 - Pluralization and number formatting

When combined with Apple's MeasurementFormatter there are issues with pluralization. For example, using `NumberFormatter` to format fractional feet, it will output "0.5 feet", read as "zero point five feet", but if you substitute `FractionFormatter` then the output is "½ feet", which is not how it is normally written in English. Normally we say "half a foot", or more formally "one half of a foot" and thus write the singular form.

The workaround it to pull the symbol from the measurement and substitute the pluralized symbol when the measurement is between -1 and 1.
