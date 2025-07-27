from flask import Blueprint, request, jsonify, g
from . import analysis_service
from core.security import login_required
from core.firestore import firestore_service

analysis_bp = Blueprint("analysis", __name__)


@analysis_bp.route("/jobs", methods=["GET"])
@login_required
def get_jobs():
    """
    Get All Jobs for a User
    ---
    security:
      - bearerAuth: []
    responses:
      200:
        description: A list of jobs for the user.
        schema:
          type: array
          items:
            type: object
      500:
        description: Internal server error.
    """
    user_id = g.user["uid"]
    result = firestore_service.get_jobs_for_user(user_id)
    if result.success:
        return jsonify(result.data), 200
    else:
        return jsonify({"message": result.message}), 500


@analysis_bp.route("/jobs", methods=["DELETE"])
@login_required
def clear_all_jobs():
    """
    Delete All Jobs for a User
    ---
    security:
      - bearerAuth: []
    responses:
      200:
        description: Number of jobs deleted.
        schema:
          type: object
          properties:
            message:
              type: string
            deleted_count:
              type: integer
      500:
        description: Internal server error.
    """
    user_id = g.user["uid"]
    result = firestore_service.delete_all_jobs_for_user(user_id)
    if result.success:
        return (
            jsonify(
                {
                    "message": f"Deleted {result.data['deleted_count']} jobs successfully",
                    "deleted_count": result.data["deleted_count"],
                }
            ),
            200,
        )
    else:
        return jsonify({"message": result.message}), result.status_code


@analysis_bp.route("/jobs/<job_id>", methods=["DELETE"])
@login_required
def delete_job(job_id: str):
    """
    Delete a Specific Job
    ---
    security:
      - bearerAuth: []
    parameters:
      - in: path
        name: job_id
        type: string
        required: true
        description: The ID of the job to delete.
    responses:
      200:
        description: Job deleted successfully.
      403:
        description: Unauthorized to delete this job.
      404:
        description: Job not found.
      500:
        description: Internal server error.
    """
    user_id = g.user["uid"]
    job_result = firestore_service.get_job(job_id)
    if not job_result.success:
        return jsonify({"message": job_result.message}), job_result.status_code
    job_data = job_result.data
    if job_data.get("user_id") != user_id:
        return jsonify({"message": "Unauthorized to delete this job"}), 403
    delete_result = firestore_service.delete_job(job_id)
    if delete_result.success:
        return jsonify({"message": "Job deleted successfully"}), 200
    else:
        return jsonify({"message": delete_result.message}), delete_result.status_code


@analysis_bp.route("/solve", methods=["POST"])
@login_required
def solve():
    """
    Upload a File and Create a Job
    ---
    security:
      - bearerAuth: []
    consumes:
      - multipart/form-data
    parameters:
      - in: formData
        name: file
        type: file
        required: true
        description: The file to upload for analysis.
    responses:
      200:
        description: Job created successfully.
      400:
        description: Bad request, e.g., no file part.
      500:
        description: Internal server error.
    """
    user_id = g.user["uid"]
    if "file" not in request.files:
        return jsonify({"message": "No file part in the request"}), 400
    file = request.files["file"]
    result = analysis_service.upload_and_create_job(file=file, user_id=user_id)
    if result.success:
        return jsonify(result.data), result.status_code
    else:
        return jsonify({"message": result.message}), result.status_code


@analysis_bp.route("/solve/<job_id>", methods=["GET"])
@login_required
def get_solution(job_id: str):
    """
    Get Solution for a Job
    ---
    security:
      - bearerAuth: []
    parameters:
      - in: path
        name: job_id
        type: string
        required: true
        description: The ID of the job to get the solution for.
      - in: query
        name: page_size
        type: integer
        required: false
        description: The number of results to return per page.
      - in: query
        name: cursor
        type: string
        required: false
        description: The cursor for pagination.
    responses:
      200:
        description: Job details and results.
      400:
        description: Invalid page_size parameter.
      403:
        description: Unauthorized.
      404:
        description: Job not found.
    """
    user_id = g.user["uid"]
    job_result = firestore_service.get_job(job_id)
    if not job_result.success:
        return jsonify({"message": job_result.message}), job_result.status_code
    job_data = job_result.data
    if job_data.get("user_id") != user_id:
        return jsonify({"message": "Unauthorized"}), 403
    if job_data.get("status") != "completed":
        return jsonify(job_data), 200
    try:
        page_size = int(request.args.get("page_size", 10))
    except ValueError:
        return jsonify({"message": "Invalid page_size parameter."}), 400
    cursor = request.args.get("cursor")
    results_result = firestore_service.get_job_results_paginated(
        job_id, page_size, cursor
    )
    if not results_result.success:
        return jsonify({"message": results_result.message}), results_result.status_code
    response_data = {**job_data, **results_result.data}
    return jsonify(response_data), 200
