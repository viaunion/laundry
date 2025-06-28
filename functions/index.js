const {onCall} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY || "sk_test_51Rf081E94pb9ZFdYafvLDxp9trxAZJJfFMrnKc8ewUqEWa8bZfyd2nHOGuwT0iUIFuMHMJi5PJLwQzV0P50qSlFl00g2nq8Olw");
const logger = require("firebase-functions/logger");

admin.initializeApp();
const db = admin.firestore();

// Create Stripe customer when user is created
exports.createStripeCustomer = onDocumentCreated("users/{userId}", async (event) => {
  const userData = event.data.data();
  const userId = event.params.userId;

  try {
    const customer = await stripe.customers.create({
      email: userData.email,
      name: userData.name,
      metadata: {
        firebaseUID: userId,
      },
    });

    await db.collection("users").doc(userId).update({
      stripeCustomerId: customer.id,
    });

    logger.info(`Created Stripe customer ${customer.id} for user ${userId}`);
  } catch (error) {
    logger.error("Error creating Stripe customer:", error);
  }
});

// Shared function to calculate pricing
async function calculatePricing(serviceType, items) {
  // Validate items based on service type
  if (serviceType === "dry-cleaning") {
    if (!items.dryCleanItems || items.dryCleanItems.length === 0) {
      throw new Error("Please select at least one item for dry cleaning");
    }
  } else {
    if (!items.estimatedWeight || items.estimatedWeight <= 0) {
      throw new Error("Please enter a valid weight for your laundry");
    }
  }

  // Get current pricing from Firestore
  const pricingDoc = await db.collection("servicePricing").doc("current").get();
  let pricing;
  
  if (!pricingDoc.exists) {
    // Create default pricing if it doesn't exist
    pricing = {
      washFold: {pricePerLb: 1.99},
      expressWashFold: {pricePerLb: 2.99},
      dryCleaningItems: {
        "suit-jacket": 11.99,
        "leather": 11.99,
        "furs": 11.99,
        "dress-gown": 11.99,
        "shirt": 11.99,
        "pants": 11.99,
        "sweater": 11.99,
        "other": 11.99,
      },
    };
    await db.collection("servicePricing").doc("current").set(pricing);
  } else {
    pricing = pricingDoc.data();
  }

  let subtotal = 0;

  switch (serviceType) {
    case "wash-fold":
      subtotal = items.estimatedWeight * pricing.washFold.pricePerLb;
      break;
    case "express-wash-fold":
      subtotal = items.estimatedWeight * pricing.expressWashFold.pricePerLb;
      break;
    case "dry-cleaning":
      subtotal = items.dryCleanItems.reduce((total, item) => {
        return total + (item.quantity * pricing.dryCleaningItems[item.type]);
      }, 0);
      break;
    default:
      throw new Error("Invalid service type");
  }

  const tax = subtotal * 0.08; // 8% tax rate
  const total = subtotal + tax;

  return {
    subtotal: Math.round(subtotal * 100) / 100,
    tax: Math.round(tax * 100) / 100,
    total: Math.round(total * 100) / 100,
  };
}

// Calculate order pricing
exports.calculateOrderPrice = onCall(async (request) => {
  const {serviceType, items} = request.data;
  
  if (!request.auth) {
    throw new Error("Authentication required");
  }

  try {
    return await calculatePricing(serviceType, items);
  } catch (error) {
    logger.error("Error calculating order price:", error);
    throw new Error(error.message || "Failed to calculate order price");
  }
});

// Create payment intent for orders
exports.createPaymentIntent = onCall(async (request) => {
  const {orderData} = request.data;
  
  if (!request.auth) {
    throw new Error("Authentication required");
  }

  try {
    // Get user's Stripe customer ID
    const userDoc = await db.collection("users").doc(request.auth.uid).get();
    if (!userDoc.exists) {
      throw new Error("User not found");
    }

    const userData = userDoc.data();
    let customerId = userData.stripeCustomerId;

    // Create Stripe customer if it doesn't exist
    if (!customerId) {
      logger.info(`Creating Stripe customer for user ${request.auth.uid}`);
      const customer = await stripe.customers.create({
        email: userData.email,
        name: userData.name,
        metadata: {
          firebaseUID: request.auth.uid,
        },
      });

      customerId = customer.id;

      // Update user document with Stripe customer ID
      await db.collection("users").doc(request.auth.uid).update({
        stripeCustomerId: customerId,
      });

      logger.info(`Created Stripe customer ${customerId} for user ${request.auth.uid}`);
    }

    // Calculate pricing using shared function
    const pricingResult = await calculatePricing(orderData.serviceType, orderData.items);

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(pricingResult.total * 100), // Convert to cents
      currency: "usd",
      customer: customerId,
      metadata: {
        userId: request.auth.uid,
        serviceType: orderData.serviceType,
      },
    });

    // Create order in Firestore
    const orderRef = db.collection("orders").doc();
    await orderRef.set({
      ...orderData,
      userId: request.auth.uid,
      status: "pending",
      pricing: pricingResult,
      paymentIntentId: paymentIntent.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      orderId: orderRef.id,
    };
  } catch (error) {
    logger.error("Error creating payment intent:", error);
    logger.error("Error details:", {
      message: error.message,
      stack: error.stack,
      orderData: orderData,
      userId: request.auth.uid
    });
    throw new Error(error.message || "Failed to create payment intent");
  }
});

// Confirm payment and update order status
exports.confirmPayment = onCall(async (request) => {
  const {paymentIntentId, orderId} = request.data;
  
  if (!request.auth) {
    throw new Error("Authentication required");
  }

  try {
    // Retrieve payment intent from Stripe
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status === "succeeded") {
      // Update order status
      await db.collection("orders").doc(orderId).update({
        status: "confirmed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true, status: "confirmed"};
    } else {
      throw new Error("Payment not successful");
    }
  } catch (error) {
    logger.error("Error confirming payment:", error);
    throw new Error("Failed to confirm payment");
  }
});

// Get user orders
exports.getUserOrders = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Authentication required");
  }

  try {
    const ordersSnapshot = await db
        .collection("orders")
        .where("userId", "==", request.auth.uid)
        .orderBy("createdAt", "desc")
        .get();

    const orders = [];
    ordersSnapshot.forEach((doc) => {
      orders.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    return {orders};
  } catch (error) {
    logger.error("Error getting user orders:", error);
    throw new Error("Failed to get user orders");
  }
});
