# Nyumba Mkononi Flutter frontend

Flutter frontend for the Nyumba Mkononi FastAPI backend. The app uses a browse-first flow: onboarding and role selection do not require authentication. Login/register is opened only when a user favorites a property, requests owner contact details, or adds a property.

## Run

Install Flutter, then from the project root:

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For an Android emulator:

```bash
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The API base URL defaults to `http://127.0.0.1:8000` on Web/desktop and `http://10.0.2.2:8000` on Android. Override it with `--dart-define=API_BASE_URL=...` when needed.

## Structure

- `lib/services/api_client.dart`: HTTP, JWT persistence, multipart uploads
- `lib/models/`: API response models
- `lib/screens/`: onboarding, browse, auth gate, buyer, seller, upload, and map flows
- `lib/theme/app_theme.dart`: shared visual system

The map uses OpenStreetMap tiles through `flutter_map`; no Google Maps API key is required.
