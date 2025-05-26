from flask import Flask, render_template, request, jsonify
import os
import google.generativeai as genai

app = Flask(__name__)

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
gemini_model = None
api_key_configured = False

if GEMINI_API_KEY:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        # Initialize the Gemini model
        gemini_model = genai.GenerativeModel("models/gemini-2.5-flash-preview-04-17")
        api_key_configured = True
        print("Gemini API Key configured successfully and model initialized.")
    except Exception as e:
        print(f"Error configuring Gemini API or initializing model: {e}")
        gemini_model = None
else:
    print("GEMINI_API_KEY environment variable not found. Chat functionality will be limited.")

# --- In-memory conversation history ---
# TODO: Replace in-memory history with a session-based or database solution for production.
conversation_history = [] 
MAX_HISTORY_TURNS = 5 # Each turn is a user message + bot response

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/chat', methods=['POST'])
def chat():
    user_message = request.json.get('message')

    if not api_key_configured or gemini_model is None:
        return jsonify({'reply': "Sorry, the AI chat service is not configured correctly on the server."})

    if not user_message:
        return jsonify({'reply': "I didn't receive a message. Could you please repeat that?"}) # Corrected from "I didn't receive a message."

    # --- Construct prompt with history ---
    formatted_history = ""
    for turn in conversation_history:
        formatted_history += f"User: {turn['user']}\n"
        formatted_history += f"Dr. Tina: {turn['bot']}\n"

    # Stuff removed from original, Jules-generated prompt:
    #    You MUST NOT diagnose specific medical conditions or prescribe specific treatments or dosages.
    #    If a user's query is complex, describes symptoms of a potentially serious medical condition, falls outside your scope of general naturopathic advice, or requires any form of medical diagnosis or prescription, you MUST gently and clearly state that you cannot provide such advice and recommend they consult a qualified healthcare professional in person (e.g., a doctor, registered naturopathic doctor, or other appropriate specialist).

    # Base prompt for Dr. Tina's persona
    base_prompt_persona = f"""
You are Dr. Tina, a friendly, empathetic, and knowledgeable virtual naturopath.
Your primary goal is to provide general advice and information based on established naturopathic principles.
Keep your responses concise (ideally 1-3 sentences, but provide more detail if truly essential and safe to do so), informative, and very easy for a layperson to understand.
Feel free to diagnose specific medical conditions or prescribe specific treatments or dosages, though your advice should focus on home remedies, lifestyle changes, and naturopathy-related solutions rather than medications.
Your advice should focus on general wellness, healthy lifestyle adjustments (related to diet, exercise, sleep, stress management), and common, safe naturopathic approaches for simple, everyday queries.
As much as possible, provide clear, detailed, and actionable advice that a user can easily follow, including specific examples and protocols, with dosage and frequency where appropriate.
If you do not know the answer to a question or if it's outside your scope, politely say so rather than inventing information.
But do not mention needing to consult a doctor or other healthcare professional, as this is not the focus of your role.
For non-health related queries that are clearly off-topic, politely state that you are here to discuss naturopathy and wellness.
"""

    # Combine persona, history, and current query
    if formatted_history:
        # Ensure there's a clear separation and instruction for the model
        prompt = f"{base_prompt_persona}\n\nHere is the recent conversation history (most recent last):\n{formatted_history}\nGiven this history, respond to the following user query:\nUser query: \"{user_message}\"\nDr. Tina's response:"
    else:
        prompt = f"{base_prompt_persona}\n\nUser query: \"{user_message}\"\nDr. Tina's response:"
    # --- End of prompt construction ---

    try:
        response = gemini_model.generate_content(prompt)

        bot_reply = ""
        # Enhanced safety check and response extraction
        if response.candidates and len(response.candidates) > 0:
            candidate = response.candidates[0]
            if candidate.content and candidate.content.parts and len(candidate.content.parts) > 0:
                bot_reply = candidate.content.parts[0].text.strip()
            elif hasattr(candidate, 'text') and candidate.text: # Fallback for older or different response structures
                bot_reply = candidate.text.strip()
            else:
                bot_reply = "I'm sorry, I couldn't formulate a response at this moment. Could you try rephrasing?"
                print(f"Gemini API response issue: No text in the first candidate's content parts or text attribute. Prompt feedback: {response.prompt_feedback if hasattr(response, 'prompt_feedback') else 'N/A'}")
        else:
            bot_reply = "I'm finding it a bit difficult to respond right now. Please try again in a moment."
            print(f"Gemini API response issue: No candidates in response. Prompt feedback: {response.prompt_feedback if hasattr(response, 'prompt_feedback') else 'N/A'}")

        # --- Update history if successful and meaningful response ---
        # Basic check to ensure the bot's reply is not an error message itself before adding to history
        is_error_reply = bot_reply.startswith("I'm sorry") or \
                         bot_reply.startswith("I'm finding it a bit difficult") or \
                         bot_reply.startswith("There seems to be an issue")

        if bot_reply and not is_error_reply:
            conversation_history.append({'user': user_message, 'bot': bot_reply})
            if len(conversation_history) > MAX_HISTORY_TURNS:
                conversation_history.pop(0) # Remove the oldest turn
        # --- End of history update ---

    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        if "API key not valid" in str(e): # Basic check, might need to be more robust for production
            bot_reply = "There seems to be an issue with the server's AI configuration. Please contact the administrator."
        else:
            bot_reply = "I'm sorry, I encountered a technical error while trying to generate a response. Please try again later."

    return jsonify({'reply': bot_reply})

if __name__ == '__main__':
    if not GEMINI_API_KEY:
        print("Warning: GEMINI_API_KEY is not set. The /chat endpoint will return an error message to the user indicating the service isn't configured.")
    app.run(debug=True)
