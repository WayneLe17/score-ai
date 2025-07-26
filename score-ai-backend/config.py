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
        "math_problem": "Solve this mathematical problem step by step"
    }
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()