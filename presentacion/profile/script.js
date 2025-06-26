document.addEventListener('DOMContentLoaded', () => {
    const userIdInput = document.getElementById('userId');
    const usernameInput = document.getElementById('username');
    const emailInput = document.getElementById('email');
    const phoneInput = document.getElementById('phone');
    const passwordInput = document.getElementById('password');
    const profileDescInput = document.getElementById('profileDescription');
    const previewPhoto = document.getElementById('previewPhoto');
    const photoUpload = document.getElementById('photoUpload');
    const profileForm = document.getElementById('profileForm');

    // Obtén el id guardado al hacer login
    const userId = localStorage.getItem('userId');
    if (!userId) {
        alert('No user ID found. Please log in.');
        window.location.href = '../login/login.html';  // o donde vaya el login
        return;
    }

    userIdInput.value = userId;

    // Cargar datos del usuario desde backend
    fetch(`http://localhost:8000/api/usr/loadProfile/${userId}`)
        .then(res => {
            if (!res.ok) throw new Error('Failed to load profile');
            return res.json();
        })
        .then(data => {
            usernameInput.value = data.username || '';
            emailInput.value = data.email || '';
            phoneInput.value = data.phone_number || '';
            profileDescInput.value = data.profile_description || '';
            if (data.profile_picture) {
                previewPhoto.src = data.profile_picture;
            }
        })
        .catch(err => {
            alert('Error loading profile: ' + err.message);
        });

    // Preview imagen subida
    photoUpload.addEventListener('change', () => {
        const file = photoUpload.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = e => {
            previewPhoto.src = e.target.result;
        };
        reader.readAsDataURL(file);
    });

    // Enviar formulario
    profileForm.addEventListener('submit', e => {
        e.preventDefault();

        const id_usr = parseInt(userIdInput.value);
        const username = usernameInput.value.trim();
        const phone_number = phoneInput.value.trim();
        const profile_description = profileDescInput.value.trim();
        const pass = passwordInput.value.trim(); // vacío = no cambiar contraseña
        let profile_picture = previewPhoto.src;

        if (!username || !phone_number) {
            alert('Username and phone number are required.');
            return;
        }

        if (profile_picture.includes('default-profile.png')) {
            profile_picture = '';
        }

        const body = {
            id_usr,
            username,
            pass,
            phone_number,
            profile_picture,
            profile_description
        };

        fetch('http://localhost:8000/api/usr/update', {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        })
        .then(res => {
            if (res.status === 204) {
                alert('Profile updated successfully');
                passwordInput.value = '';
            } else if (res.status === 409) {
                alert('Failed to update profile. Please check your data.');
            } else {
                alert('Unexpected server response: ' + res.status);
            }
        })
        .catch(err => {
            alert('Error updating profile: ' + err.message);
        });
    });
});


// Botón volver
function goBack() {
    window.location.href = '../chat_view/chat.html';
}
