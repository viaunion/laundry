import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import 'address_selection_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final ServiceType serviceType;

  const OrderDetailsScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final List<OrderItem> _items = [];
  final _specialInstructionsController = TextEditingController();
  DateTime _selectedPickupDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _selectedDeliveryDate;

  final Map<ServiceType, List<ItemOption>> _itemOptions = {
    ServiceType.washAndFold: [
      ItemOption(name: 'Shirts', price: 1.50, icon: Icons.checkroom),
      ItemOption(name: 'Pants', price: 2.00, icon: Icons.checkroom),
      ItemOption(name: 'Dresses', price: 3.50, icon: Icons.checkroom),
      ItemOption(name: 'Jeans', price: 2.50, icon: Icons.checkroom),
      ItemOption(name: 'T-Shirts', price: 1.25, icon: Icons.checkroom),
      ItemOption(name: 'Sweaters', price: 3.00, icon: Icons.checkroom),
      ItemOption(name: 'Shorts', price: 1.75, icon: Icons.checkroom),
      ItemOption(name: 'Underwear (per piece)', price: 0.75, icon: Icons.checkroom),
      ItemOption(name: 'Socks (per pair)', price: 0.50, icon: Icons.checkroom),
      ItemOption(name: 'Bedsheets (per set)', price: 8.00, icon: Icons.bed),
      ItemOption(name: 'Towels', price: 2.25, icon: Icons.checkroom),
    ],
    ServiceType.dryCleaning: [
      ItemOption(name: 'Suit (2 piece)', price: 15.99, icon: Icons.work),
      ItemOption(name: 'Suit (3 piece)', price: 22.99, icon: Icons.work),
      ItemOption(name: 'Dress Shirt', price: 4.99, icon: Icons.checkroom),
      ItemOption(name: 'Blouse', price: 6.99, icon: Icons.checkroom),
      ItemOption(name: 'Dress', price: 12.99, icon: Icons.checkroom),
      ItemOption(name: 'Coat/Jacket', price: 18.99, icon: Icons.checkroom),
      ItemOption(name: 'Tie', price: 3.99, icon: Icons.checkroom),
      ItemOption(name: 'Skirt', price: 7.99, icon: Icons.checkroom),
      ItemOption(name: 'Pants (dress)', price: 8.99, icon: Icons.checkroom),
      ItemOption(name: 'Wedding Dress', price: 89.99, icon: Icons.checkroom),
      ItemOption(name: 'Comforter', price: 25.99, icon: Icons.bed),
    ],
  };

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemOptions[widget.serviceType] ?? [];
    final subtotal = _calculateSubtotal();
    final tax = subtotal * 0.08; // 8% tax
    final deliveryFee = 4.99;
    final total = subtotal + tax + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serviceType == ServiceType.washAndFold
              ? 'Wash & Fold Details'
              : 'Dry Cleaning Details',
        ),
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
                  // Items Selection
                  const Text(
                    'Select Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...items.map((itemOption) {
                    final existingItem = _items.firstWhere(
                      (item) => item.name == itemOption.name,
                      orElse: () => OrderItem(
                        name: '',
                        quantity: 0,
                        pricePerItem: 0,
                        serviceType: widget.serviceType,
                      ),
                    );
                    final quantity = existingItem.name.isNotEmpty ? existingItem.quantity : 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              itemOption.icon,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemOption.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '\$${itemOption.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: quantity > 0
                                      ? () => _updateItemQuantity(itemOption, quantity - 1)
                                      : null,
                                  icon: const Icon(Icons.remove),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    quantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _updateItemQuantity(itemOption, quantity + 1),
                                  icon: const Icon(Icons.add),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.shade100,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Schedule Section
                  const Text(
                    'Pickup & Delivery Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.schedule, color: Colors.blue),
                            title: const Text('Pickup Date'),
                            subtitle: Text(
                              '${_selectedPickupDate.day}/${_selectedPickupDate.month}/${_selectedPickupDate.year}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _selectPickupDate,
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.local_shipping, color: Colors.blue),
                            title: const Text('Delivery Date'),
                            subtitle: Text(
                              _selectedDeliveryDate != null
                                  ? '${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}'
                                  : 'Same day as pickup (if ready)',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _selectDeliveryDate,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Special Instructions
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _specialInstructionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Any special instructions for handling your items...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Order Summary
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
                    Text('\$${subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax:'),
                    Text('\$${tax.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee:'),
                    Text('\$${deliveryFee.toStringAsFixed(2)}'),
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
                      '\$${total.toStringAsFixed(2)}',
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
                  onPressed: _items.isNotEmpty ? _continueToAddress : null,
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
                    'Continue to Address',
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
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _updateItemQuantity(ItemOption itemOption, int newQuantity) {
    setState(() {
      if (newQuantity == 0) {
        _items.removeWhere((item) => item.name == itemOption.name);
      } else {
        final existingIndex = _items.indexWhere((item) => item.name == itemOption.name);
        final newItem = OrderItem(
          name: itemOption.name,
          quantity: newQuantity,
          pricePerItem: itemOption.price,
          serviceType: widget.serviceType,
        );

        if (existingIndex >= 0) {
          _items[existingIndex] = newItem;
        } else {
          _items.add(newItem);
        }
      }
    });
  }

  Future<void> _selectPickupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedPickupDate = picked;
      });
    }
  }

  Future<void> _selectDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? _selectedPickupDate.add(const Duration(days: 1)),
      firstDate: _selectedPickupDate,
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  void _continueToAddress() {
    if (_items.isNotEmpty) {
      final subtotal = _calculateSubtotal();
      final tax = subtotal * 0.08;
      final deliveryFee = 4.99;
      final total = subtotal + tax + deliveryFee;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddressSelectionScreen(
            serviceType: widget.serviceType,
            items: _items,
            subtotal: subtotal,
            tax: tax,
            deliveryFee: deliveryFee,
            total: total,
            pickupDate: _selectedPickupDate,
            deliveryDate: _selectedDeliveryDate,
            specialInstructions: _specialInstructionsController.text.trim(),
          ),
        ),
      );
    }
  }
}

class ItemOption {
  final String name;
  final double price;
  final IconData icon;

  ItemOption({
    required this.name,
    required this.price,
    required this.icon,
  });
}