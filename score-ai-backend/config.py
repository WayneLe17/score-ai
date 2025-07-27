from typing import Dict
from pydantic import Field
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Score AI Backend"
    DESCRIPTION: str = "Backend for Score AI"
    VERSION: str = "0.1.0"
    ENV: str = Field("development", env="ENV")
    
    # Renamed to avoid Firebase reserved prefixes
    GOOGLE_APPLICATION_CREDENTIALS: str = Field("", env="GOOGLE_APPLICATION_CREDENTIALS")
    PROJECT_ID: str = Field(..., env="PROJECT_ID")
    FIRESTORE_DB: str = Field("(default)", env="FIRESTORE_DB")
    STORAGE_BUCKET: str = Field(..., env="STORAGE_BUCKET")
    GEMINI_API_KEY: str = Field(..., env="GEMINI_API_KEY")
    GEMINI_MODEL_NAME: str = Field("gemini-2.5-flash", env="GEMINI_MODEL_NAME")
    
    PROMPTS_CONFIG: Dict[str, str] = {
        "math_problem": """
        You are an expert math solver with advanced OCR capabilities. Analyze the provided image of a document page carefully. Your task is to extract questions and answers only for subjects like Math, Science, or English. For each extracted question, determine if it is a homework problem that needs to be solved.

        Your task:
        1. First, perform OCR to extract all text from the image, paying special attention to:
        - Equations
        - Mathematical symbols
        - Textual descriptions
        2. Identify mathematical, science, or english problems or expressions in the text. Ignore other content.
        3. For each problem, determine if it is a homework problem.
        4. Solve the problem step by step, ensuring all calculations are performed accurately.
        5. Provide a detailed explanation of your solution, including all necessary steps and calculations.
        6. Format your response in markdown format, don't need to use latex symbols, keep all the text in the same language as the question. Write in markdown format. When you need to go to the new line. use \n\n instead of \n.
        7. If the problem is a multiple choice question, provide the correct answer and the explanation for why it is the correct answer.
        8. If the problem is a fill in the blank question, provide the correct answer and the explanation for why it is the correct answer.
        9. If the problem is a short answer question, provide the correct answer and the explanation for why it is the correct answer.
        10. If the problem is a long answer question, provide the correct answer and the explanation for why it is the correct answer.
        11. Make the response in paragraphs format, easy to read and understand.
        
        ### Format
        Use only markdown format to write the response. Don't even use html tags or latex symbols.
        """,
        "chat_context": """You are an AI assistant. A user is asking for help with the following math problem from a document. Your task is to answer their questions about it.

        Here is the problem context:
        --------------------
        Question: {question_text}

        Correct Answer: {correct_answer}
        --------------------
        ### Format
        Format your response in markdown format, don't need to use latex symbols, keep all the text in the same language as the question. Write in markdown format. When you need to go to the new line. use \n\n instead of \n.
        Use only markdown format to write the response. Don't even use html tags or latex symbols like <br> or \n.
""",
    }
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()