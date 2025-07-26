from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__)


@health_bp.route("/")
def health_check():
    """
    Health Check
    ---
    responses:
      200:
        description: Returns "ok" if the service is healthy.
        schema:
          type: object
          properties:
            status:
              type: string
              example: ok
    """
    return jsonify({"status": "ok"}), 200
