document.addEventListener("DOMContentLoaded", () => {
    const userId = parseInt(localStorage.getItem("userId"));
    /*const filterName = params.get('contact_name') == null ? params.set('contact_name', "") : params.get('contact_name').trim();
    const filterPhone = params.get('phone_contact') == null ? params.set('phone_contact', "") : params.get('phone_contact').trim();*/

    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    const params = new URLSearchParams(window.location.search);
    const filterName = params.get('contact_name') || "";
    const filterPhone = params.get('phone_contact') || "";

    document.getElementById("userId").value = userId;
    document.getElementById("btnLoad").addEventListener("click", () => loadContacts(userId));

    loadContacts(userId, filterName, filterPhone);

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

function loadContacts(userId, name = "", phone = "") {
    const limit = 100;
    const page = 0;

    let url = `http://localhost:8000/api/contact/load/${userId}/${limit}/${page}`;

    const queryParams = new URLSearchParams();

    if (name) queryParams.append("contact_name", name);
    if (phone) queryParams.append("phone_contact", phone);

    if ([...queryParams].length > 0) url += "?" + queryParams.toString();

    fetch(url, { method: "GET" })
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
    window.location.href = "../chat_view/chat.html";
}
