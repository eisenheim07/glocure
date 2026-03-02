import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import 'address_screen.dart';

class AddressListScreen extends StatefulWidget {
  final Customer? customer;
  final bool returnSelectedAddress;

  const AddressListScreen({
    super.key,
    this.customer,
    this.returnSelectedAddress = false,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  bool _isLoading = true;
  Customer? _customer;
  String? _errorMessage;
  String? _selectedAddressId;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // If customer object is passed, use it directly
    if (widget.customer != null) {
      _customer = widget.customer;
      _selectedAddressId = _customer!.defaultAddress?.id;
      setState(() {
        _isLoading = false;
      });
    } else {
      // Otherwise fetch from API
      _fetchCustomerAddresses();
    }
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

  /// Delete address with confirmation
  Future<void> _deleteAddress(CustomerAddress address) async {
    // Check if address ID is null
    if (address.id == null || address.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid address ID'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Delete Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              'Are you sure you want to delete this address?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Delete button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5C9A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    // Show loading state
    setState(() {
      _isDeleting = true;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Delete address
      await ApiService().customerAddressDelete(
        customerAccessToken: token,
        addressId: address.id!,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh address list
      await _fetchCustomerAddresses();
    } catch (e) {
      debugPrint('❌ Error deleting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete address: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
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
      body: Stack(
        children: [
          _isLoading || _isDeleting
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildAddressListContent(),
        ],
      ),
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

    // Check if addresses list is empty or invalid
    if (_isAddressListEmpty(addresses)) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF5C9A),
            onRefresh: _fetchCustomerAddresses,
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
        ),
        // Add New Address Button or Done Button
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
            child: widget.returnSelectedAddress
                ? Row(
                    children: [
                      // Add New Address Button
                      Expanded(
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFFF5C9A),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Color(0xFFFF5C9A),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add New',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF5C9A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Done Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Return updated customer object
                            Navigator.pop(context, _customer);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5C9A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
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

  /// Check if address list is empty or invalid
  bool _isAddressListEmpty(List<CustomerAddress> addresses) {
    // Check if addresses list is null or empty
    if (addresses.isEmpty) {
      return true;
    }

    // Check if default address is null or has empty fields
    final defaultAddress = _customer!.defaultAddress;
    if (defaultAddress == null) {
      return true;
    }

    // Check if default address has all required fields empty
    if (_isAddressFieldsEmpty(defaultAddress)) {
      return true;
    }

    // Check if there's only one address and it has empty fields
    if (addresses.length == 1 && _isAddressFieldsEmpty(addresses[0])) {
      return true;
    }

    return false;
  }

  /// Check if address has all required fields empty
  bool _isAddressFieldsEmpty(CustomerAddress address) {
    return (address.address1 == null || address.address1!.isEmpty) &&
        (address.address2 == null || address.address2!.isEmpty) &&
        (address.city == null || address.city!.isEmpty) &&
        (address.zip == null || address.zip!.isEmpty) &&
        (address.province == null || address.province!.isEmpty);
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF5C9A),
            onRefresh: _fetchCustomerAddresses,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
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
                ),
              ),
            ),
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

            // Edit, Delete icons and selection radio button
            Column(
              children: [
                // Edit and Delete icons in a row with divider
                Row(
                  children: [
                    // Edit icon
                    GestureDetector(
                      onTap: isSelected
                          ? () async {
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
                            }
                          : null,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 24,
                        color: isSelected ? Colors.red : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Vertical divider
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 8),

                    // Delete icon
                    GestureDetector(
                      onTap: isSelected ? () => _deleteAddress(address) : null,
                      child: Icon(
                        Icons.delete_outline,
                        size: 24,
                        color: isSelected ? Colors.red : Colors.red.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
