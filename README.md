# Ledger — Premium Personal Finance Command Center

Ledger is a fully offline, high-fidelity personal budget, goals planner, and projection command center built with Flutter and designed specifically for Indian salary earners. By combining offline privacy, rigorous tax compliance (New Regime FY 2026-27 & Old Regime), stepped career-projection math, and visual cash flow tools, Ledger gives users absolute clarity over their financial futures.

---

## 🎨 Design Philosophy & Theme System
Ledger implements a custom, state-of-the-art **Neutral Dark Theme** to create a focused, high-contrast visual environment where colors are reserved strictly for critical data hierarchy:
- **Canvas / Scaffold Background**: `#141414` (Deep obsidian black)
- **Cards & Sheets Surface**: `#1E1E1E` (Sleek dark gray)
- **Dividers & Borders**: `#2E2E2E` (Subtle boundaries)
- **Primary Typography & High-Contrast Items**: `#FFF5EE` (Warm seashell white)
- **Data Accents (Strict Contextual Use)**:
  - **Indigo (`#6366F1`)**: Primary app branding, main corpus trajectories, and active states.
  - **Emerald Success**: Healthy metrics (Emergency Fund 6+ months, high financial health, positive regime comparisons).
  - **Amber Warning**: Building metrics (Emergency Fund 3-6 months, warnings, intermediate slabs).
  - **Coral Danger (`#F87171`)**: Critical metrics (Emergency Fund <3 months, cash flow deficits, liabilities).

---

## 🚀 Detailed Features

### 1. Dashboard (The Financial Cockpit)
- **Net Worth Summary**: A header summary card calculating active Net Worth dynamically based on `Invested Corpus + Emergency Fund + Other Assets - Liabilities`. Tapping the info icon reveals a modal breakdown.
- **Financial Health Score (0-100)**: A weighted algorithm calculating your financial readiness and presenting detailed, actionable improvement recommendations.
- **Monthly Budget Toggle**: Switch instantly between a clean **Pie Chart** and a **Cash Flow Waterfall** displaying:
  $$\text{Take-Home} \rightarrow \text{Expenses} \rightarrow \text{SIP} \rightarrow \text{Purchases} \rightarrow \text{Free Cash}$$
- **Spend Calendar**: Groups recurring year-1 purchases dynamically into calendar months based on hash values. Tapping a month reveals a detailed planned spend breakdown.
- **Emergency Fund Tracker**: Progress bar tracking emergency fund balance against a standard 6-month expenses target, color-coded for safety categories.

### 2. Goals (Milestone Tracker)
- **Priority-Coded Cards**: Red, amber, or green labels designating high, medium, and low-priority goals.
- **Target vs. Corpus Sparklines**: Embedded micro fl-charts displaying the 20-year projected corpus curve against the goal's target horizontal line, highlighting the intersection year.
- **Inflation Protection**: Automatically adjusts target savings goals against projected inflation parameters.

### 3. Purchases (Discretionary Outflow)
- **Category Groups**: Grouped lists for Tech, Travel, Lifestyle, Health, and Education purchases.
- **10-Year Cost Preview**: Displays recurrence costs and total projected expenditure over a decade.
- **Deletions with Undo**: Immediate swipe-to-dismiss deletion backed by an immediate Undo SnackBar action.

### 4. Projection Engine (20-Year Horizon)
- **Real Calendar Dates**: Configured with a `startYear` field to track projection years as real calendar years.
- **Dual-Regime Compare Toggle**: Overlays New vs Old tax regimes as side-by-side lines on the corpus chart, generating a delta card showing the lifetime difference.
- **What-If Bracket Editor**: Ephemeral sliders allowing you to experiment with hike brackets, SIP rates, and purchase costs to check impact at Year 10.
- **Retirement & SWP Planner**: Sustainability engine calculating sustainable monthly payouts, life expectancy depletion, and gap analysis.
- **Screenshot Share**: Captures the repaint boundary of the corpus chart with a solid dark canvas and shares it natively.

### 5. Settings (Configuration & Backups)
- **Stepped Hike Brackets**: Custom slider editor to configure hike rates for different career stages (e.g., Years 1-3: 15%, Years 4-7: 12%, Year 8+: 8%).
- **City Preset selector**: Instantly populates food, rent, transport, and misc expenses based on city cost profiles.
- **Tax Regime toggle**: Switches default calculations between New Regime and Old Regime.
- **JSON Import/Export**: Paste-based text configuration manager allowing full database backups and restores.

---

## 🛠️ Tech Stack & Architecture

Ledger is built using a clean, decoupling architecture:
```
lib/
├── models/         # Pure Dart objects (Hive annotations, TypeAdapters)
├── providers/      # Riverpod providers, Notifiers, debounced calculations
├── screens/        # UI widgets and layouts organized by feature areas
├── utils/          # Serializers, schema migrations, and math helpers
├── main.dart       # App entrypoint, Hive init, and migrations bootloader
└── theme.dart      # Material 3 dark design tokens and extensions
```

### Libraries Used:
- **UI & Layout**: Flutter + Material 3
- **State Management**: Riverpod (`StateNotifier` / `StateProvider` / `Notifier`)
- **Persistence**: Hive & Hive Flutter (Local-first, encrypted, no external network requirements)
- **Visualization**: `fl_chart` for custom responsive charts
- **Navigation**: `go_router` supporting hierarchical state shells

---

## 💾 Local Storage Schema (Hive)

Ledger manages local state inside 5 distinct Hive boxes. All models are serialized using adapters generated by `build_runner`.

### Schema Versioning & Migrations
On app boot, the system runs automatic migrations from version 1 to 2:
- **Box `metadata`**: Stores the current schema version (`schema_version`).
- **Migration 1 ➔ 2**: Adds support for stepped salary brackets, emergency funds, liabilities, start year, and other assets. If the user updates from a version 1 store, default fields are populated automatically without data loss.

---

## 📐 Financial Calculations & Algorithms

### 1. Income Tax Engine (New Regime - FY 2026-27)
Deductions are calculated sequentially using the standard slabs:
- **Standard Deduction**: ₹75,000
- **Basic Slab Deductions**:
  - ₹0 to ₹4,00,000: 0%
  - ₹4,00,001 to ₹8,00,000: 5%
  - ₹8,00,001 to ₹12,00,000: 10%
  - ₹12,00,001 to ₹16,00,000: 15%
  - ₹16,00,001 to ₹20,00,000: 20%
  - ₹20,00,001 to ₹24,00,000: 25%
  - ₹24,00,001 and above: 30%
- **Section 87A Rebate**: Tax is reduced to ₹0 if the total taxable income after deductions is ₹12,00,000 or less.
- **Cess**: 4% Health & Education Cess is applied to final tax liability.
- **Provident Fund**: 12% of basic salary (defined as 40% of CTC) is deducted from the gross amount.

### 2. Financial Health Score Weights
The Health Score is computed on a scale of 0 to 100 based on five criteria:
1. **SIP Savings Rate** (25 points):
   - $\ge 15\%$: 25 pts
   - $10\% \text{ to } 15\%$: 15 pts
   - $< 10\%$: 5 pts
2. **Emergency Fund** (20 points):
   - $\ge 6 \text{ months}$: 20 pts
   - $3 \text{ to } 6 \text{ months}$: 12 pts
   - $< 3 \text{ months}$: 5 pts
3. **Expense Ratio** (20 points):
   - $< 40\%$ of monthly take-home: 20 pts
   - $40\% \text{ to } 60\%$: 12 pts
   - $> 60\%$: 5 pts
4. **Goal Feasibility** (20 points):
   - 100% of goals funded by target year: 20 pts
   - $\ge 50\%$ goals: 10 pts
   - $< 50\%$ goals: 5 pts
5. **10-Year Corpus Growth** (15 points):
   - Projected corpus at Year 10 is $\ge 5\times$ starting CTC: 15 pts
   - $2\times \text{ to } 5\times$: 10 pts
   - $< 2\times$: 5 pts

### 3. Retirement SWP Math
- **Inflation-adjusted income target**:
  $$\text{Income}_{\text{retire}} = \text{Income}_{\text{today}} \times (1 + \text{Inflation})^{\text{yearsToRetire}}$$
- **Real rate of return during retirement**:
  $$r_{\text{real}} = \frac{r_{\text{SIP}} - \text{Inflation}}{1 + \text{Inflation}}$$
- **Sustainable monthly SWP withdrawal**:
  Calculated using standard annuity formulas based on expected lifespans and real return parameters.

---

## 💻 Developer Installation & Building

To run Ledger locally or build a production apk, ensure you have the Flutter SDK configured.

### 1. Setup & Package Installation
```bash
# Clone the repository and fetch dependencies
flutter pub get
```

### 2. Generate Hive TypeAdapters
```bash
# Rebuild the adapters using build_runner
dart run build_runner build --delete-conflicting-outputs
```

### 3. Running Unit Tests
```bash
# Run tests to verify the finance engine, migrations, and calculations
flutter test
```

### 4. Build APK
```bash
# Build a debug/profile version of the APK
flutter build apk --debug
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-debug.apk`

### 5. Deploy to Device
```bash
# Install directly onto an attached emulator or hardware device
adb install build/app/outputs/flutter-apk/app-debug.apk
```
