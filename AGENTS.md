# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains all application code. Use `lib/core/` for shared infrastructure such as Drift database setup, providers, and utilities; `lib/features/` for feature slices like `home`, `transaction`, `budget`, `analytics`, and `settings`; and `lib/shared/` for reusable widgets and theming. Entry points live in `lib/main.dart` and `lib/app.dart`. Tests mirror feature areas under `test/features/`. Platform folders (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) should only receive platform-specific changes.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `dart run build_runner build --delete-conflicting-outputs` regenerates Drift and other generated files.
- `dart run build_runner watch --delete-conflicting-outputs` keeps generated code updated during schema work.
- `flutter run` launches the app on a connected device or emulator.
- `flutter test` runs the widget and unit test suite.
- `flutter analyze` runs static analysis with `flutter_lints`.
- `dart format lib test` formats source and tests before review.

## Coding Style & Naming Conventions
Follow standard Dart style: 2-space indentation, trailing commas where Flutter formatting benefits, and small focused widgets/providers. Use `snake_case.dart` for files, `PascalCase` for classes/widgets, `camelCase` for methods and variables, and suffix providers clearly, for example `themeProvider` or `transactionDaoProvider`. Do not hand-edit generated files such as `lib/core/database/app_database.g.dart`.

## Testing Guidelines
Use `flutter_test` for widget and logic tests. Place tests beside the relevant feature path, for example `test/features/home/home_page_test.dart`. Name files with the `_test.dart` suffix and write test descriptions around visible behavior, not implementation details. Add or update tests for routing, state changes, and database-facing logic when modifying features.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commits with concise summaries, often in Chinese, for example `feat: 实现预算功能` and `fix(add): handle no-pop route on save and close`. Keep that format: `feat`, `fix`, `refactor`, `test`, or `docs`, with an optional scope. PRs should include a short summary, affected screens or modules, screenshots/GIFs for UI changes, and notes about schema regeneration or migration impact when Drift tables change.

## Configuration Notes
This repository currently uses Material 3, Riverpod, GoRouter, Drift, and `fl_chart`. If you add assets, register them in `pubspec.yaml`; if you change database tables or DAOs, rerun code generation before opening a PR.
