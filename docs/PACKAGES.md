# MenuApp Mobile — Package Reference

> Keep this file updated whenever a dependency is added, removed, or has its
> usage significantly changed. Version numbers reflect `pubspec.lock` as of
> 2026-07-01.

---

## Runtime dependencies

### State management

| Package | Version | Docs |
|---|---|---|
| `flutter_bloc` | 9.1.1 | https://bloclibrary.dev |
| `equatable` | 2.0.8 | https://pub.dev/packages/equatable |

**`flutter_bloc`** is the core state-management library. Every feature area has
a `*Cubit` (extends `Cubit<State>`) that owns business-side state and a
corresponding `*State` sealed class hierarchy. Screens use `BlocBuilder` to
react to state; `BlocProvider` and `BlocProvider.value` inject cubits into the
widget tree.

*Where it lives:* `lib/cubits/` — one subdirectory per feature
(`shop/`, `menu_detail/`, `groups/`, `add_recipe/`, etc.), each with
`*_cubit.dart` + `*_state.dart`.

**`equatable`** is used on every `*State` class so BLoC can detect changes
without manual `==` overrides. Every state's `props` list must include every
field — failing to list a field means UI won't rebuild when that field changes.

---

### Navigation

| Package | Version | Docs |
|---|---|---|
| `go_router` | 15.1.3 | https://pub.dev/packages/go_router |

Declarative, URL-based router. The app uses a `StatefulShellRoute` with three
`StatefulShellBranch` entries (Groups, Recipes, Shop) so each tab maintains its
own independent navigation stack and scroll position.

*Where it lives:* `lib/router.dart` — single source of truth for all routes.
`AppShell` (`lib/widgets/nav/app_shell.dart`) is the `StatefulShellRoute`'s
`builder`, owns `AppNavBar`, and handles the user-switcher debug overlay.

Named routes used in push/replace calls (e.g.
`context.push('/groups/$id')`). Never use `Navigator.push` directly —
go_router owns all navigation.

---

### Networking

| Package | Version | Docs |
|---|---|---|
| `http` | 1.4.1 | https://pub.dev/packages/http |

Low-level HTTP client. All requests go through `ApiClient`
(`lib/data/api_client.dart`), which:
- Injects the Bearer token from `_token` on every request
- Wraps 4xx/5xx into `ApiException(statusCode, message)`
- Parses `detail` from FastAPI error responses
- Handles `DELETE` with a request body via a raw `http.Request` (the standard
  `client.delete()` signature doesn't accept a body)

`*DataSource` classes (`lib/data/*_data_source.dart`) wrap `ApiClient` and
return typed model objects. Cubits receive data sources via constructor
injection — never instantiate `ApiClient` inside a cubit.

---

### Icons

| Package | Version | Docs |
|---|---|---|
| `lucide_icons_flutter` | 3.1.14+2 | https://pub.dev/packages/lucide_icons_flutter |

~1 500 outline icons, 2 px stroke, round caps/joins, 24 px grid. Matches the
design system exactly. Access via `LucideIcons.shoppingCart`,
`LucideIcons.chevronDown`, etc.

**Rule:** never mix in `Icons.*` (Material filled set) for decorative icons.
`Icons.check`, `Icons.check_rounded`, and `Icons.add` are the only Material
icons currently in use — for small inline affordances where Lucide doesn't have
a direct equivalent.

---

### Flutter SDK

| Package | Version |
|---|---|
| `flutter` SDK | ≥ 3.27.0 |
| Dart SDK | ≥ 3.12.2 |
| `cupertino_icons` | 1.0.9 |

`cupertino_icons` is included by the Flutter template and kept in case any
Cupertino widgets are introduced. Currently unused beyond the default asset.

---

## Dev dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | 6.0.0 | Recommended lint rule set, configured in `analysis_options.yaml` |
| `flutter_test` | SDK | Unit and widget tests (no test files yet — deferred to post-auth milestone) |

---

## Packages we've deliberately NOT added

| Package | Reason |
|---|---|
| `dio` | `http` is sufficient for our simple REST calls; `dio` adds complexity we don't need |
| `get_it` / `injectable` | Constructor injection via BlocProvider is explicit and traceable; a service locator would obscure dependencies |
| `freezed` | Equatable + manual `copyWith` is lightweight enough at current scale; freezed's codegen would add build overhead |
| `cached_network_image` | No remote images yet — deferred until S3/CloudFront photo infrastructure lands |
| `shared_preferences` / `hive` | No local persistence yet — deferred until offline/cache strategy is decided post-auth |

---

## Adding a new package — checklist

1. Run `flutter pub add <package>` and verify `pubspec.lock` updates cleanly
2. Add an entry to this file: version (from lock), docs link, where it lives,
   what problem it solves
3. If it replaces an existing approach, add the old package to the "deliberately
   NOT added" table with a reason
4. Update `design-system.html` if the package affects any visual component
