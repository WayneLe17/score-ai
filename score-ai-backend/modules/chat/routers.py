from flask import Blueprint, request, jsonify, g, Response, stream_with_context
from core.security import login_required
from . import chat_service
from core.firestore import firestore_service

chat_bp = Blueprint("chat", __name__, url_prefix="/chat")


@chat_bp.route("/<job_id>/explain", methods=["POST"])
@login_required
def explain_question(job_id: str):
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