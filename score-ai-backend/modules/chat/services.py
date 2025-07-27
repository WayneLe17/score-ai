import logging
from google import genai
from config import settings
from core.schemas import ServiceResult


class ChatService:
    def __init__(self):
        try:
            self.client = genai.Client()
            self.model_name = settings.GEMINI_MODEL_NAME
        except Exception as e:
            logging.error(f"Error initializing ChatService: {e}")
            self.client = None

    def get_ai_explanation(self, question: dict, chat_history: list) -> ServiceResult:
        if not self.client:
            logging.error("Chat client not initialized.")
            return ServiceResult.failure_result("Error: Chat client is not initialized. Please check the server logs.", 500)

        try:
            initial_context = self.build_context(question)
            
            if chat_history and len(chat_history) > 1:
                chat = self.client.chats.create(model=self.model_name)
                
                for i, message in enumerate(chat_history[:-1]):
                    content = message.get("content", "")
                    if not isinstance(content, str):
                        content = str(content)
                    
                    if i == 0 and message["role"] == "user":
                        content = f"{initial_context}\n\nHere is my question:\n{content}"
                    
                    if message["role"] == "user":
                        chat.send_message(content)
                
                last_message = chat_history[-1]
                if last_message["role"] == "user":
                    content = last_message.get("content", "")
                    if not isinstance(content, str):
                        content = str(content)
                    
                    response = chat.send_message(content)
                    return ServiceResult.success_result(data={"explanation": response.text})

            else:
                if chat_history:
                    content = chat_history[-1].get("content", "")
                    if not isinstance(content, str):
                        content = str(content)
                    content = f"{initial_context}\n\nHere is my question:\n{content}"
                else:
                    content = initial_context
                
                response = self.client.models.generate_content(
                    model=self.model_name,
                    contents=[content]
                )
                
                return ServiceResult.success_result(data={"explanation": response.text})

        except Exception as e:
            logging.error(f"Error getting AI explanation: {e}")
            return ServiceResult.failure_result(f"Error: Failed to get AI explanation. {e}", 500)

    def build_context(self, question: dict) -> str:
        question_text = question.get("question", "")
        correct_answer = question.get("answer", "")

        prompt_template = settings.PROMPTS_CONFIG.get("chat_context", "")
        logging.info(f"Prompt template: {prompt_template}")
        return prompt_template.format(
            question_text=question_text, correct_answer=correct_answer
        )