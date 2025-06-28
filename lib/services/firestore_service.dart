import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _orders => _firestore.collection('orders');
  CollectionReference get _addresses => _firestore.collection('addresses');
  CollectionReference get _paymentMethods => _firestore.collection('payment_methods');

  // User Management
  Future<void> createUser(UserModel user) async {
    try {
      await _users.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _users.doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _users.doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Order Management
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _orders.add(order.toMap());
      
      // Update the order with the generated ID
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _orders.doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  Future<void> updateOrder(OrderModel order) async {
    try {
      await _orders.doc(order.id).update(order.toMap());
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _orders.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Stream<List<OrderModel>> getUserOrdersStream(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<List<OrderModel>> getUserOrders(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _orders
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Address Management
  Future<String> saveAddress(String userId, AddressModel address) async {
    try {
      final docRef = await _addresses.add({
        ...address.toMap(),
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  Future<List<AddressModel>> getUserAddresses(String userId) async {
    try {
      final snapshot = await _addresses
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AddressModel.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user addresses: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _addresses.doc(addressId).delete();
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Payment Methods Management
  Future<String> savePaymentMethod(String userId, Map<String, dynamic> paymentMethodData) async {
    try {
      final docRef = await _paymentMethods.add({
        ...paymentMethodData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save payment method: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserPaymentMethods(String userId) async {
    try {
      final snapshot = await _paymentMethods
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user payment methods: $e');
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _paymentMethods.doc(paymentMethodId).delete();
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Analytics and Statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final ordersSnapshot = await _orders
          .where('userId', isEqualTo: userId)
          .get();

      final orders = ordersSnapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      double totalSpent = 0;
      int completedOrders = 0;
      
      for (final order in orders) {
        totalSpent += order.total;
        if (order.status == OrderStatus.delivered) {
          completedOrders++;
        }
      }

      return {
        'totalOrders': orders.length,
        'completedOrders': completedOrders,
        'totalSpent': totalSpent,
        'averageOrderValue': orders.isNotEmpty ? totalSpent / orders.length : 0,
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  // Batch Operations
  Future<void> batchUpdateOrders(List<OrderModel> orders) async {
    try {
      final batch = _firestore.batch();
      
      for (final order in orders) {
        final docRef = _orders.doc(order.id);
        batch.update(docRef, order.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update orders: $e');
    }
  }

  // Search and Filtering
  Future<List<OrderModel>> searchOrders(String userId, {
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    ServiceType? serviceType,
  }) async {
    try {
      Query query = _orders.where('userId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (serviceType != null) {
        query = query.where('serviceType', isEqualTo: serviceType.name);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }
}