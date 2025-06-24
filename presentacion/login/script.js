// Validación simple para el formulario
document.getElementById('loginForm').addEventListener('submit', function(e) {
    e.preventDefault();
    const usuario = document.getElementById('usuario').value;
    const clave = document.getElementById('clave').value;

    if (usuario.trim() === '' || clave.trim() === '') {
        alert('Please, complete all fields.');
    } else {
        alert('Logging in...'); // Aquí luego podrías redirigir o validar con backend
    }
});


// Acción del botón registrarse
function registrarse() {
    alert('Redirecting to the registration form...');
    // Aquí podrías cambiar location.href = 'registro.html';
}

function goToSignUp() {
    window.location.href = "../signUp/signUp.html";
}

