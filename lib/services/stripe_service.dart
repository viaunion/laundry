import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  // For production, this should be your backend endpoint
  // For demo purposes, we'll use a simple approach
  static const String _baseUrl = 'https://api.stripe.com/v1';
  
  // Note: In production, you should NEVER store the secret key in the app
  // This should be handled by your backend server
  // For development, you need to provide your Stripe secret key
  static const String _secretKey = 'sk_test_51Rf081E94pb9ZFdYafvLDxp9trxAZJJfFMrnKc8ewUqEWa8bZfyd2nHOGuwT0iUIFuMHMJi5PJLwQzV0P50qSlFl00g2nq8Olw';

  /// Create a Payment Intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
    Map<String, String>? metadata,
  }) async {
    try {
      // Convert amount to cents (Stripe works with smallest currency unit)
      final amountInCents = (amount * 100).round();

      final body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
        if (customerId != null) 'customer': customerId,
        if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value)),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// Present Payment Sheet and handle payment
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    String? customerId,
    Map<String, String>? metadata,
  }) async {
    try {
      // Step 1: Create Payment Intent
      final paymentIntentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
        metadata: metadata,
      );

      final clientSecret = paymentIntentData['client_secret'];
      final paymentIntentId = paymentIntentData['id'];

      // Step 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'LaundryPro',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF2196F3), // Blue color
                  text: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );

      // Step 3: Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // If we reach here, payment was successful
      return PaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
        clientSecret: clientSecret,
      );

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult(
          success: false,
          error: 'Payment was canceled by the user',
          errorCode: 'payment_canceled',
        );
      } else {
        return PaymentResult(
          success: false,
          error: e.error.localizedMessage ?? 'Payment failed',
          errorCode: e.error.code.toString(),
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'An unexpected error occurred: $e',
        errorCode: 'unknown_error',
      );
    }
  }

  /// Create a Setup Intent for saving payment methods
  Future<Map<String, dynamic>> createSetupIntent({
    String? customerId,
    Map<String, String>? metadata,
  }) async {
    try {
      final body = <String, String>{
        'usage': 'off_session',
        'automatic_payment_methods[enabled]': 'true',
        if (customerId != null) 'customer': customerId,
        if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value)),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/setup_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create setup intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating setup intent: $e');
    }
  }

  /// Save a payment method for future use
  Future<PaymentMethodSaveResult> savePaymentMethod({
    String? customerId,
    Map<String, String>? metadata,
  }) async {
    try {
      // Step 1: Create Setup Intent
      final setupIntentData = await createSetupIntent(
        customerId: customerId,
        metadata: metadata,
      );

      final clientSecret = setupIntentData['client_secret'];
      final setupIntentId = setupIntentData['id'];

      // Step 2: Initialize Payment Sheet for setup
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'LaundryPro',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF2196F3),
                  text: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );

      // Step 3: Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return PaymentMethodSaveResult(
        success: true,
        setupIntentId: setupIntentId,
        clientSecret: clientSecret,
      );

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentMethodSaveResult(
          success: false,
          error: 'Setup was canceled by the user',
          errorCode: 'setup_canceled',
        );
      } else {
        return PaymentMethodSaveResult(
          success: false,
          error: e.error.localizedMessage ?? 'Failed to save payment method',
          errorCode: e.error.code.toString(),
        );
      }
    } catch (e) {
      return PaymentMethodSaveResult(
        success: false,
        error: 'An unexpected error occurred: $e',
        errorCode: 'unknown_error',
      );
    }
  }

  /// Get payment method details
  Future<Map<String, dynamic>?> getPaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment_methods/$paymentMethodId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting payment method: $e');
      return null;
    }
  }

  /// Create a customer in Stripe
  Future<Map<String, dynamic>?> createCustomer({
    required String email,
    String? name,
    Map<String, String>? metadata,
  }) async {
    try {
      final body = <String, String>{
        'email': email,
        if (name != null) 'name': name,
        if (metadata != null) ...metadata.map((key, value) => MapEntry('metadata[$key]', value)),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error creating customer: $e');
      return null;
    }
  }
}

class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? clientSecret;
  final String? error;
  final String? errorCode;

  PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.clientSecret,
    this.error,
    this.errorCode,
  });
}

class PaymentMethodSaveResult {
  final bool success;
  final String? setupIntentId;
  final String? clientSecret;
  final String? paymentMethodId;
  final String? error;
  final String? errorCode;

  PaymentMethodSaveResult({
    required this.success,
    this.setupIntentId,
    this.clientSecret,
    this.paymentMethodId,
    this.error,
    this.errorCode,
  });
}