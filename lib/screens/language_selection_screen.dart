import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/image_constant.dart';
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Title
                      const Text(
                        'Choose the language',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Select your preferred language below',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // White Card with Languages
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: List.generate(
                                (_languages.length / 2).ceil(),
                                (rowIndex) {
                                  final firstIndex = rowIndex * 2;
                                  final secondIndex = firstIndex + 1;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildLanguageOption(_languages[firstIndex]),
                                        ),
                                        const SizedBox(width: 16),
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
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _continue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5C9A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFE0E0E0),
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
                  color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFFF5C9A) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.white,
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
                  color: isSelected ? const Color(0xFFFF5C9A) : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
