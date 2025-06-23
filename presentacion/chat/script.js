function toggleProfile() {
    const modal = document.getElementById('profileModal');
    if (modal.style.display === "flex") {
        modal.style.display = "none";
    } else {
        modal.style.display = "flex";
    }
}

