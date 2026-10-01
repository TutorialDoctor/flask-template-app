from flask import Flask, Response

from db_init import initialize_database
from filters import register_filters
from auth import initialize_auth
from errors import register_error_handlers
from extensions import cache
from routes import routes,auth

from flask_login import current_user

config = {
    "DEBUG": True,
    "CACHE_TYPE": "SimpleCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
}

app = Flask(__name__)

from flask import Response

@app.route("/routes", methods=["GET"])
def all_routes():
    route_text = ""
    for rule in app.url_map.iter_rules():
        methods = ",".join(sorted(rule.methods - {"HEAD", "OPTIONS"}))
        route_text += f"{rule.endpoint:<20} {methods:<15} {rule.rule}\n"
    return Response(route_text, mimetype="text/plain")

@app.context_processor
def inject_global_variables():
    return dict(current_user=current_user)

app.config["SECRET_KEY"] = "thisissecret"
app.config.from_mapping(config)
cache.init_app(app, config={
    "CACHE_TYPE": "SimpleCache"
})
initialize_auth(app)
register_filters(app)
initialize_database()
initialize_auth(app)
register_error_handlers(app)

app.register_blueprint(routes, url_prefix="")
app.register_blueprint(auth, url_prefix="/auth")


# Run
if __name__ == "__main__":
    app.run(debug=True, port=4000)
