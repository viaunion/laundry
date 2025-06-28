// App State
let currentUser = null;
let currentOrder = {};
let stripe = null;
let cardElement = null;

// Initialize Stripe
const STRIPE_PUBLISHABLE_KEY = 'pk_test_51Rf081E94pb9ZFdYqRd77yRV96VxUkjeEcVqJB8CDa92Lq1Bj25mGTdVhdnLpQ4pwdgN3SgDDkWvNCiP7yLRA6HV00rZI7OCdy';

// Wait for Firebase to initialize
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Stripe
    stripe = Stripe(STRIPE_PUBLISHABLE_KEY);
    
    // Wait for Firebase to be ready
    firebase.auth().onAuthStateChanged(function(user) {
        currentUser = user;
        updateUI();
        if (user) {
            loadUserOrders();
        }
    });
    
    // Initialize event listeners
    initializeEventListeners();
});

// Screen Management
function showScreen(screenId) {
    // Hide all screens
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.remove('active');
    });
    
    // Show target screen
    document.getElementById(screenId).classList.add('active');
}

function showLoading() {
    document.getElementById('loadingOverlay').style.display = 'flex';
}

function hideLoading() {
    document.getElementById('loadingOverlay').style.display = 'none';
}

// UI Updates
function updateUI() {
    const loginBtn = document.getElementById('loginBtn');
    const signupBtn = document.getElementById('signupBtn');
    const logoutBtn = document.getElementById('logoutBtn');
    const userGreeting = document.getElementById('userGreeting');
    
    if (currentUser) {
        loginBtn.style.display = 'none';
        signupBtn.style.display = 'none';
        logoutBtn.style.display = 'block';
        userGreeting.style.display = 'block';
        userGreeting.textContent = `Welcome, ${currentUser.displayName || currentUser.email}`;
        showScreen('dashboardScreen');
        
        // Re-attach dashboard event listeners after showing dashboard
        setTimeout(() => {
            attachDashboardEventListeners();
        }, 100);
    } else {
        loginBtn.style.display = 'block';
        signupBtn.style.display = 'block';
        logoutBtn.style.display = 'none';
        userGreeting.style.display = 'none';
        showScreen('welcomeScreen');
    }
}

// Global flag to prevent duplicate dashboard listeners
let dashboardListenersAttached = false;

function attachDashboardEventListeners() {
    console.log('Attaching direct event listeners to dashboard buttons...');
    
    // Prevent duplicate listeners
    if (dashboardListenersAttached) {
        console.log('Dashboard listeners already attached, skipping');
        return;
    }
    
    // Add direct event listeners to dashboard buttons
    const newOrderBtn = document.getElementById('newOrderBtn');
    const viewOrdersBtn = document.getElementById('viewOrdersBtn');
    
    if (newOrderBtn) {
        newOrderBtn.addEventListener('click', handleNewOrderClick);
        console.log('New Order button listener attached');
    } else {
        console.log('New Order button not found');
    }
    
    if (viewOrdersBtn) {
        viewOrdersBtn.addEventListener('click', handleViewOrdersClick);
        console.log('View Orders button listener attached');
    } else {
        console.log('View Orders button not found');
    }
    
    dashboardListenersAttached = true;
}

function handleNewOrderClick(e) {
    console.log('handleNewOrderClick called!', e);
    e.preventDefault();
    e.stopPropagation();
    console.log('New Order button clicked via direct listener!');
    showScreen('serviceScreen');
}

function handleViewOrdersClick(e) {
    console.log('handleViewOrdersClick called!', e);
    e.preventDefault();
    e.stopPropagation();
    console.log('View Orders button clicked via direct listener!');
    loadUserOrders();
}

// Event Listeners
function initializeEventListeners() {
    console.log('Initializing event listeners...');
    
    // Set up global event delegation for dashboard buttons
    console.log('Setting up global event delegation...');
    document.addEventListener('click', function(e) {
        console.log('Global click detected on:', e.target.id, e.target.tagName, e.target.className);
        
        // Log all button clicks for debugging
        if (e.target.tagName === 'BUTTON') {
            console.log('Button clicked - ID:', e.target.id, 'Classes:', e.target.className, 'Text:', e.target.textContent);
        }
        
        // Check for dashboard buttons specifically
        if (e.target && (e.target.id === 'newOrderBtn' || e.target.classList.contains('action-btn'))) {
            if (e.target.id === 'newOrderBtn' || e.target.textContent.trim() === 'New Order') {
                e.preventDefault();
                e.stopPropagation();
                console.log('New Order button clicked via global delegation!');
                showScreen('serviceScreen');
                return;
            }
        }
        
        if (e.target && (e.target.id === 'viewOrdersBtn' || e.target.classList.contains('action-btn'))) {
            if (e.target.id === 'viewOrdersBtn' || e.target.textContent.trim() === 'View Orders') {
                e.preventDefault();
                e.stopPropagation();
                console.log('View Orders button clicked via global delegation!');
                loadUserOrders();
                return;
            }
        }
    });
    
    // Navigation
    const navLogo = document.querySelector('.nav-logo');
    if (navLogo) {
        navLogo.addEventListener('click', () => {
            if (currentUser) {
                showScreen('dashboardScreen');
            } else {
                showScreen('welcomeScreen');
            }
        });
    }
    
    const loginBtn = document.getElementById('loginBtn');
    if (loginBtn) {
        loginBtn.addEventListener('click', () => showScreen('loginScreen'));
    }
    
    const signupBtn = document.getElementById('signupBtn');
    if (signupBtn) {
        signupBtn.addEventListener('click', () => showScreen('signupScreen'));
    }
    
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', logout);
    }
    
    const getStartedBtn = document.getElementById('getStartedBtn');
    if (getStartedBtn) {
        getStartedBtn.addEventListener('click', () => {
            if (currentUser) {
                showScreen('serviceScreen');
            } else {
                showScreen('signupScreen');
            }
        });
    }
    
    // Form switches
    const switchToSignup = document.getElementById('switchToSignup');
    if (switchToSignup) {
        switchToSignup.addEventListener('click', (e) => {
            e.preventDefault();
            showScreen('signupScreen');
        });
    }
    
    const switchToLogin = document.getElementById('switchToLogin');
    if (switchToLogin) {
        switchToLogin.addEventListener('click', (e) => {
            e.preventDefault();
            showScreen('loginScreen');
        });
    }
    
    // Forms
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }
    
    const signupForm = document.getElementById('signupForm');
    if (signupForm) {
        signupForm.addEventListener('submit', handleSignup);
    }
    
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
    
    // Confirmation
    const backToDashboard = document.getElementById('backToDashboard');
    if (backToDashboard) {
        backToDashboard.addEventListener('click', () => showScreen('dashboardScreen'));
    }
    
    console.log('Event listeners initialized');
}

// Authentication
async function handleLogin(e) {
    e.preventDefault();
    showLoading();
    
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    
    try {
        await firebase.auth().signInWithEmailAndPassword(email, password);
        // UI will update automatically via onAuthStateChanged
    } catch (error) {
        alert('Login failed: ' + error.message);
    } finally {
        hideLoading();
    }
}

async function handleSignup(e) {
    e.preventDefault();
    showLoading();
    
    const name = document.getElementById('signupName').value;
    const email = document.getElementById('signupEmail').value;
    const password = document.getElementById('signupPassword').value;
    const street = document.getElementById('signupStreet').value;
    const city = document.getElementById('signupCity').value;
    const state = document.getElementById('signupState').value;
    const zipCode = document.getElementById('signupZip').value;
    
    try {
        // Create user account
        const userCredential = await firebase.auth().createUserWithEmailAndPassword(email, password);
        const user = userCredential.user;
        
        // Update user profile
        await user.updateProfile({
            displayName: name
        });
        
        // Save user data to Firestore
        await firebase.firestore().collection('users').doc(user.uid).set({
            name: name,
            email: email,
            defaultAddress: {
                street: street,
                city: city,
                state: state,
                zipCode: zipCode
            },
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        
        // UI will update automatically via onAuthStateChanged
    } catch (error) {
        alert('Signup failed: ' + error.message);
    } finally {
        hideLoading();
    }
}

async function logout() {
    try {
        await firebase.auth().signOut();
        currentOrder = {};
        // UI will update automatically via onAuthStateChanged
    } catch (error) {
        alert('Logout failed: ' + error.message);
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
    setTimeout(() => showScreen('itemsScreen'), 300);
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
    
    // Double-check that we have valid items based on service type
    if (currentOrder.serviceType === 'dry-cleaning') {
        if (!currentOrder.items.dryCleanItems || currentOrder.items.dryCleanItems.length === 0) {
            alert('Please select at least one item for dry cleaning.');
            return;
        }
    } else {
        if (!currentOrder.items.estimatedWeight || currentOrder.items.estimatedWeight <= 0) {
            alert('Please enter a valid estimated weight for your laundry.');
            return;
        }
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
    
    // Validate pickup date is not more than 30 days in the future
    const maxDate = new Date();
    maxDate.setDate(maxDate.getDate() + 30);
    
    if (pickupDateTime > maxDate) {
        alert('Please select a pickup date within the next 30 days.');
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
        
        showScreen('paymentScreen');
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
    
    showScreen('confirmationScreen');
    
    // Reset current order
    currentOrder = {};
}

// Orders Management
async function loadUserOrders() {
    if (!currentUser) return;
    
    try {
        const getUserOrders = firebase.functions().httpsCallable('getUserOrders');
        const result = await getUserOrders();
        const orders = result.data.orders;
        
        displayOrders(orders);
    } catch (error) {
        console.error('Error loading orders:', error);
    }
}

function displayOrders(orders) {
    const ordersList = document.getElementById('ordersList');
    
    if (orders.length === 0) {
        ordersList.innerHTML = '<p>No orders found. <a href="#" onclick="showScreen(\'serviceScreen\')">Create your first order</a></p>';
        return;
    }
    
    const serviceNames = {
        'wash-fold': 'Wash & Fold',
        'express-wash-fold': 'Express Wash & Fold',
        'dry-cleaning': 'Dry Cleaning'
    };
    
    ordersList.innerHTML = orders.map(order => {
        const createdAt = order.createdAt ? new Date(order.createdAt.seconds * 1000).toLocaleDateString() : 'Unknown';
        
        let itemsText = '';
        if (order.serviceType === 'dry-cleaning' && order.items.dryCleanItems) {
            itemsText = order.items.dryCleanItems.map(item => 
                `${item.quantity}x ${item.type.replace('-', ' ')}`
            ).join(', ');
        } else if (order.items.estimatedWeight) {
            itemsText = `${order.items.estimatedWeight} lbs`;
        }
        
        return `
            <div class="order-item">
                <h4>Order #${order.id.substring(0, 8)}</h4>
                <p><strong>Service:</strong> ${serviceNames[order.serviceType] || order.serviceType}</p>
                <p><strong>Items:</strong> ${itemsText}</p>
                <p><strong>Total:</strong> $${order.pricing ? order.pricing.total.toFixed(2) : '0.00'}</p>
                <p><strong>Date:</strong> ${createdAt}</p>
                <p><strong>Status:</strong> <span class="order-status ${order.status}">${order.status}</span></p>
            </div>
        `;
    }).join('');
}

// Utility Functions
function formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(amount);
}

function formatDate(timestamp) {
    if (!timestamp) return 'Unknown';
    const date = timestamp.seconds ? new Date(timestamp.seconds * 1000) : new Date(timestamp);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Error Handling
window.addEventListener('error', function(e) {
    console.error('Global error:', e.error);
    hideLoading();
});

window.addEventListener('unhandledrejection', function(e) {
    console.error('Unhandled promise rejection:', e.reason);
    hideLoading();
});
