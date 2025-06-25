document.addEventListener("DOMContentLoaded", function () {
    document.getElementById('loginForm').addEventListener('submit', function(e) {
        e.preventDefault();

        const usuario = document.getElementById('usuario').value.trim();
        const clave = document.getElementById('clave').value;

        if (usuario === '' || clave === '') {
            alert('Please, complete all fields.');
            return;
        }

        // Validar si es email o número
        const data = {
            phone_number: usuario, // la API espera phone_number
            pass: clave
        };

        fetch("http://localhost:8000/api/auth/login", {
            method: "PATCH",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(data)
        })
        .then(res => {
            if (res.status === 200) {
                return res.json();
            } else {
                throw new Error("Invalid credentials");
            }
        })
        .then(data => {
            alert("Login successful!");

            // Puedes guardar el token si lo necesitas
            // localStorage.setItem("token", data.token);
            // localStorage.setItem("id_usr", data.id_usr);

            // Redirigir a la vista principal del chat
            window.location.href = "../chat/chat.html";
        })
        .catch(err => {
            console.error("Login error:", err);
            alert("Incorrect phone number/email or password.");
        });
    });
});

// Redirección a la vista de registro
function goToSignUp() {
    window.location.href = "../signUp/signUp.html";
}
