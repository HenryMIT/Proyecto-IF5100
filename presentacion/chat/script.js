function toggleProfile() {
    const modal = document.getElementById('profileModal');
    if (modal.style.display === "flex") {
        modal.style.display = "none";
    } else {
        modal.style.display = "flex";
    }
}

function goToContacts() {
    window.location.href = "../contact/contact.html";
}

function logOut() {
    // Puedes limpiar localStorage si guardaste token o ID del usuario
    localStorage.clear();
    window.location.href = "../login/login.html";
}