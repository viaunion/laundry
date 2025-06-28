import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

class DataProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _currentUser;
  List<OrderModel> _orders = [];
  List<AddressModel> _addresses = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  Map<String, dynamic> _userStats = {};
  
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  List<OrderModel> get orders => _orders;
  List<AddressModel> get addresses => _addresses;
  List<Map<String, dynamic>> get paymentMethods => _paymentMethods;
  Map<String, dynamic> get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // User Management
  Future<void> loadUserData(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentUser = await _firestoreService.getUser(userId);
      await Future.wait([
        loadUserOrders(userId),
        loadUserAddresses(userId),
        loadUserPaymentMethods(userId),
        loadUserStats(userId),
      ]);
    } catch (e) {
      _setError('Failed to load user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserData(UserModel user) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _firestoreService.updateUser(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update user: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Order Management
  Future<void> loadUserOrders(String userId) async {
    try {
      _orders = await _firestoreService.getUserOrders(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load orders: $e');
    }
  }

  Future<String?> createOrder(OrderModel order) async {
    _setLoading(true);
    _clearError();
    
    try {
      final orderId = await _firestoreService.createOrder(order);
      
      // Add the new order to local list with the generated ID
      final newOrder = OrderModel(
        id: orderId,
        userId: order.userId,
        serviceType: order.serviceType,
        items: order.items,
        pickupAddress: order.pickupAddress,
        deliveryAddress: order.deliveryAddress,
        requestedPickupDate: order.requestedPickupDate,
        requestedDeliveryDate: order.requestedDeliveryDate,
        status: order.status,
        subtotal: order.subtotal,
        tax: order.tax,
        deliveryFee: order.deliveryFee,
        total: order.total,
        paymentMethodId: order.paymentMethodId,
        stripePaymentIntentId: order.stripePaymentIntentId,
        specialInstructions: order.specialInstructions,
        createdAt: order.createdAt,
        completedAt: order.completedAt,
      );
      
      _orders.insert(0, newOrder);
      notifyListeners();
      
      return orderId;
    } catch (e) {
      _setError('Failed to create order: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    _clearError();
    
    try {
      await _firestoreService.updateOrderStatus(orderId, status);
      
      // Update local order
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        final updatedOrder = OrderModel(
          id: _orders[orderIndex].id,
          userId: _orders[orderIndex].userId,
          serviceType: _orders[orderIndex].serviceType,
          items: _orders[orderIndex].items,
          pickupAddress: _orders[orderIndex].pickupAddress,
          deliveryAddress: _orders[orderIndex].deliveryAddress,
          requestedPickupDate: _orders[orderIndex].requestedPickupDate,
          requestedDeliveryDate: _orders[orderIndex].requestedDeliveryDate,
          status: status,
          subtotal: _orders[orderIndex].subtotal,
          tax: _orders[orderIndex].tax,
          deliveryFee: _orders[orderIndex].deliveryFee,
          total: _orders[orderIndex].total,
          paymentMethodId: _orders[orderIndex].paymentMethodId,
          stripePaymentIntentId: _orders[orderIndex].stripePaymentIntentId,
          specialInstructions: _orders[orderIndex].specialInstructions,
          createdAt: _orders[orderIndex].createdAt,
          completedAt: status == OrderStatus.delivered ? DateTime.now() : _orders[orderIndex].completedAt,
        );
        
        _orders[orderIndex] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update order status: $e');
    }
  }

  // Address Management
  Future<void> loadUserAddresses(String userId) async {
    try {
      _addresses = await _firestoreService.getUserAddresses(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load addresses: $e');
    }
  }

  Future<String?> saveAddress(String userId, AddressModel address) async {
    _clearError();
    
    try {
      final addressId = await _firestoreService.saveAddress(userId, address);
      _addresses.insert(0, address);
      notifyListeners();
      return addressId;
    } catch (e) {
      _setError('Failed to save address: $e');
      return null;
    }
  }

  Future<void> deleteAddress(String addressId, AddressModel address) async {
    _clearError();
    
    try {
      await _firestoreService.deleteAddress(addressId);
      _addresses.remove(address);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete address: $e');
    }
  }

  // Payment Methods Management
  Future<void> loadUserPaymentMethods(String userId) async {
    try {
      _paymentMethods = await _firestoreService.getUserPaymentMethods(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load payment methods: $e');
    }
  }

  Future<String?> savePaymentMethod(String userId, Map<String, dynamic> paymentMethodData) async {
    _clearError();
    
    try {
      final paymentMethodId = await _firestoreService.savePaymentMethod(userId, paymentMethodData);
      paymentMethodData['id'] = paymentMethodId;
      _paymentMethods.insert(0, paymentMethodData);
      notifyListeners();
      return paymentMethodId;
    } catch (e) {
      _setError('Failed to save payment method: $e');
      return null;
    }
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    _clearError();
    
    try {
      await _firestoreService.deletePaymentMethod(paymentMethodId);
      _paymentMethods.removeWhere((pm) => pm['id'] == paymentMethodId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete payment method: $e');
    }
  }

  // Statistics
  Future<void> loadUserStats(String userId) async {
    try {
      _userStats = await _firestoreService.getUserStats(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user stats: $e');
    }
  }

  // Search and Filter
  Future<List<OrderModel>> searchOrders({
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    ServiceType? serviceType,
  }) async {
    if (_currentUser == null) return [];
    
    try {
      return await _firestoreService.searchOrders(
        _currentUser!.uid,
        status: status,
        startDate: startDate,
        endDate: endDate,
        serviceType: serviceType,
      );
    } catch (e) {
      _setError('Failed to search orders: $e');
      return [];
    }
  }

  // Real-time listeners
  void startOrdersListener(String userId) {
    _firestoreService.getUserOrdersStream(userId).listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        _setError('Orders listener error: $error');
      },
    );
  }

  void startUserListener(String userId) {
    _firestoreService.getUserStream(userId).listen(
      (user) {
        if (user != null) {
          _currentUser = user;
          notifyListeners();
        }
      },
      onError: (error) {
        _setError('User listener error: $error');
      },
    );
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  void clearData() {
    _currentUser = null;
    _orders.clear();
    _addresses.clear();
    _paymentMethods.clear();
    _userStats.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}