// Handle login form
const loginForm = document.getElementById('loginForm');
if (loginForm) {
    loginForm.addEventListener('submit', function (e) {
        e.preventDefault();
        const user = document.getElementById('usuario').value;
        const pass = document.getElementById('clave').value;

        if (user.trim() === '' || pass.trim() === '') {
            alert('Please fill in all fields.');
        } else {
            alert('Logging in...');
            // window.location.href = 'chat.html'; // future use
        }
    });
}

// Handle sign up form
const signupForm = document.getElementById('signupForm');
if (signupForm) {
    signupForm.addEventListener('submit', function (e) {
        e.preventDefault();

        const username = document.getElementById('username').value;
        const email = document.getElementById('email').value;
        const phone = document.getElementById('phone').value;
        const password = document.getElementById('password').value;

        if (
            username.trim() === '' ||
            email.trim() === '' ||
            phone.trim() === '' ||
            password.trim() === ''
        ) {
            alert('Please complete all fields before submitting.');
        } else {
            alert('Registration form completed. (No action yet)');
        }
    });
}

// Button to go back to login
function goBack() {
    window.location.href = 'login.html';
}

// From login.html: trigger signup window
function registrarse() {
    window.location.href = 'signUp.html';
}
