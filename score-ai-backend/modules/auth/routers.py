from flask import Blueprint, jsonify, g
from core.security import login_required

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/me", methods=["GET"])
@login_required
def get_current_user():
    """
    Get Current User
    ---
    security:
      - bearerAuth: []
    responses:
      200:
        description: Returns the current user's information.
        schema:
          type: object
          properties:
            uid:
              type: string
              example: "some-uid"
            email:
              type: string
              example: "user@example.com"
            name:
              type: string
              example: "John Doe"
      401:
        description: Unauthorized.
    """
    return jsonify(g.user), 200
