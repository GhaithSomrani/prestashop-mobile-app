import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import '../../config/app_theme.dart';
import '../../widgets/loading_widget.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address;

  const AddressFormScreen({
    super.key,
    this.address,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _postcodeController;
  late TextEditingController _phoneController;
  String _selectedCountry = 'United States';
  String? _selectedState;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    final customer = context.read<AuthProvider>().currentCustomer;

    _aliasController = TextEditingController(text: address?.alias ?? 'Home');
    _firstNameController = TextEditingController(
      text: address?.firstName ?? customer?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: address?.lastName ?? customer?.lastName ?? '',
    );
    _address1Controller = TextEditingController(text: address?.address1 ?? '');
    _address2Controller = TextEditingController(text: address?.address2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _postcodeController = TextEditingController(text: address?.postcode ?? '');
    _phoneController = TextEditingController(
      text: address?.phone ?? customer?.phone ?? '',
    );
    _selectedCountry = address?.country ?? 'United States';
    _selectedState = address?.state;
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();

    if (authProvider.currentCustomer?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to save address'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final address = Address(
      id: widget.address?.id,
      customerId: authProvider.currentCustomer!.id!,
      alias: _aliasController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      address1: _address1Controller.text,
      address2: _address2Controller.text.isNotEmpty ? _address2Controller.text : null,
      city: _cityController.text,
      postcode: _postcodeController.text,
      country: _selectedCountry,
      state: _selectedState,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );

    try {
      if (isEditing) {
        await addressProvider.updateAddress(address);
      } else {
        await addressProvider.createAddress(address);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Address updated' : 'Address added'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        actions: [
          TextButton(
            onPressed: _saveAddress,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          if (addressProvider.isLoading) {
            return const LoadingWidget(message: 'Saving address...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alias
                  TextFormField(
                    controller: _aliasController,
                    decoration: const InputDecoration(
                      labelText: 'Address Name',
                      hintText: 'e.g., Home, Office',
                      prefixIcon: Icon(Icons.bookmark),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address Line 1
                  TextFormField(
                    controller: _address1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 1',
                      hintText: 'Street address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address Line 2
                  TextFormField(
                    controller: _address2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 2 (Optional)',
                      hintText: 'Apt, suite, unit, building, floor',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // City and Postcode
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'City is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _postcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Postcode',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Country
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: _countries.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value!;
                        _selectedState = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // State (for US)
                  if (_selectedCountry == 'United States')
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map),
                      ),
                      items: _usStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedCountry == 'United States' && (value == null || value.isEmpty)) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone (Optional)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditing ? 'Update Address' : 'Save Address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'France',
    'Germany',
    'Spain',
    'Italy',
    'Netherlands',
    'Belgium',
    'Australia',
  ];

  static const List<String> _usStates = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming',
  ];
}
