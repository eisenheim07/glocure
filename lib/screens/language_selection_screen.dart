import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/image_constant.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/app_image.dart';
import '../utils/auth_storage.dart';
import 'main_navigation_screen.dart';

/// Language Selection Screen
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage = 'en'; // Default to English

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
    {'code': 'mr', 'name': 'मराठी'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'ml', 'name': 'മലയാളം'},
    {'code': 'or', 'name': 'ଓଡ଼ିଆ'},
    {'code': 'te', 'name': 'తెలుగు'},
  ];

  @override
  void initState() {
    super.initState();
    // Hide status bar on language selection
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _continue() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save language selection status
    await AuthStorage.setLanguageSelected(true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: SmartImage(
              source: ImageConstant.icLanguageScreenBG,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Section
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 42.w,
                          height: 42.h,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 28.h),
                      
                      // Title
                      Text(
                        'Choose the language',
                        style: TextStyle(
                          fontSize: 24.fSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      
                      SizedBox(height: 7.h),
                      
                      Text(
                        'Select your preferred language below',
                        style: TextStyle(
                          fontSize: 13.fSize,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 14.h),
                
                // White Card with Languages
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              children: List.generate(
                                (_languages.length / 2).ceil(),
                                (rowIndex) {
                                  final firstIndex = rowIndex * 2;
                                  final secondIndex = firstIndex + 1;
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 14.h),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildLanguageOption(_languages[firstIndex]),
                                        ),
                                        SizedBox(width: 14.w),
                                        if (secondIndex < _languages.length)
                                          Expanded(
                                            child: _buildLanguageOption(_languages[secondIndex]),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Continue Button
                        Padding(
                          padding: EdgeInsets.all(20.w),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _continue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 15.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(Map<String, String> language) {
    final isSelected = _selectedLanguage == language['code'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = language['code'];
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSecondary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderPrimary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: AppColors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language['name']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
