import logging
from google import generativeai as genai
from config import settings


class ChatService:
    def __init__(self):
        try:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.model = genai.GenerativeModel(model_name=settings.GEMINI_MODEL_NAME)
        except Exception as e:
            logging.error(f"Error initializing ChatService: {e}")
            self.model = None

    def get_ai_explanation_stream(self, question: dict, chat_history: list):
        if not self.model:
            logging.error("Chat model not initialized.")
            yield "Error: Chat model is not initialized. Please check the server logs."
            return

        try:
            gemini_history = []
            for message in chat_history:
                role = "user" if message["role"] == "user" else "model"
                content = message.get("content", "")
                if not isinstance(content, str):
                    content = str(content)
                gemini_history.append({"role": role, "parts": [{"text": content}]})

            if gemini_history:
                for i in range(len(gemini_history) - 1, -1, -1):
                    if gemini_history[i]["role"] == "user":
                        initial_context = self.build_context(question)
                        user_message = gemini_history[i]["parts"][0]["text"]
                        gemini_history[i]["parts"][0][
                            "text"
                        ] = f"{initial_context}\n\nHere is my question:\n{user_message}"
                        break

            logging.info(f"Sending content to Gemini: {gemini_history}")

            response_stream = self.model.generate_content(
                contents=gemini_history, stream=True
            )

            for chunk in response_stream:
                if chunk.text:
                    yield chunk.text
        except Exception as e:
            logging.error(f"Error getting AI explanation stream: {e}")
            yield f"Error: Failed to get AI explanation. {e}"

    def build_context(self, question: dict) -> str:
        question_text = question.get("question", "")
        correct_answer = question.get("answer", "")

        prompt_template = settings.PROMPTS_CONFIG.get("chat_context", "")
        logging.info(f"Prompt template: {prompt_template}")
        return prompt_template.format(
            question_text=question_text, correct_answer=correct_answer
        )