import logging
from google import genai
from config import settings


class ChatService:
    def __init__(self):
        try:
            self.client = genai.Client()
            self.model_name = settings.GEMINI_MODEL_NAME
        except Exception as e:
            logging.error(f"Error initializing ChatService: {e}")
            self.client = None

    def get_ai_explanation_stream(self, question: dict, chat_history: list):
        if not self.client:
            logging.error("Chat client not initialized.")
            yield "Error: Chat client is not initialized. Please check the server logs."
            return

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
                    
                    response = chat.send_message_stream(content)
                    for chunk in response:
                        if hasattr(chunk, 'text') and chunk.text:
                            yield chunk.text
                        elif hasattr(chunk, 'parts') and chunk.parts:
                            for part in chunk.parts:
                                if hasattr(part, 'text') and part.text:
                                    yield part.text
            else:
                if chat_history:
                    content = chat_history[-1].get("content", "")
                    if not isinstance(content, str):
                        content = str(content)
                    content = f"{initial_context}\n\nHere is my question:\n{content}"
                else:
                    content = initial_context
                
                response_stream = self.client.models.generate_content_stream(
                    model=self.model_name,
                    contents=[content]
                )
                
                for chunk in response_stream:
                    if hasattr(chunk, 'text') and chunk.text:
                        yield chunk.text
                    elif hasattr(chunk, 'parts') and chunk.parts:
                        for part in chunk.parts:
                            if hasattr(part, 'text') and part.text:
                                yield part.text

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