document.addEventListener("DOMContentLoaded", () => {
    const userId = parseInt(localStorage.getItem("userId"));
    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    document.getElementById("userId").value = userId;
    document.getElementById("btnLoad").addEventListener("click", () => loadContacts(userId));

    document.getElementById("contactForm").addEventListener("submit", async (e) => {
        e.preventDefault();
        const phone = document.getElementById("phone").value.trim();
        const name  = document.getElementById("contactName").value.trim();
        if (!phone || !name) {
            alert("Please fill in all fields.");
            return;
        }
        
        try {
            const res = await fetch("http://localhost:8000/api/contact/create", {
                method: "POST",
                headers: {"Content-Type": "application/json"},
                body: JSON.stringify({ id_usr: userId, contact_number: phone, contact_name: name })
            });

            if (res.status === 204) {
                alert("Contact added successfully!");
                document.getElementById("phone").value = "";
                document.getElementById("contactName").value = "";
                loadContacts(userId);
            } else if (res.status === 409) {
                alert("Cannot add contact: either exists already or the number is not registered.");
            } else {
                throw new Error("Unexpected status " + res.status);
            }
        } catch (err) {
            console.error("Error adding contact:", err);
            alert("Failed to add contact. Please try again.");
        }
    });
});

function loadContacts(userId) {
    const limit = 100;
    const page = 0;

    fetch(`http://localhost:8000/api/contact/load/${userId}/${limit}/${page}`, {
        method: "GET"
    })
    .then(res => {
        if (!res.ok) throw new Error("Failed to load contacts. Status: " + res.status);
        return res.json();
    })
    .then(data => {
        const list = document.getElementById("contactList");
        list.innerHTML = "";

        if (!Array.isArray(data) || data.length === 0) {
            const li = document.createElement("li");
            li.textContent = "No contacts found.";
            list.appendChild(li);
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
        alert("Could not load contacts.");
    });
}


function goBack() {
    window.location.href = "../chat/chat.html";
}
