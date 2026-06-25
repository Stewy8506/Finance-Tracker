# Ledger — Personal Finance Planner

A fully offline personal life budget & goals planner for Android, built with Flutter.

---

## Features

- **Dashboard** — Monthly take-home, SIP, free cash, corpus at year 5, budget pie chart, spend calendar, next milestone
- **Goals** — Priority-coded goal cards (high/medium/low), down-payment EMI analysis, funded-year tracking
- **Purchases** — Category-grouped recurring tech/travel/lifestyle spends, 10-year cost preview, undo delete
- **Projection** — 20-year corpus line chart with goal markers, year-by-year data table, What-If explorer with live sliders
- **Settings** — Profile editor with live take-home preview, new vs old regime tax comparison, projection assumptions, JSON export, data reset

## Tax Engine (India, New Regime FY 2026-27)

| Slab | Rate |
|------|------|
| 0 – 4L | 0% |
| 4 – 8L | 5% |
| 8 – 12L | 10% |
| 12 – 16L | 15% |
| 16 – 20L | 20% |
| 20 – 24L | 25% |
| Above 24L | 30% |

- Standard deduction: ₹75,000
- Section 87A rebate: zero tax if taxable income ≤ ₹12L
- 4% health & education cess
- PF: 12% of basic (40% of CTC)
- Old Regime also supported (for comparison)

## Tech Stack

| Layer | Library |
|-------|---------|
| UI | Flutter + Material 3 (dark mode, Indigo accent) |
| State | Riverpod (`StateNotifier`) |
| Persistence | Hive (fully offline) |
| Charts | fl_chart |
| Navigation | GoRouter (5-tab shell) |

## Building

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --debug
```

APK output: `build/app/outputs/flutter-apk/app-debug.apk`

## Install on Device

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```
