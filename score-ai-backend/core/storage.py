import logging
import datetime
from google.cloud import storage
from config import settings
from core.schemas import ServiceResult
class Storage:
    def __init__(self):
        self.client = storage.Client(project=settings.PROJECT_ID)
        self.bucket_name = settings.STORAGE_BUCKET
    def get_bucket(self):
        return self.client.get_bucket(self.bucket_name)
    def upload_file(self, source_file_name: str, destination_blob_name: str, content_type: str = None) -> ServiceResult:
        try:
            bucket = self.get_bucket()
            blob = bucket.blob(destination_blob_name)
            with open(source_file_name, "rb") as f:
                blob.upload_from_file(f, content_type=content_type)
            gcs_path = f"gs://{self.bucket_name}/{destination_blob_name}"
            logging.info(f"File {source_file_name} uploaded to {destination_blob_name} with content type {content_type}.")
            return ServiceResult.success_result(data={'gcs_path': gcs_path})
        except Exception as e:
            logging.error(f"Error uploading file: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def generate_signed_url(self, blob_name: str, expiration_mins: int = 15) -> ServiceResult:
        try:
            bucket = self.get_bucket()
            blob = bucket.blob(blob_name)
            url = blob.generate_signed_url(
                version="v4",
                expiration=datetime.timedelta(minutes=expiration_mins),
                method="GET",
            )
            return ServiceResult.success_result(data={'url': url})
        except Exception as e:
            logging.error(f"Error generating signed URL: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
storage_service = Storage()