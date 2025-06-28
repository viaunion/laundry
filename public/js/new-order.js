// New order page functionality
let currentOrder = {};
let stripe = null;
let cardElement = null;

// Initialize Stripe
const STRIPE_PUBLISHABLE_KEY = 'pk_test_51Rf081E94pb9ZFdYqRd77yRV96VxUkjeEcVqJB8CDa92Lq1Bj25mGTdVhdnLpQ4pwdgN3SgDDkWvNCiP7yLRA6HV00rZI7OCdy';

document.addEventListener('DOMContentLoaded', function() {
    // Initialize Stripe
    stripe = Stripe(STRIPE_PUBLISHABLE_KEY);
    
    // Ensure user is authenticated
    firebase.auth().onAuthStateChanged(function(user) {
        if (user) {
            initializeOrderForm();
        }
    });
});

function initializeOrderForm() {
    // Service selection
    document.querySelectorAll('.service-option').forEach(option => {
        option.addEventListener('click', selectService);
    });
    
    // Items/Weight
    const estimatedWeight = document.getElementById('estimatedWeight');
    if (estimatedWeight) {
        estimatedWeight.addEventListener('input', updatePricing);
    }
    
    document.querySelectorAll('[data-item]').forEach(input => {
        input.addEventListener('input', updatePricing);
    });
    
    // Pickup date/time
    const pickupDate = document.getElementById('pickupDate');
    if (pickupDate) {
        pickupDate.addEventListener('change', function() {
            console.log('Pickup date changed:', this.value);
            updateDeliveryEstimate();
        });
    }
    
    const pickupTime = document.getElementById('pickupTime');
    if (pickupTime) {
        pickupTime.addEventListener('change', function() {
            console.log('Pickup time changed:', this.value);
            updateDeliveryEstimate();
        });
    }
    
    const continueToPayment = document.getElementById('continueToPayment');
    if (continueToPayment) {
        continueToPayment.addEventListener('click', proceedToPayment);
    }
    
    // Payment
    const submitPayment = document.getElementById('submitPayment');
    if (submitPayment) {
        submitPayment.addEventListener('click', handlePayment);
    }
}

// Service Selection
function selectService(e) {
    // Remove previous selection
    document.querySelectorAll('.service-option').forEach(option => {
        option.classList.remove('selected');
    });
    
    // Add selection to clicked option
    e.currentTarget.classList.add('selected');
    
    const serviceType = e.currentTarget.dataset.service;
    currentOrder.serviceType = serviceType;
    
    // Update items screen based on service type
    updateItemsScreen(serviceType);
    
    // Show items screen
    setTimeout(() => {
        document.getElementById('serviceSection').style.display = 'none';
        document.getElementById('itemsSection').style.display = 'block';
    }, 300);
}

function updateItemsScreen(serviceType) {
    const itemsTitle = document.getElementById('itemsTitle');
    const weightSection = document.getElementById('weightSection');
    const dryCleanSection = document.getElementById('dryCleanSection');
    
    if (serviceType === 'dry-cleaning') {
        itemsTitle.textContent = 'Select Your Items';
        weightSection.style.display = 'none';
        dryCleanSection.style.display = 'block';
    } else {
        itemsTitle.textContent = 'Estimate Your Weight';
        weightSection.style.display = 'block';
        dryCleanSection.style.display = 'none';
    }
    
    // Set minimum date for pickup (tomorrow)
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const minDate = tomorrow.toISOString().split('T')[0];
    document.getElementById('pickupDate').min = minDate;
    
    // Reset pickup date/time fields
    document.getElementById('pickupDate').value = '';
    document.getElementById('pickupTime').value = '';
    document.getElementById('estimatedDelivery').textContent = 'Select pickup date and time';
    
    updatePricing();
}

// Pricing
async function updatePricing() {
    if (!currentOrder.serviceType) return;
    
    try {
        let items = {};
        
        if (currentOrder.serviceType === 'dry-cleaning') {
            const dryCleanItems = [];
            document.querySelectorAll('[data-item]').forEach(input => {
                const quantity = parseInt(input.value) || 0;
                if (quantity > 0) {
                    dryCleanItems.push({
                        type: input.dataset.item,
                        quantity: quantity
                    });
                }
            });
            items.dryCleanItems = dryCleanItems;
        } else {
            const weight = parseFloat(document.getElementById('estimatedWeight').value) || 0;
            items.estimatedWeight = weight;
        }
        
        if ((currentOrder.serviceType === 'dry-cleaning' && items.dryCleanItems.length === 0) ||
            (currentOrder.serviceType !== 'dry-cleaning' && items.estimatedWeight === 0)) {
            // Reset pricing display
            document.getElementById('subtotalAmount').textContent = '$0.00';
            document.getElementById('taxAmount').textContent = '$0.00';
            document.getElementById('totalAmount').textContent = '$0.00';
            return;
        }
        
        // Call Firebase function to calculate pricing
        const calculateOrderPrice = firebase.functions().httpsCallable('calculateOrderPrice');
        const result = await calculateOrderPrice({
            serviceType: currentOrder.serviceType,
            items: items
        });
        
        const pricing = result.data;
        currentOrder.items = items;
        currentOrder.pricing = pricing;
        
        // Update UI
        document.getElementById('subtotalAmount').textContent = `$${pricing.subtotal.toFixed(2)}`;
        document.getElementById('taxAmount').textContent = `$${pricing.tax.toFixed(2)}`;
        document.getElementById('totalAmount').textContent = `$${pricing.total.toFixed(2)}`;
        
    } catch (error) {
        console.error('Error calculating pricing:', error);
    }
}

// Pickup Date/Time Management
function updateDeliveryEstimate() {
    const pickupDate = document.getElementById('pickupDate').value;
    const pickupTime = document.getElementById('pickupTime').value;
    const estimatedDeliveryElement = document.getElementById('estimatedDelivery');
    
    if (!pickupDate || !pickupTime) {
        estimatedDeliveryElement.textContent = 'Select pickup date and time';
        return;
    }
    
    // Create pickup datetime
    const pickupDateTime = new Date(`${pickupDate}T${pickupTime}:00`);
    
    // Calculate delivery time based on service type
    let deliveryDateTime = new Date(pickupDateTime);
    if (currentOrder.serviceType === 'express-wash-fold') {
        // 24 hours later for express
        deliveryDateTime.setHours(deliveryDateTime.getHours() + 24);
    } else {
        // 48 hours later for standard services
        deliveryDateTime.setHours(deliveryDateTime.getHours() + 48);
    }
    
    // Store pickup and delivery times in current order
    currentOrder.pickupDateTime = pickupDateTime.toISOString();
    currentOrder.deliveryDateTime = deliveryDateTime.toISOString();
    
    // Format and display delivery estimate
    const deliveryDateStr = deliveryDateTime.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
    const deliveryTimeStr = deliveryDateTime.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    });
    
    estimatedDeliveryElement.textContent = `${deliveryDateStr} at ${deliveryTimeStr}`;
}

// Payment
async function proceedToPayment() {
    console.log('proceedToPayment called, currentOrder.serviceType:', currentOrder.serviceType);
    
    // Validate items/weight based on service type
    if (currentOrder.serviceType === 'dry-cleaning') {
        const dryCleanItems = [];
        document.querySelectorAll('[data-item]').forEach(input => {
            const quantity = parseInt(input.value) || 0;
            if (quantity > 0) {
                dryCleanItems.push({
                    type: input.dataset.item,
                    quantity: quantity
                });
            }
        });
        
        console.log('Dry clean items:', dryCleanItems);
        
        if (dryCleanItems.length === 0) {
            alert('Please select at least one item for dry cleaning.');
            return;
        }
        
        // Update current order items for dry cleaning
        currentOrder.items = { dryCleanItems: dryCleanItems };
    } else {
        const weightElement = document.getElementById('estimatedWeight');
        const weightValue = weightElement ? weightElement.value : '';
        const weight = parseFloat(weightValue) || 0;
        
        console.log('Weight element:', weightElement);
        console.log('Weight value from element:', weightValue);
        console.log('Parsed weight:', weight);
        
        if (!weightElement) {
            alert('Weight input field not found. Please refresh the page and try again.');
            return;
        }
        
        if (!weightValue || weightValue.trim() === '') {
            alert('Please enter the estimated weight for your laundry.');
            return;
        }
        
        if (weight <= 0 || isNaN(weight)) {
            alert('Please enter a valid weight greater than 0 for your laundry.');
            return;
        }
        
        // Update current order items for wash & fold
        currentOrder.items = { estimatedWeight: weight };
    }
    
    // Validate that pricing has been calculated and items are stored
    if (!currentOrder.items || !currentOrder.pricing || currentOrder.pricing.total === 0) {
        alert('Please wait for pricing to be calculated or ensure you have entered valid items/weight.');
        return;
    }
    
    // Validate pickup date and time
    const pickupDate = document.getElementById('pickupDate').value;
    const pickupTime = document.getElementById('pickupTime').value;
    
    if (!pickupDate || !pickupTime) {
        alert('Please select a pickup date and time.');
        return;
    }
    
    // Validate pickup date is not in the past
    const pickupDateTime = new Date(`${pickupDate}T${pickupTime}:00`);
    const now = new Date();
    
    if (pickupDateTime <= now) {
        alert('Please select a pickup date and time in the future.');
        return;
    }
    
    // Get user's default address
    try {
        const userDoc = await firebase.firestore().collection('users').doc(currentUser.uid).get();
        const userData = userDoc.data();
        
        currentOrder.pickupAddress = userData.defaultAddress;
        currentOrder.deliveryAddress = userData.defaultAddress;
        
        // Update order summary
        updateOrderSummary();
        
        // Initialize Stripe Elements
        initializeStripeElements();
        
        // Show payment section
        document.getElementById('itemsSection').style.display = 'none';
        document.getElementById('paymentSection').style.display = 'block';
    } catch (error) {
        console.error('Error loading user data:', error);
        alert('Error loading user information. Please try again.');
    }
}

function updateOrderSummary() {
    const orderSummary = document.getElementById('orderSummary');
    const serviceNames = {
        'wash-fold': 'Wash & Fold',
        'express-wash-fold': 'Express Wash & Fold',
        'dry-cleaning': 'Dry Cleaning'
    };
    
    let itemsText = '';
    if (currentOrder.serviceType === 'dry-cleaning') {
        itemsText = currentOrder.items.dryCleanItems.map(item => 
            `${item.quantity}x ${item.type.replace('-', ' ')}`
        ).join(', ');
    } else {
        itemsText = `${currentOrder.items.estimatedWeight} lbs`;
    }
    
    // Format pickup and delivery times
    const pickupDateTime = new Date(currentOrder.pickupDateTime);
    const deliveryDateTime = new Date(currentOrder.deliveryDateTime);
    
    const pickupDateStr = pickupDateTime.toLocaleDateString('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric'
    });
    const pickupTimeStr = pickupDateTime.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    });
    
    const deliveryDateStr = deliveryDateTime.toLocaleDateString('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric'
    });
    const deliveryTimeStr = deliveryDateTime.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    });
    
    orderSummary.innerHTML = `
        <div class="price-line">
            <span>Service:</span>
            <span>${serviceNames[currentOrder.serviceType]}</span>
        </div>
        <div class="price-line">
            <span>Items:</span>
            <span>${itemsText}</span>
        </div>
        <div class="price-line">
            <span>Pickup:</span>
            <span>${pickupDateStr} at ${pickupTimeStr}</span>
        </div>
        <div class="price-line">
            <span>Delivery:</span>
            <span>${deliveryDateStr} at ${deliveryTimeStr}</span>
        </div>
        <div class="price-line">
            <span>Subtotal:</span>
            <span>$${currentOrder.pricing.subtotal.toFixed(2)}</span>
        </div>
        <div class="price-line">
            <span>Tax:</span>
            <span>$${currentOrder.pricing.tax.toFixed(2)}</span>
        </div>
        <div class="price-line total">
            <span>Total:</span>
            <span>$${currentOrder.pricing.total.toFixed(2)}</span>
        </div>
    `;
}

function initializeStripeElements() {
    const elements = stripe.elements();
    
    cardElement = elements.create('card', {
        style: {
            base: {
                fontSize: '16px',
                color: '#424770',
                '::placeholder': {
                    color: '#aab7c4',
                },
            },
        },
    });
    
    cardElement.mount('#card-element');
    
    cardElement.on('change', function(event) {
        const displayError = document.getElementById('card-errors');
        if (event.error) {
            displayError.textContent = event.error.message;
        } else {
            displayError.textContent = '';
        }
    });
}

async function handlePayment() {
    if (!cardElement) {
        alert('Payment form not initialized. Please try again.');
        return;
    }
    
    showLoading();
    
    try {
        // Create payment intent
        const createPaymentIntent = firebase.functions().httpsCallable('createPaymentIntent');
        const result = await createPaymentIntent({
            orderData: currentOrder
        });
        
        const { clientSecret, orderId } = result.data;
        currentOrder.orderId = orderId;
        
        // Confirm payment with Stripe
        const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
            payment_method: {
                card: cardElement,
            }
        });
        
        if (error) {
            throw new Error(error.message);
        }
        
        if (paymentIntent.status === 'succeeded') {
            // Confirm payment with backend
            const confirmPayment = firebase.functions().httpsCallable('confirmPayment');
            await confirmPayment({
                paymentIntentId: paymentIntent.id,
                orderId: orderId
            });
            
            // Show confirmation
            showOrderConfirmation();
        }
        
    } catch (error) {
        console.error('Payment error:', error);
        alert('Payment failed: ' + error.message);
    } finally {
        hideLoading();
    }
}

function showOrderConfirmation() {
    const orderDetails = document.getElementById('orderDetails');
    const serviceNames = {
        'wash-fold': 'Wash & Fold',
        'express-wash-fold': 'Express Wash & Fold',
        'dry-cleaning': 'Dry Cleaning'
    };
    
    // Format pickup and delivery times
    const pickupDateTime = new Date(currentOrder.pickupDateTime);
    const deliveryDateTime = new Date(currentOrder.deliveryDateTime);
    
    const pickupDateStr = pickupDateTime.toLocaleDateString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric'
    });
    const pickupTimeStr = pickupDateTime.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    });
    
    const deliveryDateStr = deliveryDateTime.toLocaleDateString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric'
    });
    const deliveryTimeStr = deliveryDateTime.toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
    });
    
    orderDetails.innerHTML = `
        <div class="order-confirmation-details">
            <p><strong>Order ID:</strong> ${currentOrder.orderId}</p>
            <p><strong>Service:</strong> ${serviceNames[currentOrder.serviceType]}</p>
            <p><strong>Total:</strong> $${currentOrder.pricing.total.toFixed(2)}</p>
            <p><strong>Pickup:</strong> ${pickupDateStr} at ${pickupTimeStr}</p>
            <p><strong>Delivery:</strong> ${deliveryDateStr} at ${deliveryTimeStr}</p>
            <p><strong>Status:</strong> Confirmed</p>
        </div>
    `;
    
    // Show confirmation section
    document.getElementById('paymentSection').style.display = 'none';
    document.getElementById('confirmationSection').style.display = 'block';
    
    // Reset current order
    currentOrder = {};
}
