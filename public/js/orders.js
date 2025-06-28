// Orders page functionality
document.addEventListener('DOMContentLoaded', function() {
    // Ensure user is authenticated
    firebase.auth().onAuthStateChanged(function(user) {
        if (user) {
            loadUserOrders();
        }
    });
});

async function loadUserOrders() {
    if (!currentUser) return;
    
    showLoading();
    
    try {
        const getUserOrders = firebase.functions().httpsCallable('getUserOrders');
        const result = await getUserOrders();
        const orders = result.data.orders;
        
        displayOrders(orders);
    } catch (error) {
        console.error('Error loading orders:', error);
        const ordersList = document.getElementById('ordersList');
        if (ordersList) {
            ordersList.innerHTML = '<p>Unable to load orders. Please try again later.</p>';
        }
    } finally {
        hideLoading();
    }
}

function displayOrders(orders) {
    const ordersList = document.getElementById('ordersList');
    if (!ordersList) return;
    
    if (orders.length === 0) {
        ordersList.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">
                    <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
                        <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path>
                        <rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect>
                    </svg>
                </div>
                <h3>No orders yet</h3>
                <p>When you place your first order, it will appear here.</p>
                <a href="dashboard.html" class="cta-btn">Start Your First Order</a>
            </div>
        `;
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
        
        // Format pickup and delivery times if available
        let pickupText = 'Not scheduled';
        let deliveryText = 'Not scheduled';
        
        if (order.pickupDateTime) {
            const pickupDate = new Date(order.pickupDateTime);
            pickupText = pickupDate.toLocaleDateString('en-US', {
                weekday: 'short',
                month: 'short',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });
        }
        
        if (order.deliveryDateTime) {
            const deliveryDate = new Date(order.deliveryDateTime);
            deliveryText = deliveryDate.toLocaleDateString('en-US', {
                weekday: 'short',
                month: 'short',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });
        }
        
        return `
            <div class="mobile-order-card">
                <div class="order-header">
                    <div class="order-info">
                        <h3>Order #${order.id.substring(0, 8)}</h3>
                        <p class="order-date">${createdAt}</p>
                    </div>
                    <span class="order-status ${order.status}">${order.status}</span>
                </div>
                <div class="order-content">
                    <div class="service-info">
                        <h4>${serviceNames[order.serviceType] || order.serviceType}</h4>
                        <p>${itemsText}</p>
                    </div>
                    <div class="order-total">
                        <span class="total-amount">$${order.pricing ? order.pricing.total.toFixed(2) : '0.00'}</span>
                    </div>
                </div>
                <div class="order-timeline">
                    <div class="timeline-item">
                        <span class="timeline-label">Pickup:</span>
                        <span class="timeline-value">${pickupText}</span>
                    </div>
                    <div class="timeline-item">
                        <span class="timeline-label">Delivery:</span>
                        <span class="timeline-value">${deliveryText}</span>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}
