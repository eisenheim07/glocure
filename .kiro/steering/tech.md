# Technology Stack

## Framework & Language

- Flutter SDK 3.3.0+
- Dart programming language
- Material Design UI components

## State Management

- flutter_bloc (^8.1.6) - BLoC pattern for state management
- Cubit pattern for simpler state management scenarios

## Key Dependencies

- http (^1.2.2) - HTTP client for API calls
- flutter_svg (^2.0.9) - SVG rendering
- shimmer (^3.0.0) - Loading state animations
- shared_preferences (^2.2.2) - Local storage
- logger (^2.4.0) - API debugging and logging
- cupertino_icons (^1.0.8) - iOS-style icons

## Backend Integration

- Shopify Storefront API (GraphQL)
- Shopify Admin API (GraphQL + REST)
- Base URL: https://glocure.com/api/2025-01/graphql.json
- Admin URL: https://bxaqgp-p1.myshopify.com/admin/api/2023-01/graphql.json

## Common Commands

### Run the app
```bash
flutter run
```

### Build for Android
```bash
flutter build apk
flutter build appbundle
```

### Build for iOS
```bash
flutter build ios
```

### Run tests
```bash
flutter test
```

### Clean build artifacts
```bash
flutter clean
flutter pub get
```

### Analyze code
```bash
flutter analyze
```

### Check for linting issues
```bash
dart fix --dry-run
dart fix --apply
```

## Development Tools

- flutter_lints (^4.0.0) - Linting rules
- Android Studio / VS Code recommended
- Flutter DevTools for debugging
