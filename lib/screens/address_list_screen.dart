import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import 'address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  bool _isLoading = true;
  Customer? _customer;
  String? _errorMessage;
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _fetchCustomerAddresses();
  }

  /// Fetch customer data and addresses from API
  Future<void> _fetchCustomerAddresses() async {
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
        // Set default address as selected
        _selectedAddressId = customer.defaultAddress?.id;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching customer addresses: $e');
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
        title: 'My Addresses',
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildAddressListContent(),
    );
  }

  /// Build loading shimmer state
  Widget _buildLoadingState() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bottom button shimmer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
              onPressed: _fetchCustomerAddresses,
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

  /// Build address list content
  Widget _buildAddressListContent() {
    if (_customer == null) {
      return const Center(
        child: Text('No customer data available'),
      );
    }

    final addresses = _customer!.addresses;

    if (addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No addresses found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first address to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isDefault = address.id == _customer!.defaultAddress?.id;
              final isSelected = address.id == _selectedAddressId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAddressCard(
                  address: address,
                  isDefault: isDefault,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedAddressId = address.id;
                    });
                  },
                ),
              );
            },
          ),
        ),
        // Add New Address Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: () async {
                // Navigate to address screen with customer data for adding new address
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddressScreen(
                      customer: _customer,
                      isAddingNew: true,
                    ),
                  ),
                );

                // If address was added successfully, refresh the list
                if (result == true && mounted) {
                  _fetchCustomerAddresses();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C9A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual address card
  Widget _buildAddressCard({
    required CustomerAddress address,
    required bool isDefault,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Build full address text
    String fullAddress = '';
    if (address.address1 != null && address.address1!.isNotEmpty) {
      fullAddress += address.address1!;
    }
    if (address.address2 != null && address.address2!.isNotEmpty) {
      if (fullAddress.isNotEmpty) fullAddress += ', ';
      fullAddress += address.address2!;
    }
    if (address.city != null && address.city!.isNotEmpty) {
      if (fullAddress.isNotEmpty) fullAddress += ', ';
      fullAddress += address.city!;
    }
    if (address.province != null && address.province!.isNotEmpty) {
      if (fullAddress.isNotEmpty) fullAddress += ', ';
      fullAddress += address.province!;
    }
    if (address.zip != null && address.zip!.isNotEmpty) {
      if (fullAddress.isNotEmpty) fullAddress += ', ';
      fullAddress += address.zip!;
    }
    if (address.country != null && address.country!.isNotEmpty) {
      if (fullAddress.isNotEmpty) fullAddress += ', ';
      fullAddress += address.country!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5C9A) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Address content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address type and default badge
                  Row(
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Full address
                  Text(
                    fullAddress.isNotEmpty ? fullAddress : 'No address available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Edit icon and selection radio button
            Column(
              children: [
                // Edit icon
                GestureDetector(
                  onTap: () async {
                    // Navigate to address screen for editing
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddressScreen(
                          customer: _customer,
                          existingAddress: address,
                        ),
                      ),
                    );

                    // If address was updated successfully, refresh the list
                    if (result == true && mounted) {
                      _fetchCustomerAddresses();
                    }
                  },
                  child: Icon(
                    Icons.edit_outlined,
                    size: 28,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),

                // Selection radio button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF5C9A) : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: Colors.white,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF5C9A),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
