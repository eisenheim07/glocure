/// Color Migration Helper
/// This file contains mappings for replacing hardcoded colors with AppColors
/// Use this as a reference for systematic color replacement across the app

class ColorMigrationHelper {
  /// Common color mappings from hardcoded hex values to AppColors
  static const Map<String, String> colorMappings = {
    // Primary brand colors
    'Color(0xFFFF5C9A)': 'AppColors.primary',
    'const Color(0xFFFF5C9A)': 'AppColors.primary',
    'Color(0xFFFFE9F0)': 'AppColors.secondary',
    'const Color(0xFFFFE9F0)': 'AppColors.secondary',
    'Color(0xFFFF8BB5)': 'AppColors.primaryLight',
    'Color(0xFFFFB3D9)': 'AppColors.primaryLight',
    
    // White and black
    'Colors.white': 'AppColors.white',
    'Colors.black': 'AppColors.black',
    'Color(0xFFFFFFFF)': 'AppColors.white',
    'Color(0xFF000000)': 'AppColors.black',
    
    // Gray scale colors
    'Color(0xFF1A1A1A)': 'AppColors.gray900',
    'Color(0xFF333333)': 'AppColors.gray800',
    'const Color(0xFF333333)': 'AppColors.gray800',
    'Color(0xFF4A4A4A)': 'AppColors.gray700',
    'Color(0xFF666666)': 'AppColors.gray600',
    'const Color(0xFF666666)': 'AppColors.gray600',
    'Color(0xFF808080)': 'AppColors.gray500',
    'Color(0xFF999999)': 'AppColors.gray400',
    'const Color(0xFF999999)': 'AppColors.gray400',
    'Color(0xFFCCCCCC)': 'AppColors.gray300',
    'const Color(0xFFCCCCCC)': 'AppColors.gray300',
    'Color(0xFFE5E5E5)': 'AppColors.gray200',
    'Color(0xFFE0E0E0)': 'AppColors.gray200',
    'const Color(0xFFE0E0E0)': 'AppColors.gray200',
    'Color(0xFFF5F5F5)': 'AppColors.gray100',
    'const Color(0xFFF5F5F5)': 'AppColors.gray100',
    'Color(0xFFFAFAFA)': 'AppColors.gray50',
    
    // Semantic colors
    'Color(0xFF00C853)': 'AppColors.success',
    'const Color(0xFF00C853)': 'AppColors.success',
    'Color(0xFFE53E3E)': 'AppColors.error',
    'Colors.red': 'AppColors.error',
    'Colors.green': 'AppColors.success',
    'Colors.orange': 'AppColors.warning',
    'Colors.blue': 'AppColors.info',
    
    // Common Material colors
    'Colors.grey': 'AppColors.gray500',
    'Colors.transparent': 'Colors.transparent', // Keep transparent as is
  };
  
  /// Common withOpacity patterns to withValues
  static const Map<String, String> opacityMappings = {
    '.withOpacity(0.1)': '.withValues(alpha: 0.1)',
    '.withOpacity(0.2)': '.withValues(alpha: 0.2)',
    '.withOpacity(0.3)': '.withValues(alpha: 0.3)',
    '.withOpacity(0.4)': '.withValues(alpha: 0.4)',
    '.withOpacity(0.5)': '.withValues(alpha: 0.5)',
    '.withOpacity(0.6)': '.withValues(alpha: 0.6)',
    '.withOpacity(0.7)': '.withValues(alpha: 0.7)',
    '.withOpacity(0.8)': '.withValues(alpha: 0.8)',
    '.withOpacity(0.9)': '.withValues(alpha: 0.9)',
  };
  
  /// Files that need AppColors import
  static const List<String> filesToUpdate = [
    'lib/screens/login_screen.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/address_screen.dart',
    'lib/screens/product_details_screen.dart',
    'lib/screens/category_products.dart',
    'lib/screens/categories_screen.dart',
    'lib/screens/search_screen.dart',
    'lib/screens/filter_screen.dart',
    'lib/screens/wishlist_screen.dart',
    'lib/screens/cart_screen.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/order_screen.dart',
    'lib/screens/address_list_screen.dart',
    'lib/widgets/custom_app_bar.dart',
    'lib/widgets/common_bottom_sheet.dart',
    'lib/widgets/payment_selection_bottom_sheet.dart',
    'lib/widgets/custom_bottom_nav_bar.dart',
    'lib/widgets/network_image_loader.dart',
    'lib/widgets/product_rating_widget.dart',
    'lib/widgets/search_bar_widget.dart',
    'lib/services/connectivity_service.dart',
  ];
}