# ``FractionFormatter``

Format and parse fractions using Unicode glyphs, built-up forms, and configurable formatting policies.

## Overview

``FractionFormatter`` is a ``Foundation/NumberFormatter`` subclass designed for fractional text workflows.
It supports:

- Unicode fraction output (for example, `1½`, `¹²³⁄₁₀₀₀`)
- Built-up output (for example, `1 1/2`)
- Parsing from decimal, built-up, vulgar-glyph, and mixed Unicode forms
- Locale-aware numeric parsing
- Configurable rational reduction, sign handling, and typography

Use this package when you need deterministic fraction parsing/formatting behavior across Apple and Linux Foundation implementations.

## Topics

### Essentials

- ``FractionFormatter/init()``
- ``FractionFormatter/string(from:)``
- ``FractionFormatter/double(from:)``
- ``FractionFormatter/FractionType``
- ``FractionFormatter/attributedString(from:as:attributes:)``

### Parsing

- ``FractionFormatter/parsingLocale``
- ``FractionFormatter/allowsLocaleAwareParsing``
- ``FractionFormatter/acceptedInputDivisionSeparators``
- ``FractionFormatter/parseVulgarFraction(_:)``

### Formatting Policies

- ``FractionFormatter/reductionPolicy``
- ``FractionFormatter/ReductionPolicy``
- ``FractionFormatter/negativeFormatStyle``
- ``FractionFormatter/NegativeFormatStyle``
- ``FractionFormatter/negativeSignSymbol``

### Typography

- ``FractionFormatter/unicodeFormattingStyle``
- ``FractionFormatter/UnicodeFormattingStyle``
- ``FractionFormatter/caseFractionStyle``
- ``FractionFormatter/CaseFractionStyle``
- ``FractionFormatter/unicodeWholeFractionSeparator``
- ``FractionFormatter/unicodeDivisionSeparator``
- ``FractionFormatter/builtUpWholeFractionSeparator``
- ``FractionFormatter/builtUpDivisionSeparator``
- ``FractionFormatter/caseFractionWholeFractionSeparator``
- ``FractionFormatter/caseFractionDivisionSeparator``

### Extensibility

- ``FractionFormatter/vulgarFractionGlyphs``
- ``FractionFormatter/defaultVulgarFractions``

### Measurement Integration

- ``FractionFormatter/string(from:with:preferSingularUnitForProperFractions:)``

### Guides

- <doc:QuickStart>
- <doc:LocalizationAndMeasurements>
- <doc:Troubleshooting>
