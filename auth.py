from flask import redirect
from flask_login import LoginManager

from models import User

login_manager = LoginManager()

def initialize_auth(app):

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