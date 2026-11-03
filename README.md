# ExpenSense

**Scan a receipt, get a categorised expense, and see how close you are to your Malaysian income-tax relief limits.**

ExpenSense is a cross-platform Flutter app for personal expense tracking, built as my final-year project at Universiti Teknologi Malaysia (MJIIT). It turns a photo of a receipt into a categorised transaction using OCR and a hybrid rule-plus-fuzzy categoriser tuned for Malaysian merchants. It then rolls those transactions up into budgets, savings goals, spending charts and an income-tax relief tracker.

<!-- Screenshots: add 3–4 phone screenshots here (scan → result → budgets → tax tracker), e.g.
<p align="center">
  <img src="docs/screenshots/scan.png" width="220" />
  <img src="docs/screenshots/budgets.png" width="220" />
  <img src="docs/screenshots/tax.png" width="220" />
</p>
-->

---

## At a glance

| | |
|---|---|
| **Scope** | ~12k lines of Dart across 44 files · 10 feature areas (auth, home, scan, scan history, transactions, budgets, goals, stats, income tax, settings) · 6 Flutter build targets from one codebase |
| **Categorisation** | 3-stage hybrid pipeline: a dictionary of **87 merchants common in Malaysia**, then **357 keywords** across **8 spending categories**, then fuzzy matching (similarity > 0.5) as a fallback |
| **OCR pre-processing** | Resize to 1024 px + contrast boost, then adaptive JPEG compression (quality stepped 85 → 55, then downscaled) to keep every upload under the OCR API's **1 MB limit**, with a 900 KB safety target |
| **Integrations** | 4 sign-in methods (email/password, Google, Facebook, Apple) · Firebase Auth, Firestore, Storage, Analytics · OCR.space |
| **Analytics** | 3 chart views (category bar, monthly trend line, category scatter) and a tax-relief tracker that measures usage against each relief category's annual cap |

## Features

| Area | What it does |
|---|---|
| **Receipt scanning** | Capture or pick a receipt photo. It is pre-processed on device, sent to the OCR.space API, and parsed into amount, date and merchant text. |
| **Auto-categorisation** | A three-stage hybrid matcher: (1) Malaysian merchant dictionary (e.g. Tesco, AEON, 99 Speedmart, Petronas, Touch 'n Go, Unifi), (2) category keyword match, (3) fuzzy string similarity (threshold 0.5) as a fallback. |
| **Transactions** | Add, edit and delete expenses and income; scanned receipts keep their scan timestamp and appear in a scan history. |
| **Budgets** | Per-category budgets and budget periods, recalculated from the user's actual transactions. |
| **Savings goals** | Create goals, add funds and track progress. |
| **Income-tax relief tracker** | Tax-relief categories with annual caps are stored in Firestore. Transactions are matched to them by tag, assigned category or an explicit tax category, and each category shows usage against its cap. |
| **Stats** | Category bar chart, monthly trend line chart and category scatter chart (`fl_chart`). |
| **Accounts** | Firebase Authentication with email/password, Google, Facebook and Sign in with Apple; per-user data in Cloud Firestore. |
| **Theming** | Light and dark themes, custom category icons and colours. |

## How receipt scanning works

```
photo ──► resize + contrast boost ──► adaptive JPEG compression (stay under the 1 MB OCR API limit)
      ──► OCR.space ──► regex extraction (amount, date) ──► hybrid categoriser ──► review & save to Firestore
```

- **Pre-processing** (`lib/views/scan/scan_receipt_view.dart`): the image is resized and its contrast increased before upload. The JPEG quality is then lowered step by step, and the image scaled down if needed, until it fits under the OCR API's 1 MB limit.
- **Parsing** (`lib/util/receipt_parser.dart`): regular expressions pull out the total amount and the date from the OCR text.
- **Categorising** (`lib/util/category_hybrid_matcher.dart`): merchant dictionary → keyword match → fuzzy similarity, so well-known local merchants are categorised exactly and unknown ones still get a best guess.

## Tech stack

- **App:** Flutter (Dart 3.7), Provider + view models (MVVM-style), `flutter_animate`, `fl_chart`
- **Backend-as-a-service:** Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Analytics
- **OCR:** OCR.space REST API (key loaded from `.env` via `flutter_dotenv`)
- **Matching:** `string_similarity` for fuzzy categorisation
- **Platforms:** Android, iOS, web, Windows, macOS, Linux (Flutter targets)

## Project structure

```
lib/
├── models/        # Transaction, budget category/period, goal
├── services/      # Firestore access, budget service, category matcher
├── util/          # Receipt parser, hybrid categoriser, keyword tables, UI tokens
├── viewmodels/    # Budget, tax-category and theme state (Provider)
├── views/         # Auth, home, scan, transactions, budgets, goals, stats, income tax, settings
└── widgets/       # Reusable cards, charts, category form, social sign-in buttons
```

## Getting started

**Prerequisites:** Flutter SDK (Dart ≥ 3.7), a Firebase project, and a free [OCR.space](https://ocr.space/ocrapi) API key.

```bash
git clone https://github.com/sadad54/expensense.git
cd expensense
flutter pub get
```

1. Create a `.env` file in the project root:
   ```dotenv
   OCR_API_KEY=your_ocr_space_key
   ```
2. Connect your own Firebase project (`flutterfire configure`), which regenerates `firebase_options.dart` and the platform config files. Enable Email/Password (and optionally Google, Facebook, Apple) sign-in, and Cloud Firestore.
3. To use the tax tracker, add documents to an `income_tax_categories` collection with `name`, `cap` (number) and `tags` (array of strings).
4. Run:
   ```bash
   flutter run
   ```

## Status and roadmap

ExpenSense is a working academic prototype, not a store release.

- **Planned:** an on-device text classifier (a TensorFlow Lite model and Tesseract data are bundled under `assets/`, but that path is currently disabled in favour of the cloud OCR + rule-based pipeline).
- **Planned:** unit tests for the receipt parser and categoriser (the current `test/` folder only holds the Flutter template test).
- **Planned:** line-item extraction from receipts, not just totals.

## Author

**Adnan Mashrur Sadad** · [Portfolio](https://portfolio-sadad.vercel.app) · [LinkedIn](https://www.linkedin.com/in/adnan-mashrur-sadad-87a45b237) · [GitHub](https://github.com/sadad54)
