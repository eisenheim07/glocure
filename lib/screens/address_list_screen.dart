import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/size_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import '../cubits/customer/customer_cubit.dart';
import '../cubits/customer/customer_state.dart';
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
  String? _selectedAddressId;
  String? _selectedBaseAddressId; // Store base ID for comparison
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // If customer object is passed, update cubit with it
    if (widget.customer != null) {
      context.read<CustomerCubit>().updateCustomer(widget.customer!);
      _selectedAddressId = widget.customer!.defaultAddress?.id;
      _selectedBaseAddressId = _extractBaseAddressId(_selectedAddressId);
    } else {
      // Otherwise fetch from API
      context.read<CustomerCubit>().fetchCustomer();
    }
  }

  /// Extract base address ID from full Shopify address ID
  /// Example: gid://shopify/MailingAddress/10194549440690?model_name=... -> 10194549440690
  String? _extractBaseAddressId(String? fullAddressId) {
    if (fullAddressId == null || fullAddressId.isEmpty) return null;

    try {
      // Extract the numeric ID from the Shopify GID
      final regex = RegExp(r'MailingAddress/(\d+)');
      final match = regex.firstMatch(fullAddressId);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  /// Find address by base ID and update selected address ID to current full ID
  void _updateSelectedAddressAfterRefresh(List<CustomerAddress> addresses) {
    if (_selectedBaseAddressId == null) return;

    // Find address with matching base ID
    for (final address in addresses) {
      final baseId = _extractBaseAddressId(address.id);
      if (baseId == _selectedBaseAddressId) {
        // Update to current full ID with new access token
        _selectedAddressId = address.id;
        return;
      }
    }

    // If no matching address found, clear selection
    _selectedAddressId = null;
    _selectedBaseAddressId = null;
  }

  /// Refresh customer data from API
  Future<void> _refreshCustomerData() async {
    await context.read<CustomerCubit>().refreshCustomer();
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 34.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Delete Address',
                  style: TextStyle(
                    fontSize: 17.fSize,
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
                    fontSize: 12.fSize,
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
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.w,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14.fSize,
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
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5C9A),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 14.fSize,
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
              ],
            ),
          ),
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
      await context.read<CustomerCubit>().fetchCustomer();
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
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            if (_isDeleting || state is CustomerLoading) {
              return _buildLoadingState();
            }

            if (state is CustomerError) {
              return _buildErrorState(state.message);
            }

            if (state is CustomerSuccess) {
              // Update selected address ID when customer data changes
              if (_selectedAddressId == null) {
                _selectedAddressId = state.customer.defaultAddress?.id;
                _selectedBaseAddressId = _extractBaseAddressId(_selectedAddressId);
              } else {
                // Update selected address ID after refresh to handle new access tokens
                _updateSelectedAddressAfterRefresh(state.customer.addresses);
              }
              return _buildAddressListContent(state.customer);
            }

            return _buildLoadingState();
          },
        ),
      ),
    );
  }

  /// Build loading shimmer state
  Widget _buildLoadingState() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(14.w),
            children: List.generate(
              20,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bottom button shimmer
        Container(
          padding: EdgeInsets.all(14.w),
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
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build error state
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 54.h,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.fSize,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<CustomerCubit>().fetchCustomer(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
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
  Widget _buildAddressListContent(Customer customer) {
    final addresses = customer.addresses;

    // Check if addresses list is empty or invalid
    if (_isAddressListEmpty(customer, addresses)) {
      return _buildEmptyState(customer);
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF5C9A),
            onRefresh: _refreshCustomerData,
            child: ListView.builder(
              padding: EdgeInsets.all(14.w),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isDefault = address.id == customer.defaultAddress?.id;
                final isSelected = address.id == _selectedAddressId;

                return Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: _buildAddressCard(
                    address: address,
                    isDefault: isDefault,
                    isSelected: isSelected,
                    customer: customer,
                    onTap: () {
                      setState(() {
                        _selectedAddressId = address.id;
                        _selectedBaseAddressId = _extractBaseAddressId(address.id);
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
          padding: EdgeInsets.fromLTRB(8.h, 12.h, 12.h, 16.h),
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
                                  customer: customer,
                                  isAddingNew: true,
                                ),
                              ),
                            );

                            // If address was added successfully, refresh the list
                            if (result == true && mounted) {
                              context.read<CustomerCubit>().fetchCustomer();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFFF5C9A),
                                width: 2.w,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Color(0xFFFF5C9A),
                                    size: 17.h,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add New',
                                    style: TextStyle(
                                      fontSize: 14.fSize,
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
                            Navigator.pop(context, customer);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5C9A),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 14.fSize,
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
                            customer: customer,
                            isAddingNew: true,
                          ),
                        ),
                      );

                      // If address was added successfully, refresh the list
                      if (result == true && mounted) {
                        context.read<CustomerCubit>().fetchCustomer();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5C9A),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 17.h,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Add New Address',
                              style: TextStyle(
                                fontSize: 14.fSize,
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
  bool _isAddressListEmpty(Customer customer, List<CustomerAddress> addresses) {
    // Check if addresses list is null or empty
    if (addresses.isEmpty) {
      return true;
    }

    // Check if default address is null or has empty fields
    final defaultAddress = customer.defaultAddress;
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
  Widget _buildEmptyState(Customer customer) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF5C9A),
            onRefresh: _refreshCustomerData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 54.h,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No addresses found',
                          style: TextStyle(
                            fontSize: 15.fSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Add your first address to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.fSize,
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
          padding: EdgeInsets.fromLTRB(8.h, 12.h, 12.h, 16.h),
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
                      customer: customer,
                      isAddingNew: true,
                    ),
                  ),
                );

                // If address was added successfully, refresh the list
                if (result == true && mounted) {
                  context.read<CustomerCubit>().fetchCustomer();
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C9A),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 17.h,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 14.fSize,
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
    required Customer customer,
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
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
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
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 20.h,
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
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 14.fSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isDefault)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.gray200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10.fSize,
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
                      fontSize: 12.fSize,
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
                                    customer: customer,
                                    existingAddress: address,
                                  ),
                                ),
                              );

                              // If address was updated successfully, refresh the list
                              if (result == true && mounted) {
                                context.read<CustomerCubit>().fetchCustomer();
                              }
                            }
                          : null,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20.h,
                        color: isSelected ? Colors.red : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Vertical divider
                    Container(
                      width: 1.w,
                      height: 17.h,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 8),

                    // Delete icon
                    GestureDetector(
                      onTap: isSelected ? () => _deleteAddress(address) : null,
                      child: Icon(
                        Icons.delete_outline,
                        size: 20.h,
                        color: isSelected ? Colors.red : Colors.red.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selection radio button
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF5C9A) : Colors.grey.shade400,
                      width: 2.w,
                    ),
                    color: Colors.white,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10.w,
                            height: 10.h,
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
