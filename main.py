from flask import Response
from db_init import initialize_database
from helpers import register_filters, register_error_handlers, initialize_auth
from extensions import app,cache
from routes import routes,auth

app.register_blueprint(routes, url_prefix="")
app.register_blueprint(auth, url_prefix="/auth")

cache.init_app(app)
initialize_auth()
register_filters()
initialize_database()
register_error_handlers()

@app.route("/routes", methods=["GET"])
def show_routes():
    route_text = ""
    for rule in app.url_map.iter_rules():
        methods = ",".join(sorted(rule.methods - {"HEAD", "OPTIONS"}))
        route_text += f"{rule.endpoint:<20} {methods:<15} {rule.rule}\n"
    return Response(route_text, mimetype="text/plain")

# Run
if __name__ == "__main__":
    app.run(debug=True, port=4000)
