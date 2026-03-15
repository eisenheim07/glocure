import 'package:flutter/material.dart';
import '../utils/size_utils.dart';
import '../utils/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import '../utils/app_logger.dart';
import '../widgets/custom_app_bar.dart';
import 'order_summary_screen.dart';

class AddressScreen extends StatefulWidget {
  final Customer? customer;
  final bool isAddingNew;
  final CustomerAddress? existingAddress;
  final String? sourceScreen; // New parameter to track source screen

  const AddressScreen({
    super.key,
    this.customer,
    this.isAddingNew = false,
    this.existingAddress,
    this.sourceScreen, // 'product_details', 'cart', or null for default behavior
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool _isLoading = true;
  bool _isFetchingLocation = false;
  Customer? _customer;

  // Location data
  String _currentLocationName = '';
  String _currentLocationAddress = '';
  Placemark? _currentPlacemark; // Store placemark for address population

  // Track if address was populated from geolocation
  bool _isAddressFromGeolocation = false;

  // Track if address is being saved
  bool _isSavingAddress = false;

  // Text controllers
  final _fullNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();

  // Checkbox state
  bool _isDefaultAddress = false;
  bool _isDefaultAddressDisabled = false; // Track if checkbox should be disabled

  // Form validation state
  bool _isFormValid = false;

  // Error messages for each field
  String? _address1Error;
  String? _address2Error;
  String? _cityError;
  String? _provinceError;
  String? _countryError;
  String? _zipError;
  String? _phoneError;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Focus nodes for each field
  final FocusNode _address1FocusNode = FocusNode();
  final FocusNode _address2FocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _provinceFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();
  final FocusNode _zipFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    // Add listeners to all editable fields for validation
    _address1Controller.addListener(_validateForm);
    _address2Controller.addListener(_validateForm);
    _cityController.addListener(_validateForm);
    _provinceController.addListener(_validateForm);
    _countryController.addListener(_validateForm);
    _zipController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);

    // Add listeners to clear errors when user starts typing
    _address1Controller.addListener(() => _clearFieldError('address1'));
    _address2Controller.addListener(() => _clearFieldError('address2'));
    _cityController.addListener(() => _clearFieldError('city'));
    _provinceController.addListener(() => _clearFieldError('province'));
    _countryController.addListener(() => _clearFieldError('country'));
    _zipController.addListener(() => _clearFieldError('zip'));
    _phoneController.addListener(() => _clearFieldError('phone'));
  }

  void _clearFieldError(String fieldName) {
    // Clear error only if there's an error for this field
    switch (fieldName) {
      case 'address1':
        if (_address1Error != null) {
          setState(() => _address1Error = null);
        }
        break;
      case 'address2':
        if (_address2Error != null) {
          setState(() => _address2Error = null);
        }
        break;
      case 'city':
        if (_cityError != null) {
          setState(() => _cityError = null);
        }
        break;
      case 'province':
        if (_provinceError != null) {
          setState(() => _provinceError = null);
        }
        break;
      case 'country':
        if (_countryError != null) {
          setState(() => _countryError = null);
        }
        break;
      case 'zip':
        if (_zipError != null) {
          setState(() => _zipError = null);
        }
        break;
      case 'phone':
        if (_phoneError != null) {
          setState(() => _phoneError = null);
        }
        break;
    }
  }

  void _validateForm() {
    final address1 = _address1Controller.text.trim();
    final address2 = _address2Controller.text.trim();
    final city = _cityController.text.trim();
    final province = _provinceController.text.trim();
    final country = _countryController.text.trim();
    final zip = _zipController.text.trim();
    final phone = _phoneController.text.trim();

    // Validation rules
    final isAddress1Valid = address1.isNotEmpty && address1.length <= 100;
    final isAddress2Valid = address2.isNotEmpty && address2.length <= 100;
    final isCityValid = city.isNotEmpty && city.length <= 30;
    final isProvinceValid = province.isNotEmpty;
    final isCountryValid = country.isNotEmpty && country.length <= 30;
    final isZipValid = zip.isNotEmpty && zip.length == 6;
    final isPhoneValid = phone.isNotEmpty && phone.length == 10;

    final isValid = isAddress1Valid && isAddress2Valid && isCityValid && isProvinceValid && isCountryValid && isZipValid && isPhoneValid;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _handleAddAddress() {
    if (_isFormValid) {
      // If address is from geolocation, show confirmation bottom sheet
      if (_isAddressFromGeolocation) {
        _showGeolocationConfirmationBottomSheet();
      } else {
        // Address is from GraphQL, proceed directly
        _proceedWithAddAddress();
      }
    } else {
      // Show validation errors
      _showValidationErrors();
    }
  }

  void _showGeolocationConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5C9A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 32,
                  color: Color(0xFFFF5C9A),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Confirm Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                'The address was fetched from your current location and might not be accurate. Please review and confirm if you want to proceed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _proceedWithAddAddress();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5C9A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Yes, Proceed',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Inter',
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
    );
  }

  void _proceedWithAddAddress() async {
    try {
      // Show shimmer loading state
      setState(() => _isSavingAddress = true);

      // Get customer access token
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => _isSavingAddress = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Prepare address data
      final addressData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'address1': _address1Controller.text.trim(),
        'address2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'country': _countryController.text.trim(),
        'zip': _zipController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Add company if provided
      final company = _companyController.text.trim();
      if (company.isNotEmpty) {
        addressData['company'] = company;
      }

      Customer? updatedCustomer;

      // Check if we're updating an existing address or creating a new one
      if (widget.existingAddress != null) {
        // Update existing address
        AppLogger.info('Updating address with data: ${jsonEncode(addressData)}');

        updatedCustomer = await ApiService().customerAddressUpdate(
          customerAccessToken: token,
          addressId: widget.existingAddress!.id!,
          address: addressData,
        );

        AppLogger.success('Address updated successfully');
      } else {
        // Create new address
        AppLogger.info('Creating address with data: ${jsonEncode(addressData)}');

        updatedCustomer = await ApiService().customerAddressCreate(
          customerAccessToken: token,
          address: addressData,
        );

        AppLogger.success('Address created successfully');
      }

      if (updatedCustomer == null) {
        throw Exception(widget.existingAddress != null ? 'Failed to update address' : 'Failed to create address');
      }

      // If "Make this my default address" is checked AND not disabled, update default address
      if (_isDefaultAddress && !_isDefaultAddressDisabled) {
        String? addressIdToSetDefault;

        if (widget.existingAddress != null) {
          // Use the existing address ID
          addressIdToSetDefault = widget.existingAddress!.id;
        } else if (updatedCustomer.addresses.isNotEmpty) {
          // Get the newly created address (last one in the list)
          addressIdToSetDefault = updatedCustomer.addresses.last.id;
        }

        if (addressIdToSetDefault != null) {
          AppLogger.info('Setting as default address: $addressIdToSetDefault');
          await ApiService().customerDefaultAddressUpdate(
            customerAccessToken: token,
            addressId: addressIdToSetDefault,
          );
          AppLogger.success('Default address updated successfully');
        }
      } else if (_isDefaultAddressDisabled) {
        AppLogger.info('Skipping default address update - address is already default');
      }

      if (mounted) {
        setState(() => _isSavingAddress = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingAddress != null ? 'Address updated successfully' : 'Address added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate based on source
        if (widget.isAddingNew || widget.existingAddress != null) {
          // Coming from address list screen - go back to address list
          Navigator.pop(context, true); // Return true to indicate success
        } else if (widget.sourceScreen == 'product_details') {
          // Coming from product details screen - go back to product details
          Navigator.pop(context, updatedCustomer); // Return updated customer
        } else if (widget.sourceScreen == 'order_summary') {
          // Coming from order summary screen - go back to order summary
          Navigator.pop(context, updatedCustomer); // Return updated customer
        } else {
          // Coming from cart screen - navigate to order summary
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSummaryScreen(
                customer: updatedCustomer,
              ),
            ),
            (route) => route.isFirst, // Keep only the first route (home screen)
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error ${widget.existingAddress != null ? 'updating' : 'adding'} address: $e');

      if (mounted) {
        setState(() => _isSavingAddress = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.existingAddress != null ? 'update' : 'add'} address: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showValidationErrors() {
    final address1 = _address1Controller.text.trim();
    final address2 = _address2Controller.text.trim();
    final city = _cityController.text.trim();
    final province = _provinceController.text.trim();
    final country = _countryController.text.trim();
    final zip = _zipController.text.trim();
    final phone = _phoneController.text.trim();

    FocusNode? firstErrorFocusNode;

    setState(() {
      // Validate Address Line 1
      if (address1.isEmpty) {
        _address1Error = 'Address Line 1 is required';
        firstErrorFocusNode ??= _address1FocusNode;
      } else if (address1.length > 100) {
        _address1Error = 'Must be 100 characters or less';
        firstErrorFocusNode ??= _address1FocusNode;
      } else {
        _address1Error = null;
      }

      // Validate Address Line 2
      if (address2.isEmpty) {
        _address2Error = 'Address Line 2 is required';
        firstErrorFocusNode ??= _address2FocusNode;
      } else if (address2.length > 100) {
        _address2Error = 'Must be 100 characters or less';
        firstErrorFocusNode ??= _address2FocusNode;
      } else {
        _address2Error = null;
      }

      // Validate City
      if (city.isEmpty) {
        _cityError = 'City is required';
        firstErrorFocusNode ??= _cityFocusNode;
      } else if (city.length > 30) {
        _cityError = 'Must be 30 characters or less';
        firstErrorFocusNode ??= _cityFocusNode;
      } else {
        _cityError = null;
      }

      // Validate Province
      if (province.isEmpty) {
        _provinceError = 'State/Province is required';
        firstErrorFocusNode ??= _provinceFocusNode;
      } else {
        _provinceError = null;
      }

      // Validate Country
      if (country.isEmpty) {
        _countryError = 'Country is required';
        firstErrorFocusNode ??= _countryFocusNode;
      } else if (country.length > 30) {
        _countryError = 'Must be 30 characters or less';
        firstErrorFocusNode ??= _countryFocusNode;
      } else {
        _countryError = null;
      }

      // Validate ZIP
      if (zip.isEmpty) {
        _zipError = 'ZIP/Postal Code is required';
        firstErrorFocusNode ??= _zipFocusNode;
      } else if (zip.length != 6) {
        _zipError = 'Invalid pincode';
        firstErrorFocusNode ??= _zipFocusNode;
      } else {
        _zipError = null;
      }

      // Validate Phone
      if (phone.isEmpty) {
        _phoneError = 'Phone number is required';
        firstErrorFocusNode ??= _phoneFocusNode;
      } else if (phone.length != 10) {
        _phoneError = 'Must be exactly 10 digits';
        firstErrorFocusNode ??= _phoneFocusNode;
      } else {
        _phoneError = null;
      }
    });

    // Focus on first error field and scroll to it
    if (firstErrorFocusNode != null) {
      firstErrorFocusNode?.requestFocus();
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    _address1FocusNode.dispose();
    _address2FocusNode.dispose();
    _cityFocusNode.dispose();
    _provinceFocusNode.dispose();
    _countryFocusNode.dispose();
    _zipFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

    try {
      // Fetch current location first
      await _fetchCurrentLocation();

      // If customer object is passed, use it
      if (widget.customer != null) {
        _customer = widget.customer;
        AppLogger.info('Customer object from previous screen: ${jsonEncode({
          'id': _customer?.id,
          'firstName': _customer?.firstName,
          'lastName': _customer?.lastName,
          'email': _customer?.email,
          'phone': _customer?.phone,
          'defaultAddress': _customer?.defaultAddress != null
              ? {
                  'id': _customer?.defaultAddress?.id,
                  'name': _customer?.defaultAddress?.name,
                  'firstName': _customer?.defaultAddress?.firstName,
                  'lastName': _customer?.defaultAddress?.lastName,
                  'address1': _customer?.defaultAddress?.address1,
                  'address2': _customer?.defaultAddress?.address2,
                  'city': _customer?.defaultAddress?.city,
                  'province': _customer?.defaultAddress?.province,
                  'country': _customer?.defaultAddress?.country,
                  'zip': _customer?.defaultAddress?.zip,
                  'company': _customer?.defaultAddress?.company,
                  'phone': _customer?.defaultAddress?.phone,
                }
              : null,
          'addresses': _customer?.addresses
              .map((addr) => {
                    'id': addr.id,
                    'name': addr.name,
                    'firstName': addr.firstName,
                    'lastName': addr.lastName,
                    'address1': addr.address1,
                    'address2': addr.address2,
                    'city': addr.city,
                    'province': addr.province,
                    'country': addr.country,
                    'zip': addr.zip,
                    'company': addr.company,
                    'phone': addr.phone,
                  })
              .toList(),
        })}');

        // Populate fields
        _populateFields();
      } else {
        // Fetch customer data
        await _fetchCustomerData();
      }
    } catch (e) {
      AppLogger.error('Error initializing screen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCustomerData() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login first')),
          );
          Navigator.pop(context);
        }
        return;
      }

      _customer = await ApiService().getCustomer(token);

      if (_customer != null) {
        AppLogger.info('Customer object from API: ${jsonEncode({
          'id': _customer?.id,
          'firstName': _customer?.firstName,
          'lastName': _customer?.lastName,
          'email': _customer?.email,
          'phone': _customer?.phone,
          'defaultAddress': _customer?.defaultAddress != null
              ? {
                  'id': _customer?.defaultAddress?.id,
                  'name': _customer?.defaultAddress?.name,
                  'firstName': _customer?.defaultAddress?.firstName,
                  'lastName': _customer?.defaultAddress?.lastName,
                  'address1': _customer?.defaultAddress?.address1,
                  'address2': _customer?.defaultAddress?.address2,
                  'city': _customer?.defaultAddress?.city,
                  'province': _customer?.defaultAddress?.province,
                  'country': _customer?.defaultAddress?.country,
                  'zip': _customer?.defaultAddress?.zip,
                  'company': _customer?.defaultAddress?.company,
                  'phone': _customer?.defaultAddress?.phone,
                }
              : null,
          'addresses': _customer?.addresses
              .map((addr) => {
                    'id': addr.id,
                    'name': addr.name,
                    'firstName': addr.firstName,
                    'lastName': addr.lastName,
                    'address1': addr.address1,
                    'address2': addr.address2,
                    'city': addr.city,
                    'province': addr.province,
                    'country': addr.country,
                    'zip': addr.zip,
                    'company': addr.company,
                    'phone': addr.phone,
                  })
              .toList(),
        })}');

        // Populate fields
        _populateFields();
      }
    } catch (e) {
      AppLogger.error('Error fetching customer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _populateFields() {
    if (_customer == null) return;

    final firstName = _customer!.firstName ?? '';
    final lastName = _customer!.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Populate user info fields
    _fullNameController.text = fullName;
    _firstNameController.text = firstName;
    _lastNameController.text = lastName;
    _emailController.text = _customer!.email ?? '';

    // If editing an existing address, populate with that address data
    if (widget.existingAddress != null) {
      AppLogger.info('Editing existing address - populating fields');
      final addr = widget.existingAddress!;

      _address1Controller.text = addr.address1 ?? '';
      _address2Controller.text = addr.address2 ?? '';
      _cityController.text = addr.city ?? '';
      _provinceController.text = addr.province ?? '';
      _countryController.text = addr.country ?? '';
      _zipController.text = addr.zip ?? '';
      _companyController.text = addr.company ?? '';
      _phoneController.text = _extractLast10Digits(addr.phone);

      // Check if this is the default address
      final isDefault = addr.id == _customer!.defaultAddress?.id;

      setState(() {
        _isDefaultAddress = isDefault;
        _isDefaultAddressDisabled = isDefault; // Disable checkbox if already default
        _isAddressFromGeolocation = false;
      });

      AppLogger.info('Address default status: isDefault=$isDefault, disabled=$isDefault');

      // Validate form after populating fields
      _validateForm();
      return;
    }

    // If this is for adding a new address, leave all address fields empty
    if (widget.isAddingNew) {
      AppLogger.info('Adding new address - leaving address fields empty');
      setState(() {
        _isDefaultAddress = false;
        _isDefaultAddressDisabled = false; // Enable checkbox for new addresses
        _isAddressFromGeolocation = false;
      });
      return;
    }

    // Check if default address exists
    final defaultAddr = _customer!.defaultAddress;

    // If defaultAddress is null, use geolocation
    if (defaultAddr == null) {
      AppLogger.info('Default address is null, using geolocation');
      _populateFromGeolocation();

      setState(() {
        _isDefaultAddress = false;
        _isDefaultAddressDisabled = false; // Enable checkbox for geolocation addresses
        _isAddressFromGeolocation = true;
      });
      return;
    }

    // Check if default address has valid data for the 5 key fields
    final hasValidDefaultAddress = _isAddressFieldValid(defaultAddr.address1) &&
        _isAddressFieldValid(defaultAddr.address2) &&
        _isAddressFieldValid(defaultAddr.city) &&
        _isAddressFieldValid(defaultAddr.province) &&
        _isAddressFieldValid(defaultAddr.zip);

    if (hasValidDefaultAddress) {
      // Populate from default address
      _address1Controller.text = defaultAddr.address1 ?? '';
      _address2Controller.text = defaultAddr.address2 ?? '';
      _cityController.text = defaultAddr.city ?? '';
      _provinceController.text = defaultAddr.province ?? '';
      _countryController.text = defaultAddr.country ?? '';
      _zipController.text = defaultAddr.zip ?? '';
      _companyController.text = defaultAddr.company ?? '';
      _phoneController.text = _extractLast10Digits(defaultAddr.phone);

      // Set checkbox to true if there's a default address
      setState(() {
        _isDefaultAddress = true;
        _isDefaultAddressDisabled = false; // Enable checkbox for valid default address (user can uncheck)
        _isAddressFromGeolocation = false; // Address from GraphQL
      });
    } else {
      // Populate from geolocation if available
      _populateFromGeolocation();

      // Set checkbox to false since we're creating a new address
      setState(() {
        _isDefaultAddress = false;
        _isAddressFromGeolocation = true; // Address from geolocation
      });
    }

    // Validate form after populating fields
    _validateForm();
  }

  /// Check if an address field has valid (non-null, non-empty) value
  bool _isAddressFieldValid(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Extract last 10 digits from phone number (removes country code like +91)
  String _extractLast10Digits(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Remove all non-numeric characters
    final numericOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Return last 10 digits
    if (numericOnly.length >= 10) {
      return numericOnly.substring(numericOnly.length - 10);
    }

    return numericOnly;
  }

  /// Populate address fields from geolocation data
  void _populateFromGeolocation() {
    if (_currentPlacemark == null) {
      AppLogger.warning('No geolocation data available for address population');
      return;
    }

    final place = _currentPlacemark!;

    // Populate Address Line 1 (street)
    if (place.street != null && place.street!.isNotEmpty) {
      _address1Controller.text = place.street!;
    }

    // Populate Address Line 2 (subLocality or thoroughfare)
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      _address2Controller.text = place.subLocality!;
    } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      _address2Controller.text = place.thoroughfare!;
    }

    // Populate City (locality)
    if (place.locality != null && place.locality!.isNotEmpty) {
      _cityController.text = place.locality!;
    }

    // Populate State/Province (administrativeArea)
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      _provinceController.text = place.administrativeArea!;
    }

    // Populate Country
    if (place.country != null && place.country!.isNotEmpty) {
      _countryController.text = place.country!;
    }

    // Populate ZIP/Postal Code
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      _zipController.text = place.postalCode!;
    }

    AppLogger.success('Address fields populated from geolocation');
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocationName = 'Location services disabled';
          _currentLocationAddress = 'Please enable location services';
          _isFetchingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocationName = 'Location permission denied';
            _currentLocationAddress = 'Please grant location permission';
            _isFetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocationName = 'Location permission denied';
          _currentLocationAddress = 'Please enable location in settings';
          _isFetchingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Store placemark for later use
        _currentPlacemark = place;

        // Extract location name (area/locality)
        _currentLocationName = place.subLocality ?? place.locality ?? 'Current Location';

        // Build full address
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        _currentLocationAddress = addressParts.join(', ');

        if (_currentLocationAddress.isEmpty) {
          _currentLocationAddress = '${position.latitude}, ${position.longitude}';
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching location: $e');
      setState(() {
        _currentLocationName = 'Unable to fetch location';
        _currentLocationAddress = 'Please try again';
      });
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          type: AppBarType.simple,
          title: widget.existingAddress != null ? 'Update Address' : 'Add Address',
        ),
        body: _isLoading || _isSavingAddress
            ? _buildLoadingShimmer()
            : Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          SizedBox(height: 8),

                          // Current Location Section
                          _buildCurrentLocationSection(),

                          SizedBox(height: 8),

                          // User Information Form
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User Information Section
                                _buildTextField(
                                  controller: _fullNameController,
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                  enabled: false,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  hint: 'Enter your first name',
                                  enabled: false,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  hint: 'Enter your last name',
                                  enabled: false,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: false,
                                ),

                                SizedBox(height: 24),

                                // Address Information Section
                                _buildTextField(
                                  controller: _address1Controller,
                                  label: 'Address Line 1',
                                  hint: 'Enter address line 1',
                                  maxLength: 100,
                                  focusNode: _address1FocusNode,
                                  errorText: _address1Error,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _address2Controller,
                                  label: 'Address Line 2',
                                  hint: 'Enter address line 2',
                                  maxLength: 100,
                                  focusNode: _address2FocusNode,
                                  errorText: _address2Error,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _cityController,
                                  label: 'City',
                                  hint: 'Enter city',
                                  maxLength: 30,
                                  focusNode: _cityFocusNode,
                                  errorText: _cityError,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _provinceController,
                                  label: 'State/Province',
                                  hint: 'Enter state or province',
                                  focusNode: _provinceFocusNode,
                                  errorText: _provinceError,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _countryController,
                                  label: 'Country',
                                  hint: 'Enter country',
                                  maxLength: 30,
                                  focusNode: _countryFocusNode,
                                  errorText: _countryError,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _zipController,
                                  label: 'ZIP/Postal Code',
                                  hint: 'Enter ZIP or postal code',
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  focusNode: _zipFocusNode,
                                  errorText: _zipError,
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _companyController,
                                  label: 'Company (Optional)',
                                  hint: 'Enter company name',
                                ),
                                SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  hint: 'Enter phone number',
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  focusNode: _phoneFocusNode,
                                  errorText: _phoneError,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),

                                SizedBox(height: 24),

                                // Make Default Address Checkbox
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2, // Increase checkbox size
                                      child: Checkbox(
                                        value: _isDefaultAddress,
                                        onChanged: _isDefaultAddressDisabled 
                                            ? null // Disable checkbox if already default
                                            : (value) {
                                                setState(() {
                                                  _isDefaultAddress = value ?? false;
                                                });
                                              },
                                        activeColor: _isDefaultAddressDisabled
                                            ? Color(0xFFFF5C9A).withOpacity(0.4) // Faded pink for disabled
                                            : const Color(0xFFFF5C9A), // Full pink for enabled
                                        checkColor: Colors.white,
                                        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return _isDefaultAddressDisabled
                                                ? Color(0xFFFF5C9A).withOpacity(0.4) // Faded pink for disabled
                                                : const Color(0xFFFF5C9A); // Full pink for enabled
                                          }
                                          return Colors.transparent;
                                        }),
                                        side: WidgetStateBorderSide.resolveWith((states) {
                                          return BorderSide(
                                            color: _isDefaultAddressDisabled
                                                ? Color(0xFFFF5C9A).withOpacity(0.4) // Faded pink border for disabled
                                                : const Color(0xFFFF5C9A), // Full pink border for enabled
                                            width: 2.w,
                                          );
                                        }),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(3.r),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Make this my default address', // Keep same text for both states
                                        style: TextStyle(
                                          fontSize: 12.fSize,
                                          fontWeight: FontWeight.w500,
                                          color: _isDefaultAddressDisabled 
                                              ? Colors.black.withOpacity(0.5) // Faded text for disabled
                                              : Colors.black, // Full black for enabled
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fixed bottom button
                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: _handleAddAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid ? Color(0xFFFF5C9A) : const Color(0xFFFF5C9A).withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Color(0xFFFF5C9A).withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.existingAddress != null ? 'Update Address' : 'Add Address',
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int? maxLength,
    FocusNode? focusNode,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.fSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLength: maxLength,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          textCapitalization: TextCapitalization.words,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
            // Hide counter
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12.fSize,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
                width: 1.w,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
                width: 1.w,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.r),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Color(0xFFFF5C9A),
                width: 2.w,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4),
          Text(
            errorText,
            style: TextStyle(
              fontSize: 10.fSize,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentLocationSection() {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Container(
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
          children: [
            Row(
              children: [
                // Location Icon
                Container(
                  width: 41.w,
                  height: 41.h,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF5C9A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Color(0xFFFF5C9A),
                    size: 20.h,
                  ),
                ),

                SizedBox(width: 12),

                // Location Details
                Expanded(
                  child: _isFetchingLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 102.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 12.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLocationName.isNotEmpty ? _currentLocationName : 'Fetching location...',
                              style: TextStyle(
                                fontSize: 14.fSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _currentLocationAddress.isNotEmpty ? _currentLocationAddress : 'Please wait...',
                              style: TextStyle(
                                fontSize: 12.fSize,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),

                SizedBox(width: 12),

                // Retry Button
                IconButton(
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  icon: Icon(
                    Icons.refresh,
                    color: _isFetchingLocation ? Colors.grey.shade400 : const Color(0xFFFF5C9A),
                    size: 20.h,
                  ),
                  tooltip: 'Refresh location',
                  splashRadius: 24,
                ),
              ],
            ),

            // Use this location text
            if (_currentPlacemark != null && !_isFetchingLocation) ...[
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    _populateFromGeolocation();
                    // Mark as geolocation address when manually triggered
                    setState(() {
                      _isAddressFromGeolocation = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address fields populated from current location'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Use this location',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF5C9A),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFFF5C9A),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 8),

          // Location card shimmer
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 68.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Form fields shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              children: List.generate(12, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 85.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        SizedBox(height: 8),
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
                  ),
                );
              }),
            ),
          ),

          // Checkbox shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                children: [
                  Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 153.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // Button shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }
}
