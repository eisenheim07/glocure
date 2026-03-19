# Project Structure

## Directory Organization

```
lib/
├── cubits/          # State management (BLoC/Cubit)
├── models/          # Data models
├── screens/         # UI screens/pages
├── services/        # API and external services
├── utils/           # Utility functions and helpers
├── widgets/         # Reusable UI components
└── main.dart        # App entry point

assets/
├── fonts/           # Custom fonts (Inter family)
└── images/          # Image assets
    ├── home/        # Home screen images
    └── splash/      # Splash/login screen images
```

## Architecture Pattern

- BLoC/Cubit pattern for state management
- Each feature has its own Cubit in `lib/cubits/{feature_name}/`
- Cubits are provided at app level via MultiBlocProvider in main.dart
- Models represent API responses and domain entities
- Services layer handles all API communication

## Key Directories

### cubits/
State management organized by feature:
- `home_banner/`, `middle_banner/`, `bottom_banner/` - Banner management
- `top_products/`, `discounted_products/` - Product listings
- `categories/`, `browse_categories/`, `category_products/` - Category navigation
- `skin_genius/` - Skin analysis feature
- `brand_logos/` - Brand showcase
- `filter/`, `product_search/` - Search and filtering

### models/
Data models matching API responses:
- `home_top_banner_model.dart` - Banner data
- `top_products_model.dart` - Product data
- `browse_category_model.dart` - Category data
- `category_menu_model.dart` - Menu structure
- `discounted_products_model.dart` - Product listings
- `filter_model.dart` - Filter options

### screens/
UI screens:
- `splash_screen.dart` - App launch
- `language_selection_screen.dart` - Language picker
- `login_screen.dart` - Authentication
- `home_screen.dart` - Main dashboard
- `categories_screen.dart` - Category browser
- `category_products.dart` - Product listing
- `product_details_screen.dart` - Product details
- `search_screen.dart` - Product search
- `filter_screen.dart` - Filter UI

### services/
- `api_service.dart` - Centralized GraphQL API client for Shopify integration

### utils/
- `size_utils.dart` - Responsive sizing (Figma design: 393x852)
- `image_constant.dart` - Image asset paths
- `format_utils.dart` - Formatting helpers
- `auth_storage.dart` - Authentication storage

### widgets/
Reusable components:
- `custom_app_bar.dart` - App bar component
- `search_bar_widget.dart` - Search input
- `app_image.dart` - Image wrapper
- `network_image_loader.dart` - Network image with loading

## Naming Conventions

- Files: snake_case (e.g., `home_screen.dart`)
- Classes: PascalCase (e.g., `HomeScreen`)
- Variables/functions: camelCase (e.g., `fetchProducts`)
- Constants: SCREAMING_SNAKE_CASE (e.g., `FIGMA_DESIGN_WIDTH`)
- Private members: prefix with underscore (e.g., `_makeGraphQLRequest`)

## Responsive Design

- Uses custom Sizer widget for responsive layouts
- Design reference: Figma 393x852 viewport
- Extension methods on num for responsive sizing: `.h`, `.fSize`
- Device type detection: mobile vs tablet
