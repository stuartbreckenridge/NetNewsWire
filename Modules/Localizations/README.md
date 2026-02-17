# Localizations

Shared localization package for all NetNewsWire targets.

## Goals

- One shared localization source across app, extensions, and modules.
- Dot-notation keys for every string (for example: `label.text.add-feed`).
- Every key includes an explanatory comment for translators.
- Uses modern String Catalog format (`.xcstrings`).

## Package Layout

- `Sources/Localizations/Localizations.swift`
  - Public API for lookup from Swift.
- `Sources/Localizations/Resources/Localizable.xcstrings`
  - Canonical string catalog for shared strings.

## Key Rules

- Use dot notation keys only.
- Preferred prefix: `label.text.`.
- Keep keys semantic and stable.
- Always provide a human-readable `comment`.

## Swift Usage

```swift
import Localizations

let title = Localizations.labelTextAddFeed
```

Every catalog key is exposed as a static property in `Localizations.swift`.

## ObjC Usage

ObjC code should resolve keys from the `Localizations` bundle and use the same dot-notation keys from `Localizable.xcstrings`.

## Updating Strings

1. Add/update entries in `Sources/Localizations/Resources/Localizable.xcstrings`.
2. Keep `comment` accurate and specific.
3. Use `Localizations.someStaticVar` at call sites.
4. Avoid introducing direct `NSLocalizedString(...)` in target code.
