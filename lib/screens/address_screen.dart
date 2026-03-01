import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../utils/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import 'order_summary_screen.dart';

class AddressScreen extends StatefulWidget {
  final Customer? customer;

  const AddressScreen({
    super.key,
    this.customer,
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
    
    final isValid = isAddress1Valid &&
                    isAddress2Valid &&
                    isCityValid &&
                    isProvinceValid &&
                    isCountryValid &&
                    isZipValid &&
                    isPhoneValid;
    
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }
  
  void _handleAddAddress() {
    if (_isFormValid) {
      // If address is from geolocation, show confirmation dialog
      if (_isAddressFromGeolocation) {
        _showGeolocationConfirmationDialog();
      } else {
        // Address is from GraphQL, proceed directly
        _proceedWithAddAddress();
      }
    } else {
      // Show validation errors
      _showValidationErrors();
    }
  }
  
  void _showGeolocationConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'The address was fetched from your current location and might not be accurate. Do you want to proceed?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          actions: [
            // No button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'No',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Yes button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedWithAddAddress();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Yes, No Issue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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

      debugPrint('✅ Creating address with data:');
      debugPrint(jsonEncode(addressData));

      // Create address
      final updatedCustomer = await ApiService().customerAddressCreate(
        customerAccessToken: token,
        address: addressData,
      );

      if (updatedCustomer == null) {
        throw Exception('Failed to create address');
      }

      debugPrint('✅ Address created successfully');

      // If "Make this my default address" is checked, update default address
      if (_isDefaultAddress && updatedCustomer.addresses.isNotEmpty) {
        // Get the newly created address (last one in the list)
        final newAddressId = updatedCustomer.addresses.last.id;
        if (newAddressId != null) {
          debugPrint('🔄 Setting as default address: $newAddressId');
          await ApiService().customerDefaultAddressUpdate(
            customerAccessToken: token,
            addressId: newAddressId,
          );
          debugPrint('✅ Default address updated successfully');
        }
      }

      if (mounted) {
        setState(() => _isSavingAddress = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to OrderSummaryScreen and remove both address and cart screens from stack
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
    } catch (e) {
      debugPrint('❌ Error adding address: $e');
      
      if (mounted) {
        setState(() => _isSavingAddress = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add address: ${e.toString()}'),
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
        debugPrint('Customer object from previous screen:');
        debugPrint(jsonEncode({
          'id': _customer?.id,
          'firstName': _customer?.firstName,
          'lastName': _customer?.lastName,
          'email': _customer?.email,
          'phone': _customer?.phone,
          'defaultAddress': _customer?.defaultAddress != null ? {
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
          } : null,
          'addresses': _customer?.addresses.map((addr) => {
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
          }).toList(),
        }));
        
        // Populate fields
        _populateFields();
      } else {
        // Fetch customer data
        await _fetchCustomerData();
      }
    } catch (e) {
      debugPrint('Error initializing screen: $e');
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
        debugPrint('Customer object from API:');
        debugPrint(jsonEncode({
          'id': _customer?.id,
          'firstName': _customer?.firstName,
          'lastName': _customer?.lastName,
          'email': _customer?.email,
          'phone': _customer?.phone,
          'defaultAddress': _customer?.defaultAddress != null ? {
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
          } : null,
          'addresses': _customer?.addresses.map((addr) => {
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
          }).toList(),
        }));
        
        // Populate fields
        _populateFields();
      }
    } catch (e) {
      debugPrint('Error fetching customer: $e');
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
    
    // Check if default address exists
    final defaultAddr = _customer!.defaultAddress;
    
    // If defaultAddress is null, use geolocation
    if (defaultAddr == null) {
      debugPrint('ℹ️ Default address is null, using geolocation');
      _populateFromGeolocation();
      
      setState(() {
        _isDefaultAddress = false;
        _isAddressFromGeolocation = true;
      });
      return;
    }
    
    // Check if default address has valid data for the 5 key fields
    final hasValidDefaultAddress = 
        _isAddressFieldValid(defaultAddr.address1) &&
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
      _phoneController.text = defaultAddr.phone ?? '';
      
      // Set checkbox to true if there's a default address
      setState(() {
        _isDefaultAddress = true;
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
  
  /// Populate address fields from geolocation data
  void _populateFromGeolocation() {
    if (_currentPlacemark == null) {
      debugPrint('No geolocation data available for address population');
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
    
    debugPrint('✅ Address fields populated from geolocation');
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
      debugPrint('Error fetching location: $e');
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
          showDefaultLogo: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Add Address',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: false,
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
                          const SizedBox(height: 8),
                          
                          // Current Location Section
                          _buildCurrentLocationSection(),
                          
                          const SizedBox(height: 8),
                          
                          // User Information Form
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  hint: 'Enter your first name',
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  hint: 'Enter your last name',
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: false,
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Address Information Section
                                _buildTextField(
                                  controller: _address1Controller,
                                  label: 'Address Line 1',
                                  hint: 'Enter address line 1',
                                  maxLength: 100,
                                  focusNode: _address1FocusNode,
                                  errorText: _address1Error,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _address2Controller,
                                  label: 'Address Line 2',
                                  hint: 'Enter address line 2',
                                  maxLength: 100,
                                  focusNode: _address2FocusNode,
                                  errorText: _address2Error,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _cityController,
                                  label: 'City',
                                  hint: 'Enter city',
                                  maxLength: 30,
                                  focusNode: _cityFocusNode,
                                  errorText: _cityError,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _provinceController,
                                  label: 'State/Province',
                                  hint: 'Enter state or province',
                                  focusNode: _provinceFocusNode,
                                  errorText: _provinceError,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _countryController,
                                  label: 'Country',
                                  hint: 'Enter country',
                                  maxLength: 30,
                                  focusNode: _countryFocusNode,
                                  errorText: _countryError,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _zipController,
                                  label: 'ZIP/Postal Code',
                                  hint: 'Enter ZIP or postal code',
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  focusNode: _zipFocusNode,
                                  errorText: _zipError,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _companyController,
                                  label: 'Company (Optional)',
                                  hint: 'Enter company name',
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  hint: 'Enter phone number',
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  focusNode: _phoneFocusNode,
                                  errorText: _phoneError,
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Make Default Address Checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isDefaultAddress,
                                      onChanged: (value) {
                                        setState(() {
                                          _isDefaultAddress = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFFFF5C9A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const Text(
                                      'Make this my default address',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleAddAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid 
                  ? const Color(0xFFFF5C9A) 
                  : const Color(0xFFFF5C9A).withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFF5C9A).withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Address',
              style: TextStyle(
                fontSize: 16,
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
  }) {
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLength: maxLength,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
            // Hide counter
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFFFF5C9A),
                width: 2,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentLocationSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Location Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C9A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFFF5C9A),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Location Details
                Expanded(
                  child: _isFetchingLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLocationName.isNotEmpty
                                  ? _currentLocationName
                                  : 'Fetching location...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLocationAddress.isNotEmpty
                                  ? _currentLocationAddress
                                  : 'Please wait...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                
                const SizedBox(width: 12),
                
                // Retry Button
                IconButton(
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  icon: Icon(
                    Icons.refresh,
                    color: _isFetchingLocation 
                        ? Colors.grey.shade400 
                        : const Color(0xFFFF5C9A),
                    size: 24,
                  ),
                  tooltip: 'Refresh location',
                  splashRadius: 24,
                ),
              ],
            ),
            
            // Use this location text
            if (_currentPlacemark != null && !_isFetchingLocation) ...[
              const SizedBox(height: 12),
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
                      fontSize: 13,
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
          const SizedBox(height: 8),
          
          // Location card shimmer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Form fields shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(12, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                  ),
                );
              }),
            ),
          ),
          
          // Checkbox shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Button shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
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
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
