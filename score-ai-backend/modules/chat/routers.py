from flask import Blueprint, request, jsonify, g, Response, stream_with_context
from core.security import login_required
from . import chat_service
from core.firestore import firestore_service

chat_bp = Blueprint("chat", __name__, url_prefix="/chat")


@chat_bp.route("/<job_id>/explain", methods=["POST"])
@login_required
def explain_question(job_id: str):
    """
    Explain a question based on the job's context.
    ---
    tags:
      - Chat
    security:
      - bearerAuth: []
    parameters:
      - in: path
        name: job_id
        type: string
        required: true
        description: The ID of the job to which the question pertains.
      - in: body
        name: body
        schema:
          type: object
          required:
            - question
          properties:
            question:
              type: string
              description: The question to be explained.
            chat_history:
              type: array
              items:
                type: object
              description: A list of previous chat messages to provide context.
    responses:
      200:
        description: A stream of the AI's explanation.
        schema:
          type: string
      400:
        description: Bad Request, e.g., question is missing.
      403:
        description: Unauthorized to access this job.
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

    data = request.get_json()
    question = data.get("question")
    chat_history = data.get("chat_history", [])

    if not question:
        return jsonify({"message": "Question is required"}), 400

    return Response(
        stream_with_context(
            chat_service.get_ai_explanation_stream(
                question=question, chat_history=chat_history
            )
        ),
        content_type="text/event-stream",
    ) 