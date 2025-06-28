import 'user_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  pickedUp,
  inProgress,
  ready,
  outForDelivery,
  delivered,
  cancelled
}

enum ServiceType {
  washAndFold,
  dryCleaning,
  both
}

class OrderModel {
  final String id;
  final String userId;
  final ServiceType serviceType;
  final List<OrderItem> items;
  final AddressModel pickupAddress;
  final AddressModel deliveryAddress;
  final DateTime requestedPickupDate;
  final DateTime? requestedDeliveryDate;
  final OrderStatus status;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final String paymentMethodId;
  final String? stripePaymentIntentId;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? completedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.requestedPickupDate,
    this.requestedDeliveryDate,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethodId,
    this.stripePaymentIntentId,
    this.specialInstructions,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceType': serviceType.name,
      'items': items.map((item) => item.toMap()).toList(),
      'pickupAddress': pickupAddress.toMap(),
      'deliveryAddress': deliveryAddress.toMap(),
      'requestedPickupDate': requestedPickupDate.toIso8601String(),
      'requestedDeliveryDate': requestedDeliveryDate?.toIso8601String(),
      'status': status.name,
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentMethodId': paymentMethodId,
      'stripePaymentIntentId': stripePaymentIntentId,
      'specialInstructions': specialInstructions,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == map['serviceType'],
        orElse: () => ServiceType.washAndFold,
      ),
      items: List<OrderItem>.from(
        map['items']?.map((item) => OrderItem.fromMap(item)) ?? [],
      ),
      pickupAddress: AddressModel.fromMap(map['pickupAddress']),
      deliveryAddress: AddressModel.fromMap(map['deliveryAddress']),
      requestedPickupDate: DateTime.parse(map['requestedPickupDate']),
      requestedDeliveryDate: map['requestedDeliveryDate'] != null
          ? DateTime.parse(map['requestedDeliveryDate'])
          : null,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      paymentMethodId: map['paymentMethodId'] ?? '',
      stripePaymentIntentId: map['stripePaymentIntentId'],
      specialInstructions: map['specialInstructions'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double pricePerItem;
  final ServiceType serviceType;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.pricePerItem,
    required this.serviceType,
  });

  double get totalPrice => quantity * pricePerItem;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'pricePerItem': pricePerItem,
      'serviceType': serviceType.name,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      pricePerItem: (map['pricePerItem'] ?? 0.0).toDouble(),
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == map['serviceType'],
        orElse: () => ServiceType.washAndFold,
      ),
    );
  }
}