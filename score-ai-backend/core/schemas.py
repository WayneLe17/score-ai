from dataclasses import dataclass
from typing import Any, Optional, List
from pydantic import BaseModel
@dataclass
class ServiceResult:
    success: bool
    message: str
    data: Any = None
    status_code: Optional[int] = None
    @classmethod
    def success_result(cls, data: Any = None, message: str = "Success", status_code: int = 200):
        return cls(success=True, message=message, data=data, status_code=status_code)
    @classmethod
    def failure_result(cls, message: str, status_code: int = 400):
        return cls(success=False, message=message, data=None, status_code=status_code)
class QuestionAnswer(BaseModel):
    question: str
    answer: str
    is_homework_problem: bool
class PageProcessingResponse(BaseModel):
    questions_and_answers: List[QuestionAnswer]