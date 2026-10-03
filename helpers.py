from flask import render_template
from extensions import app
from flask import redirect
from flask_login import LoginManager, current_user
from models import User

@app.context_processor
def inject_global_variables():
    return dict(current_user=current_user)

def register_filters():
    @app.template_filter("reverse")
    def reverse_filter(s):
        return s[::-1]

    @app.template_filter("upcase")
    def caps(text):
        try:
            return text.upper()
        except Exception:
            return ""

    @app.template_filter("labelize")
    def labelize(text):
        try:
            return text.replace("_"," ")
        except Exception:
                return ""

    @app.template_filter("phone")
    def phone_format(n):
        try:
            return format(int(n[:-1]), ",").replace(",", "-") + n[-1]
        except Exception:
            return ""

def register_error_handlers():
    @app.errorhandler(404)
    def page_not_found(e):
        return render_template("shared/404.html"), 404

    @app.errorhandler(500)
    def server_error(e):
        return render_template("shared/500.html"), 500

login_manager = LoginManager()
def initialize_auth():
    login_manager.init_app(app)
    @login_manager.user_loader
    def load_user(user_id):
        try:
            return User.get_or_none(User.id == int(user_id))
        except (TypeError, ValueError):
            return None
    @login_manager.unauthorized_handler
    def unauthorized():
        return redirect("/auth/login")
