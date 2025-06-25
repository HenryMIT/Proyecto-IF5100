document.addEventListener("DOMContentLoaded", () => {
  // Obtener userId del localStorage
  const userId = parseInt(localStorage.getItem("userId"));

  if (!userId || isNaN(userId)) {
    alert("No se encontró el ID de usuario. Por favor inicia sesión.");
    window.location.href = "../login/login.html";
    return;
  }

  document.getElementById("userId").value = userId;

  // Cargar contactos al inicio
  loadContacts(userId);

  // Formulario para agregar contacto
  document.getElementById("contactForm").addEventListener("submit", function (e) {
    e.preventDefault();

    const phone = document.getElementById("phone").value.trim();
    const name = document.getElementById("contactName").value.trim();

    if (!phone || !name) {
      alert("Por favor completa todos los campos.");
      return;
    }

    fetch("http://localhost:8000/api/contact/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        p_id_user: userId,
        p_contact_number: phone,
        p_contact_name: name
      })
    })
      .then(res => {
        // Tu backend devuelve solo status, sin JSON en body
        if (res.status === 204) return { result: 1 }; // éxito
        if (res.status === 409) return { result: 0 }; // conflicto/error
        throw new Error(`Respuesta inesperada: ${res.status}`);
      })
      .then(result => {
        if (result.result === 1) {
          alert("¡Contacto agregado exitosamente!");
          loadContacts(userId);
          document.getElementById("phone").value = "";
          document.getElementById("contactName").value = "";
        } else if (result.result === 0) {
          alert("No se pudo agregar el contacto. Puede que ya exista o el número no esté registrado como usuario.");
        }
      })
      .catch(err => {
        console.error("Error al agregar contacto:", err);
        alert("Error al agregar contacto.");
      });
  });
});

function loadContacts(userId) {
  const params = new URLSearchParams({
    p_lim: 100,
    p_pag: 0,
    p_phone_contact: "",
    p_contact_name: "",
    p_id_user: userId
  }).toString();

  fetch(`http://localhost:8000/api/contact/load?${params}`, {
    method: "GET"
  })
    .then(res => {
      if (!res.ok) throw new Error("Respuesta de red no OK");
      return res.json().catch(() => []);
    })
    .then(data => {
      if (!Array.isArray(data)) data = [];

      const list = document.getElementById("contactList");
      list.innerHTML = "";

      if (data.length === 0) {
        const li = document.createElement("li");
        li.textContent = "No se encontraron contactos.";
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
      console.error("Error al cargar contactos:", err);
      alert("No se pudieron cargar los contactos.");
    });
}

function goBack() {
  window.location.href = "../chat/chat.html";
}
