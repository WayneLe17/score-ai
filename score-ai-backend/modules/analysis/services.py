import logging
import uuid
import os
import threading
from flask import current_app
from werkzeug.utils import secure_filename
from core.storage import storage_service
from core.firestore import firestore_service
from core.schemas import ServiceResult
from modules.processing import processing_service
def run_processing_in_background(app, job_id, gcs_path):
    with app.app_context():
        logging.info(f"Background task started for job {job_id}.")
        processing_service.solve_from_gcs_path(job_id, gcs_path)
        logging.info(f"Background task finished for job {job_id}.")
class AnalysisService:
    def upload_and_create_job(self, file, user_id: str) -> ServiceResult:
        if not file or not file.filename:
            return ServiceResult.failure_result("No file provided.")
        filename = secure_filename(file.filename)
        unique_filename = f"{uuid.uuid4()}-{filename}"
        temp_dir = "/tmp"
        if not os.path.exists(temp_dir):
            os.makedirs(temp_dir)
        local_path = os.path.join(temp_dir, unique_filename)
        file.save(local_path)
        upload_result = storage_service.upload_file(
            source_file_name=local_path, 
            destination_blob_name=unique_filename,
            content_type=file.content_type
        )
        os.remove(local_path)
        if not upload_result.success:
            return upload_result
        gcs_path = upload_result.data['gcs_path']
        job_result = firestore_service.create_job(user_id=user_id, file_gcs_path=gcs_path)
        if job_result.success:
            job_id = job_result.data['job_id']
            app = current_app._get_current_object()
            thread = threading.Thread(
                target=run_processing_in_background,
                args=(app, job_id, gcs_path)
            )
            thread.daemon = True
            thread.start()
            logging.info(f"Job {job_id} created and background processing started.")
        return job_result
analysis_service = AnalysisService()