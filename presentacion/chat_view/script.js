function goProfile() {
   window.location.href = "../profile/profile.html";
}

function goToContacts() {
    window.location.href = "../contact/contact.html";
}

function logOut() {
    localStorage.clear();
    window.location.href = "../login/login.html";
}

function loadChat() {
    const userId = parseInt(localStorage.getItem("userId"));
    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    document.getElementById("userId").value = userId;

    fetch(`http://localhost:8000/api/chat/load/${userId}`)
        .then(res => {
            if (res.status === 200) {
                return res.json();
            } else {
                throw new Error("Failed to load chat");
            }
        })
        .then(data => {
            // Process and display chat data
            console.log(data);
        })
        .catch(err => {
            console.error("Error loading chat:", err);
            alert("Failed to load chat. Please try again.");
        });
}