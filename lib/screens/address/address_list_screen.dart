import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import '../../config/app_theme.dart';
import '../../widgets/loading_widget.dart';
import 'address_form_screen.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelecting;
  final Function(Address)? onAddressSelected;

  const AddressListScreen({
    super.key,
    this.isSelecting = false,
    this.onAddressSelected,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  void _loadAddresses() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentCustomer?.id != null) {
      context.read<AddressProvider>().fetchAddresses(authProvider.currentCustomer!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Select Address' : 'My Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddressForm(null),
          ),
        ],
      ),
      body: Consumer<AddressProvider>(
        builder: (context, addressProvider, child) {
          if (addressProvider.isLoading) {
            return const LoadingWidget(message: 'Loading addresses...');
          }

          if (addressProvider.addresses.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadAddresses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addressProvider.addresses.length,
              itemBuilder: (context, index) {
                final address = addressProvider.addresses[index];
                return _buildAddressCard(address, addressProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddressForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses saved',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address for faster checkout',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddressForm(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address, AddressProvider addressProvider) {
    final isSelected = addressProvider.selectedAddress?.id == address.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected && widget.isSelecting
            ? BorderSide(color: AppTheme.accentBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.isSelecting
            ? () {
                addressProvider.selectAddress(address);
                widget.onAddressSelected?.call(address);
                Navigator.pop(context);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          address.alias ?? 'Address',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isSelecting)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, address),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (widget.isSelecting && isSelected)
                    Icon(Icons.check_circle, color: AppTheme.accentBlue),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${address.firstName} ${address.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                address.address1,
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (address.address2 != null && address.address2!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  address.address2!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${address.city}, ${address.postcode}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                address.country ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (address.phone != null && address.phone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      address.phone!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Address address) async {
    switch (action) {
      case 'edit':
        _navigateToAddressForm(address);
        break;
      case 'delete':
        _showDeleteConfirmation(address);
        break;
    }
  }

  void _showDeleteConfirmation(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.alias}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AddressProvider>().deleteAddress(address.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete address: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddressForm(Address? address) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(address: address),
      ),
    );

    if (result == true && mounted) {
      _loadAddresses();
    }
  }
}
