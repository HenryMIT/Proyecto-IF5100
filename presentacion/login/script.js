function login(event) {
  event.preventDefault();
  
  const phone = document.getElementById("phone").value.trim();
  const password = document.getElementById("password").value.trim();

  if (phone === "60001234" && password === "1234") {
    alert("Inicio de sesión exitoso 🎉");
    window.location.href = "../chat/index.html"; // Aquí iría la interfaz principal de chat
  } else {
    alert("Número o clave incorrectos.");
  }

  return false;
}
