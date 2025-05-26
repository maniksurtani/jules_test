$(document).ready(function() {
    $('#chat-form').on('submit', function(e) {
        e.preventDefault(); // Prevent page refresh
        let userInput = $('#user-input').val();
        if (userInput.trim() === '') {
            return; // Don't send empty messages
        }

        appendMessage('You', userInput, true); // Display user's message
        $('#user-input').val(''); // Clear input field

        // Send message to Flask backend
        sendMessageToServer(userInput);
    });

    function appendMessage(author, text, isUser) {
        const chatLog = $('#chat-log');
        // Determine avatar: User gets an icon, Dr. Tina gets her image (or icon fallback)
        // For Dr. Tina, we attempt to use the main avatar image if available, otherwise fallback to an icon.
        // The main avatar image is identified by the id="dr-tina-avatar-img" on an <img> tag.
        // If that specific img tag isn't found, or has no src, we use an icon.
        let botAvatarHtml = '<i class="user md circular icon"></i>'; // Default fallback icon
        const drTinaAvatarImg = $('#dr-tina-avatar-img'); // Check if an <img> with this ID exists

        if (drTinaAvatarImg.length > 0 && drTinaAvatarImg.attr('src') && drTinaAvatarImg.attr('src').trim() !== '') {
            botAvatarHtml = `<img src="${drTinaAvatarImg.attr('src')}" alt="Dr. Tina avatar" class="ui avatar image">`;
        } else {
            // If the main avatar is an icon (or image not found), use an icon in chat.
            // We select the class from the main avatar icon, assuming it's an <i> tag.
            const mainAvatarIconClasses = $('.ui.fluid.card .image i.icon').attr('class');
            if (mainAvatarIconClasses) {
                 // Reconstruct the icon tag, ensuring it's styled as an avatar for chat.
                botAvatarHtml = `<i class="${mainAvatarIconClasses} avatar"></i>`;
            }
        }


        const messageHtml = `
            <div class="comment ${isUser ? 'user-message' : 'bot-message'}">
                <a class="avatar">
                    ${isUser ? '<i class="user circle small icon avatar"></i>' : botAvatarHtml}
                </a>
                <div class="content">
                    <a class="author">${author}</a>
                    <div class="metadata">
                        <span class="date">${new Date().toLocaleTimeString()}</span>
                    </div>
                    <div class="text">${$('<div/>').text(text).html()}</div> <!-- Sanitize text before adding -->
                </div>
            </div>
        `;
        chatLog.append(messageHtml);
        chatLog.scrollTop(chatLog.prop("scrollHeight")); // Scroll to bottom
    }

    function sendMessageToServer(message) {
        const chatLog = $('#chat-log');
        
        // Determine bot avatar for typing indicator (same logic as appendMessage)
        let botAvatarHtmlTyping = '<i class="user md circular icon"></i>';
        const drTinaAvatarImgTyping = $('#dr-tina-avatar-img');
        if (drTinaAvatarImgTyping.length > 0 && drTinaAvatarImgTyping.attr('src') && drTinaAvatarImgTyping.attr('src').trim() !== '') {
            botAvatarHtmlTyping = `<img src="${drTinaAvatarImgTyping.attr('src')}" alt="Dr. Tina avatar" class="ui avatar image">`;
        } else {
            const mainAvatarIconClassesTyping = $('.ui.fluid.card .image i.icon').attr('class');
            if (mainAvatarIconClassesTyping) {
                botAvatarHtmlTyping = `<i class="${mainAvatarIconClassesTyping} avatar"></i>`;
            }
        }

        // Optional: Show typing indicator
        const typingIndicatorHtml = `
            <div class="comment bot-message" id="typing-indicator">
                <a class="avatar">
                    ${botAvatarHtmlTyping}
                </a>
                <div class="content">
                    <a class="author">Dr. Tina</a>
                    <div class="text"><em>typing...</em></div>
                </div>
            </div>`;
        chatLog.append(typingIndicatorHtml);
        chatLog.scrollTop(chatLog.prop("scrollHeight"));

        $.ajax({
            url: '/chat', // The Flask endpoint
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ message: message }),
            success: function(data) {
                $('#typing-indicator').remove(); // Remove typing indicator
                if (data.reply) {
                    appendMessage('Dr. Tina', data.reply, false);
                } else {
                    appendMessage('Dr. Tina', 'Sorry, I encountered an error processing your message.', false);
                }
            },
            error: function(xhr, status, error) {
                $('#typing-indicator').remove(); // Remove typing indicator
                console.error("Error sending message to server:", status, error, xhr.responseText);
                appendMessage('Dr. Tina', 'Sorry, I could not connect to the server. Please try again later.', false);
            }
        });
    }

    // The existing HTML already has a welcome message from Dr. Tina in the chat log.
    // No explicit client-side initial greeting here to avoid duplication.
});
