import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import '../utils/size_utils.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Customer? _customer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  /// Fetch customer data from API
  Future<void> _fetchCustomerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'No authentication token found';
          _isLoading = false;
        });
        return;
      }

      final customer = await ApiService().getCustomer(token);

      if (customer == null) {
        setState(() {
          _errorMessage = 'Failed to load customer data';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _customer = customer;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching customer data: $e');
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
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'My Profile',
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  /// Build loading shimmer state
  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Personal Information Section Shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title shimmer
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              
              // Field shimmers (3 fields for personal info)
              ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label shimmer
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Field shimmer
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 8),
              
              // Address Section title shimmer
              Container(
                width: 180,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              
              // Field shimmers (8 fields for address info)
              ...List.generate(8, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label shimmer
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Field shimmer
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  /// Build error state
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
              onPressed: _fetchCustomerData,
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

  /// Build profile content
  Widget _buildProfileContent() {
    if (_customer == null) {
      return const Center(
        child: Text('No customer data available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Personal Information Section
        _buildSectionTitle('Personal Information'),
        const SizedBox(height: 16),

        // First Name
        _buildTextField(
          label: 'First Name',
          value: _customer!.firstName,
        ),
        const SizedBox(height: 16),

        // Last Name
        _buildTextField(
          label: 'Last Name',
          value: _customer!.lastName,
        ),
        const SizedBox(height: 16),

        // Email
        _buildTextField(
          label: 'Email',
          value: _customer!.email,
        ),
        const SizedBox(height: 24),

        // Address Information Section (only if defaultAddress exists)
        if (_customer!.defaultAddress != null) ...[
          _buildSectionTitle('Address Information'),
          const SizedBox(height: 16),

          // Address Line 1
          _buildTextField(
            label: 'Address Line 1',
            value: _customer!.defaultAddress!.address1,
          ),
          const SizedBox(height: 16),

          // Address Line 2
          _buildTextField(
            label: 'Address Line 2',
            value: _customer!.defaultAddress!.address2,
          ),
          const SizedBox(height: 16),

          // City
          _buildTextField(
            label: 'City',
            value: _customer!.defaultAddress!.city,
          ),
          const SizedBox(height: 16),

          // Country
          _buildTextField(
            label: 'Country',
            value: _customer!.defaultAddress!.country,
          ),
          const SizedBox(height: 16),

          // ZIP Code
          _buildTextField(
            label: 'ZIP Code',
            value: _customer!.defaultAddress!.zip,
          ),
          const SizedBox(height: 16),

          // Company
          _buildTextField(
            label: 'Company',
            value: _customer!.defaultAddress!.company,
          ),
          const SizedBox(height: 16),

          // Province/State
          _buildTextField(
            label: 'Province/State',
            value: _customer!.defaultAddress!.province,
          ),
          const SizedBox(height: 16),

          // Phone
          _buildTextField(
            label: 'Phone',
            value: _customer!.defaultAddress!.phone,
          ),
        ],
      ],
    );
  }

  /// Build section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  /// Build non-editable text field
  Widget _buildTextField({
    required String label,
    required String? value,
  }) {
    final isEmpty = value == null || value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            isEmpty ? 'Not provided' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isEmpty ? Colors.grey.shade400 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
