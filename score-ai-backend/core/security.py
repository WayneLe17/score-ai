from functools import wraps
from flask import request, g, jsonify
import firebase_admin
from firebase_admin import credentials, auth
from config import settings
def initialize_firebase():
    try:
        firebase_admin.get_app()
    except ValueError:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {
            'projectId': settings.PROJECT_ID,
        })
def verify_firebase_token(id_token: str):
    try:
        decoded_token = auth.verify_id_token(id_token, check_revoked=True)
        return decoded_token
    except auth.RevokedIdTokenError:
        raise Exception("ID token has been revoked.")
    except auth.UserDisabledError:
        raise Exception("User account has been disabled.")
    except auth.InvalidIdTokenError:
        raise Exception("Invalid ID token.")
    except Exception as e:
        raise e
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"message": "Authorization header is missing or invalid"}), 401
        id_token = auth_header.split('Bearer ')[1]
        try:
            decoded_token = verify_firebase_token(id_token)
            g.user = decoded_token
        except Exception as e:
            return jsonify({"message": "Token verification failed", "error": str(e)}), 401
        return f(*args, **kwargs)
    return decorated_function
initialize_firebase()