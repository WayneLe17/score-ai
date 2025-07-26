from firebase_functions import https_fn
from app import create_app

app = create_app()

@https_fn.on_request()
def api(req: https_fn.Request) -> https_fn.Response:
    with app.request_context(req.environ):
        return app.full_dispatch_request()

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8080)