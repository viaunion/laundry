// Dashboard page functionality
document.addEventListener('DOMContentLoaded', function() {
    // Ensure user is authenticated
    firebase.auth().onAuthStateChanged(function(user) {
        if (user) {
            updateUserGreeting(user);
            loadRecentOrders();
        }
    });
});

function updateUserGreeting(user) {
    const userGreeting = document.getElementById('userGreeting');
    if (userGreeting) {
        // Try to get display name, fallback to email, then to "User"
        const name = user.displayName || user.email?.split('@')[0] || 'User';
        userGreeting.textContent = `Welcome, ${name}!`;
    }
}

function startOrder(serviceType) {
    // Navigate to new order page with service type
    if (serviceType === 'dry-cleaning') {
        window.location.href = 'new-order.html?service=dry-cleaning';
    } else if (serviceType === 'laundry') {
        window.location.href = 'new-order.html?service=wash-fold';
    }
}

async function loadRecentOrders() {
    if (!currentUser) return;
    
    try {
        const getUserOrders = firebase.functions().httpsCallable('getUserOrders');
        const result = await getUserOrders();
        const orders = result.data.orders;
        
        displayRecentOrders(orders.slice(0, 3)); // Show only the 3 most recent orders
    } catch (error) {
        console.error('Error loading recent orders:', error);
        const ordersList = document.getElementById('ordersList');
        if (ordersList) {
            ordersList.innerHTML = '<p>Unable to load recent orders. <a href="new-order.html">Create your first order</a></p>';
        }
    }
}

function displayRecentOrders(orders) {
    const ordersList = document.getElementById('ordersList');
    if (!ordersList) return;
    
    if (orders.length === 0) {
        ordersList.innerHTML = '<p>No orders found. <a href="new-order.html">Create your first order</a></p>';
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
