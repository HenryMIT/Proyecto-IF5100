// Handle image previewAdd commentMore actions
const photoUpload = document.getElementById('photoUpload');
const previewPhoto = document.getElementById('previewPhoto');

if (photoUpload && previewPhoto) {
    photoUpload.addEventListener('change', function () {
        const file = photoUpload.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function (e) {
                previewPhoto.src = e.target.result;
                // Optional: store e.target.result for use in chat.html
                localStorage.setItem('profilePhoto', e.target.result);
            };
            reader.readAsDataURL(file);
        }
    });
}

// Handle profile form submission
const profileForm = document.getElementById('profileForm');
if (profileForm) {
    profileForm.addEventListener('submit', function (e) {
        e.preventDefault();
        alert("Profile updated. (Data not saved yet)");
        // Future: Save data to backend or local storage
    });
}

// Back button
function goBack() {
    window.location.href = '../chat_view/chat.html';
}