import os
from flask import Flask, jsonify, send_from_directory
from flask_socketio import SocketIO
from config import get_settings

settings = get_settings()
settings.configure_threading()

app = Flask(__name__, static_folder="frontend/dist", static_url_path="")
app.config["SECRET_KEY"] = settings.app_key
app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024

socketio = SocketIO(
    app,
    cors_allowed_origins=settings.cors_origins,
    cors_credentials=settings.cors_credentials,
    async_mode="eventlet",
    ping_timeout=86400,
    ping_interval=30,
    message_queue=settings.redis_url,
    engineio_logger=False,
)


@app.route("/")
def index():
    dist_index = os.path.join(app.static_folder, "index.html")
    if os.path.exists(dist_index):
        return send_from_directory(app.static_folder, "index.html")
    return jsonify({
        "name": "FOSS Universe",
        "version": "1.0.0",
        "status": "ok",
        "message": "Backend is healthy. Frontend build pending.",
        "endpoints": ["/api/health", "/auth/check-setup"]
    })


@app.route("/auth/check-setup")
def check_setup():
    return jsonify({
        "status": "ok",
        "has_api_key": settings.has_api_key,
        "broker_configured": bool(settings.broker_api_key),
    })


@app.route("/api/health")
def health():
    return jsonify({"status": "healthy", "env": settings.flask_env})


@app.errorhandler(404)
def not_found(e):
    if e.description == "Not Found":
        return send_from_directory(app.static_folder, "index.html")
    return jsonify({"error": "Not found"}), 404


if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=8001, debug=bool(settings.flask_debug))
