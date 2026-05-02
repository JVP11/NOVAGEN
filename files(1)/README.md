# NovaGen SafeInk Scanner

Flutter app for scanning product barcodes (Open Food Facts), reading the SafeInk colour indicator with white/black reference normalisation + HSV classification, capturing GPS context, alerting manufacturers, and keeping local history.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel, Dart 3+)
- For device features (camera / GPS): a physical Android or iOS handset (emulators partially supported).

## Setup

```bash
cd files\(1\)   # or your clone path containing pubspec.yaml
flutter pub get
```

### Run

```bash
flutter run
```

Pick a connected device (`flutter devices`). Prefer **Chrome / Linux desktop** only for UI smoke tests — camera barcode and GPS flows need mobile permissions.

### Android

- **minSdkVersion** 21, **targetSdkVersion** 34 (see `android/app/build.gradle.kts`).
- Permissions are declared in `android/app/src/main/AndroidManifest.xml` (camera, location, internet).

### iOS

- Camera and location strings are set in `ios/Runner/Info.plist`.

## Architecture (lib/)

| File | Role |
|------|------|
| `main.dart` | Theme, routes (`/`, `/scanner`), permission bootstrap |
| `home_screen.dart` | Brand landing → History / Scanner |
| `scanner_screen.dart` | Barcode (mobile_scanner) + SafeInk (camera) tabs |
| `barcode_result_screen.dart` | Open Food Facts lookup + GPS / colour flow |
| `color_scan_screen.dart` | Standalone SafeInk capture |
| `result_screen.dart` | Outcome UX + history prepend |
| `gps_screen.dart` | Simulated map + Geolocator + geocoding |
| `report_screen.dart` | Mail / share templates |
| `history_screen.dart` | SharedPreferences-backed timeline |
| `models/` | `ScanRecord`, `ProductInfo` |
| `utils/` | Colour normalisation, HSV, sampling |
| `widgets/` | SafeInk overlays + camera shell |

## Open Food Facts

Product lookup calls `GET https://world.openfoodfacts.org/api/v0/product/{barcode}.json` (no API key). If nothing is returned, users can capture details manually.

## Tests

```bash
flutter test
flutter analyze
```

## Deploy on [Render](https://render.com) (static web)

The repo root includes **`render.yaml`** and **`scripts/render_build.sh`**, which install Flutter stable and run `flutter build web --release` for the app in **`files(1)/`**.

1. Push this repository to GitHub (or GitLab / Bitbucket supported by Render).
2. In Render: **New +** → **Blueprint** → connect the repo → confirm the blueprint (or **Static Site** with the same build settings).
3. After deploy, open the `.onrender.com` URL. Camera / barcode / GPS need a real browser with permissions; behaviour may differ from mobile builds.

**Manual Static Site** (if you do not use Blueprint):

| Setting | Value |
|--------|--------|
| **Root Directory** | *(leave empty if repo matches this layout)* |
| **Build Command** | `bash scripts/render_build.sh` |
| **Publish Directory** | `files(1)/build/web` |

If **`pubspec.yaml` is at the repository root** (no `files(1)` folder), set **Publish Directory** to `build/web` and change **`APP_DIR`** in `scripts/render_build.sh` to `"${ROOT}"`.

---

**Tagline:** INNOVATE. GENERATE. ELEVATE.
