from logging.config import dictConfig
from flask import Flask
from flasgger import Swagger
from flask_cors import CORS
from modules.health.routers import health_bp
from modules.auth.routers import auth_bp
from modules.analysis.routers import analysis_bp
dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://sys.stdout',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})
def create_app():
    app = Flask(__name__)
    CORS(app)
    app.config.from_mapping(
        SECRET_KEY='dev',
    )
    Swagger(app)
    app.register_blueprint(health_bp, url_prefix='/health')
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(analysis_bp, url_prefix='/analysis')
    return app