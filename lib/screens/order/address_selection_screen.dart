import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import 'payment_selection_screen.dart';
import 'add_address_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  final ServiceType serviceType;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final DateTime pickupDate;
  final DateTime? deliveryDate;
  final String specialInstructions;

  const AddressSelectionScreen({
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
  });

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  AddressModel? _selectedPickupAddress;
  AddressModel? _selectedDeliveryAddress;
  bool _sameAddress = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAddresses();
    });
  }

  void _loadUserAddresses() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      dataProvider.loadUserAddresses(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DataProvider>(
      builder: (context, authProvider, dataProvider, child) {
        final addresses = dataProvider.addresses;
        final user = authProvider.userModel;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Addresses'),
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
                      // Pickup Address Section
                      Row(
                        children: [
                          const Icon(Icons.home, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Pickup Address',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _addNewAddress(true),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (user?.defaultAddress != null)
                        _buildAddressCard(
                          user!.defaultAddress!,
                          isSelected: _selectedPickupAddress == user.defaultAddress,
                          onSelect: () {
                            setState(() {
                              _selectedPickupAddress = user.defaultAddress;
                              if (_sameAddress) {
                                _selectedDeliveryAddress = user.defaultAddress;
                              }
                            });
                          },
                          isDefault: true,
                        ),

                      ...addresses.where((addr) => addr != user?.defaultAddress).map(
                        (address) => _buildAddressCard(
                          address,
                          isSelected: _selectedPickupAddress == address,
                          onSelect: () {
                            setState(() {
                              _selectedPickupAddress = address;
                              if (_sameAddress) {
                                _selectedDeliveryAddress = address;
                              }
                            });
                          },
                        ),
                      ),

                      if (addresses.isEmpty && user?.defaultAddress == null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No addresses yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _addNewAddress(true),
                                  child: const Text('Add Address'),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Same Address Toggle
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _sameAddress,
                                onChanged: (value) {
                                  setState(() {
                                    _sameAddress = value ?? true;
                                    if (_sameAddress) {
                                      _selectedDeliveryAddress = _selectedPickupAddress;
                                    } else {
                                      _selectedDeliveryAddress = null;
                                    }
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Use same address for delivery',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Delivery Address Section
                      if (!_sameAddress) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _addNewAddress(false),
                              icon: const Icon(Icons.add),
                              label: const Text('Add New'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (user?.defaultAddress != null)
                          _buildAddressCard(
                            user!.defaultAddress!,
                            isSelected: _selectedDeliveryAddress == user.defaultAddress,
                            onSelect: () {
                              setState(() {
                                _selectedDeliveryAddress = user.defaultAddress;
                              });
                            },
                            isDefault: true,
                          ),

                        ...addresses.where((addr) => addr != user?.defaultAddress).map(
                          (address) => _buildAddressCard(
                            address,
                            isSelected: _selectedDeliveryAddress == address,
                            onSelect: () {
                              setState(() {
                                _selectedDeliveryAddress = address;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Continue Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _canContinue() ? _continueToPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressCard(
    AddressModel address, {
    required bool isSelected,
    required VoidCallback onSelect,
    bool isDefault = false,
  }) {
    return GestureDetector(
      onTap: onSelect,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
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
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                ],
              ),
              if (isDefault) const SizedBox(height: 8),
              Text(
                address.fullAddress,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (address.instructions != null && address.instructions!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Instructions: ${address.instructions}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    if (_sameAddress) {
      return _selectedPickupAddress != null;
    } else {
      return _selectedPickupAddress != null && _selectedDeliveryAddress != null;
    }
  }

  void _addNewAddress(bool isForPickup) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(
          onAddressAdded: (address) {
            setState(() {
              if (isForPickup) {
                _selectedPickupAddress = address;
                if (_sameAddress) {
                  _selectedDeliveryAddress = address;
                }
              } else {
                _selectedDeliveryAddress = address;
              }
            });
          },
        ),
      ),
    );
  }

  void _continueToPayment() {
    if (_canContinue()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentSelectionScreen(
            serviceType: widget.serviceType,
            items: widget.items,
            subtotal: widget.subtotal,
            tax: widget.tax,
            deliveryFee: widget.deliveryFee,
            total: widget.total,
            pickupDate: widget.pickupDate,
            deliveryDate: widget.deliveryDate,
            specialInstructions: widget.specialInstructions,
            pickupAddress: _selectedPickupAddress!,
            deliveryAddress: _selectedDeliveryAddress ?? _selectedPickupAddress!,
          ),
        ),
      );
    }
  }
}