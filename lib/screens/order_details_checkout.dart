import 'package:flutter/material.dart';
import 'package:glocure/utils/size_utils.dart';

import '../models/customer_model.dart';
import '../widgets/custom_app_bar.dart';

class OrderDetailsCheckout extends StatefulWidget {
  final Customer? customer;

  const OrderDetailsCheckout({this.customer, super.key});

  @override
  State<OrderDetailsCheckout> createState() => _OrderDetailsCheckoutState();
}

class _OrderDetailsCheckoutState extends State<OrderDetailsCheckout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'Order Summary',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.h),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildShippingAddressCard(widget.customer!),
              const SizedBox(height: 4),
              _buildContactInformationCard(widget.customer!),
              const SizedBox(height: 16),
              const Spacer(),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5C9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build shipping address card
  Widget _buildShippingAddressCard(Customer customer) {
    final defaultAddr = customer.defaultAddress;

    if (defaultAddr == null) {
      return _buildEmptyCard('Shipping Address', 'No address available');
    }

    // Build full address string
    final addressParts = <String>[];
    if (defaultAddr.address1 != null && defaultAddr.address1!.isNotEmpty) {
      addressParts.add(defaultAddr.address1!);
    }
    if (defaultAddr.address2 != null && defaultAddr.address2!.isNotEmpty) {
      addressParts.add(defaultAddr.address2!);
    }
    if (defaultAddr.city != null && defaultAddr.city!.isNotEmpty) {
      addressParts.add(defaultAddr.city!);
    }
    if (defaultAddr.province != null && defaultAddr.province!.isNotEmpty) {
      addressParts.add(defaultAddr.province!);
    }
    if (defaultAddr.zip != null && defaultAddr.zip!.isNotEmpty) {
      addressParts.add(defaultAddr.zip!);
    }

    final fullAddress = addressParts.join(', ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              // Edit button
              // IconButton(
              //   icon: Icon(
              //     Icons.edit_outlined,
              //     color: AppColors.primary,
              //     size: 16.h,
              //   ),
              //   onPressed: () async {
              //     // Navigate to address list screen
              //     final updatedCustomer = await Navigator.push<Customer>(
              //       context,
              //       MaterialPageRoute(
              //         builder: (_) => AddressListScreen(
              //           customer: customer,
              //           returnSelectedAddress: true,
              //         ),
              //       ),
              //     );
              //
              //     // Always refresh when returning from address screen
              //     if (mounted) {
              //       // Show shimmer during refresh
              //       setState(() {
              //         _isRefreshingAddress = true;
              //         _hasCheckedAddress = false;
              //         _buttonTextReady = false;
              //       });
              //
              //       // Update customer state if we got updated customer data
              //       if (updatedCustomer != null) {
              //         setState(() {
              //           _customer = updatedCustomer;
              //         });
              //         // Update the customer cubit as well
              //         context.read<CustomerCubit>().updateCustomer(updatedCustomer);
              //       } else {
              //         // Even if no customer returned, refresh customer data from API
              //         context.read<CustomerCubit>().refreshCustomer();
              //       }
              //
              //       // Re-check customer address to update button text and card visibility
              //       await _checkCustomerAddress();
              //
              //       // Hide shimmer after refresh
              //       setState(() {
              //         _isRefreshingAddress = false;
              //       });
              //     }
              //   },
              //   padding: EdgeInsets.zero,
              // ),
            ],
          ),
          Text(
            fullAddress.isNotEmpty ? fullAddress : 'Address not available',
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build contact information card
  Widget _buildContactInformationCard(Customer customer) {
    final firstName = customer.firstName ?? '';
    final lastName = customer.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = customer.email ?? '';
    final phone = customer.defaultAddress?.phone ?? customer.phone ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            Text(
              phone,
              style: TextStyle(
                fontSize: 12.fSize,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(
                fontSize: 12.fSize,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  /// Build empty card for missing information
  Widget _buildEmptyCard(String title, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
