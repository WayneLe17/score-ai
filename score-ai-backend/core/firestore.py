import logging
from google.cloud import firestore
from config import settings
from core.schemas import ServiceResult
class FirestoreService:
    def __init__(self):
        self.db = firestore.Client(
            project=settings.PROJECT_ID,
            database=settings.FIRESTORE_DB
        )
    def create_job(self, user_id: str, file_gcs_path: str) -> ServiceResult:
        try:
            job_ref = self.db.collection('jobs').document()
            job_data = {
                'user_id': user_id,
                'file_gcs_path': file_gcs_path,
                'status': 'processing',
                'page_count': 0,
                'processed_pages': 0,
                'created_at': firestore.SERVER_TIMESTAMP,
                'updated_at': firestore.SERVER_TIMESTAMP,
            }
            job_ref.set(job_data)
            logging.info(f"Created Firestore job with ID: {job_ref.id}")
            return ServiceResult.success_result(data={'job_id': job_ref.id}, status_code=201)
        except Exception as e:
            logging.error(f"Error creating Firestore job: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def get_job(self, job_id: str) -> ServiceResult:
        try:
            job_ref = self.db.collection('jobs').document(job_id)
            job = job_ref.get()
            if job.exists:
                return ServiceResult.success_result(data=job.to_dict())
            return ServiceResult.failure_result(message="Job not found", status_code=404)
        except Exception as e:
            logging.error(f"Error getting Firestore job {job_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def update_job(self, job_id: str, data: dict) -> ServiceResult:
        try:
            job_ref = self.db.collection('jobs').document(job_id)
            data['updated_at'] = firestore.SERVER_TIMESTAMP
            job_ref.update(data)
            logging.info(f"Updated Firestore job {job_id} with data: {data}")
            return ServiceResult.success_result()
        except Exception as e:
            logging.error(f"Error updating Firestore job {job_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def delete_job(self, job_id: str) -> ServiceResult:
        try:
            results_ref = self.db.collection('jobs').document(job_id).collection('results')
            results_docs = results_ref.stream()
            batch = self.db.batch()
            batch_count = 0
            for result_doc in results_docs:
                batch.delete(result_doc.reference)
                batch_count += 1
                if batch_count >= 500:
                    batch.commit()
                    batch = self.db.batch()
                    batch_count = 0
            if batch_count > 0:
                batch.commit()
            job_ref = self.db.collection('jobs').document(job_id)
            job_ref.delete()
            logging.info(f"Deleted Firestore job {job_id} and all associated results")
            return ServiceResult.success_result()
        except Exception as e:
            logging.error(f"Error deleting Firestore job {job_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def delete_all_jobs_for_user(self, user_id: str) -> ServiceResult:
        try:
            jobs_query = self.db.collection('jobs').where('user_id', '==', user_id)
            jobs_docs = jobs_query.stream()
            deleted_count = 0
            for job_doc in jobs_docs:
                job_id = job_doc.id
                delete_result = self.delete_job(job_id)
                if delete_result.success:
                    deleted_count += 1
                else:
                    logging.warning(f"Failed to delete job {job_id}: {delete_result.message}")
            logging.info(f"Deleted {deleted_count} jobs for user {user_id}")
            return ServiceResult.success_result(data={'deleted_count': deleted_count})
        except Exception as e:
            logging.error(f"Error deleting all jobs for user {user_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def add_page_result(self, job_id: str, page_number: int, results: list) -> ServiceResult:
        try:
            page_ref = self.db.collection('jobs').document(job_id).collection('results').document(f'page_{page_number}')
            page_ref.set({
                'page_number': page_number,
                'results': results,
                'created_at': firestore.SERVER_TIMESTAMP
            })
            job_ref = self.db.collection('jobs').document(job_id)
            job_ref.update({'processed_pages': firestore.Increment(1)})
            return ServiceResult.success_result()
        except Exception as e:
            logging.error(f"Error adding page result for job {job_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def get_job_results_paginated(self, job_id: str, page_size: int, cursor: str = None) -> ServiceResult:
        try:
            query = self.db.collection('jobs').document(job_id).collection('results').order_by('page_number').limit(page_size)
            if cursor:
                cursor_snapshot = self.db.collection('jobs').document(job_id).collection('results').document(cursor).get()
                if not cursor_snapshot.exists:
                    return ServiceResult.failure_result("Invalid cursor", 400)
                query = query.start_after(cursor_snapshot)
            docs = list(query.stream())
            results = [doc.to_dict() for doc in docs]
            next_cursor = None
            if len(docs) == page_size:
                next_cursor = docs[-1].id
            return ServiceResult.success_result(data={'results': results, 'next_cursor': next_cursor})
        except Exception as e:
            logging.error(f"Error getting paginated results for job {job_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
    def get_jobs_for_user(self, user_id: str) -> ServiceResult:
        try:
            query = self.db.collection('jobs').where('user_id', '==', user_id).order_by('created_at', direction=firestore.Query.DESCENDING)
            docs = query.stream()
            jobs = []
            completed_job_ids = []
            for doc in docs:
                job_data = doc.to_dict()
                job_data['id'] = doc.id
                jobs.append(job_data)
                if job_data.get('status') == 'completed':
                    completed_job_ids.append(doc.id)
            if completed_job_ids:
                limited_job_ids = completed_job_ids[:20]
                batch_size = 10  
                for i in range(0, len(limited_job_ids), batch_size):
                    batch_job_ids = limited_job_ids[i:i + batch_size]
                    for job_id in batch_job_ids:
                        try:
                            first_page_ref = self.db.collection('jobs').document(job_id).collection('results').document('page_1')
                            first_page_doc = first_page_ref.get()
                            if first_page_doc.exists:
                                page_data = first_page_doc.to_dict()
                                if page_data and 'results' in page_data:
                                    qa_pairs = page_data['results']
                                    if qa_pairs and len(qa_pairs) > 0:
                                        first_qa = qa_pairs[0]
                                        if 'question' in first_qa and first_qa['question']:
                                            for job in jobs:
                                                if job['id'] == job_id:
                                                    job['first_question'] = first_qa['question']
                                                    break
                        except Exception as e:
                            logging.warning(f"Error fetching first question for job {job_id}: {e}")
                            continue
            return ServiceResult.success_result(data=jobs)
        except Exception as e:
            logging.error(f"Error getting jobs for user {user_id}: {e}")
            return ServiceResult.failure_result(message=str(e), status_code=500)
firestore_service = FirestoreService()