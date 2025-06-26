document.addEventListener("DOMContentLoaded", () => {
    const params = new URLSearchParams(window.location.search);
    const userId = parseInt(localStorage.getItem("userId"));
    const filterName = params.get('contact_name') || '';
    const filterPhone = params.get('phone_contact') || '';

    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    loadContacts(userId, filterName, filterPhone);

    document.getElementById("btnLoad").addEventListener("click", () => loadContacts(userId));

    // Agregar el evento para el formulario de contacto
    document.getElementById("contactForm").addEventListener("submit", async (e) => {
        e.preventDefault();
        const phone = document.getElementById("phone").value.trim();
        const name = document.getElementById("contactName").value.trim();
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
                showNotification("Success", "Contact added successfully!");
                document.getElementById("phone").value = "";
                document.getElementById("contactName").value = "";
                loadContacts(userId);
            } else if (res.status === 409) {
                showNotification("Error", "Cannot add contact: either exists already or the number is not registered.");
            } else {
                throw new Error("Unexpected status " + res.status);
            }
        } catch (err) {
            console.error("Error adding contact:", err);
            showNotification("Error", "Failed to add contact. Please try again.");
        }
    });

    // Modal de añadir contacto
    const modal = document.getElementById("addContactModal");
    const btnAddContact = document.getElementById("btnAddContact");
    const closeModalBtns = document.querySelectorAll(".close-btn");

    btnAddContact.onclick = function() {
        modal.style.display = "block";
    }

    closeModalBtns.forEach(btn => {
        btn.onclick = function() {
            modal.style.display = "none";
        }
    });

    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    };
});

// Mostrar el modal de notificación
function showNotification(title, message) {
    const notificationModal = document.getElementById("notificationModal");
    const notificationTitle = document.getElementById("notificationTitle");
    const notificationMessage = document.getElementById("notificationMessage");

    notificationTitle.textContent = title;
    notificationMessage.textContent = message;

    notificationModal.style.display = "block";
}

// Cerrar el modal de notificación
function closeNotification() {
    const notificationModal = document.getElementById("notificationModal");
    notificationModal.style.display = "none";
}

// Mostrar el modal de editar contacto y prellenar los datos
function editContact(id_contact, contact_name, contact_number) {
    const modal = document.getElementById("editContactModal");
    const form = document.getElementById("editContactForm");
    
    // Prellenar los campos del formulario
    document.getElementById("editContactId").value = id_contact;
    document.getElementById("editContactName").value = contact_name;
    document.getElementById("editPhone").value = contact_number;

    // Mostrar el modal de edición
    modal.style.display = "block";

    // Cuando se cierra el modal
    const closeModalBtns = document.querySelectorAll(".close-btn");
    closeModalBtns.forEach(btn => {
        btn.onclick = function() {
            modal.style.display = "none";
        }
    });

    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    };

    // Enviar la actualización de contacto
    form.addEventListener("submit", async (e) => {
        e.preventDefault();

        const updatedName = document.getElementById("editContactName").value.trim();
        const updatedPhone = document.getElementById("editPhone").value.trim();

        if (!updatedName || !updatedPhone) {
            alert("Please fill in all fields.");
            return;
        }

        try {
            const res = await fetch(`http://localhost:8000/api/contact/update`, {
                method: "PUT",
                headers: {"Content-Type": "application/json"},
                body: JSON.stringify({
                    id_contact: id_contact,
                    contact_number: updatedPhone,
                    contact_name: updatedName                    
                })
            });

            if (res.status === 204) {
                showNotification("Success", "Contact updated successfully!");
                loadContacts(parseInt(localStorage.getItem("userId")));
                modal.style.display = "none"; // Cerrar el modal
            } else {
                throw new Error("Unexpected status " + res.status);
            }
        } catch (err) {
            console.error("Error updating contact:", err);
            showNotification("Error", "Failed to update contact. Please try again.");
        }
    });
}

// Cerrar el modal de editar contacto
function closeEditModal() {
    document.getElementById("editContactModal").style.display = "none";
}

// Cargar los contactos y mostrar el botón de editar
function loadContacts(userId, name = "", phone = "") {
    const limit = 100;
    const page = 0;

    let url = `http://localhost:8000/api/contact/load/${userId}/${limit}/${page}?phone_contact=${phone}&contact_name=${name}`;

    fetch(url, { method: "GET" })
        .then(res => res.json())
        .then(data => {
            const list = document.getElementById("contactList");
            list.innerHTML = "";

            if (!Array.isArray(data) || data.length === 0) {
                const div = document.createElement("div");
                div.textContent = "No contacts found.";
                list.appendChild(div);
                return;
            }

            data.forEach(contact => {
                const contactItem = document.createElement("div");
                contactItem.classList.add("contact-item");

                contactItem.innerHTML = `
                    <h3>${contact.contact_name}</h3>
                    <p>${contact.contact_number}</p>
                    <div class="buttons">
                        <button class="delete-button" onclick="deleteContact(${contact.id_contact})">Delete</button>
                        <button class="chat-button" onclick="startChat(${contact.id_contact})">Creat Chat</button>
                        <button class="edit-button" onclick="editContact(${contact.id_contact}, '${contact.contact_name}', '${contact.contact_number}')">Edit</button>
                    </div>
                `;
                list.appendChild(contactItem);
            });
        })
        .catch(err => {
            console.error("Error loading contacts:", err);
        });
}

// Iniciar un chat con el contacto seleccionado
function startChat(id_contact) {
    const userId = parseInt(localStorage.getItem("userId"));
    const ok = false;
    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    const chatData = {
        id_usr: userId, // ID del usuario actual
        id_contact: id_contact // ID del contacto con el que se desea iniciar el chat
    };

    // Hacer la solicitud POST para crear el chat
    fetch("http://localhost:8000/api/chat/create", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(chatData)
    })
    .then(response => {
        if (response.status === 204) {
            // Si el chat fue creado exitosamente, redirigir al usuario a la vista del chat
            response.json().then(data => {
                // Guardamos el ID del chat en el localStorage
                localStorage.setItem("chatId", data.id_chat);                            
            });
        } else {
            throw new Error("Failed to create chat.");
        }
    })
    .catch(error => {
        console.error("Error starting chat:", error);
        alert("Failed to start chat. Please try again.");
    });
   
    if (!ok) {
        alert('cambio ventana')
         window.location.href = "../chat_view/chat.html";
    }
}

function goBack() {
    window.location.href = "../chat_view/chat.html";
}

function deleteContact(id_contact) {
    const userId = parseInt(localStorage.getItem("userId"));

    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    const confirmDelete = confirm("Are you sure you want to delete this contact?");
    if (!confirmDelete) return;

    // Hacer la solicitud DELETE para eliminar el contacto
    fetch(`http://localhost:8000/api/contact/delete/${id_contact}`, {
        method: "DELETE",
        headers: {
            "Content-Type": "application/json"
        }
    })
    .then(response => {
        if (response.status === 204) {
            // Si la eliminación fue exitosa, actualizar la lista de contactos
            alert("Contact deleted successfully!");
            loadContacts(userId); // Recargar los contactos
        } else {
            throw new Error("Failed to delete contact.");
        }
    })
    .catch(error => {
        console.error("Error deleting contact:", error);
        alert("Failed to delete contact. Please try again.");
    });
}