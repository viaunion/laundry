import 'package:flutter/foundation.dart';
import '../services/stripe_service.dart';
import '../services/firestore_service.dart';

class PaymentProvider extends ChangeNotifier {
  final StripeService _stripeService = StripeService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isProcessingPayment = false;
  String? _paymentError;
  List<SavedPaymentMethod> _savedPaymentMethods = [];

  bool get isProcessingPayment => _isProcessingPayment;
  String? get paymentError => _paymentError;
  List<SavedPaymentMethod> get savedPaymentMethods => _savedPaymentMethods;

  /// Process a payment for an order
  Future<PaymentResult> processOrderPayment({
    required double amount,
    required String orderId,
    required String userId,
    String? customerId,
  }) async {
    _setProcessingPayment(true);
    _clearError();

    try {
      final result = await _stripeService.processPayment(
        amount: amount,
        currency: 'usd',
        customerId: customerId,
        metadata: {
          'order_id': orderId,
          'user_id': userId,
          'type': 'laundry_order',
        },
      );

      if (result.success) {
        // Save payment information to Firestore
        await _savePaymentRecord(
          userId: userId,
          orderId: orderId,
          paymentIntentId: result.paymentIntentId!,
          amount: amount,
        );
      }

      return result;
    } catch (e) {
      _setError('Payment processing failed: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
        errorCode: 'processing_error',
      );
    } finally {
      _setProcessingPayment(false);
    }
  }

  /// Save a payment method for future use
  Future<PaymentMethodSaveResult> savePaymentMethod({
    required String userId,
    String? customerId,
  }) async {
    _setProcessingPayment(true);
    _clearError();

    try {
      final result = await _stripeService.savePaymentMethod(
        customerId: customerId,
        metadata: {
          'user_id': userId,
          'type': 'saved_payment_method',
        },
      );

      if (result.success) {
        // Refresh saved payment methods
        await loadSavedPaymentMethods(userId);
      }

      return result;
    } catch (e) {
      _setError('Failed to save payment method: $e');
      return PaymentMethodSaveResult(
        success: false,
        error: e.toString(),
        errorCode: 'save_error',
      );
    } finally {
      _setProcessingPayment(false);
    }
  }

  /// Load saved payment methods for a user
  Future<void> loadSavedPaymentMethods(String userId) async {
    try {
      final paymentMethods = await _firestoreService.getUserPaymentMethods(userId);
      
      _savedPaymentMethods = paymentMethods.map((pm) {
        return SavedPaymentMethod(
          id: pm['id'] ?? '',
          type: pm['type'] ?? 'card',
          last4: pm['last4'] ?? '',
          brand: pm['brand'] ?? '',
          isDefault: pm['isDefault'] ?? false,
          stripePaymentMethodId: pm['stripePaymentMethodId'],
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load payment methods: $e');
    }
  }

  /// Create a Stripe customer for a user
  Future<String?> createStripeCustomer({
    required String email,
    required String name,
    required String userId,
  }) async {
    try {
      final customer = await _stripeService.createCustomer(
        email: email,
        name: name,
        metadata: {
          'user_id': userId,
          'app': 'laundry_pro',
        },
      );

      if (customer != null) {
        final customerId = customer['id'];
        
        // Save customer ID to user record in Firestore
        await _saveCustomerIdToUser(userId, customerId);
        
        return customerId;
      }
    } catch (e) {
      _setError('Failed to create customer: $e');
    }
    return null;
  }

  /// Save payment record to Firestore
  Future<void> _savePaymentRecord({
    required String userId,
    required String orderId,
    required String paymentIntentId,
    required double amount,
  }) async {
    try {
      await _firestoreService.savePaymentMethod(userId, {
        'type': 'payment_record',
        'order_id': orderId,
        'stripe_payment_intent_id': paymentIntentId,
        'amount': amount,
        'currency': 'usd',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving payment record: $e');
    }
  }

  /// Save Stripe customer ID to user record
  Future<void> _saveCustomerIdToUser(String userId, String customerId) async {
    try {
      await _firestoreService.updateUserData(userId, {
        'stripeCustomerId': customerId,
      });
      print('Stripe customer created: $customerId for user: $userId');
    } catch (e) {
      print('Error saving customer ID: $e');
    }
  }

  /// Delete a saved payment method
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _firestoreService.deletePaymentMethod(paymentMethodId);
      _savedPaymentMethods.removeWhere((pm) => pm.id == paymentMethodId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete payment method: $e');
      return false;
    }
  }

  /// Set the default payment method
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      // Update all payment methods to not be default
      for (var pm in _savedPaymentMethods) {
        pm.isDefault = pm.id == paymentMethodId;
      }
      
      // Here you would update the database as well
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to set default payment method: $e');
      return false;
    }
  }

  void _setProcessingPayment(bool processing) {
    _isProcessingPayment = processing;
    notifyListeners();
  }

  void _setError(String error) {
    _paymentError = error;
    notifyListeners();
  }

  void _clearError() {
    _paymentError = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}

class SavedPaymentMethod {
  final String id;
  final String type;
  final String last4;
  final String brand;
  bool isDefault;
  final String? stripePaymentMethodId;

  SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.isDefault,
    this.stripePaymentMethodId,
  });
}