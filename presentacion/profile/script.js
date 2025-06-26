document.addEventListener('DOMContentLoaded', () => {
    const userId = document.getElementById('userId').value;

    // Cargar perfil
    fetch(`http://localhost/api/usr/loadProfile/${userId}`)
        .then(res => {
            if (!res.ok) throw new Error("No se pudo cargar el perfil");
            return res.json();
        })
        .then(data => {
            document.getElementById('username').value = data.username || '';
            document.getElementById('email').value = data.email || '';
            document.getElementById('phone').value = data.phone_number || '';
            // Si hay foto, cargarla
            if (data.profile_picture) {
                document.getElementById('previewPhoto').src = data.profile_picture;
            }
        })
        .catch(err => alert("Error al cargar el perfil: " + err.message));

    // Vista previa de imagen
    document.getElementById('photoUpload').addEventListener('change', function () {
        const file = this.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function (e) {
                document.getElementById('previewPhoto').src = e.target.result;
            };
            reader.readAsDataURL(file);
        }
    });

    // Guardar cambios
    document.getElementById('profileForm').addEventListener('submit', function (e) {
        e.preventDefault();

        const id_usr = parseInt(document.getElementById('userId').value);
        const username = document.getElementById('username').value;
        const pass = ""; // Puedes agregar campo de contraseña si quieres
        const phone_number = document.getElementById('phone').value;
        const profile_description = "Perfil actualizado desde frontend"; // puedes hacer un campo si lo necesitas

        const fileInput = document.getElementById('photoUpload');
        let profile_picture = ""; // base64
        if (fileInput.files.length > 0) {
            const reader = new FileReader();
            reader.onload = function () {
                profile_picture = reader.result;

                enviarActualizacion();
            };
            reader.readAsDataURL(fileInput.files[0]);
        } else {
            profile_picture = document.getElementById('previewPhoto').src;
            enviarActualizacion();
        }

        function enviarActualizacion() {
            const body = {
                id_usr,
                username,
                pass,
                phone_number,
                profile_picture,
                profile_description
            };

            fetch('http://localhost/api/usr/update', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(body)
            })
                .then(res => {
                    if (res.status === 200) {
                        alert('Perfil actualizado correctamente');
                    } else {
                        alert('No se pudo actualizar el perfil');
                    }
                })
                .catch(err => alert('Error: ' + err.message));
        }
    });
});

function goBack() {
    window.history.back();
}

// Back button
function goBack() {
    window.location.href = '../chat_view/chat.html';
}