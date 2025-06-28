// Shared authentication utilities
let currentUser = null;

// Initialize Firebase Auth
document.addEventListener('DOMContentLoaded', function() {
    // Wait for Firebase to be ready
    firebase.auth().onAuthStateChanged(function(user) {
        currentUser = user;
        updateAuthUI();
        handleAuthRedirect();
    });
    
    // Initialize logout button if present
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', logout);
    }
});

// Update UI based on auth state
function updateAuthUI() {
    const loginBtn = document.querySelector('a[href="login.html"]');
    const signupBtn = document.querySelector('a[href="signup.html"]');
    const logoutBtn = document.getElementById('logoutBtn');
    const userGreeting = document.getElementById('userGreeting');
    
    if (currentUser) {
        // User is logged in
        if (loginBtn) loginBtn.style.display = 'none';
        if (signupBtn) signupBtn.style.display = 'none';
        if (logoutBtn) logoutBtn.style.display = 'block';
        if (userGreeting) {
            userGreeting.style.display = 'block';
            userGreeting.textContent = `Welcome, ${currentUser.displayName || currentUser.email}`;
        }
    } else {
        // User is not logged in
        if (loginBtn) loginBtn.style.display = 'block';
        if (signupBtn) signupBtn.style.display = 'block';
        if (logoutBtn) logoutBtn.style.display = 'none';
        if (userGreeting) userGreeting.style.display = 'none';
    }
}

// Handle redirects based on auth state and current page
function handleAuthRedirect() {
    const currentPath = window.location.pathname;
    const currentPage = currentPath.split('/').pop() || 'index.html';
    
    // Pages that require authentication
    const protectedPages = ['dashboard.html', 'new-order.html', 'orders.html'];
    
    // Pages that should redirect to dashboard if already logged in
    const publicPages = ['login.html', 'signup.html'];
    
    if (currentUser) {
        // User is logged in
        if (publicPages.includes(currentPage)) {
            // Redirect to dashboard if on login/signup page
            window.location.href = 'dashboard.html';
        }
    } else {
        // User is not logged in
        if (protectedPages.includes(currentPage)) {
            // Redirect to login if trying to access protected page
            window.location.href = 'login.html';
        }
    }
}

// Logout function
async function logout() {
    try {
        await firebase.auth().signOut();
        window.location.href = '/';
    } catch (error) {
        console.error('Logout error:', error);
        alert('Logout failed: ' + error.message);
    }
}

// Show/hide loading overlay
function showLoading() {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        loadingOverlay.style.display = 'flex';
    }
}

function hideLoading() {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        loadingOverlay.style.display = 'none';
    }
}

// Utility function to check if user is authenticated
function requireAuth() {
    if (!currentUser) {
        window.location.href = 'login.html';
        return false;
    }
    return true;
}
