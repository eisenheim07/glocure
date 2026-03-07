// This is a reference script for systematic color replacement across all screens
// Run these replacements for each screen file

void main() {
  // Common color replacements to apply to all screen files:
  
  // 1. Add import at the top of each file:
  // import '../utils/app_colors.dart';
  
  // 2. Replace these common patterns:
  Map<String, String> replacements = {
    // Primary brand colors
    'Color(0xFFFF5C9A)': 'AppColors.primary',
    'const Color(0xFFFF5C9A)': 'AppColors.primary',
    'Color(0xFFFFE9F0)': 'AppColors.secondary',
    'const Color(0xFFFFE9F0)': 'AppColors.secondary',
    'Color(0xFFFFE5F0)': 'AppColors.secondary',
    'const Color(0xFFFFE5F0)': 'AppColors.secondary',
    
    // White and black
    'Colors.white': 'AppColors.white',
    'Colors.black': 'AppColors.black',
    'Color(0xFFFFFFFF)': 'AppColors.white',
    'Color(0xFF000000)': 'AppColors.black',
    
    // Gray colors
    'Color(0xFF333333)': 'AppColors.gray800',
    'const Color(0xFF333333)': 'AppColors.gray800',
    'Color(0xFF666666)': 'AppColors.gray600',
    'const Color(0xFF666666)': 'AppColors.gray600',
    'Color(0xFF777777)': 'AppColors.gray500',
    'const Color(0xFF777777)': 'AppColors.gray500',
    'Color(0xFF7A7A7A)': 'AppColors.gray500',
    'const Color(0xFF7A7A7A)': 'AppColors.gray500',
    'Color(0xFF999999)': 'AppColors.gray400',
    'const Color(0xFF999999)': 'AppColors.gray400',
    'Color(0xFFCCCCCC)': 'AppColors.gray300',
    'const Color(0xFFCCCCCC)': 'AppColors.gray300',
    'Color(0xFFE0E0E0)': 'AppColors.gray200',
    'const Color(0xFFE0E0E0)': 'AppColors.gray200',
    'Color(0xFFE5E5E5)': 'AppColors.gray200',
    'const Color(0xFFE5E5E5)': 'AppColors.gray200',
    'Color(0xFFF5F5F5)': 'AppColors.gray100',
    'const Color(0xFFF5F5F5)': 'AppColors.gray100',
    
    // Semantic colors
    'Color(0xFF00C853)': 'AppColors.success',
    'const Color(0xFF00C853)': 'AppColors.success',
    'Color(0xFF4CAF50)': 'AppColors.success',
    'const Color(0xFF4CAF50)': 'AppColors.success',
    'Colors.green': 'AppColors.success',
    'Colors.red': 'AppColors.error',
    'Colors.orange': 'AppColors.warning',
    'Colors.blue': 'AppColors.info',
    
    // Common Material colors
    'Colors.grey': 'AppColors.gray500',
    'Colors.grey[300]': 'AppColors.gray300',
    'Colors.grey[400]': 'AppColors.gray400',
    'Colors.grey[500]': 'AppColors.gray500',
    'Colors.grey[600]': 'AppColors.gray600',
    'Colors.grey[700]': 'AppColors.gray700',
    
    // Opacity replacements
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
  
  // Files to update:
  List<String> filesToUpdate = [
    'lib/screens/home_screen.dart',
    'lib/screens/product_details_screen.dart',
    'lib/screens/address_screen.dart',
    'lib/screens/category_products.dart',
    'lib/screens/categories_screen.dart',
    'lib/screens/search_screen.dart',
    'lib/screens/filter_screen.dart',
    'lib/screens/wishlist_screen.dart',
    'lib/screens/cart_screen.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/order_screen.dart',
    'lib/screens/address_list_screen.dart',
    'lib/screens/splash_screen.dart',
    'lib/screens/language_selection_screen.dart',
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