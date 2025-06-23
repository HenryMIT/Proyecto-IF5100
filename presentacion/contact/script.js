// Handle contact form
const contactForm = document.getElementById('contactForm');
if (contactForm) {
    contactForm.addEventListener('submit', function (e) {
        e.preventDefault();

        const userId = document.getElementById('userId').value;
        const phone = document.getElementById('phone').value;
        const contactName = document.getElementById('contactName').value;

        if (userId.trim() === '' || phone.trim() === '' || contactName.trim() === '') {
            alert('Please fill in all fields.');
        } else {
            alert('Contact data ready to be added. (Functionality not implemented yet)');
            // Future: send this data to the database
        }
    });
}

// Go back to chat.html
function goBack() {
    window.location.href = 'chat.html';
}
