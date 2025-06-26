


document.addEventListener("DOMContentLoaded", () => {
    const userId = parseInt(localStorage.getItem("userId"));

    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    loadChats(userId); // Cargar los chats al cargar la página

    // Manejar clic en cada chat para cargar los mensajes
    document.getElementById("chatList").addEventListener("click", (e) => {
        e.preventDefault();
        const chatItem = e.target.closest(".chat-item");
        if (chatItem) {
            const chatId = chatItem.getAttribute("data-chat-id");
            const id_receiver = chatItem.getAttribute('id_receiver');
            localStorage.setItem("id_receiver", id_receiver);
            localStorage.setItem("chatId", chatId);
            loadChatMessages(chatId);
        }
    });
});

// Lista para almacenar los chats y los mensajes
let chats = [];
let messages = [];

// Cargar los chats del usuario (esto solo se hace una vez)
function loadChats(userId) {
    // Si ya tenemos los chats cargados, no los volvemos a cargar
    if (chats.length > 0) {
        displayChats();
        return;
    }

    const url = `http://localhost:8000/api/chat/load/${userId}`;

    fetch(url)
        .then(res => res.json())
        .then(data => {
            chats = data; // Guardar los chats en la lista
            displayChats(); // Mostrar los chats en la interfaz
        })
        .catch(err => {
            console.error("Error loading chats:", err);
            alert("Could not load chats.");
        });
}

// Mostrar los chats en la interfaz
function displayChats() {
    const chatList = document.getElementById("chatList");
    chatList.innerHTML = "";

    if (chats.length === 0) {
        chatList.innerHTML = "<p>No chats found.</p>";
        return;
    }

    // Mostrar los chats en la lista
    chats.forEach(chat => {
        const chatItem = document.createElement("div");
        chatItem.classList.add("chat-item");
        chatItem.setAttribute("data-chat-id", chat.id_chat);
        chatItem.setAttribute("id_receiver", chat.id_receiver);

        chatItem.innerHTML = `
            <p class="chat-name">${chat.contact_name}</p>
            <p class="chat-preview">${chat.contact_number}</p>
        `;
        chatList.appendChild(chatItem);
    });
}

// Cargar los mensajes de un chat específico
function loadChatMessages(chatId) {
    const chatMessages = document.getElementById("chatMessages");
    chatMessages.innerHTML = "Loading messages...";
    loadAllMessages();
    // Verificar si ya tenemos los mensajes cargados para este chat
    const chatMessagesData = messages.filter(msg => msg.id_chat === chatId);

    if (chatMessagesData.length === 0) {
        chatMessages.innerHTML = "<p>No messages in this chat.</p>";
        return;
    }

    // Mostrar los mensajes en la ventana del chat
    chatMessages.innerHTML = "";  // Limpiar "Loading" al cargar los mensajes
    chatMessagesData.forEach(message => {
        const messageElement = document.createElement("div");
        messageElement.classList.add("message");
        if (message.id_chat_sender == chatId) {
            messageElement.classList.add("sent");
        } else {
            messageElement.classList.add("received");
        }

        messageElement.textContent = message.text_message;
        chatMessages.appendChild(messageElement);

        // Desplazar hacia abajo automáticamente para ver el último mensaje
        chatMessages.scrollTop = chatMessages.scrollHeight;
    });
}

// Simular la carga de los mensajes para todos los chats (esto se puede hacer de manera similar con fetch)
function loadAllMessages() {
    const chatId = localStorage.getItem("chatId");

    if (!chatId) {
        alert("No chat selected. Please select a chat first.");
        return;
    }

    // Realizamos el fetch a la API para obtener los mensajes de un chat específico
    fetch(`http://localhost:8000/api/message/load/${chatId}`)
        .then(res => {
            if (!res.ok) {
                throw new Error("Failed to load messages.");
            }
            return res.json();
        })
        .then(data => {
            // Verificar si hay mensajes
            if (data.length === 0) {
                const chatMessages = document.getElementById('chatMessages');
                chatMessages.innerHTML = "<p>No messages in this chat.</p>";
                return;
            }

            // Limpiar la ventana de mensajes
            const chatMessages = document.getElementById('chatMessages');
            chatMessages.innerHTML = "";

            // Mostrar los mensajes cargados
            data.forEach(message => {
                const messageElement = document.createElement("div");

                messageElement.classList.add("message");

                // Definir si el mensaje es enviado o recibido
                if (message.id_chat_sender === parseInt(localStorage.getItem("userId"))) {
                    messageElement.classList.add("sent");
                } else {
                    messageElement.classList.add("received");
                }

                messageElement.textContent = message.text_message;
                chatMessages.appendChild(messageElement);
            });

            // Desplazar hacia abajo automáticamente para ver el último mensaje
            chatMessages.scrollTop = chatMessages.scrollHeight;
        })
        .catch(err => {
            console.error("Error loading messages:", err);
            const chatMessages = document.getElementById('chatMessages');
            chatMessages.innerHTML = "<p>Error loading messages.</p>";
        });
}

// Enviar mensaje (se agrega a la lista de mensajes)
function sendMessage() {
    const messageInput = document.getElementById('messageInput');
    const message = messageInput.value.trim();

    if (!message) {
        alert('Please type a message.');
        return;
    }

    const chatId = parseInt(localStorage.getItem("chatId"));
    const userId = parseInt(localStorage.getItem("userId"));

    if (!userId || isNaN(userId)) {
        alert("User not logged in. Please log in again.");
        window.location.href = "../login/login.html";
        return;
    }

    const receiverId = parseInt(localStorage.getItem("id_receiver"));

    const messageData = {
        id_chat_sender: chatId, // ID del chat actual
        content_media: "",      // Vacío, ya que no usamos multimedia
        text_content: message,  // El mensaje de texto
        id_user: userId,        // ID del usuario actual
        id_receiver: receiverId // ID del receptor del mensaje
    };

    // Simular el envío del mensaje agregándolo a la lista
    messages.push({
        id_chat: chatId,
        id_chat_sender: userId,
        id_receiver: receiverId,
        text_message: message,
        sender_id: userId,
    });
    sendMessageToDatabase(messageData)

    messageInput.value = ""; // Limpiar el input
    appendMessageToChat(messageData); // Agregar el mensaje al chat en la interfaz

}


function sendMessageToDatabase(messageData) {
    // Enviar el mensaje a la base de datos utilizando la API
    fetch("http://localhost:8000/api/message/send", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(messageData)
    })
        .then(response => {
            if (response.status === 204) {
                // Si la respuesta es 204, significa que la acción fue exitosa, pero no hay contenido
                console.log("Message sent successfully");
            } else {
                return response.json(); // Si la respuesta no es 204, procesamos la respuesta JSON
            }
        })
        .then(data => {
            if (data) {
                console.log("Message sent:", data);
            }
        })
        .catch(error => {
            console.error("Error sending message:", error);
            alert("Failed to send message. Please try again.");
        });
}

// Agregar el mensaje a la interfaz
function appendMessageToChat(message) {
    const chatMessages = document.getElementById('chatMessages');
    const messageElement = document.createElement("div");

     messageElement.classList.add("message");
    if (message.id_chat_sender === parseInt(localStorage.getItem("chatId"))) {
        messageElement.classList.add("sent");
    } else {
        messageElement.classList.add("received");
    }   
    messageElement.textContent = message.text_content;

    chatMessages.appendChild(messageElement);

    // Desplazar hacia abajo automáticamente para ver el último mensaje
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

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

