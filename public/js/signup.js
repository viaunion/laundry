// Signup page functionality
document.addEventListener('DOMContentLoaded', function() {
    const signupForm = document.getElementById('signupForm');
    if (signupForm) {
        signupForm.addEventListener('submit', handleSignup);
    }
});

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
        
        // Redirect will be handled by auth.js
    } catch (error) {
        console.error('Signup error:', error);
        alert('Signup failed: ' + error.message);
    } finally {
        hideLoading();
    }
}
