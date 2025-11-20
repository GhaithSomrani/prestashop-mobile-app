import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/carrier_provider.dart';
import '../../models/customer.dart';
import '../../models/address.dart';
import '../../config/app_theme.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/currency_formatter.dart';
import '../address/address_list_screen.dart';
import 'order_confirmation_screen.dart';

class EnhancedCheckoutScreen extends StatefulWidget {
  const EnhancedCheckoutScreen({super.key});

  @override
  State<EnhancedCheckoutScreen> createState() => _EnhancedCheckoutScreenState();
}

class _EnhancedCheckoutScreenState extends State<EnhancedCheckoutScreen> {
  int _currentStep = 0;
  String _selectedPayment = 'ps_cashondelivery';

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'ps_cashondelivery', 'name': 'Paiement comptant à la livraison', 'icon': Icons.money},
    {'id': 'ps_checkpayment', 'name': 'Chèque', 'icon': Icons.receipt_long},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.currentCustomer?.id != null) {
      context.read<AddressProvider>().fetchAddresses(authProvider.currentCustomer!.id!);
    }
    context.read<CarrierProvider>().fetchCarriers();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();
    final carrierProvider = context.read<CarrierProvider>();

    final selectedAddress = addressProvider.selectedAddress;
    final selectedCarrier = carrierProvider.selectedCarrier;

    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address')),
      );
      return;
    }

    if (selectedCarrier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping method')),
      );
      return;
    }

    final customer = authProvider.currentCustomer ?? Customer(
      firstName: selectedAddress.firstName,
      lastName: selectedAddress.lastName,
      email: 'guest@example.com',
    );

    try {
      await orderProvider.createOrder(
        customer: customer,
        shippingAddress: selectedAddress,
        items: cart.items,
        carrierId: selectedCarrier.id,
        paymentMethod: _selectedPayment,
        shippingCost: selectedCarrier.price,
      );

      cart.clearCart();
      cart.clearVouchers();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderConfirmationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
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
        title: const Text('Checkout'),
      ),
      body: Consumer4<CartProvider, AddressProvider, CarrierProvider, OrderProvider>(
        builder: (context, cart, addressProvider, carrierProvider, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const LoadingWidget(message: 'Processing order...');
          }

          final shippingCost = carrierProvider.selectedCarrier?.price ?? 0;
          final subtotal = cart.subtotal;
          final discount = cart.totalDiscount;
          final total = subtotal - discount + shippingCost;

          return Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _placeOrder();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Shipping Address
              Step(
                title: const Text('Shipping Address'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildAddressStep(addressProvider),
              ),

              // Step 2: Shipping Method
              Step(
                title: const Text('Shipping Method'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildCarrierStep(carrierProvider),
              ),

              // Step 3: Payment & Review
              Step(
                title: const Text('Payment & Review'),
                isActive: _currentStep >= 2,
                content: _buildPaymentStep(cart, addressProvider, carrierProvider, subtotal, discount, shippingCost, total),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressStep(AddressProvider addressProvider) {
    if (addressProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    if (addressProvider.addresses.isEmpty) {
      return Column(
        children: [
          const Text('No saved addresses found'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressListScreen(),
                ),
              );
              _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...addressProvider.addresses.map((address) {
          final isSelected = addressProvider.selectedAddress?.id == address.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isSelected
                  ? BorderSide(color: AppTheme.accentBlue, width: 2)
                  : BorderSide.none,
            ),
            child: RadioListTile<String>(
              value: address.id ?? '',
              groupValue: addressProvider.selectedAddress?.id ?? '',
              onChanged: (value) {
                addressProvider.selectAddress(address);
              },
              title: Text(
                address.alias ?? 'Address',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${address.firstName} ${address.lastName}\n${address.address1}\n${address.city}, ${address.postcode}',
              ),
              isThreeLine: true,
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddressListScreen(),
              ),
            );
            _loadData();
          },
          icon: const Icon(Icons.edit),
          label: const Text('Manage Addresses'),
        ),
      ],
    );
  }

  Widget _buildCarrierStep(CarrierProvider carrierProvider) {
    if (carrierProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    if (carrierProvider.carriers.isEmpty) {
      return const Text('No shipping methods available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: carrierProvider.carriers.map((carrier) {
        final isSelected = carrierProvider.selectedCarrier?.id == carrier.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? BorderSide(color: AppTheme.accentBlue, width: 2)
                : BorderSide.none,
          ),
          child: RadioListTile<String>(
            value: carrier.id,
            groupValue: carrierProvider.selectedCarrier?.id ?? '',
            onChanged: (value) {
              carrierProvider.selectCarrier(carrier);
            },
            title: Text(
              carrier.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(carrier.deliveryTime),
            secondary: Text(
              CurrencyFormatter.formatTND(carrier.price),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStep(
    CartProvider cart,
    AddressProvider addressProvider,
    CarrierProvider carrierProvider,
    double subtotal,
    double discount,
    double shippingCost,
    double total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Methods
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...(_paymentMethods.map((method) {
          return RadioListTile<String>(
            value: method['id'],
            groupValue: _selectedPayment,
            onChanged: (value) {
              setState(() => _selectedPayment = value!);
            },
            title: Text(method['name']),
            secondary: Icon(method['icon']),
          );
        })),
        const Divider(height: 32),

        // Order Summary
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Address Summary
        if (addressProvider.selectedAddress != null) ...[
          _buildSummaryItem(
            'Ship to',
            addressProvider.selectedAddress!.fullAddress,
          ),
          const SizedBox(height: 8),
        ],

        // Carrier Summary
        if (carrierProvider.selectedCarrier != null) ...[
          _buildSummaryItem(
            'Shipping',
            '${carrierProvider.selectedCarrier!.name} - ${carrierProvider.selectedCarrier!.deliveryTime}',
          ),
          const SizedBox(height: 8),
        ],

        const Divider(),

        // Totals
        _buildTotalRow('Subtotal (${cart.itemCount} items)', CurrencyFormatter.formatTND(subtotal)),
        if (discount > 0)
          _buildTotalRow('Discount', '-${CurrencyFormatter.formatTND(discount)}', isDiscount: true),
        _buildTotalRow('Shipping', CurrencyFormatter.formatTND(shippingCost)),
        if (cart.hasVouchers)
          ...cart.appliedVouchers.map((v) => _buildTotalRow(
            'Voucher: ${v.cartRule.code}',
            '-${CurrencyFormatter.formatTND(v.discountAmount)}',
            isDiscount: true,
          )),
        const Divider(),
        _buildTotalRow('Total', CurrencyFormatter.formatTND(total), isBold: true),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : (isBold ? AppTheme.accentBlue : null),
            ),
          ),
        ],
      ),
    );
  }
}
