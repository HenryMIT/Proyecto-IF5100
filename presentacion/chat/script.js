function sendMessage() {
  const input = document.getElementById("inputMessage");
  const msg = input.value.trim();
  if (msg === "") return;

  const chat = document.getElementById("chat-messages");
  const newMsg = document.createElement("div");
  newMsg.className = "message sent";
  newMsg.textContent = msg;

  chat.appendChild(newMsg);
  input.value = "";
  chat.scrollTop = chat.scrollHeight;
}

