# FractionFormatter

A formatter that converts between numeric values and their reduced fractional textual representations.

## Overview

Instances of FractionFormat format the textual representation of cells that contain NSNumber objects and convert textual representations of numeric values into NSNumber objects. The representation encompasses integers, floats, and doubles; floats and doubles can be formatted to a specified fractional type. Fractions are always output in their reduced form.

## Shilling and Special Fractions
A shilling fraction uses the solidus character `/` to seperate the numirator from the denominator. This creates an ASCII representation of the fraction. Special fractions use Unicode [Number Forms](https://en.wikipedia.org/wiki/Number_Forms) to format the fractional parts.

## Thread Safety
On iOS 7 and later FractionFormatter is thread-safe.

In macOS 10.9 and later FractionFormatter is thread-safe so long as you are using the modern behavior in a 64-bit app.

On earlier versions of the operating system, or when using the legacy formatter behavior or running in 32-bit in macOS, FractionFormatter is not thread-safe, and you therefore must not mutate a number formatter simultaneously from multiple threads.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
