import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../models/customer_model.dart';
import '../cubits/customer/customer_cubit.dart';
import '../cubits/customer/customer_state.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch customer data on init
    context.read<CustomerCubit>().fetchCustomer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        type: AppBarType.simple,
        title: 'My Profile',
      ),
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            if (state is CustomerLoading) {
              return _buildLoadingState();
            } else if (state is CustomerError) {
              return _buildErrorState(state.message);
            } else if (state is CustomerSuccess) {
              return _buildProfileContent(state.customer);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Build loading shimmer state
  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.all(14.w),
      children: [
        // Personal Information Section Shimmer
        Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title shimmer
              Container(
                width: 128.w,
                height: 17.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 16),
              
              // Field shimmers (3 fields for personal info)
              ...List.generate(3, (index) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label shimmer
                    Container(
                      width: 68.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Field shimmer
                    Container(
                      width: double.infinity,
                      height: 41.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                    ),
                  ],
                ),
              )),
              
              SizedBox(height: 8),
              
              // Address Section title shimmer
              Container(
                width: 153.w,
                height: 17.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 16),
              
              // Field shimmers (8 fields for address info)
              ...List.generate(8, (index) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label shimmer
                    Container(
                      width: 85.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Field shimmer
                    Container(
                      width: double.infinity,
                      height: 41.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7.r),
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
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.fSize,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<CustomerCubit>().fetchCustomer(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
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

  /// Build profile content
  Widget _buildProfileContent(Customer customer) {
    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, MediaQuery.of(context).padding.bottom + 20.h),
      children: [
        // Personal Information Section
        _buildSectionTitle('Personal Information'),
        SizedBox(height: 16),

        // First Name
        _buildTextField(
          label: 'First Name',
          value: customer.firstName,
        ),
        SizedBox(height: 16),

        // Last Name
        _buildTextField(
          label: 'Last Name',
          value: customer.lastName,
        ),
        SizedBox(height: 16),

        // Email
        _buildTextField(
          label: 'Email',
          value: customer.email,
        ),
        SizedBox(height: 24),

        // Address Information Section (only if defaultAddress exists)
        if (customer.defaultAddress != null) ...[
          _buildSectionTitle('Address Information'),
          SizedBox(height: 16),

          // Address Line 1
          _buildTextField(
            label: 'Address Line 1',
            value: customer.defaultAddress!.address1,
          ),
          SizedBox(height: 16),

          // Address Line 2
          _buildTextField(
            label: 'Address Line 2',
            value: customer.defaultAddress!.address2,
          ),
          SizedBox(height: 16),

          // City
          _buildTextField(
            label: 'City',
            value: customer.defaultAddress!.city,
          ),
          SizedBox(height: 16),

          // Country
          _buildTextField(
            label: 'Country',
            value: customer.defaultAddress!.country,
          ),
          SizedBox(height: 16),

          // ZIP Code
          _buildTextField(
            label: 'ZIP Code',
            value: customer.defaultAddress!.zip,
          ),
          SizedBox(height: 16),

          // Company
          _buildTextField(
            label: 'Company',
            value: customer.defaultAddress!.company,
          ),
          SizedBox(height: 16),

          // Province/State
          _buildTextField(
            label: 'Province/State',
            value: customer.defaultAddress!.province,
          ),
          SizedBox(height: 16),

          // Phone
          _buildTextField(
            label: 'Phone',
            value: customer.defaultAddress!.phone,
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
          style: TextStyle(
            fontSize: 12.fSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(7.r),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1.w,
            ),
          ),
          child: Text(
            isEmpty ? 'Not provided' : value,
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w400,
              color: isEmpty ? AppColors.textDisabled : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
