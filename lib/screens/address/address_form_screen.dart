import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/address.dart';
import '../../models/country.dart';
import '../../models/ps_state.dart';
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

  Country? _selectedCountry;
  PsState? _selectedState;

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

    // Load countries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCountries();
    });
  }

  Future<void> _loadCountries() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.fetchCountries();

    // Set initial country if editing
    if (widget.address?.countryId != null && locationProvider.countries.isNotEmpty) {
      final country = locationProvider.getCountryById(widget.address!.countryId!);
      if (country != null) {
        setState(() {
          _selectedCountry = country;
        });

        // Load states for this country
        if (country.containsStates) {
          await locationProvider.fetchStatesByCountry(country.id);
          if (widget.address?.stateId != null) {
            final state = locationProvider.getStateById(widget.address!.stateId!);
            if (state != null) {
              setState(() {
                _selectedState = state;
              });
            }
          }
        }
      }
    } else if (locationProvider.countries.isNotEmpty) {
      // Default to first country
      setState(() {
        _selectedCountry = locationProvider.countries.first;
      });
      if (_selectedCountry!.containsStates) {
        await locationProvider.fetchStatesByCountry(_selectedCountry!.id);
      }
    }
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

    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a country'),
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
      country: _selectedCountry!.name,
      countryId: _selectedCountry!.id,
      state: _selectedState?.name,
      stateId: _selectedState?.id,
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
      body: Consumer2<AddressProvider, LocationProvider>(
        builder: (context, addressProvider, locationProvider, child) {
          if (addressProvider.isLoading) {
            return const LoadingWidget(message: 'Saving address...');
          }

          if (locationProvider.isLoading && locationProvider.countries.isEmpty) {
            return const LoadingWidget(message: 'Loading countries...');
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
                  DropdownButtonFormField<Country>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: locationProvider.countries.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country.name),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedCountry = value;
                        _selectedState = null;
                      });

                      if (value != null && value.containsStates) {
                        await locationProvider.fetchStatesByCountry(value.id);
                      } else {
                        locationProvider.clearStates();
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Country is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // State (if country has states)
                  if (_selectedCountry?.containsStates == true && locationProvider.states.isNotEmpty)
                    DropdownButtonFormField<PsState>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State/Region',
                        prefixIcon: Icon(Icons.map),
                      ),
                      items: locationProvider.states.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedCountry?.containsStates == true && value == null) {
                          return 'State is required';
                        }
                        return null;
                      },
                    ),
                  if (_selectedCountry?.containsStates == true)
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
}
