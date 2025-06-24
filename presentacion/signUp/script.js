// Submit registration and call API
document.getElementById("registerForm").addEventListener("submit", function(e) {
    e.preventDefault();

    const username = document.getElementById("username").value.trim();
    const email = document.getElementById("email").value.trim();
    const phone_number = document.getElementById("phone_number").value.trim();
    const pass = document.getElementById("pass").value;

    if (!username || !email || !phone_number || !pass) {
        alert("Please fill in all fields.");
        return;
    }

    fetch("http://localhost:8000/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, email, phone_number, pass })
    })
    .then(res => {
        if (res.status === 201) {
            alert("Registration successful!");
            window.location.href = "../login.html";
        } else if (res.status === 409) {
            alert("User already exists.");
        } else {
            alert("Registration failed. Please try again.");
        }
    })
    .catch(err => {
        console.error("Fetch error:", err);
        alert("Could not connect to server.");
    });
});


// Button to go back to login
function goBack() {
    window.location.href = '../login/login.html';
}


