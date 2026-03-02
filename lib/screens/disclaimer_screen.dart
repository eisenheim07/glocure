import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/page_model.dart';
import '../services/api_service.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<PageModel> _pages = [];
  late TabController _tabController;

  // Filter pages by handle
  PageModel? _privacyPolicy;
  PageModel? _termsConditions;
  PageModel? _refundReturns;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getPages(first: 50);
      _pages = response.pages;

      // Filter pages by handle
      _privacyPolicy = _pages.firstWhere(
        (page) => page.handle.toLowerCase().contains('privacy'),
        orElse: () => PageModel(
          id: '',
          title: 'Privacy Policy',
          handle: 'privacy-policy',
          body: '<p>Privacy Policy content not available.</p>',
          bodySummary: '',
        ),
      );

      _termsConditions = _pages.firstWhere(
        (page) => page.handle.toLowerCase().contains('terms') || page.handle.toLowerCase().contains('condition'),
        orElse: () => PageModel(
          id: '',
          title: 'Terms & Conditions',
          handle: 'terms-conditions',
          body: '<p>Terms & Conditions content not available.</p>',
          bodySummary: '',
        ),
      );

      _refundReturns = _pages.firstWhere(
        (page) => page.handle.toLowerCase().contains('refund') || page.handle.toLowerCase().contains('return'),
        orElse: () => PageModel(
          id: '',
          title: 'Refund and Returns Policy',
          handle: 'refund-returns',
          body: '<p>Refund and Returns Policy content not available.</p>',
          bodySummary: '',
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching pages: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GloCure Disclaimer',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: _isLoading || _errorMessage != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF5C9A),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF5C9A),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Privacy Policy'),
                  Tab(text: 'Terms & Conditions'),
                  Tab(text: 'Refund & Returns'),
                ],
              ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          10,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPageContent(_privacyPolicy),
        _buildPageContent(_termsConditions),
        _buildPageContent(_refundReturns),
      ],
    );
  }

  Widget _buildPageContent(PageModel? page) {
    if (page == null) {
      return const Center(
        child: Text('Content not available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // HTML Content - Strip HTML tags and display as text
          Text(
            _stripHtmlTags(page.body),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Strip HTML tags from content
  String _stripHtmlTags(String htmlString) {
    // Remove HTML tags
    String text = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('</p>', '\n\n')
        .replaceAll('</div>', '\n\n');
    
    // Clean up extra whitespace
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    text = text.trim();
    
    return text;
  }
}
