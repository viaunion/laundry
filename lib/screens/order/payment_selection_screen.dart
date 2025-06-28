import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/payment_provider.dart';
import 'order_confirmation_screen.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final ServiceType serviceType;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final DateTime pickupDate;
  final DateTime? deliveryDate;
  final String specialInstructions;
  final AddressModel pickupAddress;
  final AddressModel deliveryAddress;

  const PaymentSelectionScreen({
    super.key,
    required this.serviceType,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    required this.pickupDate,
    this.deliveryDate,
    required this.specialInstructions,
    required this.pickupAddress,
    required this.deliveryAddress,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String? _selectedPaymentMethod;
  bool _useNewCard = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
    });
  }

  void _loadPaymentMethods() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      paymentProvider.loadSavedPaymentMethods(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, DataProvider, PaymentProvider>(
      builder: (context, authProvider, dataProvider, paymentProvider, child) {
        final savedPaymentMethods = paymentProvider.savedPaymentMethods;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Payment Method'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Order Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    widget.serviceType == ServiceType.washAndFold
                                        ? Icons.local_laundry_service
                                        : Icons.dry_cleaning,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.serviceType == ServiceType.washAndFold
                                        ? 'Wash & Fold'
                                        : 'Dry Cleaning',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.items.length} items • \$${widget.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pickup: ${widget.pickupDate.day}/${widget.pickupDate.month}/${widget.pickupDate.year}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Payment Methods
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _saveNewPaymentMethod(paymentProvider, authProvider),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // New Card Option (always available)
                      _buildNewCardOption(),

                      // Saved Payment Methods
                      if (savedPaymentMethods.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Saved Payment Methods',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...savedPaymentMethods.map((method) => _buildSavedPaymentMethodCard(method)),
                      ],

                      const SizedBox(height: 24),

                      // Security Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secure Payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Your payment information is encrypted and secure.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Payment Summary and Continue Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${widget.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax:'),
                        Text('\$${widget.tax.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee:'),
                        Text('\$${widget.deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: !paymentProvider.isProcessingPayment 
                          ? () => _placeOrderWithStripe(paymentProvider, dataProvider, authProvider) 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: paymentProvider.isProcessingPayment
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _placeOrderWithStripe(
    PaymentProvider paymentProvider,
    DataProvider dataProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null) return;

    try {
      // Process payment with Stripe
      final paymentResult = await paymentProvider.processOrderPayment(
        amount: widget.total,
        orderId: 'temp_order_id', // Will be updated after order creation
        userId: authProvider.user!.uid,
        customerId: authProvider.userModel?.stripeCustomerId,
      );

      if (!paymentResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.error ?? 'Payment failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create order after successful payment
      final order = OrderModel(
        id: '', // Will be set by Firestore
        userId: authProvider.user!.uid,
        serviceType: widget.serviceType,
        items: widget.items,
        pickupAddress: widget.pickupAddress,
        deliveryAddress: widget.deliveryAddress,
        requestedPickupDate: widget.pickupDate,
        requestedDeliveryDate: widget.deliveryDate,
        status: OrderStatus.pending,
        subtotal: widget.subtotal,
        tax: widget.tax,
        deliveryFee: widget.deliveryFee,
        total: widget.total,
        paymentMethodId: paymentResult.paymentIntentId ?? 'stripe_payment',
        specialInstructions: widget.specialInstructions.isNotEmpty 
            ? widget.specialInstructions 
            : null,
        createdAt: DateTime.now(),
      );

      final orderId = await dataProvider.createOrder(order);

      if (orderId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderId,
              orderTotal: widget.total,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNewCardOption() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _useNewCard = true;
          _selectedPaymentMethod = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _useNewCard ? Colors.blue : Colors.grey.shade300,
            width: _useNewCard ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _useNewCard ? Colors.blue.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_card,
              color: _useNewCard ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Pay with new card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_useNewCard)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPaymentMethodCard(SavedPaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method.id;
          _useNewCard = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: _getBrandColor(method.brand),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    method.brand.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '•••• •••• •••• ${method.last4}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${method.brand} ending in ${method.last4}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
        return const Color(0xFF006FCF);
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveNewPaymentMethod(
    PaymentProvider paymentProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null) return;

    try {
      // Create Stripe customer if not exists
      String? customerId = authProvider.userModel?.stripeCustomerId;
      customerId ??= await paymentProvider.createStripeCustomer(
        email: authProvider.user!.email!,
        name: '${authProvider.userModel?.firstName ?? ''} ${authProvider.userModel?.lastName ?? ''}'.trim(),
        userId: authProvider.user!.uid,
      );

      if (customerId != null) {
        final result = await paymentProvider.savePaymentMethod(
          userId: authProvider.user!.uid,
          customerId: customerId,
        );

        if (result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh payment methods
          _loadPaymentMethods();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to save payment method'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}