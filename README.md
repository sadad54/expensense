# ExpenSense

**Scan a receipt, get a categorised expense, and see how close you are to your Malaysian income-tax relief limits.**

ExpenSense is a full-stack expense tracker: a cross-platform **Flutter** app backed by a **FastAPI** receipt service and **Firebase** (Auth + Firestore). It started as my final-year project at Universiti Teknologi Malaysia (MJIIT). A photo of a receipt goes to the API, which runs OCR, extracts the merchant, total, date and line items, and assigns a spending category. The app shows the result for review, then rolls confirmed transactions up into budgets, savings goals, spending charts and an income-tax relief tracker.

<!-- Screenshots: add 3–4 phone screenshots here (scan → review → budgets → tax tracker), e.g.
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
| **Extraction accuracy** | On **326 held-out real Malaysian receipts** (SROIE, ICDAR 2019): total amount **96.9%**, date **96.6%**, merchant **74.2%**. The parser the app used to ship scored 67.2%, 0% and 53.7%. ([details](#measured-results)) |
| **Stack** | Flutter (Dart) app · FastAPI service (Python) · Firebase Auth + Cloud Firestore · OCR.space · Docker · GitHub Actions |
| **API** | 4 endpoints, Firebase ID-token auth, per-user rate limiting (10 scans/min), request IDs, about 185 req/s on one worker for the parse path |
| **Quality gates** | 40 pytest tests (API, parser, categoriser, imaging, rate limiter) · 11 Flutter tests · CI fails the build if held-out total or date accuracy drops below 95% |
| **Security** | OCR key moved off the device and onto the server; Firestore rules restrict every document to its owner |
| **App** | ~12k lines of Dart across 10 feature areas, 4 sign-in methods, 6 Flutter build targets from one codebase |

## Architecture

```
┌────────────────────────┐   multipart image +       ┌───────────────────────────────┐
│  Flutter app (Dart)    │   Firebase ID token       │  FastAPI receipt service      │
│  Provider / MVVM       │ ────────────────────────► │  · verify ID token (Google)   │
│  scan → review → save  │                           │  · per-user rate limit        │
│                        │ ◄──── merchant, total,    │  · EXIF-strip, greyscale,     │
│                        │       date, line items,   │    compress under 1 MB        │
│                        │       category, flags     │  · OCR.space (key server-side)│
└───────────┬────────────┘                           │  · parser + categoriser       │
            │ Firestore SDK                          └───────────────────────────────┘
            ▼
┌────────────────────────────────────────────┐
│  Firebase: Auth · Cloud Firestore          │
│  users/{uid}/transactions, budgets, goals  │
│  owner-only security rules                 │
└────────────────────────────────────────────┘
```

The app never writes a scan straight to Firestore. The API returns what it found plus a `needs_review` flag, and the user confirms or corrects the amount, date and category first.

## Features

| Area | What it does |
|---|---|
| **Receipt scanning** | Capture or pick a photo; the API returns merchant, total (RM), date, line items and a category, and the app shows an editable review card before saving. |
| **Auto-categorisation** | Three stages on the server: a dictionary of 87 merchants (mostly Malaysian chains such as Tesco, AEON, 99 Speedmart, Petronas, Touch 'n Go, Unifi), then a whole-word keyword vote across 8 categories, then fuzzy matching of single words so OCR typos still match. |
| **Transactions** | Add, edit and delete expenses and income; scanned receipts keep their scan timestamp and appear in a scan history. |
| **Budgets** | Per-category budgets and budget periods, recalculated from the user's actual transactions. |
| **Savings goals** | Create goals, add funds and track progress. |
| **Income-tax relief tracker** | Relief categories with annual caps live in Firestore; transactions are matched by tag, category or an explicit tax category, and each shows usage against its cap. |
| **Stats** | Category bar chart, monthly trend line chart and category scatter chart (`fl_chart`). |
| **Accounts** | Firebase Authentication with email/password, Google, Facebook and Sign in with Apple. |

## The receipt API (`server/`)

| Endpoint | Purpose |
|---|---|
| `POST /v1/receipts/scan` | Image in (JPEG, PNG, WebP or HEIC, up to 10 MB), structured receipt out |
| `POST /v1/receipts/parse` | OCR text in, structured receipt out (no OCR call; used for testing and manual entry) |
| `GET /v1/categories` | The categories the categoriser can assign |
| `GET /healthz` | Liveness probe used by the Docker health check |

How a scan is handled:

1. **Auth.** The bearer token is verified as a Firebase ID token (signature, audience, issuer, expiry) against Google's public keys. No service-account key is needed.
2. **Rate limit.** A sliding window per user (default 10 scans a minute) protects the shared OCR quota. Over the limit returns `429` with `Retry-After`.
3. **Image preparation.** EXIF orientation is applied and the metadata dropped (it can include location), then greyscale, a contrast boost and stepped JPEG compression get the image under OCR.space's 1 MB upload limit.
4. **OCR.** OCR.space is called with the server's key, which never ships inside the app. Provider errors become `502` with a user-facing message.
5. **Parsing** (`app/parser.py`). Totals are found by ranked labels (rounded total, then grand total, then total incl. tax, and so on). The parser skips sub-totals, quantity and tax lines, ignores GST summary tables, and applies rounding adjustments. Dates are read day-first in several formats, with impossible dates rejected. The merchant is picked from the header lines, with registration numbers stripped and split names rejoined.
6. **Categorising** (`app/categoriser.py`). Merchant match, then keyword vote, then fuzzy fallback. The response reports which stage fired and a confidence.

## Measured results

`server/eval/sroie_eval.py` scores the parser on [SROIE](https://github.com/zzzDavid/ICDAR-2019-SROIE), a public set of 626 scanned Malaysian receipts with hand-labelled company, date and total. Receipts are sorted by id: the first 300 were used while developing the parser and the other **326 are held out**. The numbers below are from the held-out split only.

| Field | Original app parser | API parser |
|---|---:|---:|
| Total amount (exact to the sen) | 67.2% | **96.9%** |
| Date | 0.0%¹ | **96.6%** |
| Merchant name (≥ 90 fuzzy match) | 53.7% | **74.2%** |

¹ The original app pulled out a date string but parsed it with Dart's `DateTime.tryParse`, which only accepts ISO dates. Every day-first date such as `25/12/2018` silently became "today".

The categoriser assigned a category to 93.6% of held-out receipts. That figure is coverage only: SROIE has no category labels, so category accuracy is not measured here. Parsing plus categorising takes about 2.5 ms per receipt.

CI re-runs this evaluation on every pull request and fails if total or date accuracy drops below 95%. The results file is [`server/eval/results_test.json`](server/eval/results_test.json).

**Load.** `server/eval/load_test.py` replays all 626 SROIE receipts against `/v1/receipts/parse`. On one uvicorn worker with 2 vCPUs and 8 concurrent clients: about 185 req/s, p50 42 ms, p95 62 ms, 0 errors over 2,000 requests. OCR provider latency is external and not included.

## Tech stack

- **App:** Flutter (Dart 3.7), Provider + view models (MVVM-style), `http`, `fl_chart`, `flutter_animate`
- **API:** FastAPI, Pydantic, httpx, Pillow (+ HEIC), RapidFuzz, google-auth; Docker
- **Firebase:** Authentication, Cloud Firestore (with security rules), Storage, Analytics
- **OCR:** OCR.space REST API, called only from the server
- **CI:** GitHub Actions (pytest, SROIE accuracy gate, Docker build, `flutter analyze`, `flutter test`)

## Project structure

```
lib/
├── models/        # Transaction, budget, goal, scanned receipt
├── services/      # Receipt API client, Firestore access, budget service
├── util/          # Offline categoriser tables, transaction helpers, UI tokens
├── viewmodels/    # Budget, tax-category and theme state (Provider)
├── views/         # Auth, home, scan, transactions, budgets, goals, stats, income tax, settings
└── widgets/       # Reusable cards, charts, category form, social sign-in buttons
server/
├── app/           # FastAPI app: auth, imaging, OCR client, parser, categoriser, rate limiter
├── eval/          # SROIE accuracy evaluation, load test, CI threshold check
└── tests/         # pytest suite
tools/             # export_categories.py: Dart category tables → server/app/data/categories.json
firestore.rules    # Owner-only access rules
```

## Getting started

**Prerequisites:** Flutter SDK (Dart ≥ 3.7), Python 3.12, a Firebase project, and a free [OCR.space](https://ocr.space/ocrapi) API key.

```bash
git clone https://github.com/sadad54/expensense.git
cd expensense
```

**1. API**

```bash
cd server
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env        # set OCR_API_KEY and FIREBASE_PROJECT_ID
uvicorn app.main:app --port 8080
python -m pytest -q
```

Or with Docker: `docker build -t expensense-api server && docker run --env-file server/.env -p 8080:8080 expensense-api`.

**2. App**

```bash
cp assets/.env.example assets/.env   # API_BASE_URL (10.0.2.2 reaches your machine from the Android emulator)
flutter pub get
flutter run
```

Connect your own Firebase project with `flutterfire configure`, enable the sign-in providers you want, and deploy the rules with `firebase deploy --only firestore:rules`. For the tax tracker, add documents to `income_tax_categories` with `name`, `cap` (number) and `tags` (array of strings).

**Reproduce the evaluation**

```bash
git clone --depth 1 https://github.com/zzzDavid/ICDAR-2019-SROIE.git /tmp/sroie
cd server && python eval/sroie_eval.py /tmp/sroie/data --split test
```

## Status and roadmap

ExpenSense is a working prototype, not a store release. The API runs locally or in Docker and has not been deployed to a public host.

- **Planned:** measure category accuracy on a labelled set of real receipts.
- **Planned:** Firestore rules tests against the Firebase emulator.
- **Planned:** an on-device fallback when offline (a TensorFlow Lite model and Tesseract data are bundled under `assets/` but disabled).

## Author

**Adnan Mashrur Sadad** · [Portfolio](https://portfolio-sadad.vercel.app) · [LinkedIn](https://www.linkedin.com/in/adnan-mashrur-sadad-87a45b237) · [GitHub](https://github.com/sadad54)
