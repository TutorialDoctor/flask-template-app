#!/usr/bin/env bash

set -e

APP_NAME="${1:-flask_app}"

echo "Creating Flask app: $APP_NAME"

mkdir -p "$APP_NAME"
cd "$APP_NAME"

# --------------------------------------------------
# Directories
# --------------------------------------------------

mkdir -p \
    modules \
    scripts \
    static/css \
    static/js \
    static/images \
    static/uploads \
    templates/shared \
    templates/auth \
    templates/users \
    templates/items

# --------------------------------------------------
# Python environment
# --------------------------------------------------

cat > .python-version <<'EOF'
3.12
EOF

cat > requirements.txt <<'EOF'
Flask
Flask-Login
Flask-Caching
Flask-CORS
Peewee
EOF

# --------------------------------------------------
# Main application
# --------------------------------------------------

cat > main.py <<'EOF'
from flask import Flask

from db_init import initialize_database
from filters import register_filters
from auth import initialize_auth
from errors import register_error_handlers
from extensions import cache
from routes import routes, auth


def create_app():
    app = Flask(__name__)

    app.config.update(
        DEBUG=True,
        SECRET_KEY="change-me",
        CACHE_TYPE="SimpleCache",
        CACHE_DEFAULT_TIMEOUT=300,
    )

    cache.init_app(app)

    initialize_database()
    initialize_auth(app)

    register_filters(app)
    register_error_handlers(app)

    app.register_blueprint(routes)
    app.register_blueprint(auth)

    return app


app = create_app()


if __name__ == "__main__":
    app.run(debug=True)
EOF

# --------------------------------------------------
# Database
# --------------------------------------------------

cat > db_init.py <<'EOF'
from models import (
    db,
    Role,
    User,
    Moderator,
    Guest,
    Administrator,
    Interest,
    Forum,
    Post,
    Group,
    GroupMembership,
    PhotoAlbum,
    Photo,
    Comment,
    Friendship,
    PostLike,
    Item,
    Video,
    Image,
    UserItems,
    UserInfo,
)


TABLES = [
    Role,
    User,
    Moderator,
    Guest,
    Administrator,
    Interest,
    Forum,
    Post,
    Group,
    GroupMembership,
    PhotoAlbum,
    Photo,
    Comment,
    Friendship,
    PostLike,
    Item,
    Video,
    Image,
    UserItems,
    UserInfo,
]


def initialize_database():
    db.connect(reuse_if_open=True)
    db.create_tables(TABLES, safe=True)
EOF

# --------------------------------------------------
# Models
# --------------------------------------------------

cat > models.py <<'EOF'
from datetime import datetime

from peewee import (
    SqliteDatabase,
    Model,
    CharField,
    IntegerField,
    DateTimeField,
    ForeignKeyField,
    TextField,
    BlobField,
    BooleanField,
)


db = SqliteDatabase("data.db")


class BaseModel(Model):
    class Meta:
        database = db


class Role(BaseModel):
    name = CharField(max_length=64, unique=True)
    permissions = IntegerField(null=True)

    class Meta:
        table_name = "roles"


class UserInfo(BaseModel):
    address = CharField(null=True)
    images_path = CharField(null=True)
    videos_path = CharField(null=True)
    system_prompt = CharField(null=True)
    profile_photo = CharField(null=True)
    gallery = CharField(null=True)
    bio = CharField(null=True)


class User(BaseModel):
    username = CharField(max_length=64, unique=True)
    email = CharField(max_length=255, unique=True)
    password = CharField(max_length=255)
    role = ForeignKeyField(Role, backref="users", null=True)
    user_info = ForeignKeyField(
        UserInfo,
        backref="user",
        null=True,
    )
    created_at = DateTimeField(default=datetime.now)
    active = BooleanField(default=True)


class Moderator(BaseModel):
    user = ForeignKeyField(User, backref="moderator")


class Guest(BaseModel):
    user = ForeignKeyField(User, backref="guest")


class Administrator(BaseModel):
    user = ForeignKeyField(User, backref="administrator")


class Interest(BaseModel):
    name = CharField(max_length=255)


class Forum(BaseModel):
    name = CharField(max_length=255)


class Post(BaseModel):
    user = ForeignKeyField(User, backref="posts")
    title = CharField(max_length=255)
    body = TextField()
    created_at = DateTimeField(default=datetime.now)


class Group(BaseModel):
    name = CharField(max_length=255)


class GroupMembership(BaseModel):
    user = ForeignKeyField(User, backref="group_memberships")
    group = ForeignKeyField(Group, backref="members")


class PhotoAlbum(BaseModel):
    user = ForeignKeyField(User, backref="photo_albums")
    name = CharField(max_length=255)


class Photo(BaseModel):
    album = ForeignKeyField(PhotoAlbum, backref="photos")
    path = CharField(max_length=500)


class Comment(BaseModel):
    user = ForeignKeyField(User, backref="comments")
    body = TextField()
    created_at = DateTimeField(default=datetime.now)


class Friendship(BaseModel):
    user = ForeignKeyField(User, backref="friendships")
    friend = ForeignKeyField(User, backref="friends_with")


class PostLike(BaseModel):
    user = ForeignKeyField(User, backref="likes")
    post = ForeignKeyField(Post, backref="likes")


class Item(BaseModel):
    name = CharField(max_length=255)
    description = TextField(null=True)


class Video(BaseModel):
    item = ForeignKeyField(Item, backref="videos", null=True)
    path = CharField(max_length=500)


class Image(BaseModel):
    item = ForeignKeyField(Item, backref="images", null=True)
    path = CharField(max_length=500)


class UserItems(BaseModel):
    user = ForeignKeyField(User, backref="user_items")
    item = ForeignKeyField(Item, backref="user_items")
EOF

# --------------------------------------------------
# Extensions
# --------------------------------------------------

cat > extensions.py <<'EOF'
from flask_caching import Cache


cache = Cache()
EOF

# --------------------------------------------------
# Authentication
# --------------------------------------------------

cat > auth.py <<'EOF'
from flask_login import (
    LoginManager,
    current_user,
)


login_manager = LoginManager()


def initialize_auth(app):
    login_manager.init_app(app)
    login_manager.login_view = "auth.login"


@login_manager.user_loader
def load_user(user_id):
    from models import User

    return User.get_or_none(User.id == int(user_id))
EOF

# --------------------------------------------------
# Routes
# --------------------------------------------------

cat > routes.py <<'EOF'
from flask import (
    Blueprint,
    render_template,
    request,
    redirect,
    url_for,
)

from flask_login import (
    login_user,
    login_required,
    logout_user,
)

from extensions import cache
from models import User


routes = Blueprint(
    "routes",
    __name__,
    static_folder="static",
    template_folder="templates",
)


auth = Blueprint(
    "auth",
    __name__,
    static_folder="static",
    template_folder="templates",
)


# --------------------------------------------------
# General routes
# --------------------------------------------------

@routes.route("/")
def index():
    return render_template("index.html")


@routes.route("/contact")
def contact():
    return render_template("contact.html")


# --------------------------------------------------
# Users
# --------------------------------------------------

@routes.route("/users")
@cache.cached(timeout=50)
def all_users():
    users = User.select().order_by(User.created_at.desc())

    return render_template(
        "users/index.html",
        users=users,
    )


@routes.route("/users/<int:user_id>")
def show_user(user_id):
    user = User.get_or_none(User.id == user_id)

    if not user:
        return render_template("shared/404.html"), 404

    return render_template(
        "users/show.html",
        user=user,
    )


# --------------------------------------------------
# Authentication
# --------------------------------------------------

@auth.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")

        user = User.get_or_none(
            User.username == username
        )

        if user and user.password == password:
            login_user(user)
            return redirect(url_for("routes.index"))

    return render_template("auth/login.html")


@auth.route("/logout")
@login_required
def logout():
    logout_user()

    return redirect(url_for("routes.index"))
EOF

# --------------------------------------------------
# Filters
# --------------------------------------------------

cat > filters.py <<'EOF'
def register_filters(app):

    @app.template_filter("capitalize_words")
    def capitalize_words(value):
        return value.title() if value else ""
EOF

# --------------------------------------------------
# Error handlers
# --------------------------------------------------

cat > errors.py <<'EOF'
from flask import render_template


def register_error_handlers(app):

    @app.errorhandler(404)
    def not_found(error):
        return render_template("shared/404.html"), 404

    @app.errorhandler(500)
    def server_error(error):
        return render_template("shared/500.html"), 500
EOF

# --------------------------------------------------
# Modules
# --------------------------------------------------

cat > modules/__init__.py <<'EOF'
EOF

cat > modules/BaseModule.py <<'EOF'
class BaseModule:

    @classmethod
    def dispatch(cls, action, *args, **kwargs):
        method = getattr(cls, action, None)

        if not method:
            raise AttributeError(
                f"{cls.__name__} has no action '{action}'"
            )

        return method(*args, **kwargs)
EOF

cat > modules/ScriptRunner.py <<'EOF'
class ScriptRunner:

    def __init__(self, script):
        self.script = script

    def run(self):
        return self.script()
EOF

cat > modules/PasswordGenerator.py <<'EOF'
import secrets
import string


class PasswordGenerator:

    @staticmethod
    def generate(length=16):
        characters = string.ascii_letters + string.digits

        return "".join(
            secrets.choice(characters)
            for _ in range(length)
        )
EOF

# --------------------------------------------------
# Scripts
# --------------------------------------------------

cat > scripts/__init__.py <<'EOF'
EOF

cat > scripts/seed.py <<'EOF'
from models import db, Role


def seed():
    db.connect(reuse_if_open=True)

    Role.get_or_create(name="user")
    Role.get_or_create(name="admin")

    db.close()


if __name__ == "__main__":
    seed()
EOF

# --------------------------------------------------
# Templates
# --------------------------------------------------

cat > templates/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>{{ title or "Flask App" }}</title>

    <link
        rel="stylesheet"
        href="{{ url_for('static', filename='css/style.css') }}"
    >
</head>

<body>

<header>
    <nav>
        <a href="{{ url_for('routes.index') }}">Home</a>
        <a href="{{ url_for('routes.all_users') }}">Users</a>
        <a href="{{ url_for('routes.contact') }}">Contact</a>
    </nav>
</header>

<main>
    <h1>Flask App</h1>
</main>

<script src="{{ url_for('static', filename='js/app.js') }}"></script>

</body>
</html>
EOF

cat > templates/contact.html <<'EOF'
{% extends "index.html" %}

{% block content %}
<h1>Contact</h1>
{% endblock %}
EOF

cat > templates/shared/404.html <<'EOF'
<!doctype html>
<html>
<head>
    <title>404</title>
</head>
<body>
    <h1>404</h1>
    <p>Page not found.</p>
</body>
</html>
EOF

cat > templates/shared/500.html <<'EOF'
<!doctype html>
<html>
<head>
    <title>500</title>
</head>
<body>
    <h1>500</h1>
    <p>Something went wrong.</p>
</body>
</html>
EOF

cat > templates/auth/login.html <<'EOF'
<!doctype html>
<html>
<head>
    <title>Login</title>
</head>
<body>

<h1>Login</h1>

<form method="POST">

    <label>
        Username
        <input name="username">
    </label>

    <label>
        Password
        <input
            type="password"
            name="password"
        >
    </label>

    <button type="submit">
        Login
    </button>

</form>

</body>
</html>
EOF

cat > templates/users/index.html <<'EOF'
{% extends "index.html" %}

{% block content %}

<h1>Users</h1>

{% for user in users %}

<article>
    <h2>
        <a href="{{ url_for('routes.show_user', user_id=user.id) }}">
            {{ user.username }}
        </a>
    </h2>

    <p>{{ user.email }}</p>
</article>

{% else %}

<p>No users found.</p>

{% endfor %}

{% endblock %}
EOF

cat > templates/users/show.html <<'EOF'
{% extends "index.html" %}

{% block content %}

<h1>{{ user.username }}</h1>

<p>{{ user.email }}</p>

{% endblock %}
EOF

# --------------------------------------------------
# CSS
# --------------------------------------------------

cat > static/css/style.css <<'EOF'
* {
    box-sizing: border-box;
}

body {
    margin: 0;
    padding: 2rem;
    font-family: system-ui, sans-serif;
    line-height: 1.5;
    color: #222;
    background: #f7f7f7;
}

nav {
    display: flex;
    gap: 1rem;
    margin-bottom: 2rem;
}

a {
    color: inherit;
}

main {
    max-width: 1000px;
    margin: auto;
}

button,
input,
textarea,
select {
    font: inherit;
}

button {
    cursor: pointer;
    padding: .6rem 1rem;
}

input,
textarea,
select {
    padding: .6rem;
    border: 1px solid #ccc;
    border-radius: .4rem;
}
EOF

# --------------------------------------------------
# JavaScript
# --------------------------------------------------

cat > static/js/app.js <<'EOF'
console.log("Flask app loaded");
EOF

# --------------------------------------------------
# Git
# --------------------------------------------------

cat > .gitignore <<'EOF'
.venv/
__pycache__/
*.pyc
.env
data.db
.DS_Store
static/uploads/*
EOF

# --------------------------------------------------
# README
# --------------------------------------------------

cat > README.md <<EOF
# $APP_NAME

## Setup

\`\`\`bash
python -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt

python main.py
\`\`\`

Open:

http://127.0.0.1:5000
EOF

echo ""
echo "✓ Created $APP_NAME"
echo ""
echo "Next:"
echo ""
echo "  cd $APP_NAME"
echo "  python -m venv .venv"
echo "  source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  python main.py"
echo ""