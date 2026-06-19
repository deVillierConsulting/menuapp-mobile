# MenuApp — Mobile

Flutter iOS app for MenuApp, a meal-planning app for couples and families. Talks to the `menuapp` backend API.

## Stack

| | |
|--|--|
| Framework | Flutter (Dart SDK ^3.12) |
| State management | flutter_bloc (Cubit) |
| Navigation | go_router |
| Icons | lucide_icons_flutter |

## Prerequisites

- Flutter SDK (run `flutter doctor` — everything should be green for iOS)
- Xcode + iOS Simulator
- The `menuapp` backend running locally (see its README)

## Running the app

```bash
# Install dependencies
flutter pub get

# Run on the iOS Simulator (opens Simulator if not already running)
flutter run
```

To pick a specific device:

```bash
flutter devices          # list available
flutter run -d <device>  # e.g. "iPhone 16 Pro"
```

## Backend connection

The API base URL is hardcoded in two places right now:

- [`lib/app.dart`](lib/app.dart) — `ApiClient(baseUrl: 'http://192.168.1.105:8000')`
- [`lib/router.dart`](lib/router.dart) — same URL for the group detail data source

**If you're on a different network or machine**, update both to your Mac's local IP (`System Preferences → Network`). The simulator can reach `localhost`, so you can also use `http://localhost:8000` if both are on the same machine.

## Project structure

```
lib/
  data/
    models/          # Dart data classes (immutable, Equatable)
    api_client.dart  # HTTP wrapper (GET/POST/PATCH/DELETE)
    groups_data_source.dart
  cubits/            # State management — one Cubit per screen
  ui/
    groups/          # Groups list + Group Detail screens
    recipes/         # Recipe list screen
  widgets/           # Custom widget kit (no Material/Cupertino rendering)
    buttons/
    cards/
    inputs/
    nav/
    sheets/
    states/
    ...
  theme/             # Design tokens: AppColors, AppTypography, AppRadii, AppShadows
  router.dart        # go_router config
  app.dart           # Root widget + BlocProvider setup
  main.dart
```

## Navigation

| Route | Screen |
|-------|--------|
| `/groups` | Groups list (tab) |
| `/groups/:id` | Group detail — members, active menu, past menus |
| `/recipes` | Recipe library (tab) |

Group detail is outside the tab shell so it renders full-screen with a back button and no bottom nav.

## Widget kit

All custom widgets live in `lib/widgets/`. They use `BoxDecoration` for all styling — no Material widget rendering. Design tokens come from `lib/theme/`. Don't use raw hex values or inline radii in widget files.
