document.addEventListener("DOMContentLoaded", () => {
    const userId = parseInt(localStorage.getItem("userId"));

    if (!userId || isNaN(userId)) {
        alert("No user ID found. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    document.getElementById("userId").value = userId;
    loadContacts(userId);
});

function loadContacts(userId) {
    fetch(`http://localhost:8000/api/contact/load?id_user=${userId}`)
        .then(res => {
            if (!res.ok) throw new Error("HTTP error " + res.status);
            return res.json();
        })
        .then(data => {
            const list = document.getElementById("contactList");
            list.innerHTML = "";

            if (!Array.isArray(data)) {
                console.warn("Unexpected response:", data);
                alert("Failed to load contacts. Unexpected response.");
                return;
            }

            data.forEach(contact => {
                const li = document.createElement("li");
                li.textContent = `${contact.contact_name} (${contact.contact_number})`;
                list.appendChild(li);
            });
        })
        .catch(err => {
            console.error("Error loading contacts:", err);
            alert("Failed to load contacts.");
        });
}

document.getElementById("contactForm").addEventListener("submit", function (e) {
    e.preventDefault();

    const userId = parseInt(document.getElementById("userId").value);
    const phone = document.getElementById("phone").value.trim();
    const name = document.getElementById("contactName").value.trim();

    if (!phone || !name) {
        alert("Please fill in all fields.");
        return;
    }

    fetch("http://localhost:8000/api/contact/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            id_user: userId,
            contact_number: phone,
            contact_name: name
        })
    })
    .then(res => res.text()) // usamos text() primero para depurar mejor
    .then(text => {
        console.log("Raw response:", text);
        let result;
        try {
            result = JSON.parse(text);
        } catch (e) {
            throw new Error("Failed to parse JSON: " + text);
        }

        if (result === 1 || result.result === 1) {
            alert("Contact added successfully!");
            loadContacts(userId);
        } else if (result === 0 || result.result === 0) {
            alert("Contact could not be added. It may already exist or is invalid.");
        } else {
            alert("Unexpected result from server.");
        }
    })
    .catch(err => {
        console.error("Error adding contact:", err);
        alert("Failed to add contact.");
    });
});

function goBack() {
    window.location.href = "../chat/chat.html";
}
