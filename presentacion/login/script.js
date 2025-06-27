document.addEventListener("DOMContentLoaded", function () {
    if (localStorage.getItem("userId")) {
        window.location.href = "../chat_view/chat.html";
    }

    document.getElementById('loginForm').addEventListener('submit', function (e) {
        e.preventDefault();

        const usuario = document.getElementById('usuario').value.trim();
        const clave = document.getElementById('clave').value;

        if (usuario === '' || clave === '') {
            alert('Please, complete all fields.');
            return;
        }

        const data = {
            phone_number: usuario,
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
                // Guardar id_usr en localStorage
                localStorage.setItem("userId", data.id_usr);
                // Opcional: localStorage.setItem("token", data.token);
                alert("Login successful!");

            })
            .catch(err => {
                console.error("Login error:", err);
                alert("Incorrect phone number/email or password.");
            });


    });

    window.goToSignUp = function () {
        window.location.href = "../signUp/signUp.html";
    };
});
