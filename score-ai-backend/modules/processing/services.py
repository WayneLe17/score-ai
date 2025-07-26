import logging
import io
import base64
import fitz
from config import settings
from google import genai
from google.cloud import storage
from core.firestore import firestore_service
from core.schemas import ServiceResult, PageProcessingResponse


class ProcessingService:
    def __init__(self):
        self.client = genai.Client(
            api_key=settings.GEMINI_API_KEY,
        )
        self.storage_client = storage.Client()

    def get_file_from_gcs(self, gcs_path: str) -> (bytes, str):
        try:
            bucket_name = settings.STORAGE_BUCKET
            blob_name = gcs_path.replace(f"gs://{bucket_name}/", "")
            bucket = self.storage_client.bucket(bucket_name)
            blob = bucket.blob(blob_name)
            blob.reload()
            content_type = blob.content_type
            file_bytes = blob.download_as_bytes()
            return file_bytes, content_type
        except Exception as e:
            logging.error(f"Error downloading file from GCS: {e}")
            raise

    def process_page(self, data) -> ServiceResult:
        prompt = settings.PROMPTS_CONFIG.get(
            "math_problem",
        )
        try:
            if isinstance(data, tuple) and data[0] == "IMAGE":
                _, file_bytes, content_type = data
                file_base64 = base64.b64encode(file_bytes).decode("utf-8")
                file_part = {
                    "inline_data": {"mime_type": content_type, "data": file_base64}
                }
            else:
                pdf_bytes = data
                pdf_base64 = base64.b64encode(pdf_bytes).decode("utf-8")
                file_part = {
                    "inline_data": {"mime_type": "application/pdf", "data": pdf_base64}
                }
            contents = [prompt, file_part]
            response = self.client.models.generate_content(
                model=settings.GEMINI_MODEL_NAME,
                contents=contents,
                config={
                    "response_mime_type": "application/json",
                    "response_schema": PageProcessingResponse,
                },
            )
            response = response.parsed
            logging.info(f"Response: {response}")
            legacy_format = [
                {"question": qa.question, "answer": qa.answer}
                for qa in response.questions_and_answers
            ]
            logging.info(
                f"Successfully processed page with {len(legacy_format)} questions."
            )
            return ServiceResult.success_result(
                data=legacy_format,
                message=f"Page processed successfully with {len(legacy_format)} questions",
            )
        except Exception as e:
            msg = f"Page processing failed: {str(e)}"
            logging.error(msg)
            return ServiceResult.failure_result(message=msg, status_code=500)

    def solve_from_gcs_path(self, job_id: str, gcs_path: str):
        logging.info(f"Starting solving process for job {job_id} with file {gcs_path}.")
        try:
            file_bytes, content_type = self.get_file_from_gcs(gcs_path)
            logging.info(
                f"Retrieved file from GCS. Content type: {content_type}, File size: {len(file_bytes)} bytes"
            )
            page_pdfs = []
            if content_type and "pdf" in content_type.lower():
                logging.info(f"Processing as PDF file. Content type: {content_type}")
                pdf_document = fitz.open(stream=file_bytes, filetype="pdf")
                firestore_service.update_job(job_id, {"page_count": len(pdf_document)})
                for page_num in range(len(pdf_document)):
                    single_page_pdf = fitz.open()
                    single_page_pdf.insert_pdf(
                        pdf_document, from_page=page_num, to_page=page_num
                    )
                    pdf_byte_arr = io.BytesIO()
                    single_page_pdf.save(pdf_byte_arr)
                    single_page_pdf.close()
                    page_pdfs.append(pdf_byte_arr.getvalue())
                pdf_document.close()
            elif (
                content_type
                and (
                    "image" in content_type.lower()
                    or content_type.lower().startswith("image/")
                )
            ) or (
                not content_type
                and gcs_path.lower().endswith(
                    (".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp")
                )
            ):
                logging.info(f"Processing image directly. Content type: {content_type}")
                firestore_service.update_job(job_id, {"page_count": 1})
                actual_content_type = content_type or "image/jpeg"
                page_pdfs.append(("IMAGE", file_bytes, actual_content_type))
            else:
                logging.warning(
                    f"Unknown content type: {content_type}, file path: {gcs_path}. Attempting to process as PDF."
                )
                firestore_service.update_job(job_id, {"page_count": 1})
                page_pdfs.append(file_bytes)
            for i, page_data in enumerate(page_pdfs):
                page_number = i + 1
                logging.info(f"Processing page {page_number} for job {job_id}.")
                result = self.process_page(page_data)
                if result.success:
                    firestore_service.add_page_result(job_id, page_number, result.data)
                else:
                    logging.error(
                        f"Failed to process page {page_number}: {result.message}"
                    )
                    firestore_service.add_page_result(job_id, page_number, [])
            firestore_service.update_job(job_id, {"status": "completed"})
            logging.info(f"Successfully completed job {job_id}.")
        except Exception as e:
            logging.error(f"Error during solve_from_gcs_path for job {job_id}: {e}")
            firestore_service.update_job(
                job_id, {"status": "failed", "error_message": str(e)}
            )


processing_service = ProcessingService()
