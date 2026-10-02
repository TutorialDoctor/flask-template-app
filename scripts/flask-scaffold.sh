#!/usr/bin/env bash

set -euo pipefail

SCRIPT_SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
APP_NAME="${1:-flask_app}"

echo "Creating Flask app: $APP_NAME"

mkdir -p -- "$APP_NAME"
cd -- "$APP_NAME"

# Generate a fresh app without copying local runtime state or repository metadata.
mkdir -p -- 'modules' 'scripts' 'static/css' 'static/js' 'templates' 'templates/auth' 'templates/components' 'templates/items' 'templates/partials' 'templates/shared' 'templates/users'

cat > '.gitignore' <<'FLASK_SCAFFOLD_FILE_0001'
.idea/
.vscode/
__pycache__/
dist/
.coverage*
htmlcov/
.tox/
docs/_build/
FLASK_SCAFFOLD_FILE_0001
truncate -s 73 '.gitignore'

cat > '.python-version' <<'FLASK_SCAFFOLD_FILE_0002'
3.11
FLASK_SCAFFOLD_FILE_0002

cat > 'README.md' <<'FLASK_SCAFFOLD_FILE_0003'
# Todo

- [ ] Add bcrypt and argon
- [ ] Complete Component Library

# File Structure

```
static/
templates/
app.py
auth.py
db_init.py
errors.py
extensions.py
filters.py
models.py
routes.py
requirements.txt
data.db
```

`python3 app.py`



<!-- {% with user=current_user %}

  {% include './shared/nav.html' %}

{% endwith %} -->
FLASK_SCAFFOLD_FILE_0003

cat > 'auth.py' <<'FLASK_SCAFFOLD_FILE_0004'
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
FLASK_SCAFFOLD_FILE_0004
truncate -s 482 'auth.py'

cat > 'db_init.py' <<'FLASK_SCAFFOLD_FILE_0005'
import datetime
from modules.FakeUser import FakeUser

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
    Videos,
    Images,
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
    Videos,
    Images,
    UserItems,
    UserInfo,
]


def initialize_database():
    db.connect(reuse_if_open=True)
    db.create_tables(TABLES, safe=True)

    with db.atomic():
        user1, _ = User.get_or_create(
            first_name="Alice",
            last_name="Smith",
            email="alice@email.com",
            password="password",
        )
        user2, _ = User.get_or_create(
            first_name="Bob",
            last_name="Henry",
            email="bob@gmail.com",
            password="password",
        )
        user3, _ = User.get_or_create(
            first_name="Admin",
            last_name="Admin",
            email="admin@gmail.com",
            password="password",
        )

        # Un-comment to generate more fake users
        # fake_user = FakeUser.get_data()
        # User.get_or_create(
        #     first_name = fake_user[0],
        #     last_name = fake_user[1],
        #     email= fake_user[2],
        #     password="password"
        # )

        forum, _ = Forum.get_or_create(title="Forum 1")

        Post.get_or_create(
            author=user1,
            forum=forum,
            content="Hello world!",
            defaults={"created_date": datetime.datetime.now()},
        )
        Post.get_or_create(
            author=user2,
            forum=forum,
            content="Peewee is a nice ORM.",
            defaults={"created_at": datetime.datetime.now()},
        )

    print("Database seeded successfully!")
FLASK_SCAFFOLD_FILE_0005

cat > 'errors.py' <<'FLASK_SCAFFOLD_FILE_0006'
from flask import render_template

def register_error_handlers(app):

    @app.errorhandler(404)
    def page_not_found(e):
        return render_template("shared/404.html"), 404

    @app.errorhandler(500)
    def server_error(e):
        return render_template("shared/500.html"), 500
FLASK_SCAFFOLD_FILE_0006
truncate -s 286 'errors.py'

cat > 'extensions.py' <<'FLASK_SCAFFOLD_FILE_0007'
from flask_caching import Cache

cache = Cache()
FLASK_SCAFFOLD_FILE_0007
truncate -s 48 'extensions.py'

cat > 'filters.py' <<'FLASK_SCAFFOLD_FILE_0008'
def register_filters(app):

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
FLASK_SCAFFOLD_FILE_0008
truncate -s 621 'filters.py'

cat > 'main.py' <<'FLASK_SCAFFOLD_FILE_0009'
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
FLASK_SCAFFOLD_FILE_0009

cat > 'models.py' <<'FLASK_SCAFFOLD_FILE_0010'
from peewee import (
    AutoField,
    CharField,
    IntegerField,
    DateTimeField,
    ForeignKeyField,
    CompositeKey,
    TextField,
    BlobField,
    IntegerField
)
from datetime import datetime
from flask_login import UserMixin
from peewee import SqliteDatabase, Model

db = SqliteDatabase("data.db")

class BaseModel(Model):
    class Meta:
        database = db

class Role(BaseModel):
    id = AutoField()
    name = CharField(max_length=64, unique=True)
    permissions = IntegerField(null=True)

    class Meta:
        table_name = "roles"

# One-To-One
class UserInfo(BaseModel):
        address = CharField(null=True)
        images_path = CharField(null=True)
        videos_path = CharField(null=True)
        system_prompt = CharField(null=True)
        profile_photo = CharField(null=True)
        gallery = CharField(null=True)
        bio = CharField(null=True)
        occupation = CharField(null=True)
        state= CharField(null=True)
        city= CharField(null=True)
        family_members = CharField(null=True)
        friends = CharField(null=True)
        website = CharField(null=True)
        weight = IntegerField(null=True)
        height = IntegerField(null=True)

        class Meta:
            table_name = 'user_info'

class User(UserMixin, BaseModel):
    id = AutoField()

    email = CharField(max_length=60, unique=True)
    type = CharField(max_length=50, default="guest")

    first_name = CharField(max_length=50, null=True)
    last_name = CharField(max_length=50, null=True)

    password = CharField(max_length=80, null=True)
    password_hash = CharField(max_length=128, null=True)

    role = ForeignKeyField(
        Role,
        backref="users",
        column_name="role_id",
        null=True,
    )

    phone = CharField(max_length=15, null=True)
    address = CharField(max_length=120, null=True)
    profile_img = CharField(max_length=2048, null=True)
    location = CharField(max_length=255, null=True)
    university = CharField(max_length=255, null=True)
    employer = CharField(max_length=255, null=True)
    employed_since = DateTimeField(default=datetime.now)
    birthday = CharField(max_length=255, null=True)
    ip_address = CharField(max_length=255, null=True)
    browser = CharField(max_length=255, null=True)
    forum_id = IntegerField(null=True)
    status = IntegerField(null=True)
    info = ForeignKeyField(UserInfo, backref='user',null=True)

    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "users"

# One-To-Many
class Item(BaseModel):
    user = ForeignKeyField(User, backref='items',null=True)
    name = CharField(null=True)
    numeral = IntegerField(null=True)
    numeral_name = CharField(null=True)  #cost, count, price
    description = CharField(null=True)
    image_url = CharField(null=True)
    item_type = CharField(null=True)
    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)
    class Meta:
            table_name = 'items'

# Many-To-Many
class UserItems(BaseModel):
        user = ForeignKeyField(User, backref='user_items',null=True)
        item = ForeignKeyField(Item, backref='user_items',null=True)
        class Meta:
            table_name = 'user_items'

class Moderator(BaseModel):
    moderator_id = AutoField()
    user = ForeignKeyField(
        User,
        backref="moderator_record",
        column_name="user_id",
        null=True,
    )
    phone_number = CharField(max_length=80, null=True)

    class Meta:
        table_name = "moderator"

class Guest(BaseModel):
    moderator_id = AutoField()
    user = ForeignKeyField(
        User,
        backref="guest_record",
        column_name="user_id",
        null=True,
    )
    name = CharField(max_length=80, null=True)

    class Meta:
        table_name = "guest"

class Administrator(BaseModel):
    administrator_id = AutoField()
    user = ForeignKeyField(
        User,
        backref="administrator_record",
        column_name="user_id",
        null=True,
    )

    class Meta:
        table_name = "administrator"

class Interest(BaseModel):
    id = AutoField()
    description = CharField(max_length=255, null=True)

    class Meta:
        table_name = "interests"

class Forum(BaseModel):
    id = AutoField()
    title = CharField(max_length=80, null=True)
    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "forums"

class Post(BaseModel):
    id = AutoField()
    title = CharField(max_length=80, null=True)
    content = CharField(max_length=2048, null=True)
    ip_address = CharField(max_length=255, null=True)
    user_agent = CharField(max_length=255, null=True)

    author = ForeignKeyField(
        User,
        backref="posts",
        column_name="author_id",
    )

    forum = ForeignKeyField(
        Forum,
        backref="posts",
        column_name="forum_id",
    )

    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "posts"

class Group(BaseModel):
    id = AutoField()
    title = CharField(max_length=80, null=True)

    moderator = ForeignKeyField(
        User,
        backref="groups",
        column_name="moderator_id",
    )

    forum = ForeignKeyField(
        Forum,
        backref="groups",
        column_name="forum_id",
    )

    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "groups"

class GroupMembership(BaseModel):
    id = AutoField()
    title = CharField(max_length=80, null=True)
    member_account = CharField(max_length=80, null=True)

    group = ForeignKeyField(
        Group,
        backref="memberships",
        column_name="group_id",
    )

    join_date = DateTimeField(default=datetime.now)
    leave_date = DateTimeField(null=True)

    class Meta:
        table_name = "group_memberships"


class PhotoAlbum(BaseModel):
    id = AutoField()
    title = CharField(max_length=80, null=True)

    creator = ForeignKeyField(
        User,
        backref="photo_albums",
        column_name="creator_id",
    )

    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "photo_albums"


class Photo(BaseModel):
    id = AutoField()
    title = CharField(max_length=80, null=True)

    moderator = ForeignKeyField(
        User,
        backref="photos",
        column_name="moderator_id",
    )

    forum = ForeignKeyField(
        Forum,
        backref="photos",
        column_name="forum_id",
    )

    photo_album = ForeignKeyField(
        PhotoAlbum,
        backref="photos",
        column_name="photo_album_id",
    )

    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "photos"

class Images(BaseModel):
    user = ForeignKeyField(User, backref='images',null=True)
    title = CharField(null=True)
    description = TextField(null=True)
    url = CharField(null=True)
    data = BlobField(null=True)
    extension = CharField(null=True)
    class Meta:
            table_name = 'images'

class Videos(BaseModel):
    user = ForeignKeyField(User, backref='videos',null=True)
    title = CharField(null=True)
    description = TextField(null=True)
    url = CharField(null=True)
    data = BlobField(null=True)
    extension = CharField(null=True)
    class Meta:
            table_name = 'videos'


class Comment(BaseModel):
    id = AutoField()
    content = CharField(max_length=2048, null=True)

    post = ForeignKeyField(
        Post,
        backref="comments",
        column_name="post_id",
    )

    class Meta:
        table_name = "comments"


class Friendship(BaseModel):
    quantity = IntegerField(null=True)

    friender = ForeignKeyField(
        User,
        backref="sent_friend_requests",
        column_name="friender_id",
    )

    friendee = ForeignKeyField(
        User,
        backref="received_friend_requests",
        column_name="friendee_id",
    )

    approve_date = DateTimeField(default=datetime.now)
    termination_date = DateTimeField(null=True)
    request_date = DateTimeField(default=datetime.now)

    terminator = ForeignKeyField(
        User,
        backref="terminated_friendships",
        column_name="terminator",
        null=True,
    )

    class Meta:
        table_name = "friends"
        indexes = (
            (("friender", "friendee"), True),
        )

class PostLike(BaseModel):
    post = ForeignKeyField(
        Post,
        backref="likes",
        column_name="post_id",
    )

    user = ForeignKeyField(
        User,
        backref="post_likes",
        column_name="user_id",
    )

    like_date = DateTimeField(default=datetime.now)

    class Meta:
        table_name = "post_likes"
        primary_key = CompositeKey("post", "user")
FLASK_SCAFFOLD_FILE_0010

cat > 'modules/BaseModule.py' <<'FLASK_SCAFFOLD_FILE_0011'
class BaseModule:
    name = "Base Module"
FLASK_SCAFFOLD_FILE_0011
truncate -s 42 'modules/BaseModule.py'

cat > 'modules/FakeUser.py' <<'FLASK_SCAFFOLD_FILE_0012'
from faker import Faker

fake = Faker()

class FakeUser():
    @classmethod
    def get_data(cls):
        first_name = fake.first_name()
        last_name = fake.last_name()
        email = f"{first_name}_{last_name}@gmail.com"
        return [first_name,last_name,email]
FLASK_SCAFFOLD_FILE_0012
truncate -s 272 'modules/FakeUser.py'

cat > 'modules/PasswordGenerator.py' <<'FLASK_SCAFFOLD_FILE_0013'
from random import *
import os

class PasswordGenerator:
    dirname = os.path.dirname(__file__)
    filename = os.path.join(dirname, "passwords.txt")
    MIN_CHARACTERS = 12
    MAX_CHARACTERS = 30
    PASSWORD_COUNT = 3
    PASS = ""

    @classmethod
    def generate_passwords(cls, includes=[""]):
        # print(args[0])
        for _ in range(cls.PASSWORD_COUNT):
            characters = (
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$&%"
            )
            password = "".join(
                choice(characters)
                for _ in range(randint(cls.MIN_CHARACTERS, cls.MAX_CHARACTERS))
            )
            character_list = []
            [character_list.append(char) for char in password]
            print(len(character_list))

            for string in includes:
                character_list[randint(0, len(character_list) - 1)] = string

            modified_password = "".join(character_list)
            cls.PASS = modified_password

            with open(cls.filename, "a") as outfile:
                outfile.write(modified_password + "\n")
        return cls.PASS
FLASK_SCAFFOLD_FILE_0013
truncate -s 1138 'modules/PasswordGenerator.py'

cat > 'modules/ScriptRunner.py' <<'FLASK_SCAFFOLD_FILE_0014'
import subprocess

class ScriptRunner:
    @classmethod
    def run_bash(cls,file_to_run="print.sh"):
        result = subprocess.run(["bash",f"./scripts/{file_to_run}"], capture_output=True, text=True)
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        print("Exit Code:", result.returncode)
        return result.stdout

    @classmethod
    def run_python(cls,file_to_run="test.py"):
        result = subprocess.run(["python3",f"./scripts/{file_to_run}"], capture_output=True, text=True)
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        print("Exit Code:", result.returncode)
        return result.stdout
    
FLASK_SCAFFOLD_FILE_0014
truncate -s 688 'modules/ScriptRunner.py'

cat > 'modules/__init__.py' <<'FLASK_SCAFFOLD_FILE_0015'

FLASK_SCAFFOLD_FILE_0015
truncate -s 0 'modules/__init__.py'

cat > 'modules/passwords.txt' <<'FLASK_SCAFFOLD_FILE_0016'
8AatSdoctorHH%202652tutorialUVGQgithubo4$E
Z@4c0doctor8zF2026sDtutorialdJNZE40bgNgithubB3wJr
X@j8OdoctorJDgithubT2026Btutorial
8LHgithubZ0rB%odoctorY2026@
vdoctorPE3S4N$2026U6&m9K#ogithubgPciUPjXtutorialbP
Lxdoctor9G2026github5W&OPsVd
githubDtutorialXLJ%2026doctorA9vtse
KJZujvPVgithubtutorial#45Sj9EjyDsaf$2026iUjS
Q7w#XxFeTFNrxtutorialo%D2026doctorZrXUSjlEgithub%
Kul&&github%eWB6bgDqoF2026doctorRC
STl2026TIGFLgithubqtutorialJdoctor
2Wgithub1B9MWvvb77qtutorial8AclFIdoctorRJ@ns2026k
Zdoctorh9github2026tutorialbuk%8piV
p7jtutoriallqgithub4X&SVT2026p%doctorz
doctor2026iNsAsfgithubo@&wGtgGHywd
FLASK_SCAFFOLD_FILE_0016

cat > 'pyproject.toml' <<'FLASK_SCAFFOLD_FILE_0017'
[project]
name = "app"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.11"
dependencies = [
    "faker>=40.40.0",
    "flask>=3.1.3",
    "flask-caching>=2.5.1",
    "flask-login>=0.6.3",
    "ollama>=0.6.3",
    "peewee>=4.5.2",
]
FLASK_SCAFFOLD_FILE_0017

cat > 'requirements.txt' <<'FLASK_SCAFFOLD_FILE_0018'
flask

flask_login

peewee

flask_caching

FLASK_SCAFFOLD_FILE_0018

cat > 'routes.py' <<'FLASK_SCAFFOLD_FILE_0019'
from flask import Blueprint, render_template, request, redirect, url_for, flash
from models import User,UserInfo,Item,UserItems
from datetime import datetime
from extensions import cache
from flask_login import (
    login_user,
    login_required,
    logout_user,
)

from modules.BaseModule import BaseModule
from modules.ScriptRunner import ScriptRunner
from modules.PasswordGenerator import PasswordGenerator

routes = Blueprint("routes", __name__, static_folder="static", template_folder="templates")
auth = Blueprint("auth", __name__, static_folder="static", template_folder="templates")

# General routes
# @routes.route("/admin", methods=["GET"])
# def admin():
#     users = (
#             User
#             .select()
#             .order_by(User.created_at.desc())
#         )
#     return render_template("admin.html", users=users)

# Full Page Route (Initial Load)
@routes.route('/admin')
@routes.route('/admin/users')
def admin_users():
    users = (
                User
                .select()
                .order_by(User.created_at.desc())
            )
    # If request comes from HTMX, return ONLY the partial content
    if request.headers.get('HX-Request'):
        return render_template('partials/_users_content.html', users=users)
        
    # Otherwise render full page layout
    return render_template('admin.html', active_tab='users', users=users)

@routes.route('/admin/items')
def admin_items():
    items = Item.select().order_by(Item.created_at.desc())
    
    if request.headers.get('HX-Request'):
        return render_template('partials/_items_content.html', items=items)
        
    return render_template('admin.html', active_tab='items', items=items)
    
# General routes
@routes.route("/ping", methods=["GET"])
def ping():
    password = PasswordGenerator.generate_passwords(includes=['tutorial','doctor','github','2026'])
    return "PONG \n" + ScriptRunner.run_python('test.py')  + BaseModule.name + "\nPassword: \n" + password

@routes.route("/components", methods=["GET"])
def components():
    return render_template("components/master_components.html")

@routes.route("/", methods=["GET"])
@login_required
def home():
    user = User.get_or_none(User.email == "admin@gmail.com")
    return render_template("index.html", user=user)

@routes.route("/about", methods=["GET"])
def about():
    return render_template("about.html")


@routes.route("/contact", methods=["GET"])
def contact():
    return render_template("contact.html")


# CREATE - USER
@routes.route("/users/new", methods=["GET"])
@login_required
def new_user():
    return render_template("users/new.html")

@routes.route("/users/create", methods=["GET", "POST"])
@login_required
def create_user():
    if request.method == "GET":
        return render_template("users/new.html")

    email = request.form["email"]
    first_name = request.form["first_name"]
    last_name = request.form["last_name"]
    phone = request.form["phone"]
    address = request.form["address"]

    profile_img = (
        request.form["profile_img"]
        or "https://thispersondoesnotexist.com/image"
    )

    user = User.create(
        email=email,
        first_name=first_name,
        last_name=last_name,
        phone=phone,
        address=address,
        profile_img=profile_img,
    )

    return render_template("users/show.html", user=user)

@routes.route("/users", methods=["GET"])
@login_required
def user_index():
    users = (
        User
        .select()
        .order_by(User.created_at.desc())
    )

    return render_template("users/index.html", users=users)

# RETRIEVE - USER
@routes.route("/users/<int:user_id>", methods=["GET"])
@login_required
@cache.cached(timeout=50)
def show_user(user_id):
    user = User.get_or_none(User.id == user_id)

    if user:
        similar_users = User.select().limit(4).execute()

        user_items = (Item
              .select()
              .join(UserItems)
              .where(UserItems.user == user))

        return render_template(
            "users/show.html",
            user=user,
            similar_users=similar_users,
            user_items=user_items
        )

    return render_template("shared/404.html"), 404

# UPDATE - USER
@routes.route("/users/<int:user_id>/edit", methods=["GET", "POST"])
@login_required
def edit_user(user_id):
    user = User.get_or_none(User.id == user_id)

    if not user:
        return render_template("shared/404.html"), 404

    if request.method == "POST":
        user.email = request.form["email"]
        user.first_name = request.form["first_name"]
        user.last_name = request.form["last_name"]
        user.phone = request.form["phone"]
        user.address = request.form["address"]
        user.profile_img = request.form["profile_img"]
        user.updated_at = datetime.now()
        details = "some new address"

        try:
            user.info.address = details
        except:
            details = UserInfo(address=details)
            user.info = details

        user.save()

        return redirect(url_for("routes.home"))

    return render_template("users/edit.html", user=user)

# DELETE - USER
@routes.route("/users/<int:user_id>/delete", methods=["POST", "GET"])
@login_required
def delete_user(user_id):
    user = User.get_or_none(User.id == user_id)

    if not user:
        return render_template("shared/404.html"), 404

    user.delete_instance(recursive=True)

    return redirect(url_for("routes.home"))

# ITEMS
@routes.route('/items', defaults={'id': None}, methods=['GET', 'POST'])
@routes.route('/items/<int:id>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def items(id):
    method = request.form.get('_method', request.method).upper()

    if id is None:
        if method == 'GET':
            if request.args.get('action') == 'new':
                return render_template('items/new.html')
            
            items = Item.select().order_by(Item.created_at.desc())
            return render_template('items/index.html', items=items)

        if method == 'POST':
            Item.create(**request.form.to_dict())
            flash('Item created successfully!')
            return redirect(url_for('routes.items'))

    item = Item.get_or_none(Item.id == id)

    if not item:
        return render_template('shared/404.html'), 404

    if method == 'GET':
        if request.args.get('action') == 'edit':
            return render_template('items/edit.html', item=item)
        return render_template('items/show.html', item=item)

    if method in ['POST', 'PUT']:
        for key, value in request.form.items():
            if key != '_method':
                setattr(item, key, value)
        item.save()
        flash('Item updated successfully!')
        return redirect(url_for('routes.items', id=item.id))

    if method == 'DELETE':
        item.delete_instance(recursive=True)
        flash('Item deleted successfully!')
        return redirect(url_for('routes.items'))

# Authentication
@auth.route("/login", methods=["POST", "GET"])
def login():
    if request.method == "GET":
        return render_template("auth/login.html", value=[1, 2])

    email = request.form["email"]
    password = request.form["password"]

    user = User.get_or_none(User.email == email)

    if not user:
        return render_template(
            "auth/login.html",
            message="Invalid User",
        ), 404

    if password != user.password:
        return render_template(
            "auth/login.html",
            message="Invalid Password",
        )

    login_user(user)

    return redirect(url_for("routes.home"))


@auth.route("/register", methods=["POST", "GET"])
def register():
    if request.method == "GET":
        return render_template("auth/register.html", value=[1, 2])

    first_name = request.form["first_name"]
    last_name = request.form["last_name"]
    email = request.form["email"]
    password = request.form["password"]

    user = User.get_or_none(User.email == email)

    if not user:
        new_user = User.create(
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
        )

        login_user(new_user)

        return redirect(url_for("routes.home"))

    return render_template(
        "auth/register.html",
        message="User already exists",
    )


@auth.route("/logout", methods=["GET"])
@login_required
def logout():
    logout_user()
    return render_template("auth/login.html")
FLASK_SCAFFOLD_FILE_0019
truncate -s 8479 'routes.py'

cat > 'scripts/get_help.sh' <<'FLASK_SCAFFOLD_FILE_0020'
help
FLASK_SCAFFOLD_FILE_0020
truncate -s 4 'scripts/get_help.sh'

cat > 'scripts/list_dir.sh' <<'FLASK_SCAFFOLD_FILE_0021'
ls -laR
FLASK_SCAFFOLD_FILE_0021
truncate -s 7 'scripts/list_dir.sh'

cat > 'scripts/print.sh' <<'FLASK_SCAFFOLD_FILE_0022'
pwd
FLASK_SCAFFOLD_FILE_0022
truncate -s 3 'scripts/print.sh'

cat > 'scripts/seed.py' <<'FLASK_SCAFFOLD_FILE_0023'
from models import db, Role


def seed():
    db.connect(reuse_if_open=True)

    Role.get_or_create(name="user")
    Role.get_or_create(name="admin")

    db.close()


if __name__ == "__main__":
    seed()
FLASK_SCAFFOLD_FILE_0023

cat > 'scripts/test.py' <<'FLASK_SCAFFOLD_FILE_0024'
print("Hello from test.py", flush=True)
FLASK_SCAFFOLD_FILE_0024
truncate -s 39 'scripts/test.py'

cat > 'scripts/test2.py' <<'FLASK_SCAFFOLD_FILE_0025'
import sys

sys.stdout.write("something\n")
sys.stdout.flush()  # Ensures subprocess captures it immediately
FLASK_SCAFFOLD_FILE_0025
truncate -s 108 'scripts/test2.py'

cat > 'static/css/style.css' <<'FLASK_SCAFFOLD_FILE_0026'
/* tiny.css */

:root {
  --0: #fff;
  --50: #fafafa;
  --100: #f4f4f5;
  --200: #e4e4e7;
  --300: #d4d4d8;
  --400: #a1a1aa;
  --500: #71717a;
  --600: #52525b;
  --700: #3f3f46;
  --800: #27272a;
  --900: #18181b;
  --950: #09090b;

  --r: .5rem;
  --shadow: 0 1px 3px #0001, 0 1px 2px #0001;
}

*,
*::before,
*::after {
  box-sizing: border-box;
}

ul {
  list-style-type: none;
}

html {
  font: 16px/1.5 system-ui, sans-serif;
  color: var(--900);
  background: var(--50);
}

body {
  margin: 0;
  min-height: 100vh;
}

img,
svg,
video {
  display: block;
  max-width: 100%;
}

button,
input,
textarea,
select {
  font: inherit;
}

a {
  color: var(--900);
  text-decoration: none;

}

a:hover {
  color: var(--600);
}

/* a:hover {
  text-decoration: underline;
} */

button,
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: .5rem;
  padding: .5rem .875rem;
  border: 1px solid var(--900);
  border-radius: var(--r);
  background: var(--900);
  color: var(--0);
  font-weight: 500;
  cursor: pointer;
  text-decoration: none;
}

button:hover,
.btn:hover {
  background: var(--800);
}

.btn-light {
  background: var(--0);
  color: var(--900);
  border-color: var(--300);
}

.btn-light:hover {
  background: var(--100);
}

.btn-ghost {
  background: transparent;
  color: var(--700);
  border-color: transparent;
}

.btn-ghost:hover {
  background: var(--100);
  color: var(--900);
}

input,
textarea,
select {
  width: 100%;
  padding: .5rem .75rem;
  border: 1px solid var(--300);
  border-radius: var(--r);
  background: var(--0);
  color: var(--900);
  outline: 0;
}

input:focus,
textarea:focus,
select:focus {
  border-color: var(--900);
  box-shadow: 0 0 0 3px #18181b18;
}

textarea {
  min-height: 8rem;
  resize: vertical;
}

h1,h2,h3,h4,h5,h6 {
  margin: 0 0 1rem;
  line-height: 1.2;
  color: var(--950);
}

/* h1 { font-size: 2.25rem; }
h2 { font-size: 1.875rem; }
h3 { font-size: 1.5rem; }
h4 { font-size: 1.25rem; }
h5 { font-size: 1.125rem; }
h6 { font-size: 1rem; } */

.text-xs { font-size: .75rem; line-height: 1rem; }
.text-sm { font-size: .875rem; line-height: 1.25rem; }
.text-base { font-size: 1rem; line-height: 1.5rem; }
.text-lg { font-size: 1.125rem; line-height: 1.75rem; }
.text-xl { font-size: 1.25rem; line-height: 1.75rem; }
.text-2xl { font-size: 1.5rem; line-height: 2rem; }
.text-3xl { font-size: 1.875rem; line-height: 2.25rem; }
.text-4xl { font-size: 2.25rem; line-height: 2.5rem; }
.text-5xl { font-size: 3rem; line-height: 1; }


p {
  margin: 0 0 1rem;
  color: var(--700);
}

hr {
  border: 0;
  border-top: 1px solid var(--200);
  margin: 2rem 0;
}

code {
  padding: .125rem .375rem;
  border: 1px solid var(--200);
  border-radius: .25rem;
  background: var(--100);
  font-size: .875em;
}

pre {
  padding: 1rem;
  overflow-x: auto;
  border-radius: var(--r);
  background: var(--950);
  color: var(--100);
}

blockquote {
  margin: 1.5rem 0;
  padding: .75rem 1rem;
  border-left: 3px solid var(--300);
  background: var(--100);
  color: var(--600);
}

table {
  width: 100%;
  border-collapse: collapse;
  background: var(--0);
}

th,
td {
  padding: .75rem;
  text-align: left;
  border-bottom: 1px solid var(--200);
}

th {
  color: var(--600);
  font-size: .875rem;
}

.container {
  width: min(100% - 2rem, 1200px);
  margin-inline: auto;
}

img{
    width: 32px;
    height: 32px
}
/* layout */

.uppercase {
  text-transform: uppercase;
}

.lowercase {
  text-transform: lowercase;
}

.flex { display: flex; }
.grid { display: grid; }
.block { display: block; }
.hidden { display: none; }

.items-center { align-items: center; }
.items-start { align-items: flex-start; }
.items-end { align-items: flex-end; }

.justify-center { justify-content: center; }
.justify-between { justify-content: space-between; }
.justify-end { justify-content: flex-end; }

.flex-wrap { flex-wrap: wrap; }

/* Display Grid */
.grid {
  display: grid;
}

/* Grid Columns 1-12 */
.grid-cols-1  { grid-template-columns: repeat(1, minmax(0, 1fr)); }
.grid-cols-2  { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.grid-cols-3  { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.grid-cols-4  { grid-template-columns: repeat(4, minmax(0, 1fr)); }
.grid-cols-5  { grid-template-columns: repeat(5, minmax(0, 1fr)); }
.grid-cols-6  { grid-template-columns: repeat(6, minmax(0, 1fr)); }
.grid-cols-7  { grid-template-columns: repeat(7, minmax(0, 1fr)); }
.grid-cols-8  { grid-template-columns: repeat(8, minmax(0, 1fr)); }
.grid-cols-9  { grid-template-columns: repeat(9, minmax(0, 1fr)); }
.grid-cols-10 { grid-template-columns: repeat(10, minmax(0, 1fr)); }
.grid-cols-11 { grid-template-columns: repeat(11, minmax(0, 1fr)); }
.grid-cols-12 { grid-template-columns: repeat(12, minmax(0, 1fr)); }

/* Standard Gap Sizes (Optional) */
.gap-0 { gap: 0rem; }
.gap-1 { gap: .25rem; }
.gap-2 { gap: .5rem; }
.gap-3 { gap: .75rem; }
.gap-4 { gap: 1rem; }
.gap-6 { gap: 1.5rem; }
.gap-8 { gap: 2rem; }
.gap-10 { gap: 2.5rem; }
.gap-12 { gap: 3rem; }
/* spacing */

.m-0 { margin: 0; }

.mt-1 { margin-top: .25rem; }
.mt-2 { margin-top: .5rem; }
.mt-4 { margin-top: 1rem; }
.mt-6 { margin-top: 1.5rem; }

.mb-1 { margin-bottom: .25rem; }
.mb-2 { margin-bottom: .5rem; }
.mb-4 { margin-bottom: 1rem; }
.mb-6 { margin-bottom: 1.5rem; }

.ml-1 { margin-left: .25rem; }
.ml-2 { margin-left: .5rem; }
.ml-4 { margin-left: 1rem; }
.ml-6 { margin-left: 1.5rem; }

.mr-1 { margin-right: .25rem; }
.mr-2 { margin-right: .5rem; }
.mr-4 { margin-right: 1rem; }
.mr-6 { margin-right: 1.5rem; }

.my-1 { margin: .25rem 0;  }
.my-2 { margin: .5rem 0; }
.my-4 { margin: 1rem 0; }
.my-6 { margin: 1.5rem 0; }


.mx-auto { margin-inline: auto; }
.ml-auto { margin-left: auto; }


.p-0 { padding: 0rem; }
.p-1 { padding: .25rem; }
.p-2 { padding: .5rem; }
.p-4 { padding: 1rem; }
.p-6 { padding: 1.5rem; }
.p-8 { padding: 2rem; }
.p-10 { padding: 2.5rem; }
.p-12 { padding: 3rem; }

.px-4 {
  padding-inline: 1rem;
}

.py-2 {
  padding-block: .5rem;
}

.py-4 {
  padding-block: 1rem;
}

/* sizing */

.w-full { width: 100%; }
.h-full { height: 100%; }

.max-w-sm { max-width: 24rem; }
.max-w-md { max-width: 28rem; }
.max-w-lg { max-width: 32rem; }
.max-w-xl { max-width: 36rem; }

/* surfaces */

.card {
  padding: 1.5rem;
  background: var(--0);
  border: 1px solid var(--200);
  border-radius: .75rem;
  box-shadow: var(--shadow);
}

.border {
  border: 1px solid var(--200);
}

.rounded {
  border-radius: var(--r);
}

.rounded-lg {
  border-radius: .75rem;
}

.rounded-full {
  border-radius: 999px;
}

/* colors */

.bg-white { background: var(--0); }
.bg-gray-50 { background: var(--50); }
.bg-gray-100 { background: var(--100); }
.bg-gray-900 { background: var(--900); }

.text-white { color: var(--0); }
.text-gray-500 { color: var(--500); }
.text-gray-600 { color: var(--600); }
.text-gray-700 { color: var(--700); }
.text-gray-900 { color: var(--900); }

.text-sm { font-size: .875rem; }
.text-lg { font-size: 1.125rem; }
.text-xl { font-size: 1.25rem; }

.font-normal { font-weight: 400; }
.font-medium { font-weight: 500; }
.font-semibold { font-weight: 600; }
.font-bold { font-weight: 700; }

.text-center { text-align: center; }
.text-left { text-align: left; }
.text-right { text-align: right; }

.shadow { box-shadow: var(--shadow); }

@media (max-width: 640px) {
  .grid-2,
  .grid-3,
  .grid-4 {
    grid-template-columns: 1fr;
  }

  .container {
    width: min(100% - 1rem, 1200px);
  }

  h1 { font-size: 1.875rem; }
  h2 { font-size: 1.5rem; }
}


.border-b{
    border-bottom: 1px solid var(--300)
}
FLASK_SCAFFOLD_FILE_0026
truncate -s 7575 'static/css/style.css'

cat > 'static/css/tiny.css' <<'FLASK_SCAFFOLD_FILE_0027'
/* ==========================================================================
   tiny.css — hand-rolled utility classes for the Master Component Sheet
   Same class names as the HTML already uses, so the Tailwind CDN <script>
   can be removed. Link this file instead:
     <link rel="stylesheet" href="tiny.css">
   ========================================================================== */

/* --------------------------------------------------------------------------
   1. Tokens
   -------------------------------------------------------------------------- */
:root {
    --gray-50: #f9fafb;
    --gray-100: #f3f4f6;
    --gray-200: #e5e7eb;
    --gray-300: #d1d5db;
    --gray-400: #9ca3af;
    --gray-500: #6b7280;
    --gray-600: #4b5563;
    --gray-700: #374151;
    --gray-800: #1f2937;
    --green-300: #86efac;
    --yellow-300: #fde047;

    /* semantic (shadcn-style) tokens */
    --background: #ffffff;
    --primary: #18181b;
    --primary-foreground: #fafafa;
    --muted: #f4f4f5;
    --muted-foreground: #71717a;
    --accent: #f4f4f5;
    --accent-foreground: #18181b;
    --input: #e4e4e7;
    --ring: #18181b;
}

/* --------------------------------------------------------------------------
   2. Base reset (replaces Tailwind's preflight)
-------------------------------------------------------------------------- */
*,
*::before,
*::after {
    box-sizing: border-box;
    border: 0 solid var(--gray-200);
}

html {
    line-height: 1.5;
    -webkit-text-size-adjust: 100%;
    font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

body {
    margin: 0;
    line-height: inherit;
}

p,
ul,
hr {
    margin: 0;
}

ul {
    list-style: none;
    padding: 0;
}

hr {
    height: 0;
    color: inherit;
    border-top-width: 1px;
}

img,
svg {
    display: block;
    vertical-align: middle;
}

img {
    max-width: 100%;
    height: auto;
}

table {
    border-collapse: collapse;
    text-indent: 0;
    border-color: inherit;
}

a {
    color: inherit;
    text-decoration: inherit;
}

button,
input,
select,
textarea {
    font: inherit;
    color: inherit;
    margin: 0;
    padding: 0;
}

button {
    background: transparent;
    cursor: pointer;
    text-transform: none;
}

textarea {
    resize: vertical;
}

input::placeholder,
textarea::placeholder {
    color: var(--gray-400);
}

/* --------------------------------------------------------------------------
   3. Display & position
   -------------------------------------------------------------------------- */
.block {
    display: block;
}

.inline-block {
    display: inline-block;
}

.flex {
    display: flex;
}

.inline-flex {
    display: inline-flex;
}

.grid {
    display: grid;
}

.relative {
    position: relative;
}

.absolute {
    position: absolute;
}

.sticky {
    position: sticky;
}

.top-0 {
    top: 0;
}

.right-0 {
    right: 0;
}

.bottom-4 {
    bottom: 1rem;
}

.float-right {
    float: right;
}

.overflow-y-scroll {
    overflow-y: scroll;
}

.pointer-events-none {
    pointer-events: none;
}

.cursor-pointer {
    cursor: pointer;
}

.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
}

/* --------------------------------------------------------------------------
   4. Flexbox & grid
   -------------------------------------------------------------------------- */
.flex-col {
    flex-direction: column;
}

.flex-wrap {
    flex-wrap: wrap;
}

.shrink-0 {
    flex-shrink: 0;
}

.items-start {
    align-items: flex-start;
}

.items-end {
    align-items: flex-end;
}

.items-center {
    align-items: center;
}

.items-stretch {
    align-items: stretch;
}

.justify-start {
    justify-content: flex-start;
}

.justify-center {
    justify-content: center;
}

.justify-between {
    justify-content: space-between;
}

.align-middle {
    vertical-align: middle;
}

.grid-cols-4 {
    grid-template-columns: repeat(4, minmax(0, 1fr));
}

.grid-cols-7 {
    grid-template-columns: repeat(7, minmax(0, 1fr));
}

.grid-cols-12 {
    grid-template-columns: repeat(12, minmax(0, 1fr));
}

.col-span-2 {
    grid-column: span 2 / span 2;
}

.col-span-4 {
    grid-column: span 4 / span 4;
}

.col-span-5 {
    grid-column: span 5 / span 5;
}

.col-span-8 {
    grid-column: span 8 / span 8;
}

.col-span-10 {
    grid-column: span 10 / span 10;
}

.gap-2 {
    gap: 0.5rem;
}

.gap-4 {
    gap: 1rem;
}

.gap-3 {
    gap: 0.75rem;
}

.gap-x-2 {
    column-gap: 0.5rem;
}

.gap-x-4 {
    column-gap: 1rem;
}

.gap-x-6 {
    column-gap: 1.5rem;
}

.gap-y-2 {
    row-gap: 0.5rem;
}

.gap-y-4 {
    row-gap: 1rem;
}

.space-x-2>*+* {
    margin-left: 0.5rem;
}

.space-y-2>*+* {
    margin-top: 0.5rem;
}

/* --------------------------------------------------------------------------
   5. Spacing (padding first so px/py can override p)
   -------------------------------------------------------------------------- */
.p-1 {
    padding: 0.25rem;
}

.p-2 {
    padding: 0.5rem;
}

.p-3 {
    padding: 0.75rem;
}

.p-4 {
    padding: 1rem;
}

.p-8 {
    padding: 2rem;
}

.px-2 {
    padding-left: 0.5rem;
    padding-right: 0.5rem;
}

.px-3 {
    padding-left: 0.75rem;
    padding-right: 0.75rem;
}

.px-4 {
    padding-left: 1rem;
    padding-right: 1rem;
}

.py-2 {
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
}

.pt-2 {
    padding-top: 0.5rem;
}

.pt-4 {
    padding-top: 1rem;
}

.pb-2 {
    padding-bottom: 0.5rem;
}

.m-4 {
    margin: 1rem;
}

.my-2 {
    margin-top: 0.5rem;
    margin-bottom: 0.5rem;
}

.mt-1 {
    margin-top: 0.25rem;
}

.mt-2 {
    margin-top: 0.5rem;
}

.mt-3 {
    margin-top: 0.75rem;
}

.mt-4 {
    margin-top: 1rem;
}

.mt-8 {
    margin-top: 2rem;
}

.mb-4 {
    margin-bottom: 1rem;
}

.mr-4 {
    margin-right: 1rem;
}

.-mr-2 {
    margin-right: -0.5rem;
}

.ml-2 {
    margin-left: 0.5rem;
}

.ml-3 {
    margin-left: 0.75rem;
}

.ml-4 {
    margin-left: 1rem;
}

.ml-auto {
    margin-left: auto;
}

/* --------------------------------------------------------------------------
   6. Sizing
   -------------------------------------------------------------------------- */
.w-full {
    width: 100%;
}

.w-auto {
    width: auto;
}

.w-max {
    width: max-content;
}

.w-1\/2 {
    width: 50%;
}

.w-1\/3 {
    width: 33.333333%;
}

.w-1\/5 {
    width: 20%;
}

.w-2\/5 {
    width: 40%;
}

.w-3\/4 {
    width: 75%;
}

.w-8\/12 {
    width: 66.666667%;
}

.w-4 {
    width: 1rem;
}

.w-5 {
    width: 1.25rem;
}

.w-8 {
    width: 2rem;
}

.w-9 {
    width: 2.25rem;
}

.w-32 {
    width: 8rem;
}

.w-\[30px\] {
    width: 30px;
}

.w-\[200px\] {
    width: 200px;
}

.h-2 {
    height: 0.5rem;
}

.h-4 {
    height: 1rem;
}

.h-5 {
    height: 1.25rem;
}

.h-8 {
    height: 2rem;
}

.h-9 {
    height: 2.25rem;
}

.h-10 {
    height: 2.5rem;
}

.h-32 {
    height: 8rem;
}

.h-\[20px\] {
    height: 20px;
}

.h-\[40px\] {
    height: 40px;
}

.h-\[50px\] {
    height: 50px;
}

.h-\[64px\] {
    height: 64px;
}

.h-\[70px\] {
    height: 70px;
}

.h-\[260px\] {
    height: 260px;
}

.h-\[300px\] {
    height: 300px;
}

.max-w-8 {
    max-width: 2rem;
}

.max-w-\[75\%\] {
    max-width: 75%;
}

.object-contain {
    object-fit: contain;
}

.object-cover {
    object-fit: cover;
}

.object-top {
    object-position: top;
}

/* --------------------------------------------------------------------------
   7. Typography
   -------------------------------------------------------------------------- */
.text-xs {
    font-size: 0.75rem;
    line-height: 1rem;
}

.text-sm {
    font-size: 0.875rem;
    line-height: 1.25rem;
}

.text-lg {
    font-size: 1.125rem;
    line-height: 1.75rem;
}

.text-xl {
    font-size: 1.25rem;
    line-height: 1.75rem;
}

.text-2xl {
    font-size: 1.5rem;
    line-height: 2rem;
}

/* weights: light -> bold, so the later one wins when two are combined */
.font-light {
    font-weight: 300;
}

.font-medium {
    font-weight: 500;
}

.font-semibold {
    font-weight: 600;
}

.font-bold {
    font-weight: 700;
}

.text-left {
    text-align: left;
}

.text-center {
    text-align: center;
}

.text-right {
    text-align: right;
}

.capitalize {
    text-transform: capitalize;
}

.lowercase {
    text-transform: lowercase;
}

.whitespace-nowrap {
    white-space: nowrap;
}

/* your own typo'd class name, kept working as intended */
.ellipis {
    overflow: hidden;
    text-overflow: ellipsis;
}

/* --------------------------------------------------------------------------
   8. Colors
   -------------------------------------------------------------------------- */
.text-white {
    color: #fff;
}

.text-black {
    color: #000;
}

.text-gray-400 {
    color: var(--gray-400);
}

.text-gray-500 {
    color: var(--gray-500);
}

.text-gray-600 {
    color: var(--gray-600);
}

.text-gray-700 {
    color: var(--gray-700);
}

.text-muted-foreground {
    color: var(--muted-foreground);
}

.bg-white {
    background-color: #fff;
}

.bg-black {
    background-color: #000;
}

.bg-gray-50 {
    background-color: var(--gray-50);
}

.bg-gray-100 {
    background-color: var(--gray-100);
}

.bg-gray-200 {
    background-color: var(--gray-200);
}

.bg-gray-300 {
    background-color: var(--gray-300);
}

.bg-green-300 {
    background-color: var(--green-300);
}

.bg-yellow-300 {
    background-color: var(--yellow-300);
}

.bg-primary {
    background-color: var(--primary);
}

.bg-input {
    background-color: var(--input);
}

.accent-black {
    accent-color: #000;
}

/* --------------------------------------------------------------------------
   9. Borders, outlines, radius, shadows
   -------------------------------------------------------------------------- */
.border {
    border-width: 1px;
}

.border-2 {
    border-width: 2px;
}

.border-4 {
    border-width: 4px;
}

.border-b {
    border-bottom-width: 1px;
}

.border-gray-300 {
    border-color: var(--gray-300);
}

.border-white {
    border-color: #fff;
}

.border-primary {
    border-color: var(--primary);
}

.border-transparent {
    border-color: transparent;
}

.outline-dashed {
    outline-style: dashed;
}

.outline-1 {
    outline-width: 1px;
}

.outline-gray-300 {
    outline-color: var(--gray-300);
}

.outline-none {
    outline: 2px solid transparent;
    outline-offset: 2px;
}

.rounded-sm {
    border-radius: 0.125rem;
}

.rounded-md {
    border-radius: 0.375rem;
}

.rounded-lg {
    border-radius: 0.5rem;
}

.rounded-full {
    border-radius: 9999px;
}

.rounded-l-lg {
    border-top-left-radius: 0.5rem;
    border-bottom-left-radius: 0.5rem;
}

.shadow-sm {
    box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
}

.shadow {
    box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
}

.shadow-md {
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

.shadow-lg {
    box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}

.ring-0 {
    box-shadow: none;
}

/* --------------------------------------------------------------------------
   10. Transitions & transforms
   -------------------------------------------------------------------------- */
.transition-colors {
    transition-property: color, background-color, border-color, text-decoration-color, fill, stroke;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 150ms;
}

.transition-transform {
    transition-property: transform;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    transition-duration: 150ms;
}

/* --------------------------------------------------------------------------
   11. State & variant classes
   -------------------------------------------------------------------------- */

/* hover */
.hover\:bg-gray-100:hover {
    background-color: var(--gray-100);
}

.hover\:bg-accent:hover {
    background-color: var(--accent);
}

.hover\:bg-muted\/50:hover {
    background-color: color-mix(in srgb, var(--muted) 50%, transparent);
}

.hover\:text-accent-foreground:hover {
    color: var(--accent-foreground);
}

/* focus-visible */
.focus-visible\:outline-none:focus-visible {
    outline: 2px solid transparent;
    outline-offset: 2px;
}

.focus-visible\:ring-1:focus-visible {
    box-shadow: 0 0 0 1px var(--ring);
}

.focus-visible\:ring-2:focus-visible {
    box-shadow: 0 0 0 2px var(--background), 0 0 0 4px var(--ring);
}

/* disabled */
.disabled\:cursor-not-allowed:disabled {
    cursor: not-allowed;
}

.disabled\:opacity-50:disabled {
    opacity: 0.5;
}

.disabled\:pointer-events-none:disabled {
    pointer-events: none;
}

/* data-state */
.data-\[state\=selected\]\:bg-muted[data-state="selected"] {
    background-color: var(--muted);
}

.data-\[state\=checked\]\:bg-primary[data-state="checked"] {
    background-color: var(--primary);
}

.data-\[state\=checked\]\:text-primary-foreground[data-state="checked"] {
    color: var(--primary-foreground);
}

.data-\[state\=checked\]\:translate-x-4[data-state="checked"] {
    transform: translateX(1rem);
}

.data-\[state\=unchecked\]\:bg-input[data-state="unchecked"] {
    background-color: var(--input);
}

.data-\[state\=unchecked\]\:translate-x-0[data-state="unchecked"] {
    transform: translateX(0);
}

/* dark mode (follows the OS setting) */
@media (prefers-color-scheme: dark) {
    .dark\:bg-gray-800 {
        background-color: var(--gray-800);
    }
}

/* --------------------------------------------------------------------------
   12. Misc (kept last so it wins over display utilities)
   -------------------------------------------------------------------------- */
.appearance-none {
    appearance: none;
    -webkit-appearance: none;
}

.hidden {
    display: none;
}
FLASK_SCAFFOLD_FILE_0027
truncate -s 13800 'static/css/tiny.css'

cat > 'static/css/tw.css' <<'FLASK_SCAFFOLD_FILE_0028'
/*! tailwindcss v4.3.3 | MIT License | https://tailwindcss.com */
@layer properties;
@layer theme, base, components, utilities;
@layer theme {
  :root, :host {
    --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', 'Noto Sans', Arial,
    sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
    --font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New',
    monospace;
    --color-yellow-300: oklch(90.5% 0.182 98.111);
    --color-green-300: oklch(87.1% 0.15 154.449);
    --color-gray-50: oklch(98.5% 0.002 247.839);
    --color-gray-100: oklch(96.7% 0.003 264.542);
    --color-gray-200: oklch(92.8% 0.006 264.531);
    --color-gray-300: oklch(87.2% 0.01 258.338);
    --color-gray-400: oklch(70.7% 0.022 261.325);
    --color-gray-500: oklch(55.1% 0.027 264.364);
    --color-gray-600: oklch(44.6% 0.03 256.802);
    --color-gray-700: oklch(37.3% 0.034 259.733);
    --color-gray-800: oklch(27.8% 0.033 256.848);
    --color-black: #000;
    --color-white: #fff;
    --spacing: 0.25rem;
    --text-xs: 0.75rem;
    --text-xs--line-height: calc(1 / 0.75);
    --text-sm: 0.875rem;
    --text-sm--line-height: calc(1.25 / 0.875);
    --text-lg: 1.125rem;
    --text-lg--line-height: calc(1.75 / 1.125);
    --text-xl: 1.25rem;
    --text-xl--line-height: calc(1.75 / 1.25);
    --text-2xl: 1.5rem;
    --text-2xl--line-height: calc(2 / 1.5);
    --font-weight-light: 300;
    --font-weight-medium: 500;
    --font-weight-semibold: 600;
    --font-weight-bold: 700;
    --radius-sm: 0.25rem;
    --radius-md: 0.375rem;
    --radius-lg: 0.5rem;
    --default-transition-duration: 150ms;
    --default-transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    --default-font-family: var(--font-sans);
    --default-mono-font-family: var(--font-mono);
  }
}
@layer base {
  *, ::after, ::before, ::backdrop, ::file-selector-button {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    border: 0 solid;
  }
  html, :host {
    line-height: 1.5;
    -webkit-text-size-adjust: 100%;
    tab-size: 4;
    font-family: var(--default-font-family, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', 'Noto Sans', Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji');
    font-feature-settings: var(--default-font-feature-settings, normal);
    font-variation-settings: var(--default-font-variation-settings, normal);
    -webkit-tap-highlight-color: transparent;
  }
  hr {
    height: 0;
    color: inherit;
    border-top-width: 1px;
  }
  abbr:where([title]) {
    -webkit-text-decoration: underline dotted;
    text-decoration: underline dotted;
  }
  h1, h2, h3, h4, h5, h6 {
    font-size: inherit;
    font-weight: inherit;
  }
  a {
    color: inherit;
    -webkit-text-decoration: inherit;
    text-decoration: inherit;
  }
  b, strong {
    font-weight: bolder;
  }
  code, kbd, samp, pre {
    font-family: var(--default-mono-font-family, ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace);
    font-feature-settings: var(--default-mono-font-feature-settings, normal);
    font-variation-settings: var(--default-mono-font-variation-settings, normal);
    font-size: 1em;
  }
  small {
    font-size: 80%;
  }
  sub, sup {
    font-size: 75%;
    line-height: 0;
    position: relative;
    vertical-align: baseline;
  }
  sub {
    bottom: -0.25em;
  }
  sup {
    top: -0.5em;
  }
  table {
    text-indent: 0;
    border-color: inherit;
    border-collapse: collapse;
  }
  :-moz-focusring:where(:not(iframe)) {
    outline: auto;
  }
  progress {
    vertical-align: baseline;
  }
  summary {
    display: list-item;
  }
  ol, ul, menu {
    list-style: none;
  }
  img, svg, video, canvas, audio, iframe, embed, object {
    display: block;
    vertical-align: middle;
  }
  img, video {
    max-width: 100%;
    height: auto;
  }
  button, input, select, optgroup, textarea, ::file-selector-button {
    font: inherit;
    font-feature-settings: inherit;
    font-variation-settings: inherit;
    letter-spacing: inherit;
    color: inherit;
    border-radius: 0;
    background-color: transparent;
    opacity: 1;
  }
  :where(select:is([multiple], [size])) optgroup {
    font-weight: bolder;
  }
  :where(select:is([multiple], [size])) optgroup option {
    padding-inline-start: 20px;
  }
  ::file-selector-button {
    margin-inline-end: 4px;
  }
  ::placeholder {
    opacity: 1;
  }
  @supports (not (-webkit-appearance: -apple-pay-button)) or (contain-intrinsic-size: 1px) {
    ::placeholder {
      color: currentcolor;
      @supports (color: color-mix(in lab, red, red)) {
        color: color-mix(in oklab, currentcolor 50%, transparent);
      }
    }
  }
  textarea {
    resize: vertical;
  }
  ::-webkit-search-decoration {
    -webkit-appearance: none;
  }
  ::-webkit-date-and-time-value {
    min-height: 1lh;
    text-align: inherit;
  }
  ::-webkit-datetime-edit {
    display: inline-flex;
  }
  ::-webkit-datetime-edit-fields-wrapper {
    padding: 0;
  }
  ::-webkit-datetime-edit, ::-webkit-datetime-edit-year-field, ::-webkit-datetime-edit-month-field, ::-webkit-datetime-edit-day-field, ::-webkit-datetime-edit-hour-field, ::-webkit-datetime-edit-minute-field, ::-webkit-datetime-edit-second-field, ::-webkit-datetime-edit-millisecond-field, ::-webkit-datetime-edit-meridiem-field {
    padding-block: 0;
  }
  ::-webkit-calendar-picker-indicator {
    line-height: 1;
  }
  :-moz-ui-invalid {
    box-shadow: none;
  }
  button, input:where([type='button'], [type='reset'], [type='submit']), ::file-selector-button {
    appearance: button;
  }
  ::-webkit-inner-spin-button, ::-webkit-outer-spin-button {
    height: auto;
  }
  [hidden]:where(:not([hidden='until-found'])) {
    display: none!important;
  }
}
@layer utilities {
  .pointer-events-none {
    pointer-events: none;
  }
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
    border-width: 0;
  }
  .absolute {
    position: absolute;
  }
  .relative {
    position: relative;
  }
  .sticky {
    position: sticky;
  }
  .top-0 {
    top: 0px;
  }
  .right-0 {
    right: 0px;
  }
  .bottom-4 {
    bottom: calc(var(--spacing) * 4);
  }
  .col-span-2 {
    grid-column: span 2 / span 2;
  }
  .col-span-4 {
    grid-column: span 4 / span 4;
  }
  .col-span-5 {
    grid-column: span 5 / span 5;
  }
  .col-span-8 {
    grid-column: span 8 / span 8;
  }
  .col-span-10 {
    grid-column: span 10 / span 10;
  }
  .float-right {
    float: right;
  }
  .m-4 {
    margin: calc(var(--spacing) * 4);
  }
  .my-2 {
    margin-block: calc(var(--spacing) * 2);
  }
  .my-3 {
    margin-block: calc(var(--spacing) * 3);
  }
  .mt-1 {
    margin-top: var(--spacing);
  }
  .mt-2 {
    margin-top: calc(var(--spacing) * 2);
  }
  .mt-3 {
    margin-top: calc(var(--spacing) * 3);
  }
  .mt-4 {
    margin-top: calc(var(--spacing) * 4);
  }
  .mt-8 {
    margin-top: calc(var(--spacing) * 8);
  }
  .-mr-2 {
    margin-right: calc(var(--spacing) * -2);
  }
  .mr-4 {
    margin-right: calc(var(--spacing) * 4);
  }
  .mb-4 {
    margin-bottom: calc(var(--spacing) * 4);
  }
  .ml-1 {
    margin-left: var(--spacing);
  }
  .ml-2 {
    margin-left: calc(var(--spacing) * 2);
  }
  .ml-3 {
    margin-left: calc(var(--spacing) * 3);
  }
  .ml-4 {
    margin-left: calc(var(--spacing) * 4);
  }
  .ml-auto {
    margin-left: auto;
  }
  .block {
    display: block;
  }
  .flex {
    display: flex;
  }
  .grid {
    display: grid;
  }
  .hidden {
    display: none;
  }
  .inline-block {
    display: inline-block;
  }
  .inline-flex {
    display: inline-flex;
  }
  .h-2 {
    height: calc(var(--spacing) * 2);
  }
  .h-4 {
    height: calc(var(--spacing) * 4);
  }
  .h-5 {
    height: calc(var(--spacing) * 5);
  }
  .h-8 {
    height: calc(var(--spacing) * 8);
  }
  .h-9 {
    height: calc(var(--spacing) * 9);
  }
  .h-10 {
    height: calc(var(--spacing) * 10);
  }
  .h-32 {
    height: calc(var(--spacing) * 32);
  }
  .h-\[20px\] {
    height: 20px;
  }
  .h-\[40px\] {
    height: 40px;
  }
  .h-\[50px\] {
    height: 50px;
  }
  .h-\[64px\] {
    height: 64px;
  }
  .h-\[70px\] {
    height: 70px;
  }
  .h-\[260px\] {
    height: 260px;
  }
  .h-\[300px\] {
    height: 300px;
  }
  .w-1\/2 {
    width: calc(1 / 2 * 100%);
  }
  .w-1\/3 {
    width: calc(1 / 3 * 100%);
  }
  .w-1\/5 {
    width: calc(1 / 5 * 100%);
  }
  .w-2\/5 {
    width: calc(2 / 5 * 100%);
  }
  .w-3\/4 {
    width: calc(3 / 4 * 100%);
  }
  .w-4 {
    width: calc(var(--spacing) * 4);
  }
  .w-8 {
    width: calc(var(--spacing) * 8);
  }
  .w-8\/12 {
    width: calc(8 / 12 * 100%);
  }
  .w-9 {
    width: calc(var(--spacing) * 9);
  }
  .w-32 {
    width: calc(var(--spacing) * 32);
  }
  .w-\[30px\] {
    width: 30px;
  }
  .w-\[200px\] {
    width: 200px;
  }
  .w-auto {
    width: auto;
  }
  .w-full {
    width: 100%;
  }
  .w-max {
    width: max-content;
  }
  .max-w-8 {
    max-width: calc(var(--spacing) * 8);
  }
  .max-w-\[75\%\] {
    max-width: 75%;
  }
  .shrink-0 {
    flex-shrink: 0;
  }
  .cursor-pointer {
    cursor: pointer;
  }
  .appearance-none {
    appearance: none;
  }
  .grid-cols-4 {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
  .grid-cols-7 {
    grid-template-columns: repeat(7, minmax(0, 1fr));
  }
  .grid-cols-12 {
    grid-template-columns: repeat(12, minmax(0, 1fr));
  }
  .flex-col {
    flex-direction: column;
  }
  .flex-wrap {
    flex-wrap: wrap;
  }
  .items-center {
    align-items: center;
  }
  .items-end {
    align-items: flex-end;
  }
  .items-start {
    align-items: flex-start;
  }
  .items-stretch {
    align-items: stretch;
  }
  .justify-between {
    justify-content: space-between;
  }
  .justify-center {
    justify-content: center;
  }
  .justify-start {
    justify-content: flex-start;
  }
  .gap-2 {
    gap: calc(var(--spacing) * 2);
  }
  .gap-3 {
    gap: calc(var(--spacing) * 3);
  }
  .gap-4 {
    gap: calc(var(--spacing) * 4);
  }
  :where(.space-y-2 > :not(:last-child)) {
    --tw-space-y-reverse: 0;
    margin-block-start: calc(calc(var(--spacing) * 2) * var(--tw-space-y-reverse));
    margin-block-end: calc(calc(var(--spacing) * 2) * calc(1 - var(--tw-space-y-reverse)));
  }
  .gap-x-2 {
    column-gap: calc(var(--spacing) * 2);
  }
  .gap-x-4 {
    column-gap: calc(var(--spacing) * 4);
  }
  .gap-x-6 {
    column-gap: calc(var(--spacing) * 6);
  }
  :where(.space-x-2 > :not(:last-child)) {
    --tw-space-x-reverse: 0;
    margin-inline-start: calc(calc(var(--spacing) * 2) * var(--tw-space-x-reverse));
    margin-inline-end: calc(calc(var(--spacing) * 2) * calc(1 - var(--tw-space-x-reverse)));
  }
  .gap-y-2 {
    row-gap: calc(var(--spacing) * 2);
  }
  .gap-y-4 {
    row-gap: calc(var(--spacing) * 4);
  }
  .overflow-y-scroll {
    overflow-y: scroll;
  }
  .rounded-full {
    border-radius: calc(infinity * 1px);
  }
  .rounded-lg {
    border-radius: var(--radius-lg);
  }
  .rounded-md {
    border-radius: var(--radius-md);
  }
  .rounded-sm {
    border-radius: var(--radius-sm);
  }
  .rounded-l-lg {
    border-top-left-radius: var(--radius-lg);
    border-bottom-left-radius: var(--radius-lg);
  }
  .border {
    border-style: var(--tw-border-style);
    border-width: 1px;
  }
  .border-2 {
    border-style: var(--tw-border-style);
    border-width: 2px;
  }
  .border-4 {
    border-style: var(--tw-border-style);
    border-width: 4px;
  }
  .border-b {
    border-bottom-style: var(--tw-border-style);
    border-bottom-width: 1px;
  }
  .border-gray-300 {
    border-color: var(--color-gray-300);
  }
  .border-transparent {
    border-color: transparent;
  }
  .border-white {
    border-color: var(--color-white);
  }
  .bg-black {
    background-color: var(--color-black);
  }
  .bg-gray-50 {
    background-color: var(--color-gray-50);
  }
  .bg-gray-100 {
    background-color: var(--color-gray-100);
  }
  .bg-gray-200 {
    background-color: var(--color-gray-200);
  }
  .bg-gray-300 {
    background-color: var(--color-gray-300);
  }
  .bg-green-300 {
    background-color: var(--color-green-300);
  }
  .bg-white {
    background-color: var(--color-white);
  }
  .bg-yellow-300 {
    background-color: var(--color-yellow-300);
  }
  .object-contain {
    object-fit: contain;
  }
  .object-cover {
    object-fit: cover;
  }
  .object-top {
    object-position: top;
  }
  .p-0 {
    padding: 0px;
  }
  .p-1 {
    padding: var(--spacing);
  }
  .p-2 {
    padding: calc(var(--spacing) * 2);
  }
  .p-3 {
    padding: calc(var(--spacing) * 3);
  }
  .p-4 {
    padding: calc(var(--spacing) * 4);
  }
  .p-8 {
    padding: calc(var(--spacing) * 8);
  }
  .px-2 {
    padding-inline: calc(var(--spacing) * 2);
  }
  .px-3 {
    padding-inline: calc(var(--spacing) * 3);
  }
  .px-4 {
    padding-inline: calc(var(--spacing) * 4);
  }
  .py-2 {
    padding-block: calc(var(--spacing) * 2);
  }
  .pt-2 {
    padding-top: calc(var(--spacing) * 2);
  }
  .pt-4 {
    padding-top: calc(var(--spacing) * 4);
  }
  .pb-2 {
    padding-bottom: calc(var(--spacing) * 2);
  }
  .text-center {
    text-align: center;
  }
  .text-left {
    text-align: left;
  }
  .text-right {
    text-align: right;
  }
  .align-middle {
    vertical-align: middle;
  }
  .text-2xl {
    font-size: var(--text-2xl);
    line-height: var(--tw-leading, var(--text-2xl--line-height));
  }
  .text-lg {
    font-size: var(--text-lg);
    line-height: var(--tw-leading, var(--text-lg--line-height));
  }
  .text-sm {
    font-size: var(--text-sm);
    line-height: var(--tw-leading, var(--text-sm--line-height));
  }
  .text-xl {
    font-size: var(--text-xl);
    line-height: var(--tw-leading, var(--text-xl--line-height));
  }
  .text-xs {
    font-size: var(--text-xs);
    line-height: var(--tw-leading, var(--text-xs--line-height));
  }
  .font-bold {
    --tw-font-weight: var(--font-weight-bold);
    font-weight: var(--font-weight-bold);
  }
  .font-light {
    --tw-font-weight: var(--font-weight-light);
    font-weight: var(--font-weight-light);
  }
  .font-medium {
    --tw-font-weight: var(--font-weight-medium);
    font-weight: var(--font-weight-medium);
  }
  .font-semibold {
    --tw-font-weight: var(--font-weight-semibold);
    font-weight: var(--font-weight-semibold);
  }
  .whitespace-nowrap {
    white-space: nowrap;
  }
  .text-black {
    color: var(--color-black);
  }
  .text-gray-400 {
    color: var(--color-gray-400);
  }
  .text-gray-500 {
    color: var(--color-gray-500);
  }
  .text-gray-600 {
    color: var(--color-gray-600);
  }
  .text-gray-700 {
    color: var(--color-gray-700);
  }
  .text-white {
    color: var(--color-white);
  }
  .capitalize {
    text-transform: capitalize;
  }
  .lowercase {
    text-transform: lowercase;
  }
  .accent-black {
    accent-color: var(--color-black);
  }
  .shadow {
    --tw-shadow: 0 1px 3px 0 var(--tw-shadow-color, rgb(0 0 0 / 0.1)), 0 1px 2px -1px var(--tw-shadow-color, rgb(0 0 0 / 0.1));
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .shadow-lg {
    --tw-shadow: 0 10px 15px -3px var(--tw-shadow-color, rgb(0 0 0 / 0.1)), 0 4px 6px -4px var(--tw-shadow-color, rgb(0 0 0 / 0.1));
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .shadow-md {
    --tw-shadow: 0 4px 6px -1px var(--tw-shadow-color, rgb(0 0 0 / 0.1)), 0 2px 4px -2px var(--tw-shadow-color, rgb(0 0 0 / 0.1));
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .shadow-sm {
    --tw-shadow: 0 1px 3px 0 var(--tw-shadow-color, rgb(0 0 0 / 0.1)), 0 1px 2px -1px var(--tw-shadow-color, rgb(0 0 0 / 0.1));
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .ring-0 {
    --tw-ring-shadow: var(--tw-ring-inset,) 0 0 0 calc(0px + var(--tw-ring-offset-width)) var(--tw-ring-color, currentcolor);
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .outline-1 {
    outline-style: var(--tw-outline-style);
    outline-width: 1px;
  }
  .outline-gray-300 {
    outline-color: var(--color-gray-300);
  }
  .transition-colors {
    transition-property: color, background-color, border-color, outline-color, text-decoration-color, fill, stroke, --tw-gradient-from, --tw-gradient-via, --tw-gradient-to;
    transition-timing-function: var(--tw-ease, var(--default-transition-timing-function));
    transition-duration: var(--tw-duration, var(--default-transition-duration));
  }
  .transition-transform {
    transition-property: transform, translate, scale, rotate;
    transition-timing-function: var(--tw-ease, var(--default-transition-timing-function));
    transition-duration: var(--tw-duration, var(--default-transition-duration));
  }
  .outline-dashed {
    --tw-outline-style: dashed;
    outline-style: dashed;
  }
  .outline-none {
    --tw-outline-style: none;
    outline-style: none;
  }
  @media (hover: hover) {
    .hover\:bg-gray-100:hover {
      background-color: var(--color-gray-100);
    }
  }
  .focus-visible\:ring-1:focus-visible {
    --tw-ring-shadow: var(--tw-ring-inset,) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color, currentcolor);
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .focus-visible\:ring-2:focus-visible {
    --tw-ring-shadow: var(--tw-ring-inset,) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color, currentcolor);
    box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
  }
  .focus-visible\:ring-offset-2:focus-visible {
    --tw-ring-offset-width: 2px;
    --tw-ring-offset-shadow: var(--tw-ring-inset,) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);
  }
  .focus-visible\:outline-none:focus-visible {
    --tw-outline-style: none;
    outline-style: none;
  }
  .disabled\:pointer-events-none:disabled {
    pointer-events: none;
  }
  .disabled\:cursor-not-allowed:disabled {
    cursor: not-allowed;
  }
  .disabled\:opacity-50:disabled {
    opacity: 50%;
  }
  .data-\[state\=checked\]\:translate-x-4[data-state="checked"] {
    --tw-translate-x: calc(var(--spacing) * 4);
    translate: var(--tw-translate-x) var(--tw-translate-y);
  }
  .data-\[state\=unchecked\]\:translate-x-0[data-state="unchecked"] {
    --tw-translate-x: 0px;
    translate: var(--tw-translate-x) var(--tw-translate-y);
  }
  @media (prefers-color-scheme: dark) {
    .dark\:bg-gray-800 {
      background-color: var(--color-gray-800);
    }
  }
}
@property --tw-space-y-reverse {
  syntax: "*";
  inherits: false;
  initial-value: 0;
}
@property --tw-space-x-reverse {
  syntax: "*";
  inherits: false;
  initial-value: 0;
}
@property --tw-border-style {
  syntax: "*";
  inherits: false;
  initial-value: solid;
}
@property --tw-font-weight {
  syntax: "*";
  inherits: false;
}
@property --tw-shadow {
  syntax: "*";
  inherits: false;
  initial-value: 0 0 #0000;
}
@property --tw-shadow-color {
  syntax: "*";
  inherits: false;
}
@property --tw-shadow-alpha {
  syntax: "<percentage>";
  inherits: false;
  initial-value: 100%;
}
@property --tw-inset-shadow {
  syntax: "*";
  inherits: false;
  initial-value: 0 0 #0000;
}
@property --tw-inset-shadow-color {
  syntax: "*";
  inherits: false;
}
@property --tw-inset-shadow-alpha {
  syntax: "<percentage>";
  inherits: false;
  initial-value: 100%;
}
@property --tw-ring-color {
  syntax: "*";
  inherits: false;
}
@property --tw-ring-shadow {
  syntax: "*";
  inherits: false;
  initial-value: 0 0 #0000;
}
@property --tw-inset-ring-color {
  syntax: "*";
  inherits: false;
}
@property --tw-inset-ring-shadow {
  syntax: "*";
  inherits: false;
  initial-value: 0 0 #0000;
}
@property --tw-ring-inset {
  syntax: "*";
  inherits: false;
}
@property --tw-ring-offset-width {
  syntax: "<length>";
  inherits: false;
  initial-value: 0px;
}
@property --tw-ring-offset-color {
  syntax: "*";
  inherits: false;
  initial-value: #fff;
}
@property --tw-ring-offset-shadow {
  syntax: "*";
  inherits: false;
  initial-value: 0 0 #0000;
}
@property --tw-outline-style {
  syntax: "*";
  inherits: false;
  initial-value: solid;
}
@property --tw-translate-x {
  syntax: "*";
  inherits: false;
  initial-value: 0;
}
@property --tw-translate-y {
  syntax: "*";
  inherits: false;
  initial-value: 0;
}
@property --tw-translate-z {
  syntax: "*";
  inherits: false;
  initial-value: 0;
}
@layer properties {
  @supports ((-webkit-hyphens: none) and (not (margin-trim: inline))) or ((-moz-orient: inline) and (not (color:rgb(from red r g b)))) {
    *, ::before, ::after, ::backdrop {
      --tw-space-y-reverse: 0;
      --tw-space-x-reverse: 0;
      --tw-border-style: solid;
      --tw-font-weight: initial;
      --tw-shadow: 0 0 #0000;
      --tw-shadow-color: initial;
      --tw-shadow-alpha: 100%;
      --tw-inset-shadow: 0 0 #0000;
      --tw-inset-shadow-color: initial;
      --tw-inset-shadow-alpha: 100%;
      --tw-ring-color: initial;
      --tw-ring-shadow: 0 0 #0000;
      --tw-inset-ring-color: initial;
      --tw-inset-ring-shadow: 0 0 #0000;
      --tw-ring-inset: initial;
      --tw-ring-offset-width: 0px;
      --tw-ring-offset-color: #fff;
      --tw-ring-offset-shadow: 0 0 #0000;
      --tw-outline-style: solid;
      --tw-translate-x: 0;
      --tw-translate-y: 0;
      --tw-translate-z: 0;
    }
  }
}
FLASK_SCAFFOLD_FILE_0028

cat > 'static/js/htmx.js' <<'FLASK_SCAFFOLD_FILE_0029'
// UMD insanity
// This code sets up support for (in order) AMD, ES6 modules, and globals.
(function (root, factory) {
    //@ts-ignore
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        //@ts-ignore
        define([], factory);
    } else if (typeof module === 'object' && module.exports) {
        // Node. Does not work with strict CommonJS, but
        // only CommonJS-like environments that support module.exports,
        // like Node.
        module.exports = factory();
    } else {
        // Browser globals
        root.htmx = root.htmx || factory();
    }
}(typeof self !== 'undefined' ? self : this, function () {
return (function () {
        'use strict';

        // Public API
        //** @type {import("./htmx").HtmxApi} */
        // TODO: list all methods in public API
        var htmx = {
            onLoad: onLoadHelper,
            process: processNode,
            on: addEventListenerImpl,
            off: removeEventListenerImpl,
            trigger : triggerEvent,
            ajax : ajaxHelper,
            find : find,
            findAll : findAll,
            closest : closest,
            values : function(elt, type){
                var inputValues = getInputValues(elt, type || "post");
                return inputValues.values;
            },
            remove : removeElement,
            addClass : addClassToElement,
            removeClass : removeClassFromElement,
            toggleClass : toggleClassOnElement,
            takeClass : takeClassForElement,
            defineExtension : defineExtension,
            removeExtension : removeExtension,
            logAll : logAll,
            logNone : logNone,
            logger : null,
            config : {
                historyEnabled:true,
                historyCacheSize:10,
                refreshOnHistoryMiss:false,
                defaultSwapStyle:'innerHTML',
                defaultSwapDelay:0,
                defaultSettleDelay:20,
                includeIndicatorStyles:true,
                indicatorClass:'htmx-indicator',
                requestClass:'htmx-request',
                addedClass:'htmx-added',
                settlingClass:'htmx-settling',
                swappingClass:'htmx-swapping',
                allowEval:true,
                allowScriptTags:true,
                inlineScriptNonce:'',
                attributesToSettle:["class", "style", "width", "height"],
                withCredentials:false,
                timeout:0,
                wsReconnectDelay: 'full-jitter',
                wsBinaryType: 'blob',
                disableSelector: "[hx-disable], [data-hx-disable]",
                useTemplateFragments: false,
                scrollBehavior: 'smooth',
                defaultFocusScroll: false,
                getCacheBusterParam: false,
                globalViewTransitions: false,
                methodsThatUseUrlParams: ["get"],
                selfRequestsOnly: false,
                ignoreTitle: false,
                scrollIntoViewOnBoost: true,
                triggerSpecsCache: null,
            },
            parseInterval:parseInterval,
            _:internalEval,
            createEventSource: function(url){
                return new EventSource(url, {withCredentials:true})
            },
            createWebSocket: function(url){
                var sock = new WebSocket(url, []);
                sock.binaryType = htmx.config.wsBinaryType;
                return sock;
            },
            version: "1.9.12"
        };

        /** @type {import("./htmx").HtmxInternalApi} */
        var internalAPI = {
            addTriggerHandler: addTriggerHandler,
            bodyContains: bodyContains,
            canAccessLocalStorage: canAccessLocalStorage,
            findThisElement: findThisElement,
            filterValues: filterValues,
            hasAttribute: hasAttribute,
            getAttributeValue: getAttributeValue,
            getClosestAttributeValue: getClosestAttributeValue,
            getClosestMatch: getClosestMatch,
            getExpressionVars: getExpressionVars,
            getHeaders: getHeaders,
            getInputValues: getInputValues,
            getInternalData: getInternalData,
            getSwapSpecification: getSwapSpecification,
            getTriggerSpecs: getTriggerSpecs,
            getTarget: getTarget,
            makeFragment: makeFragment,
            mergeObjects: mergeObjects,
            makeSettleInfo: makeSettleInfo,
            oobSwap: oobSwap,
            querySelectorExt: querySelectorExt,
            selectAndSwap: selectAndSwap,
            settleImmediately: settleImmediately,
            shouldCancel: shouldCancel,
            triggerEvent: triggerEvent,
            triggerErrorEvent: triggerErrorEvent,
            withExtensions: withExtensions,
        }

        var VERBS = ['get', 'post', 'put', 'delete', 'patch'];
        var VERB_SELECTOR = VERBS.map(function(verb){
            return "[hx-" + verb + "], [data-hx-" + verb + "]"
        }).join(", ");

        var HEAD_TAG_REGEX = makeTagRegEx('head'),
            TITLE_TAG_REGEX = makeTagRegEx('title'),
            SVG_TAGS_REGEX = makeTagRegEx('svg', true);

        //====================================================================
        // Utilities
        //====================================================================

        /**
         * @param {string} tag
         * @param {boolean} [global]
         * @returns {RegExp}
         */
        function makeTagRegEx(tag, global) {
          return new RegExp('<' + tag + '(\\s[^>]*>|>)([\\s\\S]*?)<\\/' + tag + '>',
            !!global ? 'gim' : 'im')
        }

        function parseInterval(str) {
            if (str == undefined)  {
                return undefined;
            }

            let interval = NaN;
            if (str.slice(-2) == "ms") {
                interval = parseFloat(str.slice(0, -2));
            } else if (str.slice(-1) == "s") {
                interval = parseFloat(str.slice(0, -1)) * 1000;
            } else if (str.slice(-1) == "m") {
                interval = parseFloat(str.slice(0, -1)) * 1000 * 60;
            } else {
                interval = parseFloat(str);
            }
            return isNaN(interval) ? undefined : interval;
        }

        /**
         * @param {HTMLElement} elt
         * @param {string} name
         * @returns {(string | null)}
         */
        function getRawAttribute(elt, name) {
            return elt.getAttribute && elt.getAttribute(name);
        }

        // resolve with both hx and data-hx prefixes
        function hasAttribute(elt, qualifiedName) {
            return elt.hasAttribute && (elt.hasAttribute(qualifiedName) ||
                elt.hasAttribute("data-" + qualifiedName));
        }

        /**
         *
         * @param {HTMLElement} elt
         * @param {string} qualifiedName
         * @returns {(string | null)}
         */
        function getAttributeValue(elt, qualifiedName) {
            return getRawAttribute(elt, qualifiedName) || getRawAttribute(elt, "data-" + qualifiedName);
        }

        /**
         * @param {HTMLElement} elt
         * @returns {HTMLElement | null}
         */
        function parentElt(elt) {
            return elt.parentElement;
        }

        /**
         * @returns {Document}
         */
        function getDocument() {
            return document;
        }

        /**
         * @param {HTMLElement} elt
         * @param {(e:HTMLElement) => boolean} condition
         * @returns {HTMLElement | null}
         */
        function getClosestMatch(elt, condition) {
            while (elt && !condition(elt)) {
                elt = parentElt(elt);
            }

            return elt ? elt : null;
        }

        function getAttributeValueWithDisinheritance(initialElement, ancestor, attributeName){
            var attributeValue = getAttributeValue(ancestor, attributeName);
            var disinherit = getAttributeValue(ancestor, "hx-disinherit");
            if (initialElement !== ancestor && disinherit && (disinherit === "*" || disinherit.split(" ").indexOf(attributeName) >= 0)) {
                return "unset";
            } else {
                return attributeValue
            }
        }

        /**
         * @param {HTMLElement} elt
         * @param {string} attributeName
         * @returns {string | null}
         */
        function getClosestAttributeValue(elt, attributeName) {
            var closestAttr = null;
            getClosestMatch(elt, function (e) {
                return closestAttr = getAttributeValueWithDisinheritance(elt, e, attributeName);
            });
            if (closestAttr !== "unset") {
                return closestAttr;
            }
        }

        /**
         * @param {HTMLElement} elt
         * @param {string} selector
         * @returns {boolean}
         */
        function matches(elt, selector) {
            // @ts-ignore: non-standard properties for browser compatibility
            // noinspection JSUnresolvedVariable
            var matchesFunction = elt.matches || elt.matchesSelector || elt.msMatchesSelector || elt.mozMatchesSelector || elt.webkitMatchesSelector || elt.oMatchesSelector;
            return matchesFunction && matchesFunction.call(elt, selector);
        }

        /**
         * @param {string} str
         * @returns {string}
         */
        function getStartTag(str) {
            var tagMatcher = /<([a-z][^\/\0>\x20\t\r\n\f]*)/i
            var match = tagMatcher.exec( str );
            if (match) {
                return match[1].toLowerCase();
            } else {
                return "";
            }
        }

        /**
         *
         * @param {string} resp
         * @param {number} depth
         * @returns {Element}
         */
        function parseHTML(resp, depth) {
            var parser = new DOMParser();
            var responseDoc = parser.parseFromString(resp, "text/html");

            /** @type {Element} */
            var responseNode = responseDoc.body;
            while (depth > 0) {
                depth--;
                // @ts-ignore
                responseNode = responseNode.firstChild;
            }
            if (responseNode == null) {
                // @ts-ignore
                responseNode = getDocument().createDocumentFragment();
            }
            return responseNode;
        }

        function aFullPageResponse(resp) {
            return /<body/.test(resp)
        }

        /**
         *
         * @param {string} response
         * @returns {Element}
         */
        function makeFragment(response) {
            var partialResponse = !aFullPageResponse(response);
            var startTag = getStartTag(response);
            var content = response;
            if (startTag === 'head') {
                content = content.replace(HEAD_TAG_REGEX, '');
            }
            if (htmx.config.useTemplateFragments && partialResponse) {
                var fragment = parseHTML("<body><template>" + content + "</template></body>", 0);
                // @ts-ignore type mismatch between DocumentFragment and Element.
                // TODO: Are these close enough for htmx to use interchangeably?
                var fragmentContent = fragment.querySelector('template').content;
                if (htmx.config.allowScriptTags) {
                    // if there is a nonce set up, set it on the new script tags
                    forEach(fragmentContent.querySelectorAll("script"), function (script) {
                        if (htmx.config.inlineScriptNonce) {
                            script.nonce = htmx.config.inlineScriptNonce;
                        }
                        // mark as executed due to template insertion semantics on all browsers except firefox fml
                        script.htmxExecuted = navigator.userAgent.indexOf("Firefox") === -1;
                    })
                } else {
                    forEach(fragmentContent.querySelectorAll("script"), function (script) {
                        // remove all script tags if scripts are disabled
                        removeElement(script);
                    })
                }
                return fragmentContent;
            }
            switch (startTag) {
                case "thead":
                case "tbody":
                case "tfoot":
                case "colgroup":
                case "caption":
                    return parseHTML("<table>" + content + "</table>", 1);
                case "col":
                    return parseHTML("<table><colgroup>" + content + "</colgroup></table>", 2);
                case "tr":
                    return parseHTML("<table><tbody>" + content + "</tbody></table>", 2);
                case "td":
                case "th":
                    return parseHTML("<table><tbody><tr>" + content + "</tr></tbody></table>", 3);
                case "script":
                case "style":
                    return parseHTML("<div>" + content + "</div>", 1);
                default:
                    return parseHTML(content, 0);
            }
        }

        /**
         * @param {Function} func
         */
        function maybeCall(func){
            if(func) {
                func();
            }
        }

        /**
         * @param {any} o
         * @param {string} type
         * @returns
         */
        function isType(o, type) {
            return Object.prototype.toString.call(o) === "[object " + type + "]";
        }

        /**
         * @param {*} o
         * @returns {o is Function}
         */
        function isFunction(o) {
            return isType(o, "Function");
        }

        /**
         * @param {*} o
         * @returns {o is Object}
         */
        function isRawObject(o) {
            return isType(o, "Object");
        }

        /**
         * getInternalData retrieves "private" data stored by htmx within an element
         * @param {HTMLElement} elt
         * @returns {*}
         */
        function getInternalData(elt) {
            var dataProp = 'htmx-internal-data';
            var data = elt[dataProp];
            if (!data) {
                data = elt[dataProp] = {};
            }
            return data;
        }

        /**
         * toArray converts an ArrayLike object into a real array.
         * @param {ArrayLike} arr
         * @returns {any[]}
         */
        function toArray(arr) {
            var returnArr = [];
            if (arr) {
                for (var i = 0; i < arr.length; i++) {
                    returnArr.push(arr[i]);
                }
            }
            return returnArr
        }

        function forEach(arr, func) {
            if (arr) {
                for (var i = 0; i < arr.length; i++) {
                    func(arr[i]);
                }
            }
        }

        function isScrolledIntoView(el) {
            var rect = el.getBoundingClientRect();
            var elemTop = rect.top;
            var elemBottom = rect.bottom;
            return elemTop < window.innerHeight && elemBottom >= 0;
        }

        function bodyContains(elt) {
            // IE Fix
            if (elt.getRootNode && elt.getRootNode() instanceof window.ShadowRoot) {
                return getDocument().body.contains(elt.getRootNode().host);
            } else {
                return getDocument().body.contains(elt);
            }
        }

        function splitOnWhitespace(trigger) {
            return trigger.trim().split(/\s+/);
        }

        /**
         * mergeObjects takes all of the keys from
         * obj2 and duplicates them into obj1
         * @param {Object} obj1
         * @param {Object} obj2
         * @returns {Object}
         */
        function mergeObjects(obj1, obj2) {
            for (var key in obj2) {
                if (obj2.hasOwnProperty(key)) {
                    obj1[key] = obj2[key];
                }
            }
            return obj1;
        }

        function parseJSON(jString) {
            try {
                return JSON.parse(jString);
            } catch(error) {
                logError(error);
                return null;
            }
        }

        function canAccessLocalStorage() {
            var test = 'htmx:localStorageTest';
            try {
                localStorage.setItem(test, test);
                localStorage.removeItem(test);
                return true;
            } catch(e) {
                return false;
            }
        }

        function normalizePath(path) {
            try {
                var url = new URL(path);
                if (url) {
                    path = url.pathname + url.search;
                }
                // remove trailing slash, unless index page
                if (!(/^\/$/.test(path))) {
                    path = path.replace(/\/+$/, '');
                }
                return path;
            } catch (e) {
                // be kind to IE11, which doesn't support URL()
                return path;
            }
        }

        //==========================================================================================
        // public API
        //==========================================================================================

        function internalEval(str){
            return maybeEval(getDocument().body, function () {
                return eval(str);
            });
        }

        function onLoadHelper(callback) {
            var value = htmx.on("htmx:load", function(evt) {
                callback(evt.detail.elt);
            });
            return value;
        }

        function logAll(){
            htmx.logger = function(elt, event, data) {
                if(console) {
                    console.log(event, elt, data);
                }
            }
        }

        function logNone() {
            htmx.logger = null
        }

        function find(eltOrSelector, selector) {
            if (selector) {
                return eltOrSelector.querySelector(selector);
            } else {
                return find(getDocument(), eltOrSelector);
            }
        }

        function findAll(eltOrSelector, selector) {
            if (selector) {
                return eltOrSelector.querySelectorAll(selector);
            } else {
                return findAll(getDocument(), eltOrSelector);
            }
        }

        function removeElement(elt, delay) {
            elt = resolveTarget(elt);
            if (delay) {
                setTimeout(function(){
                    removeElement(elt);
                    elt = null;
                }, delay);
            } else {
                elt.parentElement.removeChild(elt);
            }
        }

        function addClassToElement(elt, clazz, delay) {
            elt = resolveTarget(elt);
            if (delay) {
                setTimeout(function(){
                    addClassToElement(elt, clazz);
                    elt = null;
                }, delay);
            } else {
                elt.classList && elt.classList.add(clazz);
            }
        }

        function removeClassFromElement(elt, clazz, delay) {
            elt = resolveTarget(elt);
            if (delay) {
                setTimeout(function(){
                    removeClassFromElement(elt, clazz);
                    elt = null;
                }, delay);
            } else {
                if (elt.classList) {
                    elt.classList.remove(clazz);
                    // if there are no classes left, remove the class attribute
                    if (elt.classList.length === 0) {
                        elt.removeAttribute("class");
                    }
                }
            }
        }

        function toggleClassOnElement(elt, clazz) {
            elt = resolveTarget(elt);
            elt.classList.toggle(clazz);
        }

        function takeClassForElement(elt, clazz) {
            elt = resolveTarget(elt);
            forEach(elt.parentElement.children, function(child){
                removeClassFromElement(child, clazz);
            })
            addClassToElement(elt, clazz);
        }

        function closest(elt, selector) {
            elt = resolveTarget(elt);
            if (elt.closest) {
                return elt.closest(selector);
            } else {
                // TODO remove when IE goes away
                do{
                    if (elt == null || matches(elt, selector)){
                        return elt;
                    }
                }
                while (elt = elt && parentElt(elt));
                return null;
            }
        }

        function startsWith(str, prefix) {
            return str.substring(0, prefix.length) === prefix
        }

        function endsWith(str, suffix) {
            return str.substring(str.length - suffix.length) === suffix
        }

        function normalizeSelector(selector) {
            var trimmedSelector = selector.trim();
            if (startsWith(trimmedSelector, "<") && endsWith(trimmedSelector, "/>")) {
                return trimmedSelector.substring(1, trimmedSelector.length - 2);
            } else {
                return trimmedSelector;
            }
        }

        function querySelectorAllExt(elt, selector) {
            if (selector.indexOf("closest ") === 0) {
                return [closest(elt, normalizeSelector(selector.substr(8)))];
            } else if (selector.indexOf("find ") === 0) {
                return [find(elt, normalizeSelector(selector.substr(5)))];
            } else if (selector === "next") {
                return [elt.nextElementSibling]
            } else if (selector.indexOf("next ") === 0) {
                return [scanForwardQuery(elt, normalizeSelector(selector.substr(5)))];
            } else if (selector === "previous") {
                return [elt.previousElementSibling]
            } else if (selector.indexOf("previous ") === 0) {
                return [scanBackwardsQuery(elt, normalizeSelector(selector.substr(9)))];
            } else if (selector === 'document') {
                return [document];
            } else if (selector === 'window') {
                return [window];
            } else if (selector === 'body') {
                return [document.body];
            } else {
                return getDocument().querySelectorAll(normalizeSelector(selector));
            }
        }

        var scanForwardQuery = function(start, match) {
            var results = getDocument().querySelectorAll(match);
            for (var i = 0; i < results.length; i++) {
                var elt = results[i];
                if (elt.compareDocumentPosition(start) === Node.DOCUMENT_POSITION_PRECEDING) {
                    return elt;
                }
            }
        }

        var scanBackwardsQuery = function(start, match) {
            var results = getDocument().querySelectorAll(match);
            for (var i = results.length - 1; i >= 0; i--) {
                var elt = results[i];
                if (elt.compareDocumentPosition(start) === Node.DOCUMENT_POSITION_FOLLOWING) {
                    return elt;
                }
            }
        }

        function querySelectorExt(eltOrSelector, selector) {
            if (selector) {
                return querySelectorAllExt(eltOrSelector, selector)[0];
            } else {
                return querySelectorAllExt(getDocument().body, eltOrSelector)[0];
            }
        }

        function resolveTarget(arg2) {
            if (isType(arg2, 'String')) {
                return find(arg2);
            } else {
                return arg2;
            }
        }

        function processEventArgs(arg1, arg2, arg3) {
            if (isFunction(arg2)) {
                return {
                    target: getDocument().body,
                    event: arg1,
                    listener: arg2
                }
            } else {
                return {
                    target: resolveTarget(arg1),
                    event: arg2,
                    listener: arg3
                }
            }

        }

        function addEventListenerImpl(arg1, arg2, arg3) {
            ready(function(){
                var eventArgs = processEventArgs(arg1, arg2, arg3);
                eventArgs.target.addEventListener(eventArgs.event, eventArgs.listener);
            })
            var b = isFunction(arg2);
            return b ? arg2 : arg3;
        }

        function removeEventListenerImpl(arg1, arg2, arg3) {
            ready(function(){
                var eventArgs = processEventArgs(arg1, arg2, arg3);
                eventArgs.target.removeEventListener(eventArgs.event, eventArgs.listener);
            })
            return isFunction(arg2) ? arg2 : arg3;
        }

        //====================================================================
        // Node processing
        //====================================================================

        var DUMMY_ELT = getDocument().createElement("output"); // dummy element for bad selectors
        function findAttributeTargets(elt, attrName) {
            var attrTarget = getClosestAttributeValue(elt, attrName);
            if (attrTarget) {
                if (attrTarget === "this") {
                    return [findThisElement(elt, attrName)];
                } else {
                    var result = querySelectorAllExt(elt, attrTarget);
                    if (result.length === 0) {
                        logError('The selector "' + attrTarget + '" on ' + attrName + " returned no matches!");
                        return [DUMMY_ELT]
                    } else {
                        return result;
                    }
                }
            }
        }

        function findThisElement(elt, attribute){
            return getClosestMatch(elt, function (elt) {
                return getAttributeValue(elt, attribute) != null;
            })
        }

        function getTarget(elt) {
            var targetStr = getClosestAttributeValue(elt, "hx-target");
            if (targetStr) {
                if (targetStr === "this") {
                    return findThisElement(elt,'hx-target');
                } else {
                    return querySelectorExt(elt, targetStr)
                }
            } else {
                var data = getInternalData(elt);
                if (data.boosted) {
                    return getDocument().body;
                } else {
                    return elt;
                }
            }
        }

        function shouldSettleAttribute(name) {
            var attributesToSettle = htmx.config.attributesToSettle;
            for (var i = 0; i < attributesToSettle.length; i++) {
                if (name === attributesToSettle[i]) {
                    return true;
                }
            }
            return false;
        }

        function cloneAttributes(mergeTo, mergeFrom) {
            forEach(mergeTo.attributes, function (attr) {
                if (!mergeFrom.hasAttribute(attr.name) && shouldSettleAttribute(attr.name)) {
                    mergeTo.removeAttribute(attr.name)
                }
            });
            forEach(mergeFrom.attributes, function (attr) {
                if (shouldSettleAttribute(attr.name)) {
                    mergeTo.setAttribute(attr.name, attr.value);
                }
            });
        }

        function isInlineSwap(swapStyle, target) {
            var extensions = getExtensions(target);
            for (var i = 0; i < extensions.length; i++) {
                var extension = extensions[i];
                try {
                    if (extension.isInlineSwap(swapStyle)) {
                        return true;
                    }
                } catch(e) {
                    logError(e);
                }
            }
            return swapStyle === "outerHTML";
        }

        /**
         *
         * @param {string} oobValue
         * @param {HTMLElement} oobElement
         * @param {*} settleInfo
         * @returns
         */
        function oobSwap(oobValue, oobElement, settleInfo) {
            var selector = "#" + getRawAttribute(oobElement, "id");
            var swapStyle = "outerHTML";
            if (oobValue === "true") {
                // do nothing
            } else if (oobValue.indexOf(":") > 0) {
                swapStyle = oobValue.substr(0, oobValue.indexOf(":"));
                selector  = oobValue.substr(oobValue.indexOf(":") + 1, oobValue.length);
            } else {
                swapStyle = oobValue;
            }

            var targets = getDocument().querySelectorAll(selector);
            if (targets) {
                forEach(
                    targets,
                    function (target) {
                        var fragment;
                        var oobElementClone = oobElement.cloneNode(true);
                        fragment = getDocument().createDocumentFragment();
                        fragment.appendChild(oobElementClone);
                        if (!isInlineSwap(swapStyle, target)) {
                            fragment = oobElementClone; // if this is not an inline swap, we use the content of the node, not the node itself
                        }

                        var beforeSwapDetails = {shouldSwap: true, target: target, fragment:fragment };
                        if (!triggerEvent(target, 'htmx:oobBeforeSwap', beforeSwapDetails)) return;

                        target = beforeSwapDetails.target; // allow re-targeting
                        if (beforeSwapDetails['shouldSwap']){
                            swap(swapStyle, target, target, fragment, settleInfo);
                        }
                        forEach(settleInfo.elts, function (elt) {
                            triggerEvent(elt, 'htmx:oobAfterSwap', beforeSwapDetails);
                        });
                    }
                );
                oobElement.parentNode.removeChild(oobElement);
            } else {
                oobElement.parentNode.removeChild(oobElement);
                triggerErrorEvent(getDocument().body, "htmx:oobErrorNoTarget", {content: oobElement});
            }
            return oobValue;
        }

        function handleOutOfBandSwaps(elt, fragment, settleInfo) {
            var oobSelects = getClosestAttributeValue(elt, "hx-select-oob");
            if (oobSelects) {
                var oobSelectValues = oobSelects.split(",");
                for (var i = 0; i < oobSelectValues.length; i++) {
                    var oobSelectValue = oobSelectValues[i].split(":", 2);
                    var id = oobSelectValue[0].trim();
                    if (id.indexOf("#") === 0) {
                        id = id.substring(1);
                    }
                    var oobValue = oobSelectValue[1] || "true";
                    var oobElement = fragment.querySelector("#" + id);
                    if (oobElement) {
                        oobSwap(oobValue, oobElement, settleInfo);
                    }
                }
            }
            forEach(findAll(fragment, '[hx-swap-oob], [data-hx-swap-oob]'), function (oobElement) {
                var oobValue = getAttributeValue(oobElement, "hx-swap-oob");
                if (oobValue != null) {
                    oobSwap(oobValue, oobElement, settleInfo);
                }
            });
        }

        function handlePreservedElements(fragment) {
            forEach(findAll(fragment, '[hx-preserve], [data-hx-preserve]'), function (preservedElt) {
                var id = getAttributeValue(preservedElt, "id");
                var oldElt = getDocument().getElementById(id);
                if (oldElt != null) {
                    preservedElt.parentNode.replaceChild(oldElt, preservedElt);
                }
            });
        }

        function handleAttributes(parentNode, fragment, settleInfo) {
            forEach(fragment.querySelectorAll("[id]"), function (newNode) {
                var id = getRawAttribute(newNode, "id")
                if (id && id.length > 0) {
                    var normalizedId = id.replace("'", "\\'");
                    var normalizedTag = newNode.tagName.replace(':', '\\:');
                    var oldNode = parentNode.querySelector(normalizedTag + "[id='" + normalizedId + "']");
                    if (oldNode && oldNode !== parentNode) {
                        var newAttributes = newNode.cloneNode();
                        cloneAttributes(newNode, oldNode);
                        settleInfo.tasks.push(function () {
                            cloneAttributes(newNode, newAttributes);
                        });
                    }
                }
            });
        }

        function makeAjaxLoadTask(child) {
            return function () {
                removeClassFromElement(child, htmx.config.addedClass);
                processNode(child);
                processScripts(child);
                processFocus(child)
                triggerEvent(child, 'htmx:load');
            };
        }

        function processFocus(child) {
            var autofocus = "[autofocus]";
            var autoFocusedElt = matches(child, autofocus) ? child : child.querySelector(autofocus)
            if (autoFocusedElt != null) {
                autoFocusedElt.focus();
            }
        }

        function insertNodesBefore(parentNode, insertBefore, fragment, settleInfo) {
            handleAttributes(parentNode, fragment, settleInfo);
            while(fragment.childNodes.length > 0){
                var child = fragment.firstChild;
                addClassToElement(child, htmx.config.addedClass);
                parentNode.insertBefore(child, insertBefore);
                if (child.nodeType !== Node.TEXT_NODE && child.nodeType !== Node.COMMENT_NODE) {
                    settleInfo.tasks.push(makeAjaxLoadTask(child));
                }
            }
        }

        // based on https://gist.github.com/hyamamoto/fd435505d29ebfa3d9716fd2be8d42f0,
        // derived from Java's string hashcode implementation
        function stringHash(string, hash) {
            var char = 0;
            while (char < string.length){
                hash = (hash << 5) - hash + string.charCodeAt(char++) | 0; // bitwise or ensures we have a 32-bit int
            }
            return hash;
        }

        function attributeHash(elt) {
            var hash = 0;
            // IE fix
            if (elt.attributes) {
                for (var i = 0; i < elt.attributes.length; i++) {
                    var attribute = elt.attributes[i];
                    if(attribute.value){ // only include attributes w/ actual values (empty is same as non-existent)
                        hash = stringHash(attribute.name, hash);
                        hash = stringHash(attribute.value, hash);
                    }
                }
            }
            return hash;
        }

        function deInitOnHandlers(elt) {
            var internalData = getInternalData(elt);
            if (internalData.onHandlers) {
                for (var i = 0; i < internalData.onHandlers.length; i++) {
                    const handlerInfo = internalData.onHandlers[i];
                    elt.removeEventListener(handlerInfo.event, handlerInfo.listener);
                }
                delete internalData.onHandlers
            }
        }

        function deInitNode(element) {
            var internalData = getInternalData(element);
            if (internalData.timeout) {
                clearTimeout(internalData.timeout);
            }
            if (internalData.webSocket) {
                internalData.webSocket.close();
            }
            if (internalData.sseEventSource) {
                internalData.sseEventSource.close();
            }
            if (internalData.listenerInfos) {
                forEach(internalData.listenerInfos, function (info) {
                    if (info.on) {
                        info.on.removeEventListener(info.trigger, info.listener);
                    }
                });
            }
            deInitOnHandlers(element);
            forEach(Object.keys(internalData), function(key) { delete internalData[key] });
        }

        function cleanUpElement(element) {
            triggerEvent(element, "htmx:beforeCleanupElement")
            deInitNode(element);
            if (element.children) { // IE
                forEach(element.children, function(child) { cleanUpElement(child) });
            }
        }

        function swapOuterHTML(target, fragment, settleInfo) {
            if (target.tagName === "BODY") {
                return swapInnerHTML(target, fragment, settleInfo);
            } else {
                // @type {HTMLElement}
                var newElt
                var eltBeforeNewContent = target.previousSibling;
                insertNodesBefore(parentElt(target), target, fragment, settleInfo);
                if (eltBeforeNewContent == null) {
                    newElt = parentElt(target).firstChild;
                } else {
                    newElt = eltBeforeNewContent.nextSibling;
                }
                settleInfo.elts = settleInfo.elts.filter(function(e) { return e != target });
                while(newElt && newElt !== target) {
                    if (newElt.nodeType === Node.ELEMENT_NODE) {
                        settleInfo.elts.push(newElt);
                    }
                    newElt = newElt.nextElementSibling;
                }
                cleanUpElement(target);
                parentElt(target).removeChild(target);
            }
        }

        function swapAfterBegin(target, fragment, settleInfo) {
            return insertNodesBefore(target, target.firstChild, fragment, settleInfo);
        }

        function swapBeforeBegin(target, fragment, settleInfo) {
            return insertNodesBefore(parentElt(target), target, fragment, settleInfo);
        }

        function swapBeforeEnd(target, fragment, settleInfo) {
            return insertNodesBefore(target, null, fragment, settleInfo);
        }

        function swapAfterEnd(target, fragment, settleInfo) {
            return insertNodesBefore(parentElt(target), target.nextSibling, fragment, settleInfo);
        }
        function swapDelete(target, fragment, settleInfo) {
            cleanUpElement(target);
            return parentElt(target).removeChild(target);
        }

        function swapInnerHTML(target, fragment, settleInfo) {
            var firstChild = target.firstChild;
            insertNodesBefore(target, firstChild, fragment, settleInfo);
            if (firstChild) {
                while (firstChild.nextSibling) {
                    cleanUpElement(firstChild.nextSibling)
                    target.removeChild(firstChild.nextSibling);
                }
                cleanUpElement(firstChild)
                target.removeChild(firstChild);
            }
        }

        function maybeSelectFromResponse(elt, fragment, selectOverride) {
            var selector = selectOverride || getClosestAttributeValue(elt, "hx-select");
            if (selector) {
                var newFragment = getDocument().createDocumentFragment();
                forEach(fragment.querySelectorAll(selector), function (node) {
                    newFragment.appendChild(node);
                });
                fragment = newFragment;
            }
            return fragment;
        }

        function swap(swapStyle, elt, target, fragment, settleInfo) {
            switch (swapStyle) {
                case "none":
                    return;
                case "outerHTML":
                    swapOuterHTML(target, fragment, settleInfo);
                    return;
                case "afterbegin":
                    swapAfterBegin(target, fragment, settleInfo);
                    return;
                case "beforebegin":
                    swapBeforeBegin(target, fragment, settleInfo);
                    return;
                case "beforeend":
                    swapBeforeEnd(target, fragment, settleInfo);
                    return;
                case "afterend":
                    swapAfterEnd(target, fragment, settleInfo);
                    return;
                case "delete":
                    swapDelete(target, fragment, settleInfo);
                    return;
                default:
                    var extensions = getExtensions(elt);
                    for (var i = 0; i < extensions.length; i++) {
                        var ext = extensions[i];
                        try {
                            var newElements = ext.handleSwap(swapStyle, target, fragment, settleInfo);
                            if (newElements) {
                                if (typeof newElements.length !== 'undefined') {
                                    // if handleSwap returns an array (like) of elements, we handle them
                                    for (var j = 0; j < newElements.length; j++) {
                                        var child = newElements[j];
                                        if (child.nodeType !== Node.TEXT_NODE && child.nodeType !== Node.COMMENT_NODE) {
                                            settleInfo.tasks.push(makeAjaxLoadTask(child));
                                        }
                                    }
                                }
                                return;
                            }
                        } catch (e) {
                            logError(e);
                        }
                    }
                    if (swapStyle === "innerHTML") {
                        swapInnerHTML(target, fragment, settleInfo);
                    } else {
                        swap(htmx.config.defaultSwapStyle, elt, target, fragment, settleInfo);
                    }
            }
        }

        function findTitle(content) {
            if (content.indexOf('<title') > -1) {
                var contentWithSvgsRemoved = content.replace(SVG_TAGS_REGEX, '');
                var result = contentWithSvgsRemoved.match(TITLE_TAG_REGEX);
                if (result) {
                    return result[2];
                }
            }
        }

        function selectAndSwap(swapStyle, target, elt, responseText, settleInfo, selectOverride) {
            settleInfo.title = findTitle(responseText);
            var fragment = makeFragment(responseText);
            if (fragment) {
                handleOutOfBandSwaps(elt, fragment, settleInfo);
                fragment = maybeSelectFromResponse(elt, fragment, selectOverride);
                handlePreservedElements(fragment);
                return swap(swapStyle, elt, target, fragment, settleInfo);
            }
        }

        function handleTrigger(xhr, header, elt) {
            var triggerBody = xhr.getResponseHeader(header);
            if (triggerBody.indexOf("{") === 0) {
                var triggers = parseJSON(triggerBody);
                for (var eventName in triggers) {
                    if (triggers.hasOwnProperty(eventName)) {
                        var detail = triggers[eventName];
                        if (!isRawObject(detail)) {
                            detail = {"value": detail}
                        }
                        triggerEvent(elt, eventName, detail);
                    }
                }
            } else {
                var eventNames = triggerBody.split(",")
                for (var i = 0; i < eventNames.length; i++) {
                    triggerEvent(elt, eventNames[i].trim(), []);
                }
            }
        }

        var WHITESPACE = /\s/;
        var WHITESPACE_OR_COMMA = /[\s,]/;
        var SYMBOL_START = /[_$a-zA-Z]/;
        var SYMBOL_CONT = /[_$a-zA-Z0-9]/;
        var STRINGISH_START = ['"', "'", "/"];
        var NOT_WHITESPACE = /[^\s]/;
        var COMBINED_SELECTOR_START = /[{(]/;
        var COMBINED_SELECTOR_END = /[})]/;
        function tokenizeString(str) {
            var tokens = [];
            var position = 0;
            while (position < str.length) {
                if(SYMBOL_START.exec(str.charAt(position))) {
                    var startPosition = position;
                    while (SYMBOL_CONT.exec(str.charAt(position + 1))) {
                        position++;
                    }
                    tokens.push(str.substr(startPosition, position - startPosition + 1));
                } else if (STRINGISH_START.indexOf(str.charAt(position)) !== -1) {
                    var startChar = str.charAt(position);
                    var startPosition = position;
                    position++;
                    while (position < str.length && str.charAt(position) !== startChar ) {
                        if (str.charAt(position) === "\\") {
                            position++;
                        }
                        position++;
                    }
                    tokens.push(str.substr(startPosition, position - startPosition + 1));
                } else {
                    var symbol = str.charAt(position);
                    tokens.push(symbol);
                }
                position++;
            }
            return tokens;
        }

        function isPossibleRelativeReference(token, last, paramName) {
            return SYMBOL_START.exec(token.charAt(0)) &&
                token !== "true" &&
                token !== "false" &&
                token !== "this" &&
                token !== paramName &&
                last !== ".";
        }

        function maybeGenerateConditional(elt, tokens, paramName) {
            if (tokens[0] === '[') {
                tokens.shift();
                var bracketCount = 1;
                var conditionalSource = " return (function(" + paramName + "){ return (";
                var last = null;
                while (tokens.length > 0) {
                    var token = tokens[0];
                    if (token === "]") {
                        bracketCount--;
                        if (bracketCount === 0) {
                            if (last === null) {
                                conditionalSource = conditionalSource + "true";
                            }
                            tokens.shift();
                            conditionalSource += ")})";
                            try {
                                var conditionFunction = maybeEval(elt,function () {
                                    return Function(conditionalSource)();
                                    },
                                    function(){return true})
                                conditionFunction.source = conditionalSource;
                                return conditionFunction;
                            } catch (e) {
                                triggerErrorEvent(getDocument().body, "htmx:syntax:error", {error:e, source:conditionalSource})
                                return null;
                            }
                        }
                    } else if (token === "[") {
                        bracketCount++;
                    }
                    if (isPossibleRelativeReference(token, last, paramName)) {
                            conditionalSource += "((" + paramName + "." + token + ") ? (" + paramName + "." + token + ") : (window." + token + "))";
                    } else {
                        conditionalSource = conditionalSource + token;
                    }
                    last = tokens.shift();
                }
            }
        }

        function consumeUntil(tokens, match) {
            var result = "";
            while (tokens.length > 0 && !match.test(tokens[0])) {
                result += tokens.shift();
            }
            return result;
        }

        function consumeCSSSelector(tokens) {
            var result;
            if (tokens.length > 0 && COMBINED_SELECTOR_START.test(tokens[0])) {
                tokens.shift();
                result = consumeUntil(tokens, COMBINED_SELECTOR_END).trim();
                tokens.shift();
            } else {
                result = consumeUntil(tokens, WHITESPACE_OR_COMMA);
            }
            return result;
        }

        var INPUT_SELECTOR = 'input, textarea, select';

        /**
         * @param {HTMLElement} elt
         * @param {string} explicitTrigger
         * @param {cache} cache for trigger specs
         * @returns {import("./htmx").HtmxTriggerSpecification[]}
         */
        function parseAndCacheTrigger(elt, explicitTrigger, cache) {
            var triggerSpecs = [];
            var tokens = tokenizeString(explicitTrigger);
            do {
                consumeUntil(tokens, NOT_WHITESPACE);
                var initialLength = tokens.length;
                var trigger = consumeUntil(tokens, /[,\[\s]/);
                if (trigger !== "") {
                    if (trigger === "every") {
                        var every = {trigger: 'every'};
                        consumeUntil(tokens, NOT_WHITESPACE);
                        every.pollInterval = parseInterval(consumeUntil(tokens, /[,\[\s]/));
                        consumeUntil(tokens, NOT_WHITESPACE);
                        var eventFilter = maybeGenerateConditional(elt, tokens, "event");
                        if (eventFilter) {
                            every.eventFilter = eventFilter;
                        }
                        triggerSpecs.push(every);
                    } else if (trigger.indexOf("sse:") === 0) {
                        triggerSpecs.push({trigger: 'sse', sseEvent: trigger.substr(4)});
                    } else {
                        var triggerSpec = {trigger: trigger};
                        var eventFilter = maybeGenerateConditional(elt, tokens, "event");
                        if (eventFilter) {
                            triggerSpec.eventFilter = eventFilter;
                        }
                        while (tokens.length > 0 && tokens[0] !== ",") {
                            consumeUntil(tokens, NOT_WHITESPACE)
                            var token = tokens.shift();
                            if (token === "changed") {
                                triggerSpec.changed = true;
                            } else if (token === "once") {
                                triggerSpec.once = true;
                            } else if (token === "consume") {
                                triggerSpec.consume = true;
                            } else if (token === "delay" && tokens[0] === ":") {
                                tokens.shift();
                                triggerSpec.delay = parseInterval(consumeUntil(tokens, WHITESPACE_OR_COMMA));
                            } else if (token === "from" && tokens[0] === ":") {
                                tokens.shift();
                                if (COMBINED_SELECTOR_START.test(tokens[0])) {
                                    var from_arg = consumeCSSSelector(tokens);
                                } else {
                                    var from_arg = consumeUntil(tokens, WHITESPACE_OR_COMMA);
                                    if (from_arg === "closest" || from_arg === "find" || from_arg === "next" || from_arg === "previous") {
                                        tokens.shift();
                                        var selector = consumeCSSSelector(tokens);
                                        // `next` and `previous` allow a selector-less syntax
                                        if (selector.length > 0) {
                                            from_arg += " " + selector;
                                        }
                                    }
                                }
                                triggerSpec.from = from_arg;
                            } else if (token === "target" && tokens[0] === ":") {
                                tokens.shift();
                                triggerSpec.target = consumeCSSSelector(tokens);
                            } else if (token === "throttle" && tokens[0] === ":") {
                                tokens.shift();
                                triggerSpec.throttle = parseInterval(consumeUntil(tokens, WHITESPACE_OR_COMMA));
                            } else if (token === "queue" && tokens[0] === ":") {
                                tokens.shift();
                                triggerSpec.queue = consumeUntil(tokens, WHITESPACE_OR_COMMA);
                            } else if (token === "root" && tokens[0] === ":") {
                                tokens.shift();
                                triggerSpec[token] = consumeCSSSelector(tokens);
                            } else if (token === "threshold" && tokens[0] === ":") {
                                tokens.shift();
                                triggerSpec[token] = consumeUntil(tokens, WHITESPACE_OR_COMMA);
                            } else {
                                triggerErrorEvent(elt, "htmx:syntax:error", {token:tokens.shift()});
                            }
                        }
                        triggerSpecs.push(triggerSpec);
                    }
                }
                if (tokens.length === initialLength) {
                    triggerErrorEvent(elt, "htmx:syntax:error", {token:tokens.shift()});
                }
                consumeUntil(tokens, NOT_WHITESPACE);
            } while (tokens[0] === "," && tokens.shift())
            if (cache) {
                cache[explicitTrigger] = triggerSpecs
            }
            return triggerSpecs
        }

        /**
         * @param {HTMLElement} elt
         * @returns {import("./htmx").HtmxTriggerSpecification[]}
         */
        function getTriggerSpecs(elt) {
            var explicitTrigger = getAttributeValue(elt, 'hx-trigger');
            var triggerSpecs = [];
            if (explicitTrigger) {
                var cache = htmx.config.triggerSpecsCache
                triggerSpecs = (cache && cache[explicitTrigger]) || parseAndCacheTrigger(elt, explicitTrigger, cache)
            }

            if (triggerSpecs.length > 0) {
                return triggerSpecs;
            } else if (matches(elt, 'form')) {
                return [{trigger: 'submit'}];
            } else if (matches(elt, 'input[type="button"], input[type="submit"]')){
                return [{trigger: 'click'}];
            } else if (matches(elt, INPUT_SELECTOR)) {
                return [{trigger: 'change'}];
            } else {
                return [{trigger: 'click'}];
            }
        }

        function cancelPolling(elt) {
            getInternalData(elt).cancelled = true;
        }

        function processPolling(elt, handler, spec) {
            var nodeData = getInternalData(elt);
            nodeData.timeout = setTimeout(function () {
                if (bodyContains(elt) && nodeData.cancelled !== true) {
                    if (!maybeFilterEvent(spec, elt, makeEvent('hx:poll:trigger', {
                        triggerSpec: spec,
                        target: elt
                    }))) {
                        handler(elt);
                    }
                    processPolling(elt, handler, spec);
                }
            }, spec.pollInterval);
        }

        function isLocalLink(elt) {
            return location.hostname === elt.hostname &&
                getRawAttribute(elt,'href') &&
                getRawAttribute(elt,'href').indexOf("#") !== 0;
        }

        function boostElement(elt, nodeData, triggerSpecs) {
            if ((elt.tagName === "A" && isLocalLink(elt) && (elt.target === "" || elt.target === "_self")) || elt.tagName === "FORM") {
                nodeData.boosted = true;
                var verb, path;
                if (elt.tagName === "A") {
                    verb = "get";
                    path = getRawAttribute(elt, 'href')
                } else {
                    var rawAttribute = getRawAttribute(elt, "method");
                    verb = rawAttribute ? rawAttribute.toLowerCase() : "get";
                    if (verb === "get") {
                    }
                    path = getRawAttribute(elt, 'action');
                }
                triggerSpecs.forEach(function(triggerSpec) {
                    addEventListener(elt, function(elt, evt) {
                        if (closest(elt, htmx.config.disableSelector)) {
                            cleanUpElement(elt)
                            return
                        }
                        issueAjaxRequest(verb, path, elt, evt)
                    }, nodeData, triggerSpec, true);
                });
            }
        }

        /**
         *
         * @param {Event} evt
         * @param {HTMLElement} elt
         * @returns
         */
        function shouldCancel(evt, elt) {
            if (evt.type === "submit" || evt.type === "click") {
                if (elt.tagName === "FORM") {
                    return true;
                }
                if (matches(elt, 'input[type="submit"], button') && closest(elt, 'form') !== null) {
                    return true;
                }
                if (elt.tagName === "A" && elt.href &&
                    (elt.getAttribute('href') === '#' || elt.getAttribute('href').indexOf("#") !== 0)) {
                    return true;
                }
            }
            return false;
        }

        function ignoreBoostedAnchorCtrlClick(elt, evt) {
            return getInternalData(elt).boosted && elt.tagName === "A" && evt.type === "click" && (evt.ctrlKey || evt.metaKey);
        }

        function maybeFilterEvent(triggerSpec, elt, evt) {
            var eventFilter = triggerSpec.eventFilter;
            if(eventFilter){
                try {
                    return eventFilter.call(elt, evt) !== true;
                } catch(e) {
                    triggerErrorEvent(getDocument().body, "htmx:eventFilter:error", {error: e, source:eventFilter.source});
                    return true;
                }
            }
            return false;
        }

        function addEventListener(elt, handler, nodeData, triggerSpec, explicitCancel) {
            var elementData = getInternalData(elt);
            var eltsToListenOn;
            if (triggerSpec.from) {
                eltsToListenOn = querySelectorAllExt(elt, triggerSpec.from);
            } else {
                eltsToListenOn = [elt];
            }
            // store the initial values of the elements, so we can tell if they change
            if (triggerSpec.changed) {
                eltsToListenOn.forEach(function (eltToListenOn) {
                    var eltToListenOnData = getInternalData(eltToListenOn);
                    eltToListenOnData.lastValue = eltToListenOn.value;
                })
            }
            forEach(eltsToListenOn, function (eltToListenOn) {
                var eventListener = function (evt) {
                    if (!bodyContains(elt)) {
                        eltToListenOn.removeEventListener(triggerSpec.trigger, eventListener);
                        return;
                    }
                    if (ignoreBoostedAnchorCtrlClick(elt, evt)) {
                        return;
                    }
                    if (explicitCancel || shouldCancel(evt, elt)) {
                        evt.preventDefault();
                    }
                    if (maybeFilterEvent(triggerSpec, elt, evt)) {
                        return;
                    }
                    var eventData = getInternalData(evt);
                    eventData.triggerSpec = triggerSpec;
                    if (eventData.handledFor == null) {
                        eventData.handledFor = [];
                    }
                    if (eventData.handledFor.indexOf(elt) < 0) {
                        eventData.handledFor.push(elt);
                        if (triggerSpec.consume) {
                            evt.stopPropagation();
                        }
                        if (triggerSpec.target && evt.target) {
                            if (!matches(evt.target, triggerSpec.target)) {
                                return;
                            }
                        }
                        if (triggerSpec.once) {
                            if (elementData.triggeredOnce) {
                                return;
                            } else {
                                elementData.triggeredOnce = true;
                            }
                        }
                        if (triggerSpec.changed) {
                            var eltToListenOnData = getInternalData(eltToListenOn)
                            if (eltToListenOnData.lastValue === eltToListenOn.value) {
                                return;
                            }
                            eltToListenOnData.lastValue = eltToListenOn.value
                        }
                        if (elementData.delayed) {
                            clearTimeout(elementData.delayed);
                        }
                        if (elementData.throttle) {
                            return;
                        }

                        if (triggerSpec.throttle > 0) {
                            if (!elementData.throttle) {
                                handler(elt, evt);
                                elementData.throttle = setTimeout(function () {
                                    elementData.throttle = null;
                                }, triggerSpec.throttle);
                            }
                        } else if (triggerSpec.delay > 0) {
                            elementData.delayed = setTimeout(function() { handler(elt, evt) }, triggerSpec.delay);
                        } else {
                            triggerEvent(elt, 'htmx:trigger')
                            handler(elt, evt);
                        }
                    }
                };
                if (nodeData.listenerInfos == null) {
                    nodeData.listenerInfos = [];
                }
                nodeData.listenerInfos.push({
                    trigger: triggerSpec.trigger,
                    listener: eventListener,
                    on: eltToListenOn
                })
                eltToListenOn.addEventListener(triggerSpec.trigger, eventListener);
            });
        }

        var windowIsScrolling = false // used by initScrollHandler
        var scrollHandler = null;
        function initScrollHandler() {
            if (!scrollHandler) {
                scrollHandler = function() {
                    windowIsScrolling = true
                };
                window.addEventListener("scroll", scrollHandler)
                setInterval(function() {
                    if (windowIsScrolling) {
                        windowIsScrolling = false;
                        forEach(getDocument().querySelectorAll("[hx-trigger='revealed'],[data-hx-trigger='revealed']"), function (elt) {
                            maybeReveal(elt);
                        })
                    }
                }, 200);
            }
        }

        function maybeReveal(elt) {
            if (!hasAttribute(elt,'data-hx-revealed') && isScrolledIntoView(elt)) {
                elt.setAttribute('data-hx-revealed', 'true');
                var nodeData = getInternalData(elt);
                if (nodeData.initHash) {
                    triggerEvent(elt, 'revealed');
                } else {
                    // if the node isn't initialized, wait for it before triggering the request
                    elt.addEventListener("htmx:afterProcessNode", function(evt) { triggerEvent(elt, 'revealed') }, {once: true});
                }
            }
        }

        //====================================================================
        // Web Sockets
        //====================================================================

        function processWebSocketInfo(elt, nodeData, info) {
            var values = splitOnWhitespace(info);
            for (var i = 0; i < values.length; i++) {
                var value = values[i].split(/:(.+)/);
                if (value[0] === "connect") {
                    ensureWebSocket(elt, value[1], 0);
                }
                if (value[0] === "send") {
                    processWebSocketSend(elt);
                }
            }
        }

        function ensureWebSocket(elt, wssSource, retryCount) {
            if (!bodyContains(elt)) {
                return;  // stop ensuring websocket connection when socket bearing element ceases to exist
            }

            if (wssSource.indexOf("/") == 0) {  // complete absolute paths only
                var base_part = location.hostname + (location.port ? ':'+location.port: '');
                if (location.protocol == 'https:') {
                    wssSource = "wss://" + base_part + wssSource;
                } else if (location.protocol == 'http:') {
                    wssSource = "ws://" + base_part + wssSource;
                }
            }
            var socket = htmx.createWebSocket(wssSource);
            socket.onerror = function (e) {
                triggerErrorEvent(elt, "htmx:wsError", {error:e, socket:socket});
                maybeCloseWebSocketSource(elt);
            };

            socket.onclose = function (e) {
                if ([1006, 1012, 1013].indexOf(e.code) >= 0) {  // Abnormal Closure/Service Restart/Try Again Later
                    var delay = getWebSocketReconnectDelay(retryCount);
                    setTimeout(function() {
                        ensureWebSocket(elt, wssSource, retryCount+1);  // creates a websocket with a new timeout
                    }, delay);
                }
            };
            socket.onopen = function (e) {
                retryCount = 0;
            }

            getInternalData(elt).webSocket = socket;
            socket.addEventListener('message', function (event) {
                if (maybeCloseWebSocketSource(elt)) {
                    return;
                }

                var response = event.data;
                withExtensions(elt, function(extension){
                    response = extension.transformResponse(response, null, elt);
                });

                var settleInfo = makeSettleInfo(elt);
                var fragment = makeFragment(response);
                var children = toArray(fragment.children);
                for (var i = 0; i < children.length; i++) {
                    var child = children[i];
                    oobSwap(getAttributeValue(child, "hx-swap-oob") || "true", child, settleInfo);
                }

                settleImmediately(settleInfo.tasks);
            });
        }

        function maybeCloseWebSocketSource(elt) {
            if (!bodyContains(elt)) {
                getInternalData(elt).webSocket.close();
                return true;
            }
        }

        function processWebSocketSend(elt) {
            var webSocketSourceElt = getClosestMatch(elt, function (parent) {
                return getInternalData(parent).webSocket != null;
            });
            if (webSocketSourceElt) {
                elt.addEventListener(getTriggerSpecs(elt)[0].trigger, function (evt) {
                    var webSocket = getInternalData(webSocketSourceElt).webSocket;
                    var headers = getHeaders(elt, webSocketSourceElt);
                    var results = getInputValues(elt, 'post');
                    var errors = results.errors;
                    var rawParameters = results.values;
                    var expressionVars = getExpressionVars(elt);
                    var allParameters = mergeObjects(rawParameters, expressionVars);
                    var filteredParameters = filterValues(allParameters, elt);
                    filteredParameters['HEADERS'] = headers;
                    if (errors && errors.length > 0) {
                        triggerEvent(elt, 'htmx:validation:halted', errors);
                        return;
                    }
                    webSocket.send(JSON.stringify(filteredParameters));
                    if(shouldCancel(evt, elt)){
                        evt.preventDefault();
                    }
                });
            } else {
                triggerErrorEvent(elt, "htmx:noWebSocketSourceError");
            }
        }

        function getWebSocketReconnectDelay(retryCount) {
            var delay = htmx.config.wsReconnectDelay;
            if (typeof delay === 'function') {
                // @ts-ignore
                return delay(retryCount);
            }
            if (delay === 'full-jitter') {
                var exp = Math.min(retryCount, 6);
                var maxDelay = 1000 * Math.pow(2, exp);
                return maxDelay * Math.random();
            }
            logError('htmx.config.wsReconnectDelay must either be a function or the string "full-jitter"');
        }

        //====================================================================
        // Server Sent Events
        //====================================================================

        function processSSEInfo(elt, nodeData, info) {
            var values = splitOnWhitespace(info);
            for (var i = 0; i < values.length; i++) {
                var value = values[i].split(/:(.+)/);
                if (value[0] === "connect") {
                    processSSESource(elt, value[1]);
                }

                if ((value[0] === "swap")) {
                    processSSESwap(elt, value[1])
                }
            }
        }

        function processSSESource(elt, sseSrc) {
            var source = htmx.createEventSource(sseSrc);
            source.onerror = function (e) {
                triggerErrorEvent(elt, "htmx:sseError", {error:e, source:source});
                maybeCloseSSESource(elt);
            };
            getInternalData(elt).sseEventSource = source;
        }

        function processSSESwap(elt, sseEventName) {
            var sseSourceElt = getClosestMatch(elt, hasEventSource);
            if (sseSourceElt) {
                var sseEventSource = getInternalData(sseSourceElt).sseEventSource;
                var sseListener = function (event) {
                    if (maybeCloseSSESource(sseSourceElt)) {
                        return;
                    }
                    if (!bodyContains(elt)) {
                        sseEventSource.removeEventListener(sseEventName, sseListener);
                        return;
                    }

                    ///////////////////////////
                    // TODO: merge this code with AJAX and WebSockets code in the future.

                    var response = event.data;
                    withExtensions(elt, function(extension){
                        response = extension.transformResponse(response, null, elt);
                    });

                    var swapSpec = getSwapSpecification(elt)
                    var target = getTarget(elt)
                    var settleInfo = makeSettleInfo(elt);

                    selectAndSwap(swapSpec.swapStyle, target, elt, response, settleInfo)
                    settleImmediately(settleInfo.tasks)
                    triggerEvent(elt, "htmx:sseMessage", event)
                };

                getInternalData(elt).sseListener = sseListener;
                sseEventSource.addEventListener(sseEventName, sseListener);
            } else {
                triggerErrorEvent(elt, "htmx:noSSESourceError");
            }
        }

        function processSSETrigger(elt, handler, sseEventName) {
            var sseSourceElt = getClosestMatch(elt, hasEventSource);
            if (sseSourceElt) {
                var sseEventSource = getInternalData(sseSourceElt).sseEventSource;
                var sseListener = function () {
                    if (!maybeCloseSSESource(sseSourceElt)) {
                        if (bodyContains(elt)) {
                            handler(elt);
                        } else {
                            sseEventSource.removeEventListener(sseEventName, sseListener);
                        }
                    }
                };
                getInternalData(elt).sseListener = sseListener;
                sseEventSource.addEventListener(sseEventName, sseListener);
            } else {
                triggerErrorEvent(elt, "htmx:noSSESourceError");
            }
        }

        function maybeCloseSSESource(elt) {
            if (!bodyContains(elt)) {
                getInternalData(elt).sseEventSource.close();
                return true;
            }
        }

        function hasEventSource(node) {
            return getInternalData(node).sseEventSource != null;
        }

        //====================================================================

        function loadImmediately(elt, handler, nodeData, delay) {
            var load = function(){
                if (!nodeData.loaded) {
                    nodeData.loaded = true;
                    handler(elt);
                }
            }
            if (delay > 0) {
                setTimeout(load, delay);
            } else {
                load();
            }
        }

        function processVerbs(elt, nodeData, triggerSpecs) {
            var explicitAction = false;
            forEach(VERBS, function (verb) {
                if (hasAttribute(elt,'hx-' + verb)) {
                    var path = getAttributeValue(elt, 'hx-' + verb);
                    explicitAction = true;
                    nodeData.path = path;
                    nodeData.verb = verb;
                    triggerSpecs.forEach(function(triggerSpec) {
                        addTriggerHandler(elt, triggerSpec, nodeData, function (elt, evt) {
                            if (closest(elt, htmx.config.disableSelector)) {
                                cleanUpElement(elt)
                                return
                            }
                            issueAjaxRequest(verb, path, elt, evt)
                        })
                    });
                }
            });
            return explicitAction;
        }

        function addTriggerHandler(elt, triggerSpec, nodeData, handler) {
            if (triggerSpec.sseEvent) {
                processSSETrigger(elt, handler, triggerSpec.sseEvent);
            } else if (triggerSpec.trigger === "revealed") {
                initScrollHandler();
                addEventListener(elt, handler, nodeData, triggerSpec);
                maybeReveal(elt);
            } else if (triggerSpec.trigger === "intersect") {
                var observerOptions = {};
                if (triggerSpec.root) {
                    observerOptions.root = querySelectorExt(elt, triggerSpec.root)
                }
                if (triggerSpec.threshold) {
                    observerOptions.threshold = parseFloat(triggerSpec.threshold);
                }
                var observer = new IntersectionObserver(function (entries) {
                    for (var i = 0; i < entries.length; i++) {
                        var entry = entries[i];
                        if (entry.isIntersecting) {
                            triggerEvent(elt, "intersect");
                            break;
                        }
                    }
                }, observerOptions);
                observer.observe(elt);
                addEventListener(elt, handler, nodeData, triggerSpec);
            } else if (triggerSpec.trigger === "load") {
                if (!maybeFilterEvent(triggerSpec, elt, makeEvent("load", {elt: elt}))) {
                                loadImmediately(elt, handler, nodeData, triggerSpec.delay);
                            }
            } else if (triggerSpec.pollInterval > 0) {
                nodeData.polling = true;
                processPolling(elt, handler, triggerSpec);
            } else {
                addEventListener(elt, handler, nodeData, triggerSpec);
            }
        }

        function evalScript(script) {
            if (!script.htmxExecuted && htmx.config.allowScriptTags &&
                (script.type === "text/javascript" || script.type === "module" || script.type === "") ) {
                var newScript = getDocument().createElement("script");
                forEach(script.attributes, function (attr) {
                    newScript.setAttribute(attr.name, attr.value);
                });
                newScript.textContent = script.textContent;
                newScript.async = false;
                if (htmx.config.inlineScriptNonce) {
                    newScript.nonce = htmx.config.inlineScriptNonce;
                }
                var parent = script.parentElement;

                try {
                    parent.insertBefore(newScript, script);
                } catch (e) {
                    logError(e);
                } finally {
                    // remove old script element, but only if it is still in DOM
                    if (script.parentElement) {
                        script.parentElement.removeChild(script);
                    }
                }
            }
        }

        function processScripts(elt) {
            if (matches(elt, "script")) {
                evalScript(elt);
            }
            forEach(findAll(elt, "script"), function (script) {
                evalScript(script);
            });
        }

        function shouldProcessHxOn(elt) {
            var attributes = elt.attributes
            if (!attributes) {
                return false
            }
            for (var j = 0; j < attributes.length; j++) {
                var attrName = attributes[j].name
                if (startsWith(attrName, "hx-on:") || startsWith(attrName, "data-hx-on:") ||
                    startsWith(attrName, "hx-on-") || startsWith(attrName, "data-hx-on-")) {
                    return true
                }
            }
            return false
        }

        function findHxOnWildcardElements(elt) {
            var node = null
            var elements = []

            if (shouldProcessHxOn(elt)) {
                elements.push(elt)
            }

            if (document.evaluate) {
                var iter = document.evaluate('.//*[@*[ starts-with(name(), "hx-on:") or starts-with(name(), "data-hx-on:") or' +
                                                                           ' starts-with(name(), "hx-on-") or starts-with(name(), "data-hx-on-") ]]', elt)
                while (node = iter.iterateNext()) elements.push(node)
            } else if (typeof elt.getElementsByTagName === "function") {
                var allElements = elt.getElementsByTagName("*")
                for (var i = 0; i < allElements.length; i++) {
                  if (shouldProcessHxOn(allElements[i])) {
                      elements.push(allElements[i])
                    }
                }
            }

            return elements
        }

        function findElementsToProcess(elt) {
            if (elt.querySelectorAll) {
                var boostedSelector = ", [hx-boost] a, [data-hx-boost] a, a[hx-boost], a[data-hx-boost]";
                var results = elt.querySelectorAll(VERB_SELECTOR + boostedSelector + ", form, [type='submit'], [hx-sse], [data-hx-sse], [hx-ws]," +
                    " [data-hx-ws], [hx-ext], [data-hx-ext], [hx-trigger], [data-hx-trigger], [hx-on], [data-hx-on]");
                return results;
            } else {
                return [];
            }
        }

        // Handle submit buttons/inputs that have the form attribute set
        // see https://developer.mozilla.org/docs/Web/HTML/Element/button
         function maybeSetLastButtonClicked(evt) {
            var elt = closest(evt.target, "button, input[type='submit']");
            var internalData = getRelatedFormData(evt)
            if (internalData) {
              internalData.lastButtonClicked = elt;
            }
        };
        function maybeUnsetLastButtonClicked(evt){
            var internalData = getRelatedFormData(evt)
            if (internalData) {
              internalData.lastButtonClicked = null;
            }
        }
        function getRelatedFormData(evt) {
           var elt = closest(evt.target, "button, input[type='submit']");
           if (!elt) {
             return;
           }
           var form = resolveTarget('#' + getRawAttribute(elt, 'form')) || closest(elt, 'form');
           if (!form) {
             return;
           }
           return getInternalData(form);
        }
        function initButtonTracking(elt) {
            // need to handle both click and focus in:
            //   focusin - in case someone tabs in to a button and hits the space bar
            //   click - on OSX buttons do not focus on click see https://bugs.webkit.org/show_bug.cgi?id=13724
            elt.addEventListener('click', maybeSetLastButtonClicked)
            elt.addEventListener('focusin', maybeSetLastButtonClicked)
            elt.addEventListener('focusout', maybeUnsetLastButtonClicked)
        }

        function countCurlies(line) {
            var tokens = tokenizeString(line);
            var netCurlies = 0;
            for (var i = 0; i < tokens.length; i++) {
                const token = tokens[i];
                if (token === "{") {
                    netCurlies++;
                } else if (token === "}") {
                    netCurlies--;
                }
            }
            return netCurlies;
        }

        function addHxOnEventHandler(elt, eventName, code) {
            var nodeData = getInternalData(elt);
            if (!Array.isArray(nodeData.onHandlers)) {
                nodeData.onHandlers = [];
            }
            var func;
            var listener = function (e) {
                return maybeEval(elt, function() {
                    if (!func) {
                        func = new Function("event", code);
                    }
                    func.call(elt, e);
                });
            };
            elt.addEventListener(eventName, listener);
            nodeData.onHandlers.push({event:eventName, listener:listener});
        }

        function processHxOn(elt) {
            var hxOnValue = getAttributeValue(elt, 'hx-on');
            if (hxOnValue) {
                var handlers = {}
                var lines = hxOnValue.split("\n");
                var currentEvent = null;
                var curlyCount = 0;
                while (lines.length > 0) {
                    var line = lines.shift();
                    var match = line.match(/^\s*([a-zA-Z:\-\.]+:)(.*)/);
                    if (curlyCount === 0 && match) {
                        line.split(":")
                        currentEvent = match[1].slice(0, -1); // strip last colon
                        handlers[currentEvent] = match[2];
                    } else {
                        handlers[currentEvent] += line;
                    }
                    curlyCount += countCurlies(line);
                }

                for (var eventName in handlers) {
                    addHxOnEventHandler(elt, eventName, handlers[eventName]);
                }
            }
        }

        function processHxOnWildcard(elt) {
            // wipe any previous on handlers so that this function takes precedence
            deInitOnHandlers(elt)

            for (var i = 0; i < elt.attributes.length; i++) {
                var name = elt.attributes[i].name
                var value = elt.attributes[i].value
                if (startsWith(name, "hx-on") || startsWith(name, "data-hx-on")) {
                    var afterOnPosition = name.indexOf("-on") + 3;
                    var nextChar = name.slice(afterOnPosition, afterOnPosition + 1);
                    if (nextChar === "-" || nextChar === ":") {
                        var eventName = name.slice(afterOnPosition + 1);
                        // if the eventName starts with a colon or dash, prepend "htmx" for shorthand support
                        if (startsWith(eventName, ":")) {
                            eventName = "htmx" + eventName
                        } else if (startsWith(eventName, "-")) {
                            eventName = "htmx:" + eventName.slice(1);
                        } else if (startsWith(eventName, "htmx-")) {
                            eventName = "htmx:" + eventName.slice(5);
                        }

                        addHxOnEventHandler(elt, eventName, value)
                    }
                }
            }
        }

        function initNode(elt) {
            if (closest(elt, htmx.config.disableSelector)) {
                cleanUpElement(elt)
                return;
            }
            var nodeData = getInternalData(elt);
            if (nodeData.initHash !== attributeHash(elt)) {
                // clean up any previously processed info
                deInitNode(elt);

                nodeData.initHash = attributeHash(elt);

                processHxOn(elt);

                triggerEvent(elt, "htmx:beforeProcessNode")

                if (elt.value) {
                    nodeData.lastValue = elt.value;
                }

                var triggerSpecs = getTriggerSpecs(elt);
                var hasExplicitHttpAction = processVerbs(elt, nodeData, triggerSpecs);

                if (!hasExplicitHttpAction) {
                    if (getClosestAttributeValue(elt, "hx-boost") === "true") {
                        boostElement(elt, nodeData, triggerSpecs);
                    } else if (hasAttribute(elt, 'hx-trigger')) {
                        triggerSpecs.forEach(function (triggerSpec) {
                            // For "naked" triggers, don't do anything at all
                            addTriggerHandler(elt, triggerSpec, nodeData, function () {
                            })
                        })
                    }
                }

                // Handle submit buttons/inputs that have the form attribute set
                // see https://developer.mozilla.org/docs/Web/HTML/Element/button
                if (elt.tagName === "FORM" || (getRawAttribute(elt, "type") === "submit" && hasAttribute(elt, "form"))) {
                    initButtonTracking(elt)
                }

                var sseInfo = getAttributeValue(elt, 'hx-sse');
                if (sseInfo) {
                    processSSEInfo(elt, nodeData, sseInfo);
                }

                var wsInfo = getAttributeValue(elt, 'hx-ws');
                if (wsInfo) {
                    processWebSocketInfo(elt, nodeData, wsInfo);
                }
                triggerEvent(elt, "htmx:afterProcessNode");
            }
        }

        function processNode(elt) {
            elt = resolveTarget(elt);
            if (closest(elt, htmx.config.disableSelector)) {
                cleanUpElement(elt)
                return;
            }
            initNode(elt);
            forEach(findElementsToProcess(elt), function(child) { initNode(child) });
            // Because it happens second, the new way of adding onHandlers superseeds the old one
            // i.e. if there are any hx-on:eventName attributes, the hx-on attribute will be ignored
            forEach(findHxOnWildcardElements(elt), processHxOnWildcard);
        }

        //====================================================================
        // Event/Log Support
        //====================================================================

        function kebabEventName(str) {
            return str.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
        }

        function makeEvent(eventName, detail) {
            var evt;
            if (window.CustomEvent && typeof window.CustomEvent === 'function') {
                evt = new CustomEvent(eventName, {bubbles: true, cancelable: true, detail: detail});
            } else {
                evt = getDocument().createEvent('CustomEvent');
                evt.initCustomEvent(eventName, true, true, detail);
            }
            return evt;
        }

        function triggerErrorEvent(elt, eventName, detail) {
            triggerEvent(elt, eventName, mergeObjects({error:eventName}, detail));
        }

        function ignoreEventForLogging(eventName) {
            return eventName === "htmx:afterProcessNode"
        }

        /**
         * `withExtensions` locates all active extensions for a provided element, then
         * executes the provided function using each of the active extensions.  It should
         * be called internally at every extendable execution point in htmx.
         *
         * @param {HTMLElement} elt
         * @param {(extension:import("./htmx").HtmxExtension) => void} toDo
         * @returns void
         */
        function withExtensions(elt, toDo) {
            forEach(getExtensions(elt), function(extension){
                try {
                    toDo(extension);
                } catch (e) {
                    logError(e);
                }
            });
        }

        function logError(msg) {
            if(console.error) {
                console.error(msg);
            } else if (console.log) {
                console.log("ERROR: ", msg);
            }
        }

        function triggerEvent(elt, eventName, detail) {
            elt = resolveTarget(elt);
            if (detail == null) {
                detail = {};
            }
            detail["elt"] = elt;
            var event = makeEvent(eventName, detail);
            if (htmx.logger && !ignoreEventForLogging(eventName)) {
                htmx.logger(elt, eventName, detail);
            }
            if (detail.error) {
                logError(detail.error);
                triggerEvent(elt, "htmx:error", {errorInfo:detail})
            }
            var eventResult = elt.dispatchEvent(event);
            var kebabName = kebabEventName(eventName);
            if (eventResult && kebabName !== eventName) {
                var kebabedEvent = makeEvent(kebabName, event.detail);
                eventResult = eventResult && elt.dispatchEvent(kebabedEvent)
            }
            withExtensions(elt, function (extension) {
                eventResult = eventResult && (extension.onEvent(eventName, event) !== false && !event.defaultPrevented)
            });
            return eventResult;
        }

        //====================================================================
        // History Support
        //====================================================================
        var currentPathForHistory = location.pathname+location.search;

        function getHistoryElement() {
            var historyElt = getDocument().querySelector('[hx-history-elt],[data-hx-history-elt]');
            return historyElt || getDocument().body;
        }

        function saveToHistoryCache(url, content, title, scroll) {
            if (!canAccessLocalStorage()) {
                return;
            }

            if (htmx.config.historyCacheSize <= 0) {
                // make sure that an eventually already existing cache is purged
                localStorage.removeItem("htmx-history-cache");
                return;
            }

            url = normalizePath(url);

            var historyCache = parseJSON(localStorage.getItem("htmx-history-cache")) || [];
            for (var i = 0; i < historyCache.length; i++) {
                if (historyCache[i].url === url) {
                    historyCache.splice(i, 1);
                    break;
                }
            }
            var newHistoryItem = {url:url, content: content, title:title, scroll:scroll};
            triggerEvent(getDocument().body, "htmx:historyItemCreated", {item:newHistoryItem, cache: historyCache})
            historyCache.push(newHistoryItem)
            while (historyCache.length > htmx.config.historyCacheSize) {
                historyCache.shift();
            }
            while(historyCache.length > 0){
                try {
                    localStorage.setItem("htmx-history-cache", JSON.stringify(historyCache));
                    break;
                } catch (e) {
                    triggerErrorEvent(getDocument().body, "htmx:historyCacheError", {cause:e, cache: historyCache})
                    historyCache.shift(); // shrink the cache and retry
                }
            }
        }

        function getCachedHistory(url) {
            if (!canAccessLocalStorage()) {
                return null;
            }

            url = normalizePath(url);

            var historyCache = parseJSON(localStorage.getItem("htmx-history-cache")) || [];
            for (var i = 0; i < historyCache.length; i++) {
                if (historyCache[i].url === url) {
                    return historyCache[i];
                }
            }
            return null;
        }

        function cleanInnerHtmlForHistory(elt) {
            var className = htmx.config.requestClass;
            var clone = elt.cloneNode(true);
            forEach(findAll(clone, "." + className), function(child){
                removeClassFromElement(child, className);
            });
            return clone.innerHTML;
        }

        function saveCurrentPageToHistory() {
            var elt = getHistoryElement();
            var path = currentPathForHistory || location.pathname+location.search;

            // Allow history snapshot feature to be disabled where hx-history="false"
            // is present *anywhere* in the current document we're about to save,
            // so we can prevent privileged data entering the cache.
            // The page will still be reachable as a history entry, but htmx will fetch it
            // live from the server onpopstate rather than look in the localStorage cache
            var disableHistoryCache
            try {
                disableHistoryCache = getDocument().querySelector('[hx-history="false" i],[data-hx-history="false" i]')
            } catch (e) {
                // IE11: insensitive modifier not supported so fallback to case sensitive selector
                disableHistoryCache = getDocument().querySelector('[hx-history="false"],[data-hx-history="false"]')
            }
            if (!disableHistoryCache) {
                triggerEvent(getDocument().body, "htmx:beforeHistorySave", {path: path, historyElt: elt});
                saveToHistoryCache(path, cleanInnerHtmlForHistory(elt), getDocument().title, window.scrollY);
            }

            if (htmx.config.historyEnabled) history.replaceState({htmx: true}, getDocument().title, window.location.href);
        }

        function pushUrlIntoHistory(path) {
            // remove the cache buster parameter, if any
            if (htmx.config.getCacheBusterParam) {
                path = path.replace(/org\.htmx\.cache-buster=[^&]*&?/, '')
                if (endsWith(path, '&') || endsWith(path, "?")) {
                    path = path.slice(0, -1);
                }
            }
            if(htmx.config.historyEnabled) {
                history.pushState({htmx:true}, "", path);
            }
            currentPathForHistory = path;
        }

        function replaceUrlInHistory(path) {
            if(htmx.config.historyEnabled)  history.replaceState({htmx:true}, "", path);
            currentPathForHistory = path;
        }

        function settleImmediately(tasks) {
            forEach(tasks, function (task) {
                task.call();
            });
        }

        function loadHistoryFromServer(path) {
            var request = new XMLHttpRequest();
            var description = {path: path, xhr:request};
            triggerEvent(getDocument().body, "htmx:historyCacheMiss", description);
            request.open('GET', path, true);
            request.setRequestHeader("HX-Request", "true");
            request.setRequestHeader("HX-History-Restore-Request", "true");
            request.setRequestHeader("HX-Current-URL", getDocument().location.href);
            request.onload = function () {
                if (this.status >= 200 && this.status < 400) {
                    triggerEvent(getDocument().body, "htmx:historyCacheMissLoad", description);
                    var fragment = makeFragment(this.response);
                    // @ts-ignore
                    fragment = fragment.querySelector('[hx-history-elt],[data-hx-history-elt]') || fragment;
                    var historyElement = getHistoryElement();
                    var settleInfo = makeSettleInfo(historyElement);
                    var title = findTitle(this.response);
                    if (title) {
                        var titleElt = find("title");
                        if (titleElt) {
                            titleElt.innerHTML = title;
                        } else {
                            window.document.title = title;
                        }
                    }
                    // @ts-ignore
                    swapInnerHTML(historyElement, fragment, settleInfo)
                    settleImmediately(settleInfo.tasks);
                    currentPathForHistory = path;
                    triggerEvent(getDocument().body, "htmx:historyRestore", {path: path, cacheMiss:true, serverResponse:this.response});
                } else {
                    triggerErrorEvent(getDocument().body, "htmx:historyCacheMissLoadError", description);
                }
            };
            request.send();
        }

        function restoreHistory(path) {
            saveCurrentPageToHistory();
            path = path || location.pathname+location.search;
            var cached = getCachedHistory(path);
            if (cached) {
                var fragment = makeFragment(cached.content);
                var historyElement = getHistoryElement();
                var settleInfo = makeSettleInfo(historyElement);
                swapInnerHTML(historyElement, fragment, settleInfo)
                settleImmediately(settleInfo.tasks);
                document.title = cached.title;
                setTimeout(function () {
                    window.scrollTo(0, cached.scroll);
                }, 0); // next 'tick', so browser has time to render layout
                currentPathForHistory = path;
                triggerEvent(getDocument().body, "htmx:historyRestore", {path:path, item:cached});
            } else {
                if (htmx.config.refreshOnHistoryMiss) {

                    // @ts-ignore: optional parameter in reload() function throws error
                    window.location.reload(true);
                } else {
                    loadHistoryFromServer(path);
                }
            }
        }

        function addRequestIndicatorClasses(elt) {
            var indicators = findAttributeTargets(elt, 'hx-indicator');
            if (indicators == null) {
                indicators = [elt];
            }
            forEach(indicators, function (ic) {
                var internalData = getInternalData(ic);
                internalData.requestCount = (internalData.requestCount || 0) + 1;
                ic.classList["add"].call(ic.classList, htmx.config.requestClass);
            });
            return indicators;
        }

        function disableElements(elt) {
            var disabledElts = findAttributeTargets(elt, 'hx-disabled-elt');
            if (disabledElts == null) {
                disabledElts = [];
            }
            forEach(disabledElts, function (disabledElement) {
                var internalData = getInternalData(disabledElement);
                internalData.requestCount = (internalData.requestCount || 0) + 1;
                disabledElement.setAttribute("disabled", "");
            });
            return disabledElts;
        }

        function removeRequestIndicators(indicators, disabled) {
            forEach(indicators, function (ic) {
                var internalData = getInternalData(ic);
                internalData.requestCount = (internalData.requestCount || 0) - 1;
                if (internalData.requestCount === 0) {
                    ic.classList["remove"].call(ic.classList, htmx.config.requestClass);
                }
            });
            forEach(disabled, function (disabledElement) {
                var internalData = getInternalData(disabledElement);
                internalData.requestCount = (internalData.requestCount || 0) - 1;
                if (internalData.requestCount === 0) {
                    disabledElement.removeAttribute('disabled');
                }
            });
        }

        //====================================================================
        // Input Value Processing
        //====================================================================

        function haveSeenNode(processed, elt) {
            for (var i = 0; i < processed.length; i++) {
                var node = processed[i];
                if (node.isSameNode(elt)) {
                    return true;
                }
            }
            return false;
        }

        function shouldInclude(elt) {
            if(elt.name === "" || elt.name == null || elt.disabled || closest(elt, "fieldset[disabled]")) {
                return false;
            }
            // ignore "submitter" types (see jQuery src/serialize.js)
            if (elt.type === "button" || elt.type === "submit" || elt.tagName === "image" || elt.tagName === "reset" || elt.tagName === "file" ) {
                return false;
            }
            if (elt.type === "checkbox" || elt.type === "radio" ) {
                return elt.checked;
            }
            return true;
        }

        function addValueToValues(name, value, values) {
            // This is a little ugly because both the current value of the named value in the form
            // and the new value could be arrays, so we have to handle all four cases :/
            if (name != null && value != null) {
                var current = values[name];
                if (current === undefined) {
                    values[name] = value;
                } else if (Array.isArray(current)) {
                    if (Array.isArray(value)) {
                        values[name] = current.concat(value);
                    } else {
                        current.push(value);
                    }
                } else {
                    if (Array.isArray(value)) {
                        values[name] = [current].concat(value);
                    } else {
                        values[name] = [current, value];
                    }
                }
            }
        }

        function processInputValue(processed, values, errors, elt, validate) {
            if (elt == null || haveSeenNode(processed, elt)) {
                return;
            } else {
                processed.push(elt);
            }
            if (shouldInclude(elt)) {
                var name = getRawAttribute(elt,"name");
                var value = elt.value;
                if (elt.multiple && elt.tagName === "SELECT") {
                    value = toArray(elt.querySelectorAll("option:checked")).map(function (e) { return e.value });
                }
                // include file inputs
                if (elt.files) {
                    value = toArray(elt.files);
                }
                addValueToValues(name, value, values);
                if (validate) {
                    validateElement(elt, errors);
                }
            }
            if (matches(elt, 'form')) {
                var inputs = elt.elements;
                forEach(inputs, function(input) {
                    processInputValue(processed, values, errors, input, validate);
                });
            }
        }

        function validateElement(element, errors) {
            if (element.willValidate) {
                triggerEvent(element, "htmx:validation:validate")
                if (!element.checkValidity()) {
                    errors.push({elt: element, message:element.validationMessage, validity:element.validity});
                    triggerEvent(element, "htmx:validation:failed", {message:element.validationMessage, validity:element.validity})
                }
            }
        }

        /**
         * @param {HTMLElement} elt
         * @param {string} verb
         */
        function getInputValues(elt, verb) {
            var processed = [];
            var values = {};
            var formValues = {};
            var errors = [];
            var internalData = getInternalData(elt);
            if (internalData.lastButtonClicked && !bodyContains(internalData.lastButtonClicked)) {
                internalData.lastButtonClicked = null
            }

            // only validate when form is directly submitted and novalidate or formnovalidate are not set
            // or if the element has an explicit hx-validate="true" on it
            var validate = (matches(elt, 'form') && elt.noValidate !== true) || getAttributeValue(elt, "hx-validate") === "true";
            if (internalData.lastButtonClicked) {
                validate = validate && internalData.lastButtonClicked.formNoValidate !== true;
            }

            // for a non-GET include the closest form
            if (verb !== 'get') {
                processInputValue(processed, formValues, errors, closest(elt, 'form'), validate);
            }

            // include the element itself
            processInputValue(processed, values, errors, elt, validate);

            // if a button or submit was clicked last, include its value
            if (internalData.lastButtonClicked || elt.tagName === "BUTTON" ||
                (elt.tagName === "INPUT" && getRawAttribute(elt, "type") === "submit")) {
                var button = internalData.lastButtonClicked || elt
                var name = getRawAttribute(button, "name")
                addValueToValues(name, button.value, formValues)
            }

            // include any explicit includes
            var includes = findAttributeTargets(elt, "hx-include");
            forEach(includes, function(node) {
                processInputValue(processed, values, errors, node, validate);
                // if a non-form is included, include any input values within it
                if (!matches(node, 'form')) {
                    forEach(node.querySelectorAll(INPUT_SELECTOR), function (descendant) {
                        processInputValue(processed, values, errors, descendant, validate);
                    })
                }
            });

            // form values take precedence, overriding the regular values
            values = mergeObjects(values, formValues);

            return {errors:errors, values:values};
        }

        function appendParam(returnStr, name, realValue) {
            if (returnStr !== "") {
                returnStr += "&";
            }
            if (String(realValue) === "[object Object]") {
                realValue = JSON.stringify(realValue);
            }
            var s = encodeURIComponent(realValue);
            returnStr += encodeURIComponent(name) + "=" + s;
            return returnStr;
        }

        function urlEncode(values) {
            var returnStr = "";
            for (var name in values) {
                if (values.hasOwnProperty(name)) {
                    var value = values[name];
                    if (Array.isArray(value)) {
                        forEach(value, function(v) {
                            returnStr = appendParam(returnStr, name, v);
                        });
                    } else {
                        returnStr = appendParam(returnStr, name, value);
                    }
                }
            }
            return returnStr;
        }

        function makeFormData(values) {
            var formData = new FormData();
            for (var name in values) {
                if (values.hasOwnProperty(name)) {
                    var value = values[name];
                    if (Array.isArray(value)) {
                        forEach(value, function(v) {
                            formData.append(name, v);
                        });
                    } else {
                        formData.append(name, value);
                    }
                }
            }
            return formData;
        }

        //====================================================================
        // Ajax
        //====================================================================

        /**
         * @param {HTMLElement} elt
         * @param {HTMLElement} target
         * @param {string} prompt
         * @returns {Object} // TODO: Define/Improve HtmxHeaderSpecification
         */
        function getHeaders(elt, target, prompt) {
            var headers = {
                "HX-Request" : "true",
                "HX-Trigger" : getRawAttribute(elt, "id"),
                "HX-Trigger-Name" : getRawAttribute(elt, "name"),
                "HX-Target" : getAttributeValue(target, "id"),
                "HX-Current-URL" : getDocument().location.href,
            }
            getValuesForElement(elt, "hx-headers", false, headers)
            if (prompt !== undefined) {
                headers["HX-Prompt"] = prompt;
            }
            if (getInternalData(elt).boosted) {
                headers["HX-Boosted"] = "true";
            }
            return headers;
        }

        /**
         * filterValues takes an object containing form input values
         * and returns a new object that only contains keys that are
         * specified by the closest "hx-params" attribute
         * @param {Object} inputValues
         * @param {HTMLElement} elt
         * @returns {Object}
         */
        function filterValues(inputValues, elt) {
            var paramsValue = getClosestAttributeValue(elt, "hx-params");
            if (paramsValue) {
                if (paramsValue === "none") {
                    return {};
                } else if (paramsValue === "*") {
                    return inputValues;
                } else if(paramsValue.indexOf("not ") === 0) {
                    forEach(paramsValue.substr(4).split(","), function (name) {
                        name = name.trim();
                        delete inputValues[name];
                    });
                    return inputValues;
                } else {
                    var newValues = {}
                    forEach(paramsValue.split(","), function (name) {
                        name = name.trim();
                        newValues[name] = inputValues[name];
                    });
                    return newValues;
                }
            } else {
                return inputValues;
            }
        }

        function isAnchorLink(elt) {
          return getRawAttribute(elt, 'href') && getRawAttribute(elt, 'href').indexOf("#") >=0
        }

        /**
         *
         * @param {HTMLElement} elt
         * @param {string} swapInfoOverride
         * @returns {import("./htmx").HtmxSwapSpecification}
         */
        function getSwapSpecification(elt, swapInfoOverride) {
            var swapInfo = swapInfoOverride ? swapInfoOverride : getClosestAttributeValue(elt, "hx-swap");
            var swapSpec = {
                "swapStyle" : getInternalData(elt).boosted ? 'innerHTML' : htmx.config.defaultSwapStyle,
                "swapDelay" : htmx.config.defaultSwapDelay,
                "settleDelay" : htmx.config.defaultSettleDelay
            }
            if (htmx.config.scrollIntoViewOnBoost && getInternalData(elt).boosted && !isAnchorLink(elt)) {
              swapSpec["show"] = "top"
            }
            if (swapInfo) {
                var split = splitOnWhitespace(swapInfo);
                if (split.length > 0) {
                    for (var i = 0; i < split.length; i++) {
                        var value = split[i];
                        if (value.indexOf("swap:") === 0) {
                            swapSpec["swapDelay"] = parseInterval(value.substr(5));
                        } else if (value.indexOf("settle:") === 0) {
                            swapSpec["settleDelay"] = parseInterval(value.substr(7));
                        } else if (value.indexOf("transition:") === 0) {
                            swapSpec["transition"] = value.substr(11) === "true";
                        } else if (value.indexOf("ignoreTitle:") === 0) {
                            swapSpec["ignoreTitle"] = value.substr(12) === "true";
                        } else if (value.indexOf("scroll:") === 0) {
                            var scrollSpec = value.substr(7);
                            var splitSpec = scrollSpec.split(":");
                            var scrollVal = splitSpec.pop();
                            var selectorVal = splitSpec.length > 0 ? splitSpec.join(":") : null;
                            swapSpec["scroll"] = scrollVal;
                            swapSpec["scrollTarget"] = selectorVal;
                        } else if (value.indexOf("show:") === 0) {
                            var showSpec = value.substr(5);
                            var splitSpec = showSpec.split(":");
                            var showVal = splitSpec.pop();
                            var selectorVal = splitSpec.length > 0 ? splitSpec.join(":") : null;
                            swapSpec["show"] = showVal;
                            swapSpec["showTarget"] = selectorVal;
                        } else if (value.indexOf("focus-scroll:") === 0) {
                            var focusScrollVal = value.substr("focus-scroll:".length);
                            swapSpec["focusScroll"] = focusScrollVal == "true";
                        } else if (i == 0) {
                            swapSpec["swapStyle"] = value;
                        } else {
                            logError('Unknown modifier in hx-swap: ' + value);
                        }
                    }
                }
            }
            return swapSpec;
        }

        function usesFormData(elt) {
            return getClosestAttributeValue(elt, "hx-encoding") === "multipart/form-data" ||
                (matches(elt, "form") && getRawAttribute(elt, 'enctype') === "multipart/form-data");
        }

        function encodeParamsForBody(xhr, elt, filteredParameters) {
            var encodedParameters = null;
            withExtensions(elt, function (extension) {
                if (encodedParameters == null) {
                    encodedParameters = extension.encodeParameters(xhr, filteredParameters, elt);
                }
            });
            if (encodedParameters != null) {
                return encodedParameters;
            } else {
                if (usesFormData(elt)) {
                    return makeFormData(filteredParameters);
                } else {
                    return urlEncode(filteredParameters);
                }
            }
        }

        /**
         *
         * @param {Element} target
         * @returns {import("./htmx").HtmxSettleInfo}
         */
        function makeSettleInfo(target) {
            return {tasks: [], elts: [target]};
        }

        function updateScrollState(content, swapSpec) {
            var first = content[0];
            var last = content[content.length - 1];
            if (swapSpec.scroll) {
                var target = null;
                if (swapSpec.scrollTarget) {
                    target = querySelectorExt(first, swapSpec.scrollTarget);
                }
                if (swapSpec.scroll === "top" && (first || target)) {
                    target = target || first;
                    target.scrollTop = 0;
                }
                if (swapSpec.scroll === "bottom" && (last || target)) {
                    target = target || last;
                    target.scrollTop = target.scrollHeight;
                }
            }
            if (swapSpec.show) {
                var target = null;
                if (swapSpec.showTarget) {
                    var targetStr = swapSpec.showTarget;
                    if (swapSpec.showTarget === "window") {
                        targetStr = "body";
                    }
                    target = querySelectorExt(first, targetStr);
                }
                if (swapSpec.show === "top" && (first || target)) {
                    target = target || first;
                    target.scrollIntoView({block:'start', behavior: htmx.config.scrollBehavior});
                }
                if (swapSpec.show === "bottom" && (last || target)) {
                    target = target || last;
                    target.scrollIntoView({block:'end', behavior: htmx.config.scrollBehavior});
                }
            }
        }

        /**
         * @param {HTMLElement} elt
         * @param {string} attr
         * @param {boolean=} evalAsDefault
         * @param {Object=} values
         * @returns {Object}
         */
        function getValuesForElement(elt, attr, evalAsDefault, values) {
            if (values == null) {
                values = {};
            }
            if (elt == null) {
                return values;
            }
            var attributeValue = getAttributeValue(elt, attr);
            if (attributeValue) {
                var str = attributeValue.trim();
                var evaluateValue = evalAsDefault;
                if (str === "unset") {
                    return null;
                }
                if (str.indexOf("javascript:") === 0) {
                    str = str.substr(11);
                    evaluateValue = true;
                } else if (str.indexOf("js:") === 0) {
                    str = str.substr(3);
                    evaluateValue = true;
                }
                if (str.indexOf('{') !== 0) {
                    str = "{" + str + "}";
                }
                var varsValues;
                if (evaluateValue) {
                    varsValues = maybeEval(elt,function () {return Function("return (" + str + ")")();}, {});
                } else {
                    varsValues = parseJSON(str);
                }
                for (var key in varsValues) {
                    if (varsValues.hasOwnProperty(key)) {
                        if (values[key] == null) {
                            values[key] = varsValues[key];
                        }
                    }
                }
            }
            return getValuesForElement(parentElt(elt), attr, evalAsDefault, values);
        }

        function maybeEval(elt, toEval, defaultVal) {
            if (htmx.config.allowEval) {
                return toEval();
            } else {
                triggerErrorEvent(elt, 'htmx:evalDisallowedError');
                return defaultVal;
            }
        }

        /**
         * @param {HTMLElement} elt
         * @param {*} expressionVars
         * @returns
         */
        function getHXVarsForElement(elt, expressionVars) {
            return getValuesForElement(elt, "hx-vars", true, expressionVars);
        }

        /**
         * @param {HTMLElement} elt
         * @param {*} expressionVars
         * @returns
         */
        function getHXValsForElement(elt, expressionVars) {
            return getValuesForElement(elt, "hx-vals", false, expressionVars);
        }

        /**
         * @param {HTMLElement} elt
         * @returns {Object}
         */
        function getExpressionVars(elt) {
            return mergeObjects(getHXVarsForElement(elt), getHXValsForElement(elt));
        }

        function safelySetHeaderValue(xhr, header, headerValue) {
            if (headerValue !== null) {
                try {
                    xhr.setRequestHeader(header, headerValue);
                } catch (e) {
                    // On an exception, try to set the header URI encoded instead
                    xhr.setRequestHeader(header, encodeURIComponent(headerValue));
                    xhr.setRequestHeader(header + "-URI-AutoEncoded", "true");
                }
            }
        }

        function getPathFromResponse(xhr) {
            // NB: IE11 does not support this stuff
            if (xhr.responseURL && typeof(URL) !== "undefined") {
                try {
                    var url = new URL(xhr.responseURL);
                    return url.pathname + url.search;
                } catch (e) {
                    triggerErrorEvent(getDocument().body, "htmx:badResponseUrl", {url: xhr.responseURL});
                }
            }
        }

        function hasHeader(xhr, regexp) {
            return regexp.test(xhr.getAllResponseHeaders())
        }

        function ajaxHelper(verb, path, context) {
            verb = verb.toLowerCase();
            if (context) {
                if (context instanceof Element || isType(context, 'String')) {
                    return issueAjaxRequest(verb, path, null, null, {
                        targetOverride: resolveTarget(context),
                        returnPromise: true
                    });
                } else {
                    return issueAjaxRequest(verb, path, resolveTarget(context.source), context.event,
                        {
                            handler : context.handler,
                            headers : context.headers,
                            values : context.values,
                            targetOverride: resolveTarget(context.target),
                            swapOverride: context.swap,
                            select: context.select,
                            returnPromise: true
                        });
                }
            } else {
                return issueAjaxRequest(verb, path, null, null, {
                        returnPromise: true
                });
            }
        }

        function hierarchyForElt(elt) {
            var arr = [];
            while (elt) {
                arr.push(elt);
                elt = elt.parentElement;
            }
            return arr;
        }

        function verifyPath(elt, path, requestConfig) {
            var sameHost
            var url
            if (typeof URL === "function") {
                url = new URL(path, document.location.href);
                var origin = document.location.origin;
                sameHost = origin === url.origin;
            } else {
                // IE11 doesn't support URL
                url = path
                sameHost = startsWith(path, document.location.origin)
            }

            if (htmx.config.selfRequestsOnly) {
                if (!sameHost) {
                    return false;
                }
            }
            return triggerEvent(elt, "htmx:validateUrl", mergeObjects({url: url, sameHost: sameHost}, requestConfig));
        }

        function issueAjaxRequest(verb, path, elt, event, etc, confirmed) {
            var resolve = null;
            var reject = null;
            etc = etc != null ? etc : {};
            if(etc.returnPromise && typeof Promise !== "undefined"){
                var promise = new Promise(function (_resolve, _reject) {
                    resolve = _resolve;
                    reject = _reject;
                });
            }
            if(elt == null) {
                elt = getDocument().body;
            }
            var responseHandler = etc.handler || handleAjaxResponse;
            var select = etc.select || null;

            if (!bodyContains(elt)) {
                // do not issue requests for elements removed from the DOM
                maybeCall(resolve);
                return promise;
            }
            var target = etc.targetOverride || getTarget(elt);
            if (target == null || target == DUMMY_ELT) {
                triggerErrorEvent(elt, 'htmx:targetError', {target: getAttributeValue(elt, "hx-target")});
                maybeCall(reject);
                return promise;
            }

            var eltData = getInternalData(elt);
            var submitter = eltData.lastButtonClicked;

            if (submitter) {
                var buttonPath = getRawAttribute(submitter, "formaction");
                if (buttonPath != null) {
                    path = buttonPath;
                }

                var buttonVerb = getRawAttribute(submitter, "formmethod")
                if (buttonVerb != null) {
                    // ignore buttons with formmethod="dialog"
                    if (buttonVerb.toLowerCase() !== "dialog") {
                        verb = buttonVerb;
                    }
                }
            }

            var confirmQuestion = getClosestAttributeValue(elt, "hx-confirm");
            // allow event-based confirmation w/ a callback
            if (confirmed === undefined) {
                var issueRequest = function(skipConfirmation) {
                    return issueAjaxRequest(verb, path, elt, event, etc, !!skipConfirmation);
                }
                var confirmDetails = {target: target, elt: elt, path: path, verb: verb, triggeringEvent: event, etc: etc, issueRequest: issueRequest, question: confirmQuestion};
                if (triggerEvent(elt, 'htmx:confirm', confirmDetails) === false) {
                    maybeCall(resolve);
                    return promise;
                }
            }

            var syncElt = elt;
            var syncStrategy = getClosestAttributeValue(elt, "hx-sync");
            var queueStrategy = null;
            var abortable = false;
            if (syncStrategy) {
                var syncStrings = syncStrategy.split(":");
                var selector = syncStrings[0].trim();
                if (selector === "this") {
                    syncElt = findThisElement(elt, 'hx-sync');
                } else {
                    syncElt = querySelectorExt(elt, selector);
                }
                // default to the drop strategy
                syncStrategy = (syncStrings[1] || 'drop').trim();
                eltData = getInternalData(syncElt);
                if (syncStrategy === "drop" && eltData.xhr && eltData.abortable !== true) {
                    maybeCall(resolve);
                    return promise;
                } else if (syncStrategy === "abort") {
                    if (eltData.xhr) {
                        maybeCall(resolve);
                        return promise;
                    } else {
                        abortable = true;
                    }
                } else if (syncStrategy === "replace") {
                    triggerEvent(syncElt, 'htmx:abort'); // abort the current request and continue
                } else if (syncStrategy.indexOf("queue") === 0) {
                    var queueStrArray = syncStrategy.split(" ");
                    queueStrategy = (queueStrArray[1] || "last").trim();
                }
            }

            if (eltData.xhr) {
                if (eltData.abortable) {
                    triggerEvent(syncElt, 'htmx:abort'); // abort the current request and continue
                } else {
                    if(queueStrategy == null){
                        if (event) {
                            var eventData = getInternalData(event);
                            if (eventData && eventData.triggerSpec && eventData.triggerSpec.queue) {
                                queueStrategy = eventData.triggerSpec.queue;
                            }
                        }
                        if (queueStrategy == null) {
                            queueStrategy = "last";
                        }
                    }
                    if (eltData.queuedRequests == null) {
                        eltData.queuedRequests = [];
                    }
                    if (queueStrategy === "first" && eltData.queuedRequests.length === 0) {
                        eltData.queuedRequests.push(function () {
                            issueAjaxRequest(verb, path, elt, event, etc)
                        });
                    } else if (queueStrategy === "all") {
                        eltData.queuedRequests.push(function () {
                            issueAjaxRequest(verb, path, elt, event, etc)
                        });
                    } else if (queueStrategy === "last") {
                        eltData.queuedRequests = []; // dump existing queue
                        eltData.queuedRequests.push(function () {
                            issueAjaxRequest(verb, path, elt, event, etc)
                        });
                    }
                    maybeCall(resolve);
                    return promise;
                }
            }

            var xhr = new XMLHttpRequest();
            eltData.xhr = xhr;
            eltData.abortable = abortable;
            var endRequestLock = function(){
                eltData.xhr = null;
                eltData.abortable = false;
                if (eltData.queuedRequests != null &&
                    eltData.queuedRequests.length > 0) {
                    var queuedRequest = eltData.queuedRequests.shift();
                    queuedRequest();
                }
            }
            var promptQuestion = getClosestAttributeValue(elt, "hx-prompt");
            if (promptQuestion) {
                var promptResponse = prompt(promptQuestion);
                // prompt returns null if cancelled and empty string if accepted with no entry
                if (promptResponse === null ||
                    !triggerEvent(elt, 'htmx:prompt', {prompt: promptResponse, target:target})) {
                    maybeCall(resolve);
                    endRequestLock();
                    return promise;
                }
            }

            if (confirmQuestion && !confirmed) {
                if(!confirm(confirmQuestion)) {
                    maybeCall(resolve);
                    endRequestLock()
                    return promise;
                }
            }


            var headers = getHeaders(elt, target, promptResponse);

            if (verb !== 'get' && !usesFormData(elt)) {
                headers['Content-Type'] = 'application/x-www-form-urlencoded';
            }

            if (etc.headers) {
                headers = mergeObjects(headers, etc.headers);
            }
            var results = getInputValues(elt, verb);
            var errors = results.errors;
            var rawParameters = results.values;
            if (etc.values) {
                rawParameters = mergeObjects(rawParameters, etc.values);
            }
            var expressionVars = getExpressionVars(elt);
            var allParameters = mergeObjects(rawParameters, expressionVars);
            var filteredParameters = filterValues(allParameters, elt);

            if (htmx.config.getCacheBusterParam && verb === 'get') {
                filteredParameters['org.htmx.cache-buster'] = getRawAttribute(target, "id") || "true";
            }

            // behavior of anchors w/ empty href is to use the current URL
            if (path == null || path === "") {
                path = getDocument().location.href;
            }


            var requestAttrValues = getValuesForElement(elt, 'hx-request');

            var eltIsBoosted = getInternalData(elt).boosted;

            var useUrlParams = htmx.config.methodsThatUseUrlParams.indexOf(verb) >= 0

            var requestConfig = {
                boosted: eltIsBoosted,
                useUrlParams: useUrlParams,
                parameters: filteredParameters,
                unfilteredParameters: allParameters,
                headers:headers,
                target:target,
                verb:verb,
                errors:errors,
                withCredentials: etc.credentials || requestAttrValues.credentials || htmx.config.withCredentials,
                timeout:  etc.timeout || requestAttrValues.timeout || htmx.config.timeout,
                path:path,
                triggeringEvent:event
            };

            if(!triggerEvent(elt, 'htmx:configRequest', requestConfig)){
                maybeCall(resolve);
                endRequestLock();
                return promise;
            }

            // copy out in case the object was overwritten
            path = requestConfig.path;
            verb = requestConfig.verb;
            headers = requestConfig.headers;
            filteredParameters = requestConfig.parameters;
            errors = requestConfig.errors;
            useUrlParams = requestConfig.useUrlParams;

            if(errors && errors.length > 0){
                triggerEvent(elt, 'htmx:validation:halted', requestConfig)
                maybeCall(resolve);
                endRequestLock();
                return promise;
            }

            var splitPath = path.split("#");
            var pathNoAnchor = splitPath[0];
            var anchor = splitPath[1];

            var finalPath = path
            if (useUrlParams) {
                finalPath = pathNoAnchor;
                var values = Object.keys(filteredParameters).length !== 0;
                if (values) {
                    if (finalPath.indexOf("?") < 0) {
                        finalPath += "?";
                    } else {
                        finalPath += "&";
                    }
                    finalPath += urlEncode(filteredParameters);
                    if (anchor) {
                        finalPath += "#" + anchor;
                    }
                }
            }

            if (!verifyPath(elt, finalPath, requestConfig)) {
                triggerErrorEvent(elt, 'htmx:invalidPath', requestConfig)
                maybeCall(reject);
                return promise;
            };

            xhr.open(verb.toUpperCase(), finalPath, true);
            xhr.overrideMimeType("text/html");
            xhr.withCredentials = requestConfig.withCredentials;
            xhr.timeout = requestConfig.timeout;

            // request headers
            if (requestAttrValues.noHeaders) {
                // ignore all headers
            } else {
                for (var header in headers) {
                    if (headers.hasOwnProperty(header)) {
                        var headerValue = headers[header];
                        safelySetHeaderValue(xhr, header, headerValue);
                    }
                }
            }

            var responseInfo = {
                xhr: xhr, target: target, requestConfig: requestConfig, etc: etc, boosted: eltIsBoosted, select: select,
                pathInfo: {
                    requestPath: path,
                    finalRequestPath: finalPath,
                    anchor: anchor
                }
            };

            xhr.onload = function () {
                try {
                    var hierarchy = hierarchyForElt(elt);
                    responseInfo.pathInfo.responsePath = getPathFromResponse(xhr);
                    responseHandler(elt, responseInfo);
                    removeRequestIndicators(indicators, disableElts);
                    triggerEvent(elt, 'htmx:afterRequest', responseInfo);
                    triggerEvent(elt, 'htmx:afterOnLoad', responseInfo);
                    // if the body no longer contains the element, trigger the event on the closest parent
                    // remaining in the DOM
                    if (!bodyContains(elt)) {
                        var secondaryTriggerElt = null;
                        while (hierarchy.length > 0 && secondaryTriggerElt == null) {
                            var parentEltInHierarchy = hierarchy.shift();
                            if (bodyContains(parentEltInHierarchy)) {
                                secondaryTriggerElt = parentEltInHierarchy;
                            }
                        }
                        if (secondaryTriggerElt) {
                            triggerEvent(secondaryTriggerElt, 'htmx:afterRequest', responseInfo);
                            triggerEvent(secondaryTriggerElt, 'htmx:afterOnLoad', responseInfo);
                        }
                    }
                    maybeCall(resolve);
                    endRequestLock();
                } catch (e) {
                    triggerErrorEvent(elt, 'htmx:onLoadError', mergeObjects({error:e}, responseInfo));
                    throw e;
                }
            }
            xhr.onerror = function () {
                removeRequestIndicators(indicators, disableElts);
                triggerErrorEvent(elt, 'htmx:afterRequest', responseInfo);
                triggerErrorEvent(elt, 'htmx:sendError', responseInfo);
                maybeCall(reject);
                endRequestLock();
            }
            xhr.onabort = function() {
                removeRequestIndicators(indicators, disableElts);
                triggerErrorEvent(elt, 'htmx:afterRequest', responseInfo);
                triggerErrorEvent(elt, 'htmx:sendAbort', responseInfo);
                maybeCall(reject);
                endRequestLock();
            }
            xhr.ontimeout = function() {
                removeRequestIndicators(indicators, disableElts);
                triggerErrorEvent(elt, 'htmx:afterRequest', responseInfo);
                triggerErrorEvent(elt, 'htmx:timeout', responseInfo);
                maybeCall(reject);
                endRequestLock();
            }
            if(!triggerEvent(elt, 'htmx:beforeRequest', responseInfo)){
                maybeCall(resolve);
                endRequestLock()
                return promise
            }
            var indicators = addRequestIndicatorClasses(elt);
            var disableElts = disableElements(elt);

            forEach(['loadstart', 'loadend', 'progress', 'abort'], function(eventName) {
                forEach([xhr, xhr.upload], function (target) {
                    target.addEventListener(eventName, function(event){
                        triggerEvent(elt, "htmx:xhr:" + eventName, {
                            lengthComputable:event.lengthComputable,
                            loaded:event.loaded,
                            total:event.total
                        });
                    })
                });
            });
            triggerEvent(elt, 'htmx:beforeSend', responseInfo);
            var params = useUrlParams ? null : encodeParamsForBody(xhr, elt, filteredParameters)
            xhr.send(params);
            return promise;
        }

        function determineHistoryUpdates(elt, responseInfo) {

            var xhr = responseInfo.xhr;

            //===========================================
            // First consult response headers
            //===========================================
            var pathFromHeaders = null;
            var typeFromHeaders = null;
            if (hasHeader(xhr,/HX-Push:/i)) {
                pathFromHeaders = xhr.getResponseHeader("HX-Push");
                typeFromHeaders = "push";
            } else if (hasHeader(xhr,/HX-Push-Url:/i)) {
                pathFromHeaders = xhr.getResponseHeader("HX-Push-Url");
                typeFromHeaders = "push";
            } else if (hasHeader(xhr,/HX-Replace-Url:/i)) {
                pathFromHeaders = xhr.getResponseHeader("HX-Replace-Url");
                typeFromHeaders = "replace";
            }

            // if there was a response header, that has priority
            if (pathFromHeaders) {
                if (pathFromHeaders === "false") {
                    return {}
                } else {
                    return {
                        type: typeFromHeaders,
                        path : pathFromHeaders
                    }
                }
            }

            //===========================================
            // Next resolve via DOM values
            //===========================================
            var requestPath =  responseInfo.pathInfo.finalRequestPath;
            var responsePath =  responseInfo.pathInfo.responsePath;

            var pushUrl = getClosestAttributeValue(elt, "hx-push-url");
            var replaceUrl = getClosestAttributeValue(elt, "hx-replace-url");
            var elementIsBoosted = getInternalData(elt).boosted;

            var saveType = null;
            var path = null;

            if (pushUrl) {
                saveType = "push";
                path = pushUrl;
            } else if (replaceUrl) {
                saveType = "replace";
                path = replaceUrl;
            } else if (elementIsBoosted) {
                saveType = "push";
                path = responsePath || requestPath; // if there is no response path, go with the original request path
            }

            if (path) {
                // false indicates no push, return empty object
                if (path === "false") {
                    return {};
                }

                // true indicates we want to follow wherever the server ended up sending us
                if (path === "true") {
                    path = responsePath || requestPath; // if there is no response path, go with the original request path
                }

                // restore any anchor associated with the request
                if (responseInfo.pathInfo.anchor &&
                    path.indexOf("#") === -1) {
                    path = path + "#" + responseInfo.pathInfo.anchor;
                }

                return {
                    type:saveType,
                    path: path
                }
            } else {
                return {};
            }
        }

        function handleAjaxResponse(elt, responseInfo) {
            var xhr = responseInfo.xhr;
            var target = responseInfo.target;
            var etc = responseInfo.etc;
            var requestConfig = responseInfo.requestConfig;
            var select = responseInfo.select;

            if (!triggerEvent(elt, 'htmx:beforeOnLoad', responseInfo)) return;

            if (hasHeader(xhr, /HX-Trigger:/i)) {
                handleTrigger(xhr, "HX-Trigger", elt);
            }

            if (hasHeader(xhr, /HX-Location:/i)) {
                saveCurrentPageToHistory();
                var redirectPath = xhr.getResponseHeader("HX-Location");
                var swapSpec;
                if (redirectPath.indexOf("{") === 0) {
                    swapSpec = parseJSON(redirectPath);
                    // what's the best way to throw an error if the user didn't include this
                    redirectPath = swapSpec['path'];
                    delete swapSpec['path'];
                }
                ajaxHelper('GET', redirectPath, swapSpec).then(function(){
                    pushUrlIntoHistory(redirectPath);
                });
                return;
            }

            var shouldRefresh = hasHeader(xhr, /HX-Refresh:/i) && "true" === xhr.getResponseHeader("HX-Refresh");

            if (hasHeader(xhr, /HX-Redirect:/i)) {
                location.href = xhr.getResponseHeader("HX-Redirect");
                shouldRefresh && location.reload();
                return;
            }

            if (shouldRefresh) {
                location.reload();
                return;
            }

            if (hasHeader(xhr,/HX-Retarget:/i)) {
                if (xhr.getResponseHeader("HX-Retarget") === "this") {
                    responseInfo.target = elt;
                } else {
                    responseInfo.target = querySelectorExt(elt, xhr.getResponseHeader("HX-Retarget"));
                }
            }

            var historyUpdate = determineHistoryUpdates(elt, responseInfo);

            // by default htmx only swaps on 200 return codes and does not swap
            // on 204 'No Content'
            // this can be ovverriden by responding to the htmx:beforeSwap event and
            // overriding the detail.shouldSwap property
            var shouldSwap = xhr.status >= 200 && xhr.status < 400 && xhr.status !== 204;
            var serverResponse = xhr.response;
            var isError = xhr.status >= 400;
            var ignoreTitle = htmx.config.ignoreTitle
            var beforeSwapDetails = mergeObjects({shouldSwap: shouldSwap, serverResponse:serverResponse, isError:isError, ignoreTitle:ignoreTitle }, responseInfo);
            if (!triggerEvent(target, 'htmx:beforeSwap', beforeSwapDetails)) return;

            target = beforeSwapDetails.target; // allow re-targeting
            serverResponse = beforeSwapDetails.serverResponse; // allow updating content
            isError = beforeSwapDetails.isError; // allow updating error
            ignoreTitle = beforeSwapDetails.ignoreTitle; // allow updating ignoring title

            responseInfo.target = target; // Make updated target available to response events
            responseInfo.failed = isError; // Make failed property available to response events
            responseInfo.successful = !isError; // Make successful property available to response events

            if (beforeSwapDetails.shouldSwap) {
                if (xhr.status === 286) {
                    cancelPolling(elt);
                }

                withExtensions(elt, function (extension) {
                    serverResponse = extension.transformResponse(serverResponse, xhr, elt);
                });

                // Save current page if there will be a history update
                if (historyUpdate.type) {
                    saveCurrentPageToHistory();
                }

                var swapOverride = etc.swapOverride;
                if (hasHeader(xhr,/HX-Reswap:/i)) {
                    swapOverride = xhr.getResponseHeader("HX-Reswap");
                }
                var swapSpec = getSwapSpecification(elt, swapOverride);

                if (swapSpec.hasOwnProperty('ignoreTitle')) {
                    ignoreTitle = swapSpec.ignoreTitle;
                }

                target.classList.add(htmx.config.swappingClass);

                // optional transition API promise callbacks
                var settleResolve = null;
                var settleReject = null;

                var doSwap = function () {
                    try {
                        var activeElt = document.activeElement;
                        var selectionInfo = {};
                        try {
                            selectionInfo = {
                                elt: activeElt,
                                // @ts-ignore
                                start: activeElt ? activeElt.selectionStart : null,
                                // @ts-ignore
                                end: activeElt ? activeElt.selectionEnd : null
                            };
                        } catch (e) {
                            // safari issue - see https://github.com/microsoft/playwright/issues/5894
                        }

                        var selectOverride;
                        if (select) {
                            selectOverride = select;
                        }

                        if (hasHeader(xhr, /HX-Reselect:/i)) {
                            selectOverride = xhr.getResponseHeader("HX-Reselect");
                        }

                        // if we need to save history, do so, before swapping so that relative resources have the correct base URL
                        if (historyUpdate.type) {
                            triggerEvent(getDocument().body, 'htmx:beforeHistoryUpdate', mergeObjects({ history: historyUpdate }, responseInfo));
                            if (historyUpdate.type === "push") {
                                pushUrlIntoHistory(historyUpdate.path);
                                triggerEvent(getDocument().body, 'htmx:pushedIntoHistory', {path: historyUpdate.path});
                            } else {
                                replaceUrlInHistory(historyUpdate.path);
                                triggerEvent(getDocument().body, 'htmx:replacedInHistory', {path: historyUpdate.path});
                            }
                        }

                        var settleInfo = makeSettleInfo(target);
                        selectAndSwap(swapSpec.swapStyle, target, elt, serverResponse, settleInfo, selectOverride);

                        if (selectionInfo.elt &&
                            !bodyContains(selectionInfo.elt) &&
                            getRawAttribute(selectionInfo.elt, "id")) {
                            var newActiveElt = document.getElementById(getRawAttribute(selectionInfo.elt, "id"));
                            var focusOptions = { preventScroll: swapSpec.focusScroll !== undefined ? !swapSpec.focusScroll : !htmx.config.defaultFocusScroll };
                            if (newActiveElt) {
                                // @ts-ignore
                                if (selectionInfo.start && newActiveElt.setSelectionRange) {
                                    // @ts-ignore
                                    try {
                                        newActiveElt.setSelectionRange(selectionInfo.start, selectionInfo.end);
                                    } catch (e) {
                                        // the setSelectionRange method is present on fields that don't support it, so just let this fail
                                    }
                                }
                                newActiveElt.focus(focusOptions);
                            }
                        }

                        target.classList.remove(htmx.config.swappingClass);
                        forEach(settleInfo.elts, function (elt) {
                            if (elt.classList) {
                                elt.classList.add(htmx.config.settlingClass);
                            }
                            triggerEvent(elt, 'htmx:afterSwap', responseInfo);
                        });

                        if (hasHeader(xhr, /HX-Trigger-After-Swap:/i)) {
                            var finalElt = elt;
                            if (!bodyContains(elt)) {
                                finalElt = getDocument().body;
                            }
                            handleTrigger(xhr, "HX-Trigger-After-Swap", finalElt);
                        }

                        var doSettle = function () {
                            forEach(settleInfo.tasks, function (task) {
                                task.call();
                            });
                            forEach(settleInfo.elts, function (elt) {
                                if (elt.classList) {
                                    elt.classList.remove(htmx.config.settlingClass);
                                }
                                triggerEvent(elt, 'htmx:afterSettle', responseInfo);
                            });

                            if (responseInfo.pathInfo.anchor) {
                                var anchorTarget = getDocument().getElementById(responseInfo.pathInfo.anchor);
                                if(anchorTarget) {
                                    anchorTarget.scrollIntoView({block:'start', behavior: "auto"});
                                }
                            }

                            if(settleInfo.title && !ignoreTitle) {
                                var titleElt = find("title");
                                if(titleElt) {
                                    titleElt.innerHTML = settleInfo.title;
                                } else {
                                    window.document.title = settleInfo.title;
                                }
                            }

                            updateScrollState(settleInfo.elts, swapSpec);

                            if (hasHeader(xhr, /HX-Trigger-After-Settle:/i)) {
                                var finalElt = elt;
                                if (!bodyContains(elt)) {
                                    finalElt = getDocument().body;
                                }
                                handleTrigger(xhr, "HX-Trigger-After-Settle", finalElt);
                            }
                            maybeCall(settleResolve);
                        }

                        if (swapSpec.settleDelay > 0) {
                            setTimeout(doSettle, swapSpec.settleDelay)
                        } else {
                            doSettle();
                        }
                    } catch (e) {
                        triggerErrorEvent(elt, 'htmx:swapError', responseInfo);
                        maybeCall(settleReject);
                        throw e;
                    }
                };

                var shouldTransition = htmx.config.globalViewTransitions
                if(swapSpec.hasOwnProperty('transition')){
                    shouldTransition = swapSpec.transition;
                }

                if(shouldTransition &&
                    triggerEvent(elt, 'htmx:beforeTransition', responseInfo) &&
                    typeof Promise !== "undefined" && document.startViewTransition){
                    var settlePromise = new Promise(function (_resolve, _reject) {
                        settleResolve = _resolve;
                        settleReject = _reject;
                    });
                    // wrap the original doSwap() in a call to startViewTransition()
                    var innerDoSwap = doSwap;
                    doSwap = function() {
                        document.startViewTransition(function () {
                            innerDoSwap();
                            return settlePromise;
                        });
                    }
                }


                if (swapSpec.swapDelay > 0) {
                    setTimeout(doSwap, swapSpec.swapDelay)
                } else {
                    doSwap();
                }
            }
            if (isError) {
                triggerErrorEvent(elt, 'htmx:responseError', mergeObjects({error: "Response Status Error Code " + xhr.status + " from " + responseInfo.pathInfo.requestPath}, responseInfo));
            }
        }

        //====================================================================
        // Extensions API
        //====================================================================

        /** @type {Object<string, import("./htmx").HtmxExtension>} */
        var extensions = {};

        /**
         * extensionBase defines the default functions for all extensions.
         * @returns {import("./htmx").HtmxExtension}
         */
        function extensionBase() {
            return {
                init: function(api) {return null;},
                onEvent : function(name, evt) {return true;},
                transformResponse : function(text, xhr, elt) {return text;},
                isInlineSwap : function(swapStyle) {return false;},
                handleSwap : function(swapStyle, target, fragment, settleInfo) {return false;},
                encodeParameters : function(xhr, parameters, elt) {return null;}
            }
        }

        /**
         * defineExtension initializes the extension and adds it to the htmx registry
         *
         * @param {string} name
         * @param {import("./htmx").HtmxExtension} extension
         */
        function defineExtension(name, extension) {
            if(extension.init) {
                extension.init(internalAPI)
            }
            extensions[name] = mergeObjects(extensionBase(), extension);
        }

        /**
         * removeExtension removes an extension from the htmx registry
         *
         * @param {string} name
         */
        function removeExtension(name) {
            delete extensions[name];
        }

        /**
         * getExtensions searches up the DOM tree to return all extensions that can be applied to a given element
         *
         * @param {HTMLElement} elt
         * @param {import("./htmx").HtmxExtension[]=} extensionsToReturn
         * @param {import("./htmx").HtmxExtension[]=} extensionsToIgnore
         */
         function getExtensions(elt, extensionsToReturn, extensionsToIgnore) {

            if (elt == undefined) {
                return extensionsToReturn;
            }
            if (extensionsToReturn == undefined) {
                extensionsToReturn = [];
            }
            if (extensionsToIgnore == undefined) {
                extensionsToIgnore = [];
            }
            var extensionsForElement = getAttributeValue(elt, "hx-ext");
            if (extensionsForElement) {
                forEach(extensionsForElement.split(","), function(extensionName){
                    extensionName = extensionName.replace(/ /g, '');
                    if (extensionName.slice(0, 7) == "ignore:") {
                        extensionsToIgnore.push(extensionName.slice(7));
                        return;
                    }
                    if (extensionsToIgnore.indexOf(extensionName) < 0) {
                        var extension = extensions[extensionName];
                        if (extension && extensionsToReturn.indexOf(extension) < 0) {
                            extensionsToReturn.push(extension);
                        }
                    }
                });
            }
            return getExtensions(parentElt(elt), extensionsToReturn, extensionsToIgnore);
        }

        //====================================================================
        // Initialization
        //====================================================================
        var isReady = false
        getDocument().addEventListener('DOMContentLoaded', function() {
            isReady = true
        })

        /**
         * Execute a function now if DOMContentLoaded has fired, otherwise listen for it.
         *
         * This function uses isReady because there is no realiable way to ask the browswer whether
         * the DOMContentLoaded event has already been fired; there's a gap between DOMContentLoaded
         * firing and readystate=complete.
         */
        function ready(fn) {
            // Checking readyState here is a failsafe in case the htmx script tag entered the DOM by
            // some means other than the initial page load.
            if (isReady || getDocument().readyState === 'complete') {
                fn();
            } else {
                getDocument().addEventListener('DOMContentLoaded', fn);
            }
        }

        function insertIndicatorStyles() {
            if (htmx.config.includeIndicatorStyles !== false) {
                getDocument().head.insertAdjacentHTML("beforeend",
                    "<style>\
                      ." + htmx.config.indicatorClass + "{opacity:0}\
                      ." + htmx.config.requestClass + " ." + htmx.config.indicatorClass + "{opacity:1; transition: opacity 200ms ease-in;}\
                      ." + htmx.config.requestClass + "." + htmx.config.indicatorClass + "{opacity:1; transition: opacity 200ms ease-in;}\
                    </style>");
            }
        }

        function getMetaConfig() {
            var element = getDocument().querySelector('meta[name="htmx-config"]');
            if (element) {
                // @ts-ignore
                return parseJSON(element.content);
            } else {
                return null;
            }
        }

        function mergeMetaConfig() {
            var metaConfig = getMetaConfig();
            if (metaConfig) {
                htmx.config = mergeObjects(htmx.config , metaConfig)
            }
        }

        // initialize the document
        ready(function () {
            mergeMetaConfig();
            insertIndicatorStyles();
            var body = getDocument().body;
            processNode(body);
            var restoredElts = getDocument().querySelectorAll(
                "[hx-trigger='restored'],[data-hx-trigger='restored']"
            );
            body.addEventListener("htmx:abort", function (evt) {
                var target = evt.target;
                var internalData = getInternalData(target);
                if (internalData && internalData.xhr) {
                    internalData.xhr.abort();
                }
            });
            /** @type {(ev: PopStateEvent) => any} */
            const originalPopstate = window.onpopstate ? window.onpopstate.bind(window) : null;
            /** @type {(ev: PopStateEvent) => any} */
            window.onpopstate = function (event) {
                if (event.state && event.state.htmx) {
                    restoreHistory();
                    forEach(restoredElts, function(elt){
                        triggerEvent(elt, 'htmx:restored', {
                            'document': getDocument(),
                            'triggerEvent': triggerEvent
                        });
                    });
                } else {
                    if (originalPopstate) {
                        originalPopstate(event);
                    }
                }
            };
            setTimeout(function () {
                triggerEvent(body, 'htmx:load', {}); // give ready handlers a chance to load up before firing this event
                body = null; // kill reference for gc
            }, 0);
        })

        return htmx;
    }
)()
}));
FLASK_SCAFFOLD_FILE_0029
truncate -s 162033 'static/js/htmx.js'

cat > 'static/js/script.js' <<'FLASK_SCAFFOLD_FILE_0030'

FLASK_SCAFFOLD_FILE_0030
truncate -s 0 'static/js/script.js'

cat > 'templates/about.html' <<'FLASK_SCAFFOLD_FILE_0031'

{% extends 'shared/layout.html'%}

{% block content %}

<h1 class="text-2xl">About Page</h1>


{% endblock%}

FLASK_SCAFFOLD_FILE_0031

cat > 'templates/admin.html' <<'FLASK_SCAFFOLD_FILE_0032'
{% extends 'shared/layout.html'%}

{% block content %}

<div id="music" class="mt-4 col-span-5 empty rounded-lg border border-gray-300 shadow-md">
    <div class="hidden text-xs py-2 px-4 w-full border-b" placeholder="Enter your name">
        <ul class="flex justify-start gap-4 flex-wrap items-center">
            <li>
                <a class="font-bold">Admin</a>
            </li>
            <li>
                <a>File</a>
            </li>
            <li>
                <a>Edit</a>
            </li>
            <li>
                <a>View</a>
            </li>
            <li>
                <a>Account</a>
            </li>
        </ul>
    </div>


    <div class="flex justify-start gap-x-6 p-8">
        <aside id="sidenav" class="w-1/5">

            <div class="grid gap-y-4">
                {%set navbaritems = ['users','items','photos','videos'] %}


                {%for item in navbaritems%}
                <div
                    class="{{ 'bg-gray-100' if active_tab==item else '' }} p-2 rounded-md flex justify-start items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-inbox" viewBox="0 0 16 16">
                        <path
                            d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z">
                        </path>
                    </svg>
                    <div class="ml-3 col-span-10">
                        <a class="text-xs capitalize" href="/admin/{{item}}" hx-get="/admin/{{item}}"
                            hx-target="#main-content" hx-push-url="true">{{item}}</a>
                    </div>
                    <div class="ml-auto text-xs">
                        <p>128</p>
                    </div>
                </div>
                {%endfor%}
                <hr>

                {%for item in navbaritems%}
                <div
                    class="{{ 'bg-gray-100' if active_tab==item else '' }} p-2 rounded-md flex justify-start items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-inbox" viewBox="0 0 16 16">
                        <path
                            d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z">
                        </path>
                    </svg>
                    <div class="ml-3 col-span-10">
                        <a class="text-xs capitalize" href="/admin/{{item}}" hx-get="/admin/{{item}}"
                            hx-target="#main-content" hx-push-url="true">{{item}}</a>
                    </div>
                    <div class="ml-auto text-xs">
                        <p>128</p>
                    </div>
                </div>
                {%endfor%}
                <div>
                    <button class="text-center text-xs border border-gray-300 px-4 py-2 rounded-lg w-full">Save
                        Preferences</button>
                </div>
            </div>
        </aside>
        <div id="table" class="w-3/5">

            <main id="main-content">
                {% if active_tab == 'items' %}
                {% include 'partials/_items_content.html' %}
                {% else %}
                {% include 'partials/_users_content.html' %}
                {% endif %}
            </main>

        </div>

        <aside id="sidenav" class="w-1/5">

            <div id="user-box" class="p-4 rounded-lg border border-gray-200">

                <p class="text-xs font-light font-semibold">Create User</p>
                <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>

                <div class="mt-4 grid gap-y-4">
                    {% set names= ['email','first_name','last_name','password','profile_img','phone','address']%}

                    {%for name in names%}
                    <div>
                        <p class="text-xs capitalize">{{name | labelize}}</p>
                        <p class="text-gray-500" style="font-size: .60rem">Descriptive text about this specific field
                        </p>
                        <input name="{{name}}" id="{{name}}"
                            class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                            placeholder="Enter your name">
                    </div>
                    {%endfor%}

                    {%for i in range(3)%}
                    <div class="flex justify-between items-center">
                        <div class="col-span-10">
                            <p class="text-xs"></p>
                            <p class="text-gray-500" style="font-size: .60rem">These cookies are essentil in order to
                                use the website and
                                it's features</p>
                        </div>
                        <div class="ml-4">
                            <button type="button" role="switch" aria-checked="true" data-state="checked" value="on"
                                class="peer inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed bg-black disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input"
                                id="necessary" aria-label="Necessary"><span data-state="checked"
                                    class="pointer-events-none block h-4 w-4 rounded-full bg-white shadow-lg ring-0 transition-transform data-[state=checked]:translate-x-4 data-[state=unchecked]:translate-x-0"></span></button>
                        </div>
                    </div>
                    {%endfor%}

                    <div>
                        <button
                            class="text-center text-xs border border-gray-300 px-4 py-2 rounded-lg w-full">Create</button>
                    </div>
                </div>
            </div>
        </aside>
    </div>
</div>


{% endblock%}
FLASK_SCAFFOLD_FILE_0032
truncate -s 6932 'templates/admin.html'

cat > 'templates/auth/login.html' <<'FLASK_SCAFFOLD_FILE_0033'

{%extends 'shared/layout.html'%}

{%block content%}

<section class="flex flex-col md:flex-row h-screen items-center">

    <div class="bg-indigo-600 hidden lg:block w-full md:w-1/2 xl:w-2/3 h-screen">

      <img src="https://images.prismic.io/upskil/ZrvZvEaF0TcGI6NT_55f5c200-1c67-4df3-89f2-82f5a25913f1.webp?auto=format,compress" alt="" class="w-full h-full object-cover">

    </div>

    <div class="bg-white w-full md:max-w-md lg:max-w-full md:mx-auto md:mx-0 md:w-1/2 xl:w-1/3 h-screen px-6 lg:px-16 xl:px-12

          flex items-center justify-center">

      <div class="w-full h-100 p-4">

        <h1 class="text-xl md:text-2xl font-bold leading-tight mt-12">Log in to your account</h1>

        {{message}}

        <form class="mt-6" action="{{url_for('auth.login')}}" method="POST">

          <div>

            <label class="block text-gray-700">Email Address</label>

            <input type="email" name="email" id="email" placeholder="Enter Email Address" class="w-full px-4 py-3 rounded-lg bg-gray-200 mt-2 border focus:border-blue-500 focus:bg-white focus:outline-none" autofocus autocomplete required>

          </div>

          <div class="mt-4">

            <label class="block text-gray-700">Password</label>

            <input type="password" name="password" id="password" placeholder="Enter Password" minlength="6" class="w-full px-4 py-3 rounded-lg bg-gray-200 mt-2 border focus:border-blue-500

                  focus:bg-white focus:outline-none" required>

          </div>

          <div class="text-right mt-2">

            <a href="#" class="text-sm font-semibold text-gray-700 hover:text-blue-700 focus:text-blue-700">Forgot Password?</a>

          </div>

          <button type="submit" class="w-full block bg-indigo-500 hover:bg-indigo-400 focus:bg-indigo-400 text-white font-semibold rounded-lg

                px-4 py-3 mt-6">Log In</button>

        </form>

        <hr class="my-6 border-gray-300 w-full">

        <button type="button" class="w-full block bg-white hover:bg-gray-100 focus:bg-gray-100 text-gray-900 font-semibold rounded-lg px-4 py-3 border border-gray-300">

              <div class="flex items-center justify-center">

              <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" class="w-6 h-6" viewBox="0 0 48 48"><defs><path id="a" d="M44.5 20H24v8.5h11.8C34.7 33.9 30.1 37 24 37c-7.2 0-13-5.8-13-13s5.8-13 13-13c3.1 0 5.9 1.1 8.1 2.9l6.4-6.4C34.6 4.1 29.6 2 24 2 11.8 2 2 11.8 2 24s9.8 22 22 22c11 0 21-8 21-22 0-1.3-.2-2.7-.5-4z"/></defs><clipPath id="b"><use xlink:href="#a" overflow="visible"/></clipPath><path clip-path="url(#b)" fill="#FBBC05" d="M0 37V11l17 13z"/><path clip-path="url(#b)" fill="#EA4335" d="M0 11l17 13 7-6.1L48 14V0H0z"/><path clip-path="url(#b)" fill="#34A853" d="M0 37l30-23 7.9 1L48 0v48H0z"/><path clip-path="url(#b)" fill="#4285F4" d="M48 48L17 24l-4-3 35-10z"/></svg>

              <span class="ml-4">

              Log in

              with

              Google</span>

              </div>

            </button>

        <p class="mt-8">Need an account? <a href="/auth/register" class="text-blue-500 hover:text-blue-700 font-semibold">Create an

                account</a></p>

      </div>

    </div>

  </section>

  {%endblock%}

FLASK_SCAFFOLD_FILE_0033

cat > 'templates/auth/register.html' <<'FLASK_SCAFFOLD_FILE_0034'

{%extends 'shared/layout.html'%}

{%block content%}

<section class="flex flex-col md:flex-row h-screen items-center">

    <div class="bg-indigo-600 hidden lg:block w-full md:w-1/2 xl:w-2/3 h-screen">

      <img src="https://image.civitai.com/xG1nkqKTMzGDvpLrqFT7WA/8014a2d3-f1ca-460c-a46e-f485fe93bf35/original=true/000431001-Krea2_Turbo_fp8mixed.jpeg"  alt="" class="w-full h-full object-cover">

    </div>

    <div class="bg-white w-full md:max-w-md lg:max-w-full md:mx-auto md:mx-0 md:w-1/2 xl:w-1/3 h-screen px-6 lg:px-16 xl:px-12

          flex items-center justify-center">

      <div class="w-full h-100  p-4">

        <h1 class="text-xl md:text-2xl font-bold leading-tight mt-12">Register for an account</h1>

        <form class="mt-6" action="{{url_for('auth.register')}}" method="POST">

            <div>

                <label class="block text-gray-700">First Name</label>

                <input type="text" name="first_name" id="first_name" placeholder="John" class="w-full px-4 py-3 rounded-lg bg-gray-200 mt-2 border focus:border-blue-500 focus:bg-white focus:outline-none" autofocus autocomplete required>

              </div>

            <div>

                <label class="block text-gray-700">Last name</label>

                <input type="text" name="last_name" id="last_name" placeholder="Clark" class="w-full px-4 py-3 rounded-lg bg-gray-200 mt-2 border focus:border-blue-500 focus:bg-white focus:outline-none" autofocus autocomplete required>

            </div>

          <div>

            <label class="block text-gray-700">Email Address</label>

            <input type="email" name="email" id="email" placeholder="Enter Email Address" class="w-full px-4 py-3 rounded-lg bg-gray-200 mt-2 border focus:border-blue-500 focus:bg-white focus:outline-none" autofocus autocomplete required>

          </div>

          <div class="mt-4">

            <label class="block text-gray-700">Password</label>

            <input type="password" name="password" id="password" placeholder="Enter Password" minlength="6" class="w-full px-4 py-3 rounded-lg bg-gray-200 mt-2 border focus:border-blue-500

                  focus:bg-white focus:outline-none" required>

          </div>

          <div class="text-right mt-2">

            <a href="#" class="text-sm font-semibold text-gray-700 hover:text-blue-700 focus:text-blue-700">Forgot Password?</a>

          </div>

          <button type="submit" class="w-full block bg-indigo-500 hover:bg-indigo-400 focus:bg-indigo-400 text-white font-semibold rounded-lg

                px-4 py-3 mt-6">Log In</button>

        </form>

        <hr class="my-6 border-gray-300 w-full">

        <button type="button" class="w-full block bg-white hover:bg-gray-100 focus:bg-gray-100 text-gray-900 font-semibold rounded-lg px-4 py-3 border border-gray-300">

              <div class="flex items-center justify-center">

              <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" class="w-6 h-6" viewBox="0 0 48 48"><defs><path id="a" d="M44.5 20H24v8.5h11.8C34.7 33.9 30.1 37 24 37c-7.2 0-13-5.8-13-13s5.8-13 13-13c3.1 0 5.9 1.1 8.1 2.9l6.4-6.4C34.6 4.1 29.6 2 24 2 11.8 2 2 11.8 2 24s9.8 22 22 22c11 0 21-8 21-22 0-1.3-.2-2.7-.5-4z"/></defs><clipPath id="b"><use xlink:href="#a" overflow="visible"/></clipPath><path clip-path="url(#b)" fill="#FBBC05" d="M0 37V11l17 13z"/><path clip-path="url(#b)" fill="#EA4335" d="M0 11l17 13 7-6.1L48 14V0H0z"/><path clip-path="url(#b)" fill="#34A853" d="M0 37l30-23 7.9 1L48 0v48H0z"/><path clip-path="url(#b)" fill="#4285F4" d="M48 48L17 24l-4-3 35-10z"/></svg>

              <span class="ml-4">

              Log in

              with

              Google</span>

              </div>

            </button>

        <p class="mt-8">Already have an account? <a href="/auth/login" class="text-blue-500 hover:text-blue-700 font-semibold">Login to your

                account</a></p>

      </div>

    </div>

  </section>

  {%endblock%}

FLASK_SCAFFOLD_FILE_0034

cat > 'templates/components/_flash.html' <<'FLASK_SCAFFOLD_FILE_0035'

FLASK_SCAFFOLD_FILE_0035
truncate -s 0 'templates/components/_flash.html'

cat > 'templates/components/_footer.html' <<'FLASK_SCAFFOLD_FILE_0036'

FLASK_SCAFFOLD_FILE_0036
truncate -s 0 'templates/components/_footer.html'

cat > 'templates/components/_hero.html' <<'FLASK_SCAFFOLD_FILE_0037'

FLASK_SCAFFOLD_FILE_0037
truncate -s 0 'templates/components/_hero.html'

cat > 'templates/components/_nav.html' <<'FLASK_SCAFFOLD_FILE_0038'

FLASK_SCAFFOLD_FILE_0038
truncate -s 0 'templates/components/_nav.html'

cat > 'templates/components/_sidebar.html' <<'FLASK_SCAFFOLD_FILE_0039'

FLASK_SCAFFOLD_FILE_0039
truncate -s 0 'templates/components/_sidebar.html'

cat > 'templates/components/master_components.html' <<'FLASK_SCAFFOLD_FILE_0040'
{% extends 'shared/layout.html'%}

{% block content %}
<body>
    <div id="app" class="relative">

        <div class="grid gap-4 grid-cols-4 p-8">

            <div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
                
                <p class="text-xs">Backlog</p>

                <button class="rounded-md mt-4 p-1 w-full bg-white outline-dashed outline-1 outline-gray-300">
+
                </button>

                <div v-for="i in ['Research','Wireframing']" class="mt-4 bg-white p-4 rounded-md shadow">
                    

                    <span class="px-3 py-2 text-xs rounded-full bg-gray-100 text-gray-600">{{i}}</span>

                    <div class="mt-4 border-b pb-2">
                        <p class="text-sm">Meeting with the Client</p>
                        <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
                        <a class="my-2 p-3 rounded-lg text-xs flex items-top bg-gray-100">
                            <img class="max-w-8 rounded-lg object-contain" src="https://upskil.dev/commerce.png"/>
                            <div class="ml-3">
                                <p class="text-gray-700 font-semibold">Website URL</p>
                                <p style="font-size: .70rem" class="text-gray-400">www.upskil.dev</p>
                            </div>
                        </a>
                    </div>

                    <ul class="mt-4 space-y-2">
                        <li v-for="i in ['Slicing Design to Code','Responsive','Create animation with CSS','Ajax CRUD']" class="items-center flex justify-between">
                            <p style="font-size: .70rem" class="text-gray-500">{{i}}</p>
                            <input class="accent-black" type="checkbox"/>
                        </li>
                    </ul>

                    <button class="mt-4 text-center text-xs text-black rounded-lg w-auto">+ Create
                        Account</button>

                    <div class="mt-3 flex items-center justify-between">
                        <div class="flex">
                        <img v-for="i in ['https://images.prismic.io/upskil/ZrvRh0aF0TcGI6Kq_valley.webp?auto=format,compress','https://images.prismic.io/upskil/ZrudT0aF0TcGI52W_20e6082b-ccd3-4170-9d55-d57591c3b4ca.webp?auto=format,compress','https://images.prismic.io/upskil/ZrvZvEaF0TcGI6NT_55f5c200-1c67-4df3-89f2-82f5a25913f1.webp?auto=format,compress']" class="border-white border-2 -mr-2 w-8 h-8 object-cover object-top rounded-full" :src="i"/>
                        </div>

                        <div class="flex text-xs text-gray-400">
                        <div>
                            32
                        </div>

                        <div class="ml-2">
                            32
                        </div>
                        </div>
                    </div>

                </div>
            </div>

            <div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
                
                <p class="text-xs">Backlog</p>

                <button class="rounded-md mt-4 p-1 w-full bg-white outline-dashed outline-1 outline-gray-300">
+
                </button>

                <div v-for="i in ['Research','Wireframing']" class="mt-4 bg-white p-4 rounded-md shadow">
                    

                    <span class="px-3 py-2 text-xs rounded-full bg-gray-100 text-gray-600">{{i}}</span>

                    <div class="mt-4 border-b pb-2">
                        <p class="text-sm">Meeting with the Client</p>
                        <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
                        <a class="my-2 p-3 rounded-lg text-xs flex items-top bg-gray-100">
                            <img class="max-w-8 rounded-lg object-contain" src="https://upskil.dev/commerce.png"/>
                            <div class="ml-3">
                                <p class="text-gray-700 font-semibold">Website URL</p>
                                <p style="font-size: .70rem" class="text-gray-400">www.upskil.dev</p>
                            </div>
                        </a>
                    </div>

                    <ul class="mt-4 space-y-2">
                        <li v-for="i in ['Slicing Design to Code','Responsive','Create animation with CSS','Ajax CRUD']" class="items-center flex justify-between">
                            <p style="font-size: .70rem" class="text-gray-500">{{i}}</p>
                            <input class="accent-black" type="checkbox"/>
                        </li>
                    </ul>

                    <button class="mt-4 text-center text-xs text-black rounded-lg w-auto">+ Create
                        Account</button>

                    <div class="mt-3 flex items-center justify-between">
                        <div class="flex">
                        <img v-for="i in ['https://images.prismic.io/upskil/ZrvRh0aF0TcGI6Kq_valley.webp?auto=format,compress','https://images.prismic.io/upskil/ZrudT0aF0TcGI52W_20e6082b-ccd3-4170-9d55-d57591c3b4ca.webp?auto=format,compress','https://images.prismic.io/upskil/ZrvZvEaF0TcGI6NT_55f5c200-1c67-4df3-89f2-82f5a25913f1.webp?auto=format,compress']" class="border-white border-2 -mr-2 w-8 h-8 object-cover object-top rounded-full" :src="i"/>
                        </div>

                        <div class="flex text-xs text-gray-400">
                        <div>
                            32
                        </div>

                        <div class="ml-2">
                            32
                        </div>
                        </div>
                    </div>

                </div>
            </div>

            
<div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
     <div id="photo-card" class="p-4 rounded-lg border border-gray-300 shadow-md">
                    <img class="rounded-md" src="https://www.careersinfilm.com/wp-content/uploads/2019/05/wide-shot-days-of-heaven.jpg"/>
                    <div class="mt-3 rounded-lg text-xs  flex gap-x-2 items-center justify-between">
                        <button
                            class="shadow-sm p-1 w-1/2 bg-white rounded-md" role="tab">Primary</button><button
                            class="p-1 w-1/2 text-gray-500 rounded-md" role="tab">Secondary</button></div>
                </div>
</div>
<div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
       <button class="text-xs text-gray-500 rounded-md p-4 w-full bg-white outline-dashed outline-1 outline-gray-300"> Upload Photos/Videos </button>
</div>

<div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
    <div id="prompt-box" class="rounded-lg border border-gray-300 shadow-md p-2">
                    <textarea rows="9" class="p-3 text-xs border border-gray-300 rounded-lg w-full"
                        placeholder="Prompt"></textarea>
                </div>

</div>

<div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
    
  <select class="mt-4 p-2 w-full border appearance-none bg-gray-50 dark:bg-gray-800 ...">
    <option disabled selected>Pick an option</option>

    <option>Yes</option>
    <option>No</option>
    <option>Maybe</option>
  </select>


</div>

            <div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
                
                <p class="text-xs">Backlog</p>

                <button class="rounded-md mt-4 p-1 w-full bg-white outline-dashed outline-1 outline-gray-300">
+
                </button>

                <div v-for="i in ['Research','Wireframing']" class="mt-4 bg-white p-4 rounded-md shadow">
                    

                    <span class="px-3 py-2 text-xs rounded-full bg-gray-100 text-gray-600">{{i}}</span>

                    <div class="mt-4 border-b pb-2">
                        <p class="text-sm">Meeting with the Client</p>
                        <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
                        <a class="my-2 p-3 rounded-lg text-xs flex items-top bg-gray-100">
                            <img class="max-w-8 rounded-lg object-contain" src="https://upskil.dev/commerce.png"/>
                            <div class="ml-3">
                                <p class="text-gray-700 font-semibold">Website URL</p>
                                <p style="font-size: .70rem" class="text-gray-400">www.upskil.dev</p>
                            </div>
                        </a>
                    </div>

                    <ul class="mt-4 space-y-2">
                        <li v-for="i in ['Slicing Design to Code','Responsive','Create animation with CSS','Ajax CRUD']" class="items-center flex justify-between">
                            <p style="font-size: .70rem" class="text-gray-500">{{i}}</p>
                            <input class="accent-black" type="checkbox"/>
                        </li>
                    </ul>

                    <button class="mt-4 text-center text-xs text-black rounded-lg w-auto">+ Create
                        Account</button>

                    <div class="mt-3 flex items-center justify-between">
                        <div class="flex">
                        <img v-for="i in ['https://images.prismic.io/upskil/ZrvRh0aF0TcGI6Kq_valley.webp?auto=format,compress','https://images.prismic.io/upskil/ZrudT0aF0TcGI52W_20e6082b-ccd3-4170-9d55-d57591c3b4ca.webp?auto=format,compress','https://images.prismic.io/upskil/ZrvZvEaF0TcGI6NT_55f5c200-1c67-4df3-89f2-82f5a25913f1.webp?auto=format,compress']" class="border-white border-2 -mr-2 w-8 h-8 object-cover object-top rounded-full" :src="i"/>
                        </div>

                        <div class="flex text-xs text-gray-400">
                        <div>
                            32
                        </div>

                        <div class="ml-2">
                            32
                        </div>
                        </div>
                    </div>

                </div>
            </div>

            <div class="empty p-4 bg-gray-50 rounded-lg border border-gray-300 shadow-md">
                
                <p class="text-xs">Backlog</p>

                <button class="rounded-md mt-4 p-1 w-full bg-white outline-dashed outline-1 outline-gray-300">
+
                </button>

                <div v-for="i in ['Research','Wireframing']" class="mt-4 bg-white p-4 rounded-md shadow">
                    

                    <span class="px-3 py-2 text-xs rounded-full bg-gray-100 text-gray-600">{{i}}</span>

                    <div class="mt-4 border-b pb-2">
                        <p class="text-sm">Meeting with the Client</p>
                        <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
                        <a class="my-2 p-3 rounded-lg text-xs flex items-top bg-gray-100">
                            <img class="max-w-8 rounded-lg object-contain" src="https://upskil.dev/commerce.png"/>
                            <div class="ml-3">
                                <p class="text-gray-700 font-semibold">Website URL</p>
                                <p style="font-size: .70rem" class="text-gray-400">www.upskil.dev</p>
                            </div>
                        </a>
                    </div>

                    <ul class="mt-4 space-y-2">
                        <li v-for="i in ['Slicing Design to Code','Responsive','Create animation with CSS','Ajax CRUD']" class="items-center flex justify-between">
                            <p style="font-size: .70rem" class="text-gray-500">{{i}}</p>
                            <input class="accent-black" type="checkbox"/>
                        </li>
                    </ul>

                    <button class="mt-4 text-center text-xs text-black rounded-lg w-auto">+ Create
                        Account</button>

                    <div class="mt-3 flex items-center justify-between">
                        <div class="flex">
                        <img v-for="i in ['https://images.prismic.io/upskil/ZrvRh0aF0TcGI6Kq_valley.webp?auto=format,compress','https://images.prismic.io/upskil/ZrudT0aF0TcGI52W_20e6082b-ccd3-4170-9d55-d57591c3b4ca.webp?auto=format,compress','https://images.prismic.io/upskil/ZrvZvEaF0TcGI6NT_55f5c200-1c67-4df3-89f2-82f5a25913f1.webp?auto=format,compress']" class="border-white border-2 -mr-2 w-8 h-8 object-cover object-top rounded-full" :src="i"/>
                        </div>

                        <div class="flex text-xs text-gray-400">
                        <div>
                            32
                        </div>

                        <div class="ml-2">
                            32
                        </div>
                        </div>
                    </div>

                </div>
            </div>

            <div class="empty p-4 rounded-lg border border-gray-300 shadow-md">
                <nav class="text-gray-400 empty p-4 rounded-lg border border-gray-300 shadow-md">
                    <ul class="items-center flex gap-2 flex-wrap">
                    <li class="flex items-ceter">
                        <button>
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-table" viewBox="0 0 16 16">
                                <path d="M0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2zm15 2h-4v3h4zm0 4h-4v3h4zm0 4h-4v3h3a1 1 0 0 0 1-1zm-5 3v-3H6v3zm-5 0v-3H1v2a1 1 0 0 0 1 1zm-4-4h4V8H1zm0-4h4V4H1zm5-3v3h4V4zm4 4H6v3h4z"/>
                              </svg>
                        </button>
                        <span style="font-size: .70rem" class="ml-1 text-xs">Table</span>
                    </li>

                    <li class="flex items-ceter">
                        <button>
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-kanban" viewBox="0 0 16 16">
                                <path d="M13.5 1a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1h-11a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1zm-11-1a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2z"/>
                                <path d="M6.5 3a1 1 0 0 1 1-1h1a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-1a1 1 0 0 1-1-1zm-4 0a1 1 0 0 1 1-1h1a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1h-1a1 1 0 0 1-1-1zm8 0a1 1 0 0 1 1-1h1a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1h-1a1 1 0 0 1-1-1z"/>
                              </svg>
                        </button>
                        <span style="font-size: .70rem" class="ml-1 text-xs">KanBan</span>
                    </li>

                    <li class="flex items-ceter">
                        <button>
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-calendar2-event" viewBox="0 0 16 16">
                                <path d="M11 7.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5z"/>
                                <path d="M3.5 0a.5.5 0 0 1 .5.5V1h8V.5a.5.5 0 0 1 1 0V1h1a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2h1V.5a.5.5 0 0 1 .5-.5M2 2a1 1 0 0 0-1 1v11a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1z"/>
                                <path d="M2.5 4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5z"/>
                              </svg>
                            </button>
                        <span style="font-size: .70rem" class="ml-1 text-xs">Calendar</span>
                    </li>
                    </ul>
                </nav>
                
            </div>


            <div class="hidden p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="flex justify-between">
                <div class="rounded-lg text-xs bg-gray-200 p-1 flex gap-x-2 items-center justify-between">
                    <button class="shadow-sm px-2 p-1 bg-white rounded-md" role="tab">Scripture</button>
                    <button class="px-2 p-1 text-gray-500 rounded-md" role="tab">Notes</button>
                </div>
                <button class="ml-auto text-center text-xs bg-black text-white px-4 py-2 rounded-lg">New Note</button>
                </div>

                <input class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                            placeholder="ex: 'g 1 1-5' or 'darkness'">

                            <aside id="scrollview" class="mt-2">
                                <div class="example mt-4 gap-y-2 overflow-y-scroll">
                                    <div class="flex justify-start items-center">
                                        <p class="text-xl font-light font-semibold ">Genesis</p>
                                        <button class="mr-4 ml-auto text-center text-xs bg-black text-white px-4 py-2 rounded-lg">Select All</button>
                                        <button class="text-center text-xs h-8 w-8 justify-center bg-black text-white p-2 flex items-center py-2 rounded-lg">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right-square-fill" viewBox="0 0 16 16">
                                                <path d="M0 14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2a2 2 0 0 0-2 2zm4.5-6.5h5.793L8.146 5.354a.5.5 0 1 1 .708-.708l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L10.293 8.5H4.5a.5.5 0 0 1 0-1"/>
                                              </svg>
                                        </button>
                                    </div>
                                    <div v-for="note in ['Chapter 1','Chapter 2','Chapter 3','Chapter 4']" class="relative mt-2 font-light space-y-2">
                                        <div class="border p-4 rounded-md shadow-sm hover:bg-gray-100">
                                            <p class="text-xs font-medium">{{note}}</p>
                                            <p class="text-xs ellipis">1: In the beginning God created the heaven and the earth. And the earth was without form, and void; and <span class="bg-green-300">darkness</span> was upon the face of the deep. And the Spirit of God moved upon the face of the waters.</p>
                                            <p class="mt-1 text-xs ellipis">2: In the beginning God created the heaven and the earth. And the earth was without form, and void; and <span class="bg-green-300">darkness</span> was upon the face of the deep. And the Spirit of God moved upon the face of the waters.</p>
                                            <div class="mt-2 flex flex-wrap justify-start gap-x-4 gap-y-2 ">
                                                <p v-for="tag in ['beggining','creation','order','waters']" class="text-xs p-1 rounded-md bg-gray-100">{{tag}}</p>
                                            </div>
                                            <input class="accent-black m-4 absolute top-0 right-0" type="radio"/>
                                        </div>
                                    </div>
                                </div>

                                <div class="example mt-4 gap-y-2 overflow-y-scroll">
                                    <div class="flex justify-start items-center">
                                        <p class="text-xl font-light font-semibold ">Exodus</p>
                                        <button class="mr-4 ml-auto text-center text-xs bg-black text-white px-4 py-2 rounded-lg">Select All</button>
                                        <button class="text-center text-xs h-8 w-8 justify-center bg-black text-white p-2 flex items-center py-2 rounded-lg">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right-square-fill" viewBox="0 0 16 16">
                                                <path d="M0 14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2a2 2 0 0 0-2 2zm4.5-6.5h5.793L8.146 5.354a.5.5 0 1 1 .708-.708l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L10.293 8.5H4.5a.5.5 0 0 1 0-1"/>
                                              </svg>
                                        </button>
                                    </div>
                                    <div v-for="setting in 5" class="mt-2 font-light space-y-2 relative">
                                        <div class="border p-4 rounded-md  shadow-sm hover:bg-gray-100">
                                            <p class="text-xs font-medium">Study - Idols and Gods</p>
                                            <p class="text-xs ellipis">Isarel served idols and gods</p>
                                            <p class="text-xs ellipis">Mar 4, 2024</p>
                                            <input class="accent-black m-4 absolute top-0 right-0" type="radio"/>
                                        </div>
                                    </div>
                                </div>
                            </aside>
            </div>

            <div class="hidden p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="flex justify-between">
                <div class="rounded-lg text-xs bg-gray-200 p-1 flex gap-x-2 items-center justify-between">
                    <button class="px-2 p-1 text-gray-500 rounded-md" role="tab">Scripture</button>
                    <button class="shadow-sm px-2 p-1 bg-white rounded-md" role="tab">Notes</button>
                </div>
                <button class="ml-auto text-center text-xs bg-black text-white px-4 py-2 rounded-lg">New Note</button>
                </div>

                <input class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                            placeholder="ex: 'idols'">

                            <aside id="scrollview" class="mt-2">
                                <div class="example mt-4 gap-y-2 overflow-y-scroll">
                                    <div class="flex justify-start items-center">
                                        <p class="text-xl font-light font-semibold ">2025</p>
                                        <button class="mr-4 ml-auto text-center text-xs bg-black text-white px-4 py-2 rounded-lg">Select All</button>
                                        <button class="text-center text-xs h-8 w-8 justify-center bg-black text-white p-2 flex items-center py-2 rounded-lg">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right-square-fill" viewBox="0 0 16 16">
                                                <path d="M0 14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2a2 2 0 0 0-2 2zm4.5-6.5h5.793L8.146 5.354a.5.5 0 1 1 .708-.708l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L10.293 8.5H4.5a.5.5 0 0 1 0-1"/>
                                              </svg>
                                        </button>
                                    </div>
                                    <div v-for="note in ['Study - Idols and Gods','Obtaining Eternal Life','The Destruction of the Gentiles','The Timeline of God']" class="relative mt-2 font-light space-y-2">
                                        <div class="border p-4 rounded-md shadow-sm hover:bg-gray-100">
                                            <p class="text-xs font-medium">{{note}}</p>
                                            <p class="text-xs ellipis">Isarel served <span class="bg-yellow-300">idols</span> and gods</p>
                                            <p class="text-xs ellipis">Mar 4, 2025</p>
                                            <input class="accent-black m-4 absolute top-0 right-0" type="radio"/>
                                        </div>
                                    </div>
                                </div>

                                <div class="example mt-4 gap-y-2 overflow-y-scroll">
                                    <div class="flex justify-start items-center">
                                        <p class="text-xl font-light font-semibold ">2024</p>
                                        <button class="mr-4 ml-auto text-center text-xs bg-black text-white px-4 py-2 rounded-lg">Select All</button>
                                        <button class="text-center text-xs h-8 w-8 justify-center bg-black text-white p-2 flex items-center py-2 rounded-lg">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right-square-fill" viewBox="0 0 16 16">
                                                <path d="M0 14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2a2 2 0 0 0-2 2zm4.5-6.5h5.793L8.146 5.354a.5.5 0 1 1 .708-.708l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L10.293 8.5H4.5a.5.5 0 0 1 0-1"/>
                                              </svg>
                                        </button>
                                    </div>
                                    <div v-for="setting in 5" class="mt-2 font-light space-y-2 relative">
                                        <div class="border p-4 rounded-md  shadow-sm hover:bg-gray-100">
                                            <p class="text-xs font-medium">Study - Idols and Gods</p>
                                            <p class="text-xs ellipis">Isarel served idols and gods</p>
                                            <p class="text-xs ellipis">Mar 4, 2024</p>
                                            <input class="accent-black m-4 absolute top-0 right-0" type="radio"/>
                                        </div>
                                    </div>
                                </div>
                            </aside>
            </div>

            <div class="hidden col-span-2 p-4 rounded-lg border border-gray-300 shadow-md">

                <input class="w-full text-2xl font-semibold outline-none" value="Study - Idols and Gods">
                <div class="mt-1 flex justify-start gap-2 flex-wrap">
                    <select class="px-2 text-xs ellipis border p-1 rounded-md">
                        <option>Michael E. Parker</option>
                        <option>Robert Wright</option>
                        <option>Roger Bell</option>
                        <option>John-Te Jones</option>
                        <option>Lacy Hawkins</option>
                    </select>
                    <select class="px-2 text-xs ellipis border p-1 rounded-md">
                        <option>The Body Of Christ</option>
                        <option>Vallejo</option>
                        <option>Union City</option>
                        <option>Stockbridge</option>
                        <option>Moreno Valley</option>
                        <option>Beavercreek</option>
                        <option>North Carolina</option>
                        <option>Baton Rouge</option>
                        <option>Tyler</option>
                        <option>India</option>
                        <option>Congo</option>
                        <option>Vallejo</option>
                    </select>
                    <input class="text-xs ellipis border p-1 rounded-md px-2" type="date">
                </div>

                <div class="mt-2 font-light space-y-2">
                    <input class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                            placeholder="ex: 'idols'">
                    <div class="pt-2">
                        <p class="text-xs font-medium">Genesis 1:1</p>
                        <p class="text-xs ellipis">In the beginning God created the heaven and the earth. And the earth was without form, and void; and <span class="bg-green-300">darkness</span> was upon the face of the deep. And the Spirit of God moved upon the face of the waters.</p>
                        <div class="mt-2 flex flex-wrap justify-start gap-x-4 gap-y-2 ">
                            <p v-for="tag in ['beggining','creation','order','waters']" class="text-xs p-1 rounded-md bg-gray-100">{{tag}}</p>
                        </div>
                        <textarea class="bg-gray-50 text-xs border p-4 mt-4 w-full rounded-md"></textarea>
                    </div>

                    <div class="pt-4">
                        <p class="text-xs font-medium">John 1:1</p>
                        <p class="text-xs ellipis">In the beginning God created the heaven and the earth. And the earth was without form, and void; and <span class="bg-green-300">darkness</span> was upon the face of the deep. And the Spirit of God moved upon the face of the waters.</p>
                        <div class="mt-2 flex flex-wrap justify-start gap-x-4 gap-y-2 ">
                            <p v-for="tag in ['beggining','creation','order','waters']" class="text-xs p-1 rounded-md bg-gray-100">{{tag}}</p>
                        </div>
                        <textarea class="bg-gray-50 text-xs border p-4 mt-4 w-full rounded-md"></textarea>
                    </div>
                </div>

            </div>

            <div class="empty p-4 rounded-lg border border-gray-300 shadow-md">
            </div>


            <div id="chart" class="p-4 rounded-lg border border-gray-300 shadow-md">

                <p class="text-xs font-light">Total Revenue</p>
                <p class="mt-1 font-bold text-lg">$15,231.89</p>
                <p class="text-gray-500" style="font-size: .65rem">+20.1% from last month</p>
            </div>

            <div id="bars" class="p-4 rounded-lg border border-gray-300 shadow-md">
                <p class="text-xs font-light">Subscriptions</p>
                <p class="mt-1 font-bold text-lg">+2350</p>
                <p class="text-gray-500" style="font-size: .65rem">+180.1% from last month</p>
                <div class="mt-3 space-x-2 flex items-end">
                    <div class="h-[50px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[70px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[20px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[40px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[50px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[70px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[20px] bg-black w-[30px] rounded-sm"></div>
                    <div class="h-[40px] bg-black w-[30px] rounded-sm"></div>
                </div>
            </div>

            <div id="calendar" class="p-4 rounded-lg border border-gray-300 shadow-md">

                <div class="text-xs font-light flex justify-between">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-caret-left" viewBox="0 0 16 16">
                        <path
                            d="M10 12.796V3.204L4.519 8zm-.659.753-5.48-4.796a1 1 0 0 1 0-1.506l5.48-4.796A1 1 0 0 1 11 3.204v9.592a1 1 0 0 1-1.659.753" />
                    </svg>
                    <p>June 2023</p>
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-caret-right" viewBox="0 0 16 16">
                        <path
                            d="M6 12.796V3.204L11.481 8zm.659.753 5.48-4.796a1 1 0 0 0 0-1.506L6.66 2.451C6.011 1.885 5 2.345 5 3.204v9.592a1 1 0 0 0 1.659.753" />
                    </svg>
                </div>
                <div class="mt-2 grid grid-cols-7 gap-2 text-xs text-gray-500">
                    <p v-for="day in ['Su','Mo','Tu','We','Th','Fr','Sa']">{{day}}</p>
                </div>

                <div class="mt-2 grid grid-cols-7 gap-2 justify-start text-xs">
                    <div v-for="day in 30">
                        <p v-if="day==5 || day==13"
                            class="p-1 rounded-lg flex items-center justify-center bg-black text-white">{{day}}</p>
                        <p v-else-if="day > 5 && day < 13"
                            class="p-1 rounded-lg flex items-center justify-center bg-gray-100 text-black">{{day}}</p>
                        <p v-else class="p-1 rounded-lg flex items-center justify-center text-black">{{day}}</p>
                    </div>
                </div>
            </div>

            <div id="chat-box" class="p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="text-xs font-light flex items-start items-center">
                    <img class="w-8 h-8 object-cover" src="https://ui.shadcn.com/avatars/01.png">
                    <div class="ml-3">
                        <p>Tutorial Doctor</p>
                        <p class="text-xs text-gray-500">m@example.com</p>
                    </div>
                    <button
                        class="border p-2 w-8 h-8 flex items-center rounded-full text-center justify-center ml-auto">
                        +
                    </button>
                </div>
                <div class="mt-4">
                    <div class="text-xs">
                        <div v-for="(message,ndx) in ['Hi, how can I help you today?','Hey, I am having trouble with my account','What seems to be the problem?','I cannot log in.']"
                            :key="ndx">
                            <span v-if="ndx%2 == 0"
                                class="text-left bg-gray-100 p-2 rounded-lg flex w-max max-w-[75%] flex-col rounded-lg px-3 py-2">{{message}}</span>
                            <span v-else
                                class="text-left my-3 bg-black text-white p-2 rounded-lg flex w-max max-w-[75%] flex-col rounded-lg px-3 py-2 ml-auto">{{message}}</span>
                        </div>
                    </div>
                </div>
            </div>

            <div id="profile-card" class="p-4 rounded-lg border border-gray-300 shadow-md flex justify-center">
                <div class="text-center text-xs font-light">
                    <img class="border-4 rounded-full w-32 h-32 object-cover" src="https://ui.shadcn.com/avatars/01.png">
                    <div class="mt-3">
                        <p>Tutorial Doctor</p>
                        <p class="text-xs text-gray-500">m@example.com</p>
                    </div>
                </div>
            </div>

            <div id="chart" class="p-4 rounded-lg border border-gray-300 shadow-md">

                <p class="text-xs font-light font-semibold">Cookie Settings</p>
                <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>

                <div class="mt-4 grid gap-y-4">
                    <div>
                        <p class="text-xs">First Name</p>
                        <p class="text-gray-500" style="font-size: .60rem">These cookies are essential in order to use
                            the website and
                            it's features</p>
                        <input class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                            placeholder="Enter your name">
                    </div>
                    <div v-for="setting in ['Strictly Neccesary','Functional Cookies','Performance Cookies']"
                        class="flex justify-between items-center">
                        <div class="col-span-10">
                            <p class="text-xs">{{setting}}</p>
                            <p class="text-gray-500" style="font-size: .60rem">These cookies are essentil in order to
                                use the website and
                                it's features</p>
                        </div>
                        <div class="ml-4">
                            <button type="button" role="switch" aria-checked="true" data-state="checked" value="on"
                                class="peer inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed bg-black disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input"
                                id="necessary" aria-label="Necessary"><span data-state="checked"
                                    class="pointer-events-none block h-4 w-4 rounded-full bg-white shadow-lg ring-0 transition-transform data-[state=checked]:translate-x-4 data-[state=unchecked]:translate-x-0"></span></button>
                        </div>
                    </div>
                    <div>
                        <button class="text-center text-xs border border-gray-300 px-4 py-2 rounded-lg w-full">Save
                            Preferences</button>
                    </div>
                </div>
            </div>

            <div id="form" class="p-4 rounded-lg border border-gray-300 shadow-md">

                <p class="text-xs font-light font-semibold">Form Details</p>
                <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>

                <div class="mt-4 grid gap-y-4">
                    <div v-for="setting in ['First Name','Last Name','Email']"
                        class="flex justify-between items-center">
                        <div class="w-full">
                            <p class="text-xs">{{setting}}</p>
                            <p class="hidden text-gray-500" style="font-size: .60rem">These cookies are essential in
                                order to use the website and
                                it's features</p>
                            <input class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                                placeholder="Enter your name">
                        </div>
                    </div>
                    <div>
                        <button class="text-center text-xs bg-black text-white px-4 py-2 rounded-lg w-full">Create
                            Account</button>
                    </div>
                </div>
            </div>

            <aside id="sidenav" class="p-4 rounded-lg border border-gray-300 shadow-md">

                <p class="text-xs font-light font-semibold">Sidebar</p>
                <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>

                <div class="mt-4 grid gap-y-4">
                    <div v-for="setting in ['Inbox']"
                        class="bg-black p-2 text-white rounded-md flex justify-start items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                            class="bi bi-inbox" viewBox="0 0 16 16">
                            <path
                                d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z" />
                        </svg>
                        <div class="ml-3 col-span-10">
                            <p class="text-xs">{{setting}}</p>
                        </div>
                        <div class="ml-auto text-xs">
                            <p>128</p>
                        </div>
                    </div>
                    <div v-for="setting in ['Drafts','Sent','Junk','Trash','Archive']"
                        class="p-2 rounded-md flex justify-start items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                            class="bi bi-inbox" viewBox="0 0 16 16">
                            <path
                                d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z" />
                        </svg>
                        <div class="ml-3 col-span-10">
                            <p class="text-xs">{{setting}}</p>
                        </div>
                        <div class="ml-auto text-xs">
                            <p>128</p>
                        </div>
                    </div>
                    <hr>
                    <div v-for="setting in ['Social','Updates','Forums','Shopping','Promotions']"
                        class="p-2 rounded-md flex justify-start items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                            class="bi bi-inbox" viewBox="0 0 16 16">
                            <path
                                d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z" />
                        </svg>
                        <div class="ml-2 col-span-10">
                            <p class="text-xs">{{setting}}</p>
                        </div>
                        <div class="ml-auto text-xs">
                            <p>128</p>
                        </div>
                    </div>
                    <div>
                        <button class="text-center text-xs border border-gray-300 px-4 py-2 rounded-lg w-full">Save
                            Preferences</button>
                    </div>
                </div>
            </aside>

            <div id="alert" class="p-4 h-[64px] rounded-lg border border-gray-300 shadow-md">
                <p class="text-xs font-medium">Heads up!</p>
                <p class="mt-1" style="font-size: .65rem">+20.1% from last month</p>
            </div>

            <div id="table" class="col-span-2 p-4 rounded-lg border border-gray-300 shadow-md">
                <p class="hidden text-xs font-light font-semibold">Sidebar</p>
                <p class="hidden mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b">
                            <th class="h-10 px-2 text-left align-middle font-medium">
                                <button type="button" role="checkbox" value="on"
                                    class="h-4 w-4 shrink-0 rounded-sm border border-primary shadow focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                                    aria-label="Select all"></button>
                            </th>
                            <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground">
                                Status</th>
                            <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground">
                                <button
                                    class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2">Email<svg
                                        xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
                                        fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round" class="lucide lucide-arrow-up-down">
                                        <path d="m21 16-4 4-4-4"></path>
                                        <path d="M17 20V4"></path>
                                        <path d="m3 8 4-4 4 4"></path>
                                        <path d="M7 4v16"></path>
                                    </svg></button>
                            </th>
                            <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground">
                                <div class="text-right">Amount</div>
                            </th>
                            <th class="h-10 px-2 text-left align-middle font-medium text-muted-foreground">
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="i in 3"
                            class="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted"
                            data-state="false">
                            <td class="p-2 align-middle">
                                <button type="button" role="checkbox" aria-checked="false" data-state="unchecked"
                                    value="on"
                                    class="peer h-4 w-4 shrink-0 rounded-sm border border-primary shadow focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground"
                                    aria-label="Select row"></button>
                            </td>
                            <td class="p-2 align-middle">
                                <div class="capitalize">success</div>
                            </td>
                            <td class="p-2 align-middle">
                                <div class="lowercase">ken99@example.com</div>
                            </td>
                            <td class="p-2 align-middle">
                                <div class="text-right font-medium">$316.00</div>
                            </td>
                            <td class="p-2 align-middle">
                                <button
                                    class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none hover:text-accent-foreground h-8 w-8 p-0"
                                    type="button" id="radix-:r2o0:" aria-haspopup="menu" aria-expanded="false"
                                    data-state="closed"><span class="sr-only">Open menu</span><svg
                                        xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
                                        fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round" class="lucide lucide-ellipsis">
                                        <circle cx="12" cy="12" r="1"></circle>
                                        <circle cx="19" cy="12" r="1"></circle>
                                        <circle cx="5" cy="12" r="1"></circle>
                                    </svg>
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="tabs" class="p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="rounded-lg text-xs bg-gray-200 p-1 flex gap-x-2 items-center justify-between">
                    <button class="shadow-sm p-1 w-1/2 bg-white rounded-md" role="tab">Old Testament</button>
                    <button class="p-1 w-1/2 text-gray-500 rounded-md" role="tab">New Testament</button>

                </div>
            </div>

            <div id="checkbox" class="flex items-center p-4 h-[64px] rounded-lg border border-gray-300 shadow-md">
                <input class="accent-black " type="checkbox" />
                <p class="ml-2 font-medium" style="font-size: .65rem">Accept terms and conditions</p>
            </div>

            <div id="nav" class="flex items-center p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                    placeholder="Enter your name">
                    <ul class="flex justify-start gap-4 flex-wrap items-center">
                        <li>
                            <a>File</a>
                        </li>
                        <li>
                            <a>Edit</a>
                        </li>
                        <li>
                            <a>View</a>
                        </li>
                        <li>
                            <a>Profiles</a>
                        </li>
                        <li class="ml-auto">
                            <a><img class="w-8 h-8 object-cover" src="https://ui.shadcn.com/avatars/01.png"></a>
                        </li>
                        <li>
                            <a>Logout</a>
                        </li>
                    </ul>
                </div>
            </div>

            <div id="progress" class="flex items-center p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="flex items-center justify-start h-2 mt-2 text-xs bg-gray-300 rounded-lg w-full">
                    <div class="h-2 w-8/12 text-xs bg-black border border-gray-300 rounded-l-lg"
                        placeholder="Enter your name">
                    </div>

                </div>
            </div>

            <div id="radios" class="space-y-2 p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="flex" v-for="radio in ['Default','Comfortable','Compact']">
                    <input class="accent-black " type="radio" name="radios" />
                    <p class="ml-2 font-medium" style="font-size: .65rem">{{radio}}</p>
                </div>
            </div>

            <aside id="scrollview" class="p-4 rounded-lg border border-gray-300 shadow-md">
                <div class="example mt-4 gap-y-2 overflow-y-scroll h-[300px]">
                    <p class="text-xs font-light font-semibold">Tags</p>
                    <div v-for="setting in 30" class="mt-2 font-light space-y-2">
                        <p class="text-xs">asdf</p>
                        <hr>
                    </div>
                </div>
            </aside>

            <div class="flex items-stretch justify-between gap-4 flex-wrap">
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
            </div>

            <div class="flex items-start justify-between gap-4 flex-wrap">
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
            </div>

            <div class="flex items-center justify-between gap-4 flex-wrap">
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="w-1/3 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
            </div>

            <div class="grid grid-cols-12 gap-2 items-stretch justify-between flex-wrap">
                <div class="col-span-2 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="col-span-8 empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
                <div class="col-span-2 empty p-4 rounded-lg border border-gray-300 shadow-md"></div>
            </div>

            <div class="grid grid-cols-4 gap-2">
                <div v-for="col in 12" class="empty p-4 rounded-lg border border-gray-300 shadow-md">
                </div>
            </div>


            <div class="col-span-4 empty p-8 rounded-lg border border-gray-300 shadow-md">
                <p class="font-bold text-xl">Settings</p>
                <p class="text-gray-500" style="font-size: .75rem">Manager your account settings and set e-mail preferences.</p>
                <hr class="mt-4">

                <div class="flex justify-start gap-x-6">
                    <aside class="w-1/5 mt-4">        
                        <div class="mt-4 grid gap-y-4">
                            <div v-for="setting in ['Profile']"
                                class="bg-gray-100 p-2 rounded-md flex justify-start items-center">
                                <div class="ml-3 col-span-10">
                                    <p class="text-xs">{{setting}}</p>
                                </div>
                            </div>
                            <div v-for="setting in ['Account','Apperance','Notifications','Display']"
                                class="hover:bg-gray-100 p-2 rounded-md flex justify-start items-center">
                                <div class="ml-3 col-span-10">
                                    <p class="text-xs">{{setting}}</p>
                                </div>
                            </div>
                            <hr>
                        </div>
                    </aside>
                    <div id="chart" class="mt-8 w-1/3">

                        <p class="text-sm font-medium font-light">Profile</p>
                        <p class="text-gray-500" style="font-size: .65rem">This is how others will see you on the site</p>
                        <hr class="mt-4">

                        <div class=>
                            <div class="mt-4 grid gap-y-4">
                                <div v-for="setting in ['First Name','Last Name','Email']"
                                    class="flex justify-between items-center">
                                    <div class="mt-2 w-full">
                                        <p class="text-xs">{{setting}}</p>
                                        <p class="hidden text-gray-500" style="font-size: .60rem">These cookies are essential in
                                            order to use the website and
                                            it's features</p>
                                        <input class="mt-2 text-xs border border-gray-300 px-4 py-2 rounded-lg w-full"
                                            placeholder="Enter your name">
                                            <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
                                    </div>
                                </div>
                                <div>
                                    <button class="text-center text-xs bg-black text-white px-4 py-2 rounded-lg">Update Profile</button>
                                </div>
                            </div>
                        </div>
                        
                        
                    </div>
                </div>
            </div>

            <div id="music" class="col-span-5 empty rounded-lg border border-gray-300 shadow-md">
                <div class="text-xs py-2 px-4 w-full border-b"
                    placeholder="Enter your name">
                    <ul class="flex justify-start gap-4 flex-wrap items-center">
                        <li>
                            <a class="font-bold">Music</a>
                        </li>
                        <li>
                            <a>File</a>
                        </li>
                        <li>
                            <a>Edit</a>
                        </li>
                        <li>
                            <a>View</a>
                        </li>
                        <li>
                            <a>Account</a>
                        </li>
                    </ul>
                </div>


                <div class="flex justify-start gap-x-6">
                    <aside id="sidenav" class="w-1/5 p-4">

                        <p class="text-sm font-light font-semibold">Discover</p>
                        <p class="mt-1 text-gray-500" style="font-size: .70rem">Manage your cookie settings here.</p>
        
                        <div class="mt-4 grid gap-y-4">
                            <div v-for="setting in ['Listen Now']"
                                class="bg-gray-100 p-2 rounded-md flex justify-start items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                                    class="bi bi-inbox" viewBox="0 0 16 16">
                                    <path
                                        d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z" />
                                </svg>
                                <div class="ml-3 col-span-10">
                                    <p class="text-xs">{{setting}}</p>
                                </div>
                                <div class="ml-auto text-xs">
                                    <p>128</p>
                                </div>
                            </div>
                            <div v-for="setting in ['Drafts','Sent','Junk','Trash','Archive']"
                                class="p-2 rounded-md flex justify-start items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                                    class="bi bi-inbox" viewBox="0 0 16 16">
                                    <path
                                        d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z" />
                                </svg>
                                <div class="ml-3 col-span-10">
                                    <p class="text-xs">{{setting}}</p>
                                </div>
                                <div class="ml-auto text-xs">
                                    <p>128</p>
                                </div>
                            </div>
                            <hr>
                            <div v-for="setting in ['Social','Updates','Forums','Shopping','Promotions']"
                                class="p-2 rounded-md flex justify-start items-center">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                                    class="bi bi-inbox" viewBox="0 0 16 16">
                                    <path
                                        d="M4.98 4a.5.5 0 0 0-.39.188L1.54 8H6a.5.5 0 0 1 .5.5 1.5 1.5 0 1 0 3 0A.5.5 0 0 1 10 8h4.46l-3.05-3.812A.5.5 0 0 0 11.02 4zm9.954 5H10.45a2.5 2.5 0 0 1-4.9 0H1.066l.32 2.562a.5.5 0 0 0 .497.438h12.234a.5.5 0 0 0 .496-.438zM3.809 3.563A1.5 1.5 0 0 1 4.981 3h6.038a1.5 1.5 0 0 1 1.172.563l3.7 4.625a.5.5 0 0 1 .105.374l-.39 3.124A1.5 1.5 0 0 1 14.117 13H1.883a1.5 1.5 0 0 1-1.489-1.314l-.39-3.124a.5.5 0 0 1 .106-.374z" />
                                </svg>
                                <div class="ml-2 col-span-10">
                                    <p class="text-xs">{{setting}}</p>
                                </div>
                                <div class="ml-auto text-xs">
                                    <p>128</p>
                                </div>
                            </div>
                            <div>
                                <button class="text-center text-xs border border-gray-300 px-4 py-2 rounded-lg w-full">Save
                                    Preferences</button>
                            </div>
                        </div>
                    </aside>
                    <div id="chart" class="mt-8 w-3/4">

                        <div class="flex justify-between">
                        <div class="w-2/5 rounded-lg text-xs bg-gray-100 p-1 gap-x-2">
                            <button class="inline-block shadow-sm p-1 bg-white rounded-md" role="tab">Music</button>
                            <button class="inline-block ml-4 p-1 text-gray-500 rounded-md" role="tab">Podcasts</button>
                            <button class="inline-block ml-4 p-1 text-gray-500 rounded-md" role="tab">Live</button>
        
                        </div>
                        <button class="text-center text-xs bg-black text-white px-4 py-2 rounded-lg flex items-center">
                            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-plus-circle" viewBox="0 0 16 16">
                                <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
                                <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
                              </svg>

                            <span class="ml-2">Add Music</span></button>
                        </div>

                        <p class="mt-4 font-medium text-xl">Listen Now</p>
                <p class="text-gray-500" style="font-size: .75rem">Manager your account settings and set e-mail preferences.</p>
                <hr class="mt-4">

                <div class="mt-4 flex justify-start flex-wrap gap-3">
                    <div v-for="col in 12" class="empty">
                        <img class="h-[260px] w-[200px] rounded-md object-cover" src="https://ui.shadcn.com/_next/image?url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1611348586804-61bf6c080437%3Fw%3D300%26dpr%3D2%26q%3D80&w=640&q=75"/>
                        <p class="mt-2 text-xs font-medium">Heads up!</p>
                        <p class="mt-1 text-gray-500" style="font-size: .65rem">+20.1% from last month</p>
                    </div>
                </div>

                <p class="mt-4 font-medium text-xl">Made for You</p>
                <p class="text-gray-500" style="font-size: .75rem">Your personal playlists. Updated daily.</p>
                <hr class="mt-4">

                <div class="mt-4 flex justify-start flex-wrap gap-3">
                    <div v-for="col in 12" class="empty">
                        <img class="h-32 w-32 rounded-md object-cover" src="https://ui.shadcn.com/_next/image?url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1611348586804-61bf6c080437%3Fw%3D300%26dpr%3D2%26q%3D80&w=640&q=75"/>
                        <p class="mt-2 text-xs font-medium">Heads up!</p>
                        <p class="mt-1 text-gray-500" style="font-size: .65rem">+20.1% from last month</p>
                    </div>
                </div>

                       
                        
                        
                    </div>
                </div>
            </div>

            







        </div>

        <div class="w-1/3 mb-4 mr-4 sticky bottom-4 right-0 float-right mt-4 bg-black text-white p-4 rounded-md">
            <p class="text-xs font-medium">Warning!</p>
            <p class="mt-1" style="font-size: .65rem">You still have some work to do. Please complete it then try again.
            </p>
        </div>

    </div>

    <script src='script.js' text='text/javascript'></script>

    <script>
        const { createApp, ref } = Vue

        createApp({
            setup() {
                const message = ref('Saved');
                return {
                    message
                }
            }
        }).mount('#app')



    </script>

    <style>
        .example::-webkit-scrollbar {
            display: none;
        }

        /* Hide scrollbar for IE, Edge and Firefox */
        .example {
            -ms-overflow-style: none;
            /* IE and Edge */
            scrollbar-width: none;
            /* Firefox */
        }
    </style>

</body>

{% endblock%}
FLASK_SCAFFOLD_FILE_0040
truncate -s 67293 'templates/components/master_components.html'

cat > 'templates/contact.html' <<'FLASK_SCAFFOLD_FILE_0041'

{% extends 'shared/layout.html'%}

{% block content %}

<h1 class="text-4xl">Contact Page</h1>


{% endblock%}

FLASK_SCAFFOLD_FILE_0041

cat > 'templates/home.html' <<'FLASK_SCAFFOLD_FILE_0042'
Welcome Home
FLASK_SCAFFOLD_FILE_0042

cat > 'templates/index.html' <<'FLASK_SCAFFOLD_FILE_0043'

{% extends 'shared/layout.html'%}

{% block content %}

<h1 class="text-4xl">Index Page</h1>

Admin: {{user.email}}

<br/>

<button hx-get="/ping" hx-swap="innerHTML" hx-target="#swapper">
    PING
</button>
<br/>
<pre id="swapper">
</pre>

{% endblock%}

FLASK_SCAFFOLD_FILE_0043

cat > 'templates/items/edit.html' <<'FLASK_SCAFFOLD_FILE_0044'
{% extends 'shared/layout.html' %}


{% block content %}
<h1 class="text-4xl">Edit Item</h1>

<form class="grid gap-2" method="POST" action="/items/{{item.id}}">
	<input name="name" value="{{item.name}}">
	<input name="description" value="{{item.description}}">
    <input type="submit" value="Submit">
</form>
{% endblock %}
FLASK_SCAFFOLD_FILE_0044
truncate -s 325 'templates/items/edit.html'

cat > 'templates/items/index.html' <<'FLASK_SCAFFOLD_FILE_0045'
{% extends "shared/layout.html" %}

{% block content %}
<div class="container my-4">
  <div class="flex justify-content-between align-items-center mb-3">
    <h1 class="text-4xl">Items</h1>
    {# Points to /items?action=new #}
    <a href="{{ url_for('routes.items', action='new') }}" class="ml-2 btn btn-primary">
      + Add New Item
    </a>
  </div>

  {% if items %}
    <table class="table table-striped mt-4">
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {% for item in items %}
          <tr>
            <td>{{ item.id }}</td>
            <td>{{ item.name }}</td>
            <td class="flex gap-2">
               <a href="{{ url_for('routes.items', id=item.id) }}" class="btn btn-sm btn-info">
    View
  </a>
              <a href="{{ url_for('routes.items', id=item.id, action='edit') }}" class="btn btn-sm btn-outline-secondary">
                Edit
              </a>

              <form action="{{ url_for('routes.items', id=item.id) }}" method="POST" class="d-inline" onsubmit="return confirm('Are you sure?');">
                <input type="hidden" name="_method" value="DELETE">
                <button type="submit" class="btn btn-sm btn-outline-danger">
                  Delete
                </button>
              </form>
            </td>
          </tr>
        {% endfor %}
      </tbody>
    </table>
  {% else %}
    <p>No items found.</p>
  {% endif %}
</div>
{% endblock %}
FLASK_SCAFFOLD_FILE_0045
truncate -s 1515 'templates/items/index.html'

cat > 'templates/items/new.html' <<'FLASK_SCAFFOLD_FILE_0046'
{% extends 'shared/layout.html' %}


{% block content %}
<h1 class="text-4xl">New Item</h1>

<form class="grid gap-4" method="POST" action="/items">
	<input name="name" placeholder="name">
	<input name="description" placeholder="description">
    <input type="submit" value="Submit">
</form>
{% endblock %}
FLASK_SCAFFOLD_FILE_0046
truncate -s 306 'templates/items/new.html'

cat > 'templates/items/show.html' <<'FLASK_SCAFFOLD_FILE_0047'
{% extends "shared/layout.html" %}


{% block content %}

<h1 class="text-4xl">Show Items</h1>

<div class="container my-4">
  <div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
      <a href="{{ url_for('routes.items') }}" class="btn btn-outline-secondary">
        &larr; Back to Items
      </a>
      <h2 class="mt-4">Item Details #{{ item.id }}</h2>
    </div>
    <div class="card-body">
      <h3 class="card-title">{{ item.name }}</h3>
      
      {% if item.description %}
        <p class="card-text">{{ item.description }}</p>
      {% endif %}

      <p class="text-muted">
        Created: {{ item.created_at.strftime('%Y-%m-%d %H:%M') if item.created_at else 'N/A' }}
      </p>
    </div>
    <div class="card-footer flex gap-2">
      {# Link to Edit mode via ?action=edit #}
      <a href="{{ url_for('routes.items', id=item.id, action='edit') }}" class="btn btn-warning">
        Edit
      </a>

      {# Delete Form #}
      <form action="{{ url_for('routes.items', id=item.id) }}" method="POST" onsubmit="return confirm('Delete this item?');">
        <input type="hidden" name="_method" value="DELETE">
        <button type="submit" class="btn btn-danger">Delete</button>
      </form>
    </div>
  </div>
</div>
{% endblock %}
FLASK_SCAFFOLD_FILE_0047
truncate -s 1298 'templates/items/show.html'

cat > 'templates/partials/_items_content.html' <<'FLASK_SCAFFOLD_FILE_0048'
<div>
    <!-- Center Section: Title and Item Table -->
    <div class="w-full">
        <div>
             <p class="font-medium text-2xl">Items</p>
            <p class="text-gray-500" style="font-size: .75rem">Manager your account settings and set e-mail preferences.
            </p>

            <div class="mt-4 flex justify-between">
                <div class="w-2/5 rounded-lg text-xs bg-gray-100 p-1 gap-x-2">
                    <button class="inline-block shadow-sm p-1 bg-white rounded-md" role="tab">All Items</button>
                    <button class="inline-block ml-4 p-1 text-gray-500 rounded-md" role="tab">Roles</button>
                    <button class="inline-block ml-4 p-1 text-gray-500 rounded-md" role="tab">Permission</button>

                </div>
                <button class="text-center text-xs bg-black text-white px-4 py-2 rounded-lg flex items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor"
                        class="bi bi-plus-circle" viewBox="0 0 16 16">
                        <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"></path>
                        <path
                            d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4">
                        </path>
                    </svg>


                    <span class="ml-2">
                        <a href="{{url_for('routes.items', action='new')}}">Add Item</a>
                    </span>
                </button>
            </div>

            <hr class="mt-4">
        </div>

        <div class="relative overflow-x-auto bg-neutral-primary-soft shadow-xs rounded-base border border-default h-[800px]">
            <table class="w-full text-sm text-left rtl:text-right text-body">
                <thead class="text-sm text-body bg-neutral-secondary-soft border-b rounded-base border-default">
                    <tr class="bg-gray-50">
                        <th scope="col" class="px-6 py-3 font-medium">Item Name</th>
                        <th scope="col" class="px-6 py-3 font-medium">SKU</th>
                        <th scope="col" class="px-6 py-3 font-medium">Category</th>
                        <th scope="col" class="px-6 py-3 font-medium">Stock</th>
                        <th scope="col" class="px-6 py-3 font-medium">Price</th>
                        <th scope="col" class="px-6 py-3 font-medium">Status</th>
                    </tr>
                </thead>
                <tbody>
                    {% for item in items %}
                    <tr class="bg-neutral-primary border-b border-default">
                        <th scope="row" class="px-6 py-4 font-medium text-heading whitespace-nowrap">
                            <a class="hover:text-gray-500" href="{{url_for('routes.items', id=item.id)}}">
                            {{item.name}}
                        </a>
                        </th>
                        <td class="px-6 py-4">{{ item.sku or 'asd'}}</td>
                        <td class="px-6 py-4">{{ item.category or 'as'}}</td>
                        <td class="px-6 py-4">{{ item.stock or 'yes'}}</td>
                        <td class="px-6 py-4">${{ item.price or '123'}}</td>
                        <td class="px-6 py-4">
                            <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800">Active</span>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>

    <!-- Right-Hand Side Form: Create Item -->
    <div class="hidden col-span-12 lg:col-span-3 border border-default rounded-base p-5 bg-neutral-primary h-fit">
        <h2 class="font-bold text-lg text-heading">Create Item</h2>
        <p class="text-xs text-body mb-4">Add a new item to inventory.</p>

        <form action="/admin/items/create" method="POST" class="space-y-4">
            <div>
                <label class="block text-xs font-medium text-heading mb-1">Item Name</label>
                <input type="text" name="name" placeholder="Enter item name" class="w-full text-xs p-2.5 border border-default rounded-base bg-transparent">
            </div>
            <div>
                <label class="block text-xs font-medium text-heading mb-1">Category</label>
                <input type="text" name="category" placeholder="Enter category" class="w-full text-xs p-2.5 border border-default rounded-base bg-transparent">
            </div>
            <div>
                <label class="block text-xs font-medium text-heading mb-1">Price</label>
                <input type="number" name="price" step="0.01" placeholder="0.00" class="w-full text-xs p-2.5 border border-default rounded-base bg-transparent">
            </div>
            <button type="submit" class="w-full py-2 bg-black text-white text-xs rounded-base font-medium mt-4">
                Save Item
            </button>
        </form>
    </div>
</div>
FLASK_SCAFFOLD_FILE_0048
truncate -s 5076 'templates/partials/_items_content.html'

cat > 'templates/partials/_users_content.html' <<'FLASK_SCAFFOLD_FILE_0049'
<!-- Center Section: Title, Sub-tabs, and Table (8 cols or 9 cols) -->
<div>
    <!-- Section Header -->
    <div>
        <p class="font-medium text-2xl">Users</p>
        <p class="text-gray-500" style="font-size: .75rem">Manager your account settings and set e-mail preferences.
        </p>

        <div class="mt-4 flex justify-between">
            <div class="w-2/5 rounded-lg text-xs bg-gray-100 p-1 gap-x-2">
                <button class="inline-block shadow-sm p-1 bg-white rounded-md" role="tab">All Users</button>
                <button class="inline-block ml-4 p-1 text-gray-500 rounded-md" role="tab">Roles</button>
                <button class="inline-block ml-4 p-1 text-gray-500 rounded-md" role="tab">Permission</button>

            </div>
            <button class="text-center text-xs bg-black text-white px-4 py-2 rounded-lg flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor"
                    class="bi bi-plus-circle" viewBox="0 0 16 16">
                    <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"></path>
                    <path
                        d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4">
                    </path>
                </svg>


                <span class="ml-2">
                    <a href="{{url_for('routes.items', action='new')}}">Add User</a>
                </span>
            </button>
        </div>

        <hr class="mt-4">
    </div>

    <!-- Table Container -->
    <div
        class="relative overflow-x-auto bg-neutral-primary-soft shadow-xs rounded-base border border-default h-[800px]">
        <table class="w-full text-sm text-left rtl:text-right text-body">
            <thead class="text-sm text-body bg-neutral-secondary-soft border-b rounded-base border-default">
                <tr class="bg-gray-50">
                    <th scope="col" class="px-6 py-3 font-medium">Full Name</th>
                    <th scope="col" class="px-6 py-3 font-medium">Email</th>
                    <th scope="col" class="px-6 py-3 font-medium">Phone</th>
                    <th scope="col" class="px-6 py-3 font-medium">Address</th>
                    <th scope="col" class="px-6 py-3 font-medium">State</th>
                    <th scope="col" class="px-6 py-3 font-medium">City</th>
                    <th scope="col" class="px-6 py-3 font-medium">ZIP</th>
                    <th scope="col" class="px-6 py-3 font-medium">Website</th>
                    <th scope="col" class="px-6 py-3 font-medium">Occupation</th>
                    <th scope="col" class="px-6 py-3 font-medium">Weight</th>
                    <th scope="col" class="px-6 py-3 font-medium">Height</th>
                </tr>
            </thead>
            <tbody>
                {% for user in users %}
                <tr class="bg-neutral-primary border-b border-default">
                    <th scope="row" class="px-6 py-4 font-medium text-heading whitespace-nowrap">
                        <a class="hover:text-gray-500" href="{{url_for('routes.show_user', user_id=user.id)}}">
                           <img src="{{user.profile_img or 'https://images.unsplash.com/photo-1614204424926-196a80bf0be8?q=80&w=1587&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'}}" class="w-8 h-8 rounded-full object-cover inline-block mr-1"/> <span>{{user.first_name}} {{user.last_name}}</span>
                        </a>
                    </th>
                    <td class="px-6 py-4">{{ user.email }}</td>
                    <td class="px-6 py-4">{{ user.phone or '323-323-23232' }}</td>
                    <td class="px-6 py-4">{{ user.address or '231 Harris St' }}</td>
                    <td class="px-6 py-4">{{ user.state or 'NY' }}</td>
                    <td class="px-6 py-4">{{ user.city or 'New York' }}</td>
                    <td class="px-6 py-4">{{ user.zip or '50399' }}</td>
                    <td class="px-6 py-4">{{ user.website or 'http://www.helpers.com' }}</td>
                    <td class="px-6 py-4">{{ user.info.occupation or 'Interior Designer' }}</td>
                    <td class="px-6 py-4">{{ user.weight or '200lb' }}</td>
                    <td class="px-6 py-4">{{ user.height or "6' 1\"" }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
</div>

<!-- Right-Hand Side Form: Create User -->
<div class="hidden col-span-12 lg:col-span-3 border border-default rounded-base p-5 bg-neutral-primary h-fit">
    <h2 class="font-bold text-lg text-heading">Create User</h2>
    <p class="text-xs text-body mb-4">Manage your cookie settings here.</p>

    <form action="/admin/users/create" method="POST" class="space-y-4">
        <div>
            <label class="block text-xs font-medium text-heading mb-1">Email</label>
            <input type="email" name="email" placeholder="Enter your name"
                class="w-full text-xs p-2.5 border border-default rounded-base bg-transparent">
        </div>
        <div>
            <label class="block text-xs font-medium text-heading mb-1">First Name</label>
            <input type="text" name="first_name" placeholder="Enter your name"
                class="w-full text-xs p-2.5 border border-default rounded-base bg-transparent">
        </div>
        <div>
            <label class="block text-xs font-medium text-heading mb-1">Last Name</label>
            <input type="text" name="last_name" placeholder="Enter your name"
                class="w-full text-xs p-2.5 border border-default rounded-base bg-transparent">
        </div>
        <button type="submit" class="w-full py-2 bg-black text-white text-xs rounded-base font-medium mt-4">
            Create
        </button>
    </form>
</div>
FLASK_SCAFFOLD_FILE_0049
truncate -s 5907 'templates/partials/_users_content.html'

cat > 'templates/shared/404.html' <<'FLASK_SCAFFOLD_FILE_0050'
404
FLASK_SCAFFOLD_FILE_0050

cat > 'templates/shared/500.html' <<'FLASK_SCAFFOLD_FILE_0051'
500
FLASK_SCAFFOLD_FILE_0051

cat > 'templates/shared/layout.html' <<'FLASK_SCAFFOLD_FILE_0052'
<!DOCTYPE html>

<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- <link rel="stylesheet" href="{{url_for('static', filename='css/tiny.css')}}"> -->
    <!-- <link rel="stylesheet" href="{{url_for('static', filename='css/tw.css')}}"> -->
    <title>Flask Template App</title>
</head>

<body>

    {% include './shared/nav.html' %}

    <div class="p-4">
    {% block content %} {% endblock %}
    </div>

    <script src="https://cdn.tailwindcss.com"></script>

    <script src="{{url_for('static', filename='js/script.js')}}"></script>
    <script src="{{url_for('static', filename='js/htmx.js')}}"></script>

</body>

</html>
FLASK_SCAFFOLD_FILE_0052
truncate -s 771 'templates/shared/layout.html'

cat > 'templates/shared/nav.html' <<'FLASK_SCAFFOLD_FILE_0053'
<nav class="text-xs py-2 px-4 w-full border-b">
    <ul class="flex justify-start gap-4 flex-wrap items-center">
        <li><a href="{{url_for('routes.home')}}">Home</a></li>
        <li><a href="{{url_for('routes.contact')}}">Contact</a></li>
        <li><a href="{{url_for('routes.components')}}">Components</a></li>
        {%if current_user.is_authenticated%}
            <li><a href="{{url_for('routes.user_index')}}">Users</a></li>
            <li><a href="{{url_for('routes.items')}}">Items</a></li>
            <li><a class="font-bold" href="{{url_for('routes.admin_users')}}">Admin</a></li>
        {%endif%}
        <li class="ml-auto">
            <div class="flex items-center">
                <span>{{current_user.first_name}} {{current_user.last_name}}</span>
                {%if current_user.profile_img%}
                <img class="ml-2 inline-block w-6 h-6 rounded-full object-cover" src="{{current_user.profile_img}}">
                {%else%}
                <img class="ml-2 inline h-8 w-8 rounded-full object-cover object-center"
                    src="https://images.prismic.io/upskil/ZrvZvEaF0TcGI6NT_55f5c200-1c67-4df3-89f2-82f5a25913f1.webp?auto=format,compress">
                {%endif%}
            </div>
        </li>
        <li><a href="{{url_for('auth.logout')}}">Logout</a></li>
    </ul>
</nav>
FLASK_SCAFFOLD_FILE_0053
truncate -s 1335 'templates/shared/nav.html'

cat > 'templates/shared/unauthorized.html' <<'FLASK_SCAFFOLD_FILE_0054'

{%extends 'shared/layout.html'%}

{%block content%}

<div class="w-full h-screen flex justify-center items-center my-auto">

    <div class="bg-white rounded flex justify-center items-center" style="height:800px;width:1000px">

        <span class="text-indigo-600 font-bold text-5xl">404</span>

        <div class="ml-8"> <span class="text-5xl font-bold">Unauthorized</span>

            <p class="text-gray-500">Please login</p>

        </div>

    </div>

</div>

{%endblock%}

FLASK_SCAFFOLD_FILE_0054

cat > 'templates/users/edit.html' <<'FLASK_SCAFFOLD_FILE_0055'
{%extends 'shared/layout.html'%}

{%block content%}

  <h1 class="text-4xl">Edit User &lt{{user.first_name}} {{user.last_name}}&gt</h1>


<form class="mt-4" action="{{url_for('routes.edit_user', user_id=user.id)}}" method="POST">

  <img class="w-32 h-32 object-cover" alt="User avatar" src="{{user.profile_img}}" />

  <div class="mt-2 grid grid-cols-4 gap-4">

{% set names= ['email','profile_img','first_name','last_name','phone','address','password']%}
{% for name in names %}
<div>
    <label for="name" class="uppercase">{{name}}</label>
    <input type="text" name="{{name}}" value="{{user[name]}}" id="name" placeholder="http://" />
</div>
{% endfor %}

  <input
    type="submit" placeholder="Update" />
  </div>

</form>

{%endblock%}
FLASK_SCAFFOLD_FILE_0055
truncate -s 744 'templates/users/edit.html'

cat > 'templates/users/index.html' <<'FLASK_SCAFFOLD_FILE_0056'
{%extends 'shared/layout.html'%}

{%block content%}

<h1 class="text-4xl">Users</h1>

{% for user in users %}

<div class="border rounded-lg p-4">
    <p>Name:  {{user.first_name}} {{user.last_name}}</p>
    <p>Email: {{user.email}}</p>
</div>

<div class="my-4">
<a href="{{url_for('routes.show_user', user_id=user.id)}}">See</a>

<a href="{{url_for('routes.edit_user', user_id=user.id)}}">Edit</a>

<a href="{{url_for('routes.new_user')}}">New</a>
</div>

{% endfor %}

{%endblock%}
FLASK_SCAFFOLD_FILE_0056
truncate -s 484 'templates/users/index.html'

cat > 'templates/users/new.html' <<'FLASK_SCAFFOLD_FILE_0057'
{%extends 'shared/layout.html'%}

{%block content%}

<form action="{{url_for('routes.create_user')}}" method="POST">

    <h1 class="text-4xl">New User</h1>

  <img alt="User avatar"
    src="https://avatars3.githubusercontent.com/u/72724639?s=400&u=964a4803693899ad66a9229db55953a3dbaad5c6&v=4" />

    {% set names= ['email','profile_img','first_name','last_name','phone','address','password']%}
<div class="grid grid-cols-4 gap-4">
{% for name in names %}
<div>
    <label for="name" class="uppercase">{{name}}</label>
    <input type="text" name="name" id="name" placeholder="{{name}}" />
</div>
{% endfor %}

  <input type="submit" placeholder="submit" />
</div>

</form>

{%endblock%}
FLASK_SCAFFOLD_FILE_0057
truncate -s 690 'templates/users/new.html'

cat > 'templates/users/show.html' <<'FLASK_SCAFFOLD_FILE_0058'
{%extends 'shared/layout.html'%}

{%block content%}


<h1 class="text-3xl">{{user.first_name}} {{user.last_name}}</h1>
<img class="w-32 h-32 object-cover" src="{{user.profile_img}}" alt="">

{{user.profile_img}}

<h1 class="text-2xl">Other users</h1>

{% for u in similar_users %}

<div>

    <img class="w-32 h-32 object-cover" src="{{u.profile_img}}" alt="">

    <a href="{{url_for('routes.show_user', user_id=u.id)}}">{{u.first_name}}</a>

</div>

{%endfor%}

{{user.first_name}}

{{user.last_name}}

<a href="tel:{{user.phone | phone}}">{{user.phone | phone}}</a>

{{user.address}}

<a href="mailto:{{user.email}}">{{user.email}}</a>

<h2>
    <p>Bio</p>
    {{user.info.address}}
</h2>

<hr>
ITEMS
<!-- {{user_items}} -->
{%for item in user_items%}
{{item.name}}<br />
{{item.numeral_name}}
{{item.numeral}}
{%endfor%}


<a href="{{ url_for('routes.delete_user', user_id=user.id) }}">Delete</a>



{%endblock%}
FLASK_SCAFFOLD_FILE_0058
truncate -s 916 'templates/users/show.html'

cat > 'uv.lock' <<'FLASK_SCAFFOLD_FILE_0059'
version = 1
revision = 3
requires-python = ">=3.11"

[[package]]
name = "annotated-types"
version = "0.8.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/5f/56/a8120250d128bed162cd73c76d45f6ef9991f3e068f62a8ee060afa3104a/annotated_types-0.8.0.tar.gz", hash = "sha256:13b2beaad985e05e2d6407ee4c4f35590b11f8d693a258a561055cac8f64cab7", size = 15893, upload-time = "2026-07-23T20:16:13.995Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/99/91/8acff4f5e50511b911bbccb72b8628a49c68ce14148cd9f6431094859a90/annotated_types-0.8.0-py3-none-any.whl", hash = "sha256:f072f4d804ea359e4eaf198b1af7a8b0943881a87f31bb764f8bf219bb9419e0", size = 13427, upload-time = "2026-07-23T20:16:12.938Z" },
]

[[package]]
name = "anyio"
version = "4.15.1"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "idna" },
    { name = "typing-extensions", marker = "python_full_version < '3.15'" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a9/d2/f4d173e22df740bc37b1db102b386ba719b66e95b0f0d751f556b387e6d2/anyio-4.15.1.tar.gz", hash = "sha256:9f28306018cbd6d329e64a36d58256edff76dd996fe423bc957326e578b82a94", size = 276966, upload-time = "2026-09-05T10:42:39.44Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/12/b8/4bd346e22b28902df4d651910f5242c28d84e4a5c2435ca5c3f797ed7e2e/anyio-4.15.1-py3-none-any.whl", hash = "sha256:6152fdbbf9a77fdec97731721bebf7c4c44f7c29b424b0065826173efc7ed101", size = 132079, upload-time = "2026-09-05T10:42:37.923Z" },
]

[[package]]
name = "app"
version = "0.1.0"
source = { virtual = "." }
dependencies = [
    { name = "faker" },
    { name = "flask" },
    { name = "flask-caching" },
    { name = "flask-login" },
    { name = "ollama" },
    { name = "peewee" },
]

[package.metadata]
requires-dist = [
    { name = "faker", specifier = ">=40.40.0" },
    { name = "flask", specifier = ">=3.1.3" },
    { name = "flask-caching", specifier = ">=2.5.1" },
    { name = "flask-login", specifier = ">=0.6.3" },
    { name = "ollama", specifier = ">=0.6.3" },
    { name = "peewee", specifier = ">=4.5.2" },
]

[[package]]
name = "blinker"
version = "1.9.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/21/28/9b3f50ce0e048515135495f198351908d99540d69bfdc8c1d15b73dc55ce/blinker-1.9.0.tar.gz", hash = "sha256:b4ce2265a7abece45e7cc896e98dbebe6cead56bcf805a3d23136d145f5445bf", size = 22460, upload-time = "2024-11-08T17:25:47.436Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/10/cb/f2ad4230dc2eb1a74edf38f1a38b9b52277f75bef262d8908e60d957e13c/blinker-1.9.0-py3-none-any.whl", hash = "sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc", size = 8458, upload-time = "2024-11-08T17:25:46.184Z" },
]

[[package]]
name = "cachelib"
version = "0.17.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/c6/f4/b20875916b83f68775093554ce2544b12255396ba69abd93d8903cce0feb/cachelib-0.17.0.tar.gz", hash = "sha256:f3c7dc8d3c1132ab699681ffdf8a52d341d9425ac1401c538cf0b1d87b1677c8", size = 135529, upload-time = "2026-08-24T00:40:51.851Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/f5/87/9110494f2816d3f2907ac9a0a0a5387f34bc4fa9755721ad09f0a2c99e9b/cachelib-0.17.0-py3-none-any.whl", hash = "sha256:f83909b6f78741c3a5d76d292d13bf24964ffb13e00ea1d18f92e20599766ce0", size = 28221, upload-time = "2026-08-24T00:40:50.237Z" },
]

[[package]]
name = "certifi"
version = "2026.7.22"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/a3/c2/24167ea9858356b47a87a50d39908bfdb72ceeefe0041586e704e5376b3a/certifi-2026.7.22.tar.gz", hash = "sha256:741e2c3b351ddf169a738da9f2c048608ff7f2c5cc02f1ebc6b118bb090d5d55", size = 138112, upload-time = "2026-07-22T03:35:12.644Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/0b/a7/71ac2cff56fec219ed242bb11b8efb69fcc4bec75db06fb7bfe35de520e6/certifi-2026.7.22-py3-none-any.whl", hash = "sha256:62f22742b58a1a33014a2b6b706588a8d7e2a88ae7bd1a6ebe8c992928483775", size = 136983, upload-time = "2026-07-22T03:35:11.276Z" },
]

[[package]]
name = "click"
version = "8.5.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/c7/0e/7fa0ef50764b67090eca4114772a2abf8b6148198475e54c660b97caeee6/click-8.5.0.tar.gz", hash = "sha256:ba0d2089de75ea0310e2dde03160e6ca10009947fb95a182f9b54021bb272e34", size = 382235, upload-time = "2026-08-26T13:33:14.56Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/58/50/6c0d534c5f134586a8e1ba4e330569e32f057e33372ae556463212fb4cd3/click-8.5.0-py3-none-any.whl", hash = "sha256:255bc9599cf7748b4b1a446ccc735421bd08a2ae529a8b88597d3de5664ee360", size = 125251, upload-time = "2026-08-26T13:33:12.928Z" },
]

[[package]]
name = "faker"
version = "40.40.0"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "tzdata", marker = "sys_platform == 'win32'" },
]
sdist = { url = "https://files.pythonhosted.org/packages/43/43/7f5870d05331cb1649704040f51332d37f2468ed857de1e226482e2948b0/faker-40.40.0.tar.gz", hash = "sha256:803ee7f920679e7367c3f7b7f97752f5a9780aa5566c71723fbe57d591beafe1", size = 2029985, upload-time = "2026-09-29T00:56:19.983Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/e1/d2/58beb2b8355f89b483fa21b99fe9934ee7312e3ccf228bb7cefe9e8d979c/faker-40.40.0-py3-none-any.whl", hash = "sha256:cd45ebdd1363f92a45740ac49945e49fa18f7e10771884a83c796a235550d7b7", size = 2066663, upload-time = "2026-09-29T00:56:17.952Z" },
]

[[package]]
name = "flask"
version = "3.1.3"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "blinker" },
    { name = "click" },
    { name = "itsdangerous" },
    { name = "jinja2" },
    { name = "markupsafe" },
    { name = "werkzeug" },
]
sdist = { url = "https://files.pythonhosted.org/packages/26/00/35d85dcce6c57fdc871f3867d465d780f302a175ea360f62533f12b27e2b/flask-3.1.3.tar.gz", hash = "sha256:0ef0e52b8a9cd932855379197dd8f94047b359ca0a78695144304cb45f87c9eb", size = 759004, upload-time = "2026-02-19T05:00:57.678Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/7f/9c/34f6962f9b9e9c71f6e5ed806e0d0ff03c9d1b0b2340088a0cf4bce09b18/flask-3.1.3-py3-none-any.whl", hash = "sha256:f4bcbefc124291925f1a26446da31a5178f9483862233b23c0c96a20701f670c", size = 103424, upload-time = "2026-02-19T05:00:56.027Z" },
]

[[package]]
name = "flask-caching"
version = "2.5.1"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "cachelib" },
    { name = "flask" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a2/74/37c0cfc97444bc639a2854808c55ef61266c3637ab0a64c794b9f6ea1649/flask_caching-2.5.1.tar.gz", hash = "sha256:f75b451fde3faac0e278da72263818134deca8c4ba6bb07b9b3b238991368dae", size = 219102, upload-time = "2026-09-04T18:59:15.541Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/a3/62/e22db0afb98b481878f22c0cec125d29b33948863b4e3f4a083e610c40c7/flask_caching-2.5.1-py3-none-any.whl", hash = "sha256:a8591b0315f033d1f10ba67e318b82b3179e548306195ec08e8f0c5f8ef287bf", size = 35082, upload-time = "2026-09-04T18:59:13.862Z" },
]

[[package]]
name = "flask-login"
version = "0.6.3"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "flask" },
    { name = "werkzeug" },
]
sdist = { url = "https://files.pythonhosted.org/packages/c3/6e/2f4e13e373bb49e68c02c51ceadd22d172715a06716f9299d9df01b6ddb2/Flask-Login-0.6.3.tar.gz", hash = "sha256:5e23d14a607ef12806c699590b89d0f0e0d67baeec599d75947bf9c147330333", size = 48834, upload-time = "2023-10-30T14:53:21.151Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/59/f5/67e9cc5c2036f58115f9fe0f00d203cf6780c3ff8ae0e705e7a9d9e8ff9e/Flask_Login-0.6.3-py3-none-any.whl", hash = "sha256:849b25b82a436bf830a054e74214074af59097171562ab10bfa999e6b78aae5d", size = 17303, upload-time = "2023-10-30T14:53:19.636Z" },
]

[[package]]
name = "h11"
version = "0.16.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz", hash = "sha256:4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1", size = 101250, upload-time = "2025-04-24T03:35:25.427Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/04/4b/29cac41a4d98d144bf5f6d33995617b185d14b22401f75ca86f384e87ff1/h11-0.16.0-py3-none-any.whl", hash = "sha256:63cf8bbe7522de3bf65932fda1d9c2772064ffb3dae62d55932da54b31cb6c86", size = 37515, upload-time = "2025-04-24T03:35:24.344Z" },
]

[[package]]
name = "httpcore"
version = "1.0.9"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "certifi" },
    { name = "h11" },
]
sdist = { url = "https://files.pythonhosted.org/packages/06/94/82699a10bca87a5556c9c59b5963f2d039dbd239f25bc2a63907a05a14cb/httpcore-1.0.9.tar.gz", hash = "sha256:6e34463af53fd2ab5d807f399a9b45ea31c3dfa2276f15a2c3f00afff6e176e8", size = 85484, upload-time = "2025-04-24T22:06:22.219Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/7e/f5/f66802a942d491edb555dd61e3a9961140fd64c90bce1eafd741609d334d/httpcore-1.0.9-py3-none-any.whl", hash = "sha256:2d400746a40668fc9dec9810239072b40b4484b640a8c38fd654a024c7a1bf55", size = 78784, upload-time = "2025-04-24T22:06:20.566Z" },
]

[[package]]
name = "httpx"
version = "0.28.1"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "anyio" },
    { name = "certifi" },
    { name = "httpcore" },
    { name = "idna" },
]
sdist = { url = "https://files.pythonhosted.org/packages/b1/df/48c586a5fe32a0f01324ee087459e112ebb7224f646c0b5023f5e79e9956/httpx-0.28.1.tar.gz", hash = "sha256:75e98c5f16b0f35b567856f597f06ff2270a374470a5c2392242528e3e3e42fc", size = 141406, upload-time = "2024-12-06T15:37:23.222Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/2a/39/e50c7c3a983047577ee07d2a9e53faf5a69493943ec3f6a384bdc792deb2/httpx-0.28.1-py3-none-any.whl", hash = "sha256:d909fcccc110f8c7faf814ca82a9a4d816bc5a6dbfea25d6591d6985b8ba59ad", size = 73517, upload-time = "2024-12-06T15:37:21.509Z" },
]

[[package]]
name = "idna"
version = "3.20"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/f5/08/8eea9d4b8302028f3abb2c0813953f7aec26d33b7a8960ed760e65ff29fa/idna-3.20.tar.gz", hash = "sha256:a7db850025b95ded1eae8a46181a1a6c56c92c96f0e2b005d9ff8dc0210cab44", size = 216463, upload-time = "2026-09-17T14:11:04.752Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/58/a2/bb081bab032533a855d44de1d56f8e8426114ff1ba5d1f07a438a0a654f8/idna-3.20-py3-none-any.whl", hash = "sha256:ab7ae7122974553370f0bdb919e1a960b2cd1bc1ef0276416d896db81c14582c", size = 69583, upload-time = "2026-09-17T14:11:03.168Z" },
]

[[package]]
name = "itsdangerous"
version = "2.2.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/9c/cb/8ac0172223afbccb63986cc25049b154ecfb5e85932587206f42317be31d/itsdangerous-2.2.0.tar.gz", hash = "sha256:e0050c0b7da1eea53ffaf149c0cfbb5c6e2e2b69c4bef22c81fa6eb73e5f6173", size = 54410, upload-time = "2024-04-16T21:28:15.614Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/04/96/92447566d16df59b2a776c0fb82dbc4d9e07cd95062562af01e408583fc4/itsdangerous-2.2.0-py3-none-any.whl", hash = "sha256:c6242fc49e35958c8b15141343aa660db5fc54d4f13a1db01a3f5891b98700ef", size = 16234, upload-time = "2024-04-16T21:28:14.499Z" },
]

[[package]]
name = "jinja2"
version = "3.1.6"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "markupsafe" },
]
sdist = { url = "https://files.pythonhosted.org/packages/df/bf/f7da0350254c0ed7c72f3e33cef02e048281fec7ecec5f032d4aac52226b/jinja2-3.1.6.tar.gz", hash = "sha256:0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d", size = 245115, upload-time = "2025-03-05T20:05:02.478Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/62/a1/3d680cbfd5f4b8f15abc1d571870c5fc3e594bb582bc3b64ea099db13e56/jinja2-3.1.6-py3-none-any.whl", hash = "sha256:85ece4451f492d0c13c5dd7c13a64681a86afae63a5f347908daf103ce6d2f67", size = 134899, upload-time = "2025-03-05T20:05:00.369Z" },
]

[[package]]
name = "markupsafe"
version = "3.0.3"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/7e/99/7690b6d4034fffd95959cbe0c02de8deb3098cc577c67bb6a24fe5d7caa7/markupsafe-3.0.3.tar.gz", hash = "sha256:722695808f4b6457b320fdc131280796bdceb04ab50fe1795cd540799ebe1698", size = 80313, upload-time = "2025-09-27T18:37:40.426Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/08/db/fefacb2136439fc8dd20e797950e749aa1f4997ed584c62cfb8ef7c2be0e/markupsafe-3.0.3-cp311-cp311-macosx_10_9_x86_64.whl", hash = "sha256:1cc7ea17a6824959616c525620e387f6dd30fec8cb44f649e31712db02123dad", size = 11631, upload-time = "2025-09-27T18:36:18.185Z" },
    { url = "https://files.pythonhosted.org/packages/e1/2e/5898933336b61975ce9dc04decbc0a7f2fee78c30353c5efba7f2d6ff27a/markupsafe-3.0.3-cp311-cp311-macosx_11_0_arm64.whl", hash = "sha256:4bd4cd07944443f5a265608cc6aab442e4f74dff8088b0dfc8238647b8f6ae9a", size = 12058, upload-time = "2025-09-27T18:36:19.444Z" },
    { url = "https://files.pythonhosted.org/packages/1d/09/adf2df3699d87d1d8184038df46a9c80d78c0148492323f4693df54e17bb/markupsafe-3.0.3-cp311-cp311-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl", hash = "sha256:6b5420a1d9450023228968e7e6a9ce57f65d148ab56d2313fcd589eee96a7a50", size = 24287, upload-time = "2025-09-27T18:36:20.768Z" },
    { url = "https://files.pythonhosted.org/packages/30/ac/0273f6fcb5f42e314c6d8cd99effae6a5354604d461b8d392b5ec9530a54/markupsafe-3.0.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl", hash = "sha256:0bf2a864d67e76e5c9a34dc26ec616a66b9888e25e7b9460e1c76d3293bd9dbf", size = 22940, upload-time = "2025-09-27T18:36:22.249Z" },
    { url = "https://files.pythonhosted.org/packages/19/ae/31c1be199ef767124c042c6c3e904da327a2f7f0cd63a0337e1eca2967a8/markupsafe-3.0.3-cp311-cp311-manylinux_2_31_riscv64.manylinux_2_39_riscv64.whl", hash = "sha256:bc51efed119bc9cfdf792cdeaa4d67e8f6fcccab66ed4bfdd6bde3e59bfcbb2f", size = 21887, upload-time = "2025-09-27T18:36:23.535Z" },
    { url = "https://files.pythonhosted.org/packages/b2/76/7edcab99d5349a4532a459e1fe64f0b0467a3365056ae550d3bcf3f79e1e/markupsafe-3.0.3-cp311-cp311-musllinux_1_2_aarch64.whl", hash = "sha256:068f375c472b3e7acbe2d5318dea141359e6900156b5b2ba06a30b169086b91a", size = 23692, upload-time = "2025-09-27T18:36:24.823Z" },
    { url = "https://files.pythonhosted.org/packages/a4/28/6e74cdd26d7514849143d69f0bf2399f929c37dc2b31e6829fd2045b2765/markupsafe-3.0.3-cp311-cp311-musllinux_1_2_riscv64.whl", hash = "sha256:7be7b61bb172e1ed687f1754f8e7484f1c8019780f6f6b0786e76bb01c2ae115", size = 21471, upload-time = "2025-09-27T18:36:25.95Z" },
    { url = "https://files.pythonhosted.org/packages/62/7e/a145f36a5c2945673e590850a6f8014318d5577ed7e5920a4b3448e0865d/markupsafe-3.0.3-cp311-cp311-musllinux_1_2_x86_64.whl", hash = "sha256:f9e130248f4462aaa8e2552d547f36ddadbeaa573879158d721bbd33dfe4743a", size = 22923, upload-time = "2025-09-27T18:36:27.109Z" },
    { url = "https://files.pythonhosted.org/packages/0f/62/d9c46a7f5c9adbeeeda52f5b8d802e1094e9717705a645efc71b0913a0a8/markupsafe-3.0.3-cp311-cp311-win32.whl", hash = "sha256:0db14f5dafddbb6d9208827849fad01f1a2609380add406671a26386cdf15a19", size = 14572, upload-time = "2025-09-27T18:36:28.045Z" },
    { url = "https://files.pythonhosted.org/packages/83/8a/4414c03d3f891739326e1783338e48fb49781cc915b2e0ee052aa490d586/markupsafe-3.0.3-cp311-cp311-win_amd64.whl", hash = "sha256:de8a88e63464af587c950061a5e6a67d3632e36df62b986892331d4620a35c01", size = 15077, upload-time = "2025-09-27T18:36:29.025Z" },
    { url = "https://files.pythonhosted.org/packages/35/73/893072b42e6862f319b5207adc9ae06070f095b358655f077f69a35601f0/markupsafe-3.0.3-cp311-cp311-win_arm64.whl", hash = "sha256:3b562dd9e9ea93f13d53989d23a7e775fdfd1066c33494ff43f5418bc8c58a5c", size = 13876, upload-time = "2025-09-27T18:36:29.954Z" },
    { url = "https://files.pythonhosted.org/packages/5a/72/147da192e38635ada20e0a2e1a51cf8823d2119ce8883f7053879c2199b5/markupsafe-3.0.3-cp312-cp312-macosx_10_13_x86_64.whl", hash = "sha256:d53197da72cc091b024dd97249dfc7794d6a56530370992a5e1a08983ad9230e", size = 11615, upload-time = "2025-09-27T18:36:30.854Z" },
    { url = "https://files.pythonhosted.org/packages/9a/81/7e4e08678a1f98521201c3079f77db69fb552acd56067661f8c2f534a718/markupsafe-3.0.3-cp312-cp312-macosx_11_0_arm64.whl", hash = "sha256:1872df69a4de6aead3491198eaf13810b565bdbeec3ae2dc8780f14458ec73ce", size = 12020, upload-time = "2025-09-27T18:36:31.971Z" },
    { url = "https://files.pythonhosted.org/packages/1e/2c/799f4742efc39633a1b54a92eec4082e4f815314869865d876824c257c1e/markupsafe-3.0.3-cp312-cp312-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl", hash = "sha256:3a7e8ae81ae39e62a41ec302f972ba6ae23a5c5396c8e60113e9066ef893da0d", size = 24332, upload-time = "2025-09-27T18:36:32.813Z" },
    { url = "https://files.pythonhosted.org/packages/3c/2e/8d0c2ab90a8c1d9a24f0399058ab8519a3279d1bd4289511d74e909f060e/markupsafe-3.0.3-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl", hash = "sha256:d6dd0be5b5b189d31db7cda48b91d7e0a9795f31430b7f271219ab30f1d3ac9d", size = 22947, upload-time = "2025-09-27T18:36:33.86Z" },
    { url = "https://files.pythonhosted.org/packages/2c/54/887f3092a85238093a0b2154bd629c89444f395618842e8b0c41783898ea/markupsafe-3.0.3-cp312-cp312-manylinux_2_31_riscv64.manylinux_2_39_riscv64.whl", hash = "sha256:94c6f0bb423f739146aec64595853541634bde58b2135f27f61c1ffd1cd4d16a", size = 21962, upload-time = "2025-09-27T18:36:35.099Z" },
    { url = "https://files.pythonhosted.org/packages/c9/2f/336b8c7b6f4a4d95e91119dc8521402461b74a485558d8f238a68312f11c/markupsafe-3.0.3-cp312-cp312-musllinux_1_2_aarch64.whl", hash = "sha256:be8813b57049a7dc738189df53d69395eba14fb99345e0a5994914a3864c8a4b", size = 23760, upload-time = "2025-09-27T18:36:36.001Z" },
    { url = "https://files.pythonhosted.org/packages/32/43/67935f2b7e4982ffb50a4d169b724d74b62a3964bc1a9a527f5ac4f1ee2b/markupsafe-3.0.3-cp312-cp312-musllinux_1_2_riscv64.whl", hash = "sha256:83891d0e9fb81a825d9a6d61e3f07550ca70a076484292a70fde82c4b807286f", size = 21529, upload-time = "2025-09-27T18:36:36.906Z" },
    { url = "https://files.pythonhosted.org/packages/89/e0/4486f11e51bbba8b0c041098859e869e304d1c261e59244baa3d295d47b7/markupsafe-3.0.3-cp312-cp312-musllinux_1_2_x86_64.whl", hash = "sha256:77f0643abe7495da77fb436f50f8dab76dbc6e5fd25d39589a0f1fe6548bfa2b", size = 23015, upload-time = "2025-09-27T18:36:37.868Z" },
    { url = "https://files.pythonhosted.org/packages/2f/e1/78ee7a023dac597a5825441ebd17170785a9dab23de95d2c7508ade94e0e/markupsafe-3.0.3-cp312-cp312-win32.whl", hash = "sha256:d88b440e37a16e651bda4c7c2b930eb586fd15ca7406cb39e211fcff3bf3017d", size = 14540, upload-time = "2025-09-27T18:36:38.761Z" },
    { url = "https://files.pythonhosted.org/packages/aa/5b/bec5aa9bbbb2c946ca2733ef9c4ca91c91b6a24580193e891b5f7dbe8e1e/markupsafe-3.0.3-cp312-cp312-win_amd64.whl", hash = "sha256:26a5784ded40c9e318cfc2bdb30fe164bdb8665ded9cd64d500a34fb42067b1c", size = 15105, upload-time = "2025-09-27T18:36:39.701Z" },
    { url = "https://files.pythonhosted.org/packages/e5/f1/216fc1bbfd74011693a4fd837e7026152e89c4bcf3e77b6692fba9923123/markupsafe-3.0.3-cp312-cp312-win_arm64.whl", hash = "sha256:35add3b638a5d900e807944a078b51922212fb3dedb01633a8defc4b01a3c85f", size = 13906, upload-time = "2025-09-27T18:36:40.689Z" },
    { url = "https://files.pythonhosted.org/packages/38/2f/907b9c7bbba283e68f20259574b13d005c121a0fa4c175f9bed27c4597ff/markupsafe-3.0.3-cp313-cp313-macosx_10_13_x86_64.whl", hash = "sha256:e1cf1972137e83c5d4c136c43ced9ac51d0e124706ee1c8aa8532c1287fa8795", size = 11622, upload-time = "2025-09-27T18:36:41.777Z" },
    { url = "https://files.pythonhosted.org/packages/9c/d9/5f7756922cdd676869eca1c4e3c0cd0df60ed30199ffd775e319089cb3ed/markupsafe-3.0.3-cp313-cp313-macosx_11_0_arm64.whl", hash = "sha256:116bb52f642a37c115f517494ea5feb03889e04df47eeff5b130b1808ce7c219", size = 12029, upload-time = "2025-09-27T18:36:43.257Z" },
    { url = "https://files.pythonhosted.org/packages/00/07/575a68c754943058c78f30db02ee03a64b3c638586fba6a6dd56830b30a3/markupsafe-3.0.3-cp313-cp313-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl", hash = "sha256:133a43e73a802c5562be9bbcd03d090aa5a1fe899db609c29e8c8d815c5f6de6", size = 24374, upload-time = "2025-09-27T18:36:44.508Z" },
    { url = "https://files.pythonhosted.org/packages/a9/21/9b05698b46f218fc0e118e1f8168395c65c8a2c750ae2bab54fc4bd4e0e8/markupsafe-3.0.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl", hash = "sha256:ccfcd093f13f0f0b7fdd0f198b90053bf7b2f02a3927a30e63f3ccc9df56b676", size = 22980, upload-time = "2025-09-27T18:36:45.385Z" },
    { url = "https://files.pythonhosted.org/packages/7f/71/544260864f893f18b6827315b988c146b559391e6e7e8f7252839b1b846a/markupsafe-3.0.3-cp313-cp313-manylinux_2_31_riscv64.manylinux_2_39_riscv64.whl", hash = "sha256:509fa21c6deb7a7a273d629cf5ec029bc209d1a51178615ddf718f5918992ab9", size = 21990, upload-time = "2025-09-27T18:36:46.916Z" },
    { url = "https://files.pythonhosted.org/packages/c2/28/b50fc2f74d1ad761af2f5dcce7492648b983d00a65b8c0e0cb457c82ebbe/markupsafe-3.0.3-cp313-cp313-musllinux_1_2_aarch64.whl", hash = "sha256:a4afe79fb3de0b7097d81da19090f4df4f8d3a2b3adaa8764138aac2e44f3af1", size = 23784, upload-time = "2025-09-27T18:36:47.884Z" },
    { url = "https://files.pythonhosted.org/packages/ed/76/104b2aa106a208da8b17a2fb72e033a5a9d7073c68f7e508b94916ed47a9/markupsafe-3.0.3-cp313-cp313-musllinux_1_2_riscv64.whl", hash = "sha256:795e7751525cae078558e679d646ae45574b47ed6e7771863fcc079a6171a0fc", size = 21588, upload-time = "2025-09-27T18:36:48.82Z" },
    { url = "https://files.pythonhosted.org/packages/b5/99/16a5eb2d140087ebd97180d95249b00a03aa87e29cc224056274f2e45fd6/markupsafe-3.0.3-cp313-cp313-musllinux_1_2_x86_64.whl", hash = "sha256:8485f406a96febb5140bfeca44a73e3ce5116b2501ac54fe953e488fb1d03b12", size = 23041, upload-time = "2025-09-27T18:36:49.797Z" },
    { url = "https://files.pythonhosted.org/packages/19/bc/e7140ed90c5d61d77cea142eed9f9c303f4c4806f60a1044c13e3f1471d0/markupsafe-3.0.3-cp313-cp313-win32.whl", hash = "sha256:bdd37121970bfd8be76c5fb069c7751683bdf373db1ed6c010162b2a130248ed", size = 14543, upload-time = "2025-09-27T18:36:51.584Z" },
    { url = "https://files.pythonhosted.org/packages/05/73/c4abe620b841b6b791f2edc248f556900667a5a1cf023a6646967ae98335/markupsafe-3.0.3-cp313-cp313-win_amd64.whl", hash = "sha256:9a1abfdc021a164803f4d485104931fb8f8c1efd55bc6b748d2f5774e78b62c5", size = 15113, upload-time = "2025-09-27T18:36:52.537Z" },
    { url = "https://files.pythonhosted.org/packages/f0/3a/fa34a0f7cfef23cf9500d68cb7c32dd64ffd58a12b09225fb03dd37d5b80/markupsafe-3.0.3-cp313-cp313-win_arm64.whl", hash = "sha256:7e68f88e5b8799aa49c85cd116c932a1ac15caaa3f5db09087854d218359e485", size = 13911, upload-time = "2025-09-27T18:36:53.513Z" },
    { url = "https://files.pythonhosted.org/packages/e4/d7/e05cd7efe43a88a17a37b3ae96e79a19e846f3f456fe79c57ca61356ef01/markupsafe-3.0.3-cp313-cp313t-macosx_10_13_x86_64.whl", hash = "sha256:218551f6df4868a8d527e3062d0fb968682fe92054e89978594c28e642c43a73", size = 11658, upload-time = "2025-09-27T18:36:54.819Z" },
    { url = "https://files.pythonhosted.org/packages/99/9e/e412117548182ce2148bdeacdda3bb494260c0b0184360fe0d56389b523b/markupsafe-3.0.3-cp313-cp313t-macosx_11_0_arm64.whl", hash = "sha256:3524b778fe5cfb3452a09d31e7b5adefeea8c5be1d43c4f810ba09f2ceb29d37", size = 12066, upload-time = "2025-09-27T18:36:55.714Z" },
    { url = "https://files.pythonhosted.org/packages/bc/e6/fa0ffcda717ef64a5108eaa7b4f5ed28d56122c9a6d70ab8b72f9f715c80/markupsafe-3.0.3-cp313-cp313t-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl", hash = "sha256:4e885a3d1efa2eadc93c894a21770e4bc67899e3543680313b09f139e149ab19", size = 25639, upload-time = "2025-09-27T18:36:56.908Z" },
    { url = "https://files.pythonhosted.org/packages/96/ec/2102e881fe9d25fc16cb4b25d5f5cde50970967ffa5dddafdb771237062d/markupsafe-3.0.3-cp313-cp313t-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl", hash = "sha256:8709b08f4a89aa7586de0aadc8da56180242ee0ada3999749b183aa23df95025", size = 23569, upload-time = "2025-09-27T18:36:57.913Z" },
    { url = "https://files.pythonhosted.org/packages/4b/30/6f2fce1f1f205fc9323255b216ca8a235b15860c34b6798f810f05828e32/markupsafe-3.0.3-cp313-cp313t-manylinux_2_31_riscv64.manylinux_2_39_riscv64.whl", hash = "sha256:b8512a91625c9b3da6f127803b166b629725e68af71f8184ae7e7d54686a56d6", size = 23284, upload-time = "2025-09-27T18:36:58.833Z" },
    { url = "https://files.pythonhosted.org/packages/58/47/4a0ccea4ab9f5dcb6f79c0236d954acb382202721e704223a8aafa38b5c8/markupsafe-3.0.3-cp313-cp313t-musllinux_1_2_aarch64.whl", hash = "sha256:9b79b7a16f7fedff2495d684f2b59b0457c3b493778c9eed31111be64d58279f", size = 24801, upload-time = "2025-09-27T18:36:59.739Z" },
    { url = "https://files.pythonhosted.org/packages/6a/70/3780e9b72180b6fecb83a4814d84c3bf4b4ae4bf0b19c27196104149734c/markupsafe-3.0.3-cp313-cp313t-musllinux_1_2_riscv64.whl", hash = "sha256:12c63dfb4a98206f045aa9563db46507995f7ef6d83b2f68eda65c307c6829eb", size = 22769, upload-time = "2025-09-27T18:37:00.719Z" },
    { url = "https://files.pythonhosted.org/packages/98/c5/c03c7f4125180fc215220c035beac6b9cb684bc7a067c84fc69414d315f5/markupsafe-3.0.3-cp313-cp313t-musllinux_1_2_x86_64.whl", hash = "sha256:8f71bc33915be5186016f675cd83a1e08523649b0e33efdb898db577ef5bb009", size = 23642, upload-time = "2025-09-27T18:37:01.673Z" },
    { url = "https://files.pythonhosted.org/packages/80/d6/2d1b89f6ca4bff1036499b1e29a1d02d282259f3681540e16563f27ebc23/markupsafe-3.0.3-cp313-cp313t-win32.whl", hash = "sha256:69c0b73548bc525c8cb9a251cddf1931d1db4d2258e9599c28c07ef3580ef354", size = 14612, upload-time = "2025-09-27T18:37:02.639Z" },
    { url = "https://files.pythonhosted.org/packages/2b/98/e48a4bfba0a0ffcf9925fe2d69240bfaa19c6f7507b8cd09c70684a53c1e/markupsafe-3.0.3-cp313-cp313t-win_amd64.whl", hash = "sha256:1b4b79e8ebf6b55351f0d91fe80f893b4743f104bff22e90697db1590e47a218", size = 15200, upload-time = "2025-09-27T18:37:03.582Z" },
    { url = "https://files.pythonhosted.org/packages/0e/72/e3cc540f351f316e9ed0f092757459afbc595824ca724cbc5a5d4263713f/markupsafe-3.0.3-cp313-cp313t-win_arm64.whl", hash = "sha256:ad2cf8aa28b8c020ab2fc8287b0f823d0a7d8630784c31e9ee5edea20f406287", size = 13973, upload-time = "2025-09-27T18:37:04.929Z" },
    { url = "https://files.pythonhosted.org/packages/33/8a/8e42d4838cd89b7dde187011e97fe6c3af66d8c044997d2183fbd6d31352/markupsafe-3.0.3-cp314-cp314-macosx_10_13_x86_64.whl", hash = "sha256:eaa9599de571d72e2daf60164784109f19978b327a3910d3e9de8c97b5b70cfe", size = 11619, upload-time = "2025-09-27T18:37:06.342Z" },
    { url = "https://files.pythonhosted.org/packages/b5/64/7660f8a4a8e53c924d0fa05dc3a55c9cee10bbd82b11c5afb27d44b096ce/markupsafe-3.0.3-cp314-cp314-macosx_11_0_arm64.whl", hash = "sha256:c47a551199eb8eb2121d4f0f15ae0f923d31350ab9280078d1e5f12b249e0026", size = 12029, upload-time = "2025-09-27T18:37:07.213Z" },
    { url = "https://files.pythonhosted.org/packages/da/ef/e648bfd021127bef5fa12e1720ffed0c6cbb8310c8d9bea7266337ff06de/markupsafe-3.0.3-cp314-cp314-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl", hash = "sha256:f34c41761022dd093b4b6896d4810782ffbabe30f2d443ff5f083e0cbbb8c737", size = 24408, upload-time = "2025-09-27T18:37:09.572Z" },
    { url = "https://files.pythonhosted.org/packages/41/3c/a36c2450754618e62008bf7435ccb0f88053e07592e6028a34776213d877/markupsafe-3.0.3-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl", hash = "sha256:457a69a9577064c05a97c41f4e65148652db078a3a509039e64d3467b9e7ef97", size = 23005, upload-time = "2025-09-27T18:37:10.58Z" },
    { url = "https://files.pythonhosted.org/packages/bc/20/b7fdf89a8456b099837cd1dc21974632a02a999ec9bf7ca3e490aacd98e7/markupsafe-3.0.3-cp314-cp314-manylinux_2_31_riscv64.manylinux_2_39_riscv64.whl", hash = "sha256:e8afc3f2ccfa24215f8cb28dcf43f0113ac3c37c2f0f0806d8c70e4228c5cf4d", size = 22048, upload-time = "2025-09-27T18:37:11.547Z" },
    { url = "https://files.pythonhosted.org/packages/9a/a7/591f592afdc734f47db08a75793a55d7fbcc6902a723ae4cfbab61010cc5/markupsafe-3.0.3-cp314-cp314-musllinux_1_2_aarch64.whl", hash = "sha256:ec15a59cf5af7be74194f7ab02d0f59a62bdcf1a537677ce67a2537c9b87fcda", size = 23821, upload-time = "2025-09-27T18:37:12.48Z" },
    { url = "https://files.pythonhosted.org/packages/7d/33/45b24e4f44195b26521bc6f1a82197118f74df348556594bd2262bda1038/markupsafe-3.0.3-cp314-cp314-musllinux_1_2_riscv64.whl", hash = "sha256:0eb9ff8191e8498cca014656ae6b8d61f39da5f95b488805da4bb029cccbfbaf", size = 21606, upload-time = "2025-09-27T18:37:13.485Z" },
    { url = "https://files.pythonhosted.org/packages/ff/0e/53dfaca23a69fbfbbf17a4b64072090e70717344c52eaaaa9c5ddff1e5f0/markupsafe-3.0.3-cp314-cp314-musllinux_1_2_x86_64.whl", hash = "sha256:2713baf880df847f2bece4230d4d094280f4e67b1e813eec43b4c0e144a34ffe", size = 23043, upload-time = "2025-09-27T18:37:14.408Z" },
    { url = "https://files.pythonhosted.org/packages/46/11/f333a06fc16236d5238bfe74daccbca41459dcd8d1fa952e8fbd5dccfb70/markupsafe-3.0.3-cp314-cp314-win32.whl", hash = "sha256:729586769a26dbceff69f7a7dbbf59ab6572b99d94576a5592625d5b411576b9", size = 14747, upload-time = "2025-09-27T18:37:15.36Z" },
    { url = "https://files.pythonhosted.org/packages/28/52/182836104b33b444e400b14f797212f720cbc9ed6ba34c800639d154e821/markupsafe-3.0.3-cp314-cp314-win_amd64.whl", hash = "sha256:bdc919ead48f234740ad807933cdf545180bfbe9342c2bb451556db2ed958581", size = 15341, upload-time = "2025-09-27T18:37:16.496Z" },
    { url = "https://files.pythonhosted.org/packages/6f/18/acf23e91bd94fd7b3031558b1f013adfa21a8e407a3fdb32745538730382/markupsafe-3.0.3-cp314-cp314-win_arm64.whl", hash = "sha256:5a7d5dc5140555cf21a6fefbdbf8723f06fcd2f63ef108f2854de715e4422cb4", size = 14073, upload-time = "2025-09-27T18:37:17.476Z" },
    { url = "https://files.pythonhosted.org/packages/3c/f0/57689aa4076e1b43b15fdfa646b04653969d50cf30c32a102762be2485da/markupsafe-3.0.3-cp314-cp314t-macosx_10_13_x86_64.whl", hash = "sha256:1353ef0c1b138e1907ae78e2f6c63ff67501122006b0f9abad68fda5f4ffc6ab", size = 11661, upload-time = "2025-09-27T18:37:18.453Z" },
    { url = "https://files.pythonhosted.org/packages/89/c3/2e67a7ca217c6912985ec766c6393b636fb0c2344443ff9d91404dc4c79f/markupsafe-3.0.3-cp314-cp314t-macosx_11_0_arm64.whl", hash = "sha256:1085e7fbddd3be5f89cc898938f42c0b3c711fdcb37d75221de2666af647c175", size = 12069, upload-time = "2025-09-27T18:37:19.332Z" },
    { url = "https://files.pythonhosted.org/packages/f0/00/be561dce4e6ca66b15276e184ce4b8aec61fe83662cce2f7d72bd3249d28/markupsafe-3.0.3-cp314-cp314t-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl", hash = "sha256:1b52b4fb9df4eb9ae465f8d0c228a00624de2334f216f178a995ccdcf82c4634", size = 25670, upload-time = "2025-09-27T18:37:20.245Z" },
    { url = "https://files.pythonhosted.org/packages/50/09/c419f6f5a92e5fadde27efd190eca90f05e1261b10dbd8cbcb39cd8ea1dc/markupsafe-3.0.3-cp314-cp314t-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl", hash = "sha256:fed51ac40f757d41b7c48425901843666a6677e3e8eb0abcff09e4ba6e664f50", size = 23598, upload-time = "2025-09-27T18:37:21.177Z" },
    { url = "https://files.pythonhosted.org/packages/22/44/a0681611106e0b2921b3033fc19bc53323e0b50bc70cffdd19f7d679bb66/markupsafe-3.0.3-cp314-cp314t-manylinux_2_31_riscv64.manylinux_2_39_riscv64.whl", hash = "sha256:f190daf01f13c72eac4efd5c430a8de82489d9cff23c364c3ea822545032993e", size = 23261, upload-time = "2025-09-27T18:37:22.167Z" },
    { url = "https://files.pythonhosted.org/packages/5f/57/1b0b3f100259dc9fffe780cfb60d4be71375510e435efec3d116b6436d43/markupsafe-3.0.3-cp314-cp314t-musllinux_1_2_aarch64.whl", hash = "sha256:e56b7d45a839a697b5eb268c82a71bd8c7f6c94d6fd50c3d577fa39a9f1409f5", size = 24835, upload-time = "2025-09-27T18:37:23.296Z" },
    { url = "https://files.pythonhosted.org/packages/26/6a/4bf6d0c97c4920f1597cc14dd720705eca0bf7c787aebc6bb4d1bead5388/markupsafe-3.0.3-cp314-cp314t-musllinux_1_2_riscv64.whl", hash = "sha256:f3e98bb3798ead92273dc0e5fd0f31ade220f59a266ffd8a4f6065e0a3ce0523", size = 22733, upload-time = "2025-09-27T18:37:24.237Z" },
    { url = "https://files.pythonhosted.org/packages/14/c7/ca723101509b518797fedc2fdf79ba57f886b4aca8a7d31857ba3ee8281f/markupsafe-3.0.3-cp314-cp314t-musllinux_1_2_x86_64.whl", hash = "sha256:5678211cb9333a6468fb8d8be0305520aa073f50d17f089b5b4b477ea6e67fdc", size = 23672, upload-time = "2025-09-27T18:37:25.271Z" },
    { url = "https://files.pythonhosted.org/packages/fb/df/5bd7a48c256faecd1d36edc13133e51397e41b73bb77e1a69deab746ebac/markupsafe-3.0.3-cp314-cp314t-win32.whl", hash = "sha256:915c04ba3851909ce68ccc2b8e2cd691618c4dc4c4232fb7982bca3f41fd8c3d", size = 14819, upload-time = "2025-09-27T18:37:26.285Z" },
    { url = "https://files.pythonhosted.org/packages/1a/8a/0402ba61a2f16038b48b39bccca271134be00c5c9f0f623208399333c448/markupsafe-3.0.3-cp314-cp314t-win_amd64.whl", hash = "sha256:4faffd047e07c38848ce017e8725090413cd80cbc23d86e55c587bf979e579c9", size = 15426, upload-time = "2025-09-27T18:37:27.316Z" },
    { url = "https://files.pythonhosted.org/packages/70/bc/6f1c2f612465f5fa89b95bead1f44dcb607670fd42891d8fdcd5d039f4f4/markupsafe-3.0.3-cp314-cp314t-win_arm64.whl", hash = "sha256:32001d6a8fc98c8cb5c947787c5d08b0a50663d139f1305bac5885d98d9b40fa", size = 14146, upload-time = "2025-09-27T18:37:28.327Z" },
]

[[package]]
name = "ollama"
version = "0.6.3"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "httpx" },
    { name = "pydantic" },
]
sdist = { url = "https://files.pythonhosted.org/packages/b8/97/eeafe65594e4f4b25e443e068ef7d83aa3105b023e12e1c408c38669fc07/ollama-0.6.3.tar.gz", hash = "sha256:41fc49a8095c4a75939c4c1f8582e4d0671692fb6eac2a5a7ede8c9872b67096", size = 56868, upload-time = "2026-09-29T01:26:51.906Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/4d/64/87505d9e006461233c21c8e66dc1ecee49c996090584b216abd0dd4a8322/ollama-0.6.3-py3-none-any.whl", hash = "sha256:6a20bc42c1a5f889295d7ec490d35e5132fc31f339561530f43a8abd4dbfe508", size = 16603, upload-time = "2026-09-29T01:26:50.451Z" },
]

[[package]]
name = "peewee"
version = "4.5.2"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/38/84/bd871d2a3d8a7a1eac8cdb586aacd9e89c52f57cc360c1e565cb52433f66/peewee-4.5.2.tar.gz", hash = "sha256:10724cf1a6bda2bcdc4da17c376e6ed1d875f16dcabbb42594123cba1304d598", size = 823227, upload-time = "2026-09-27T19:20:13.562Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/c7/9d/7ce9daf923fbe2a61069a7ffc8907f1207d667bb04169f0a97fa049be41e/peewee-4.5.2-py3-none-any.whl", hash = "sha256:a7765c76834c84799b533aeaa0afeebdcd123b894faefbcebe495fbf4c7548ba", size = 194163, upload-time = "2026-09-27T19:20:11.977Z" },
]

[[package]]
name = "pydantic"
version = "2.13.5"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "annotated-types" },
    { name = "pydantic-core" },
    { name = "typing-extensions" },
    { name = "typing-inspection" },
]
sdist = { url = "https://files.pythonhosted.org/packages/53/ef/fc4f868f4e2cee79f863883abffceff107875f569b848507319842d2a681/pydantic-2.13.5.tar.gz", hash = "sha256:51a9c5f7b2f8e636f04c6cada605d9b6a3bf1348fdf945a3d8869b19bba0ee08", size = 845750, upload-time = "2026-08-28T14:04:00.916Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/eb/47/c95ffc2009878c7aac0c5e08528022dcb885933252a88b5f170058014464/pydantic-2.13.5-py3-none-any.whl", hash = "sha256:346a034f080da3755d8e9cb5e00e8b07de1d39e4f6e2c87d8ab7cafa0b269a73", size = 472589, upload-time = "2026-08-28T14:03:59.136Z" },
]

[[package]]
name = "pydantic-core"
version = "2.46.5"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "typing-extensions" },
]
sdist = { url = "https://files.pythonhosted.org/packages/af/f9/8a06bea35ef8daf588f707784c973a7046e0034c8d8cfb08828eeffb8b75/pydantic_core-2.46.5.tar.gz", hash = "sha256:10416c15b8839ecc4ef4d0885da76da6fd0f67333a0eb8aff6d93c4b8f2910fc", size = 472262, upload-time = "2026-08-28T10:01:31.677Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/a2/b6/81d2d19ea0be2c03664381b59f65fa72fc7969decedae00bc2c4ad835708/pydantic_core-2.46.5-cp311-cp311-macosx_10_12_x86_64.whl", hash = "sha256:a1dee1b804ff4d11c663636cf15d2ea47e9f79cd56c033fb1cbf08924842a48f", size = 2074737, upload-time = "2026-08-28T09:57:57.711Z" },
    { url = "https://files.pythonhosted.org/packages/0c/18/b70da8300e292df4099684ea11b1958043580d2f50d2dc8bf7e542bdd84a/pydantic_core-2.46.5-cp311-cp311-macosx_11_0_arm64.whl", hash = "sha256:d625a186a65201c23a9e3b8ed9c47e90a026e03256608cc91851c6709096844f", size = 1921751, upload-time = "2026-08-28T09:57:59.265Z" },
    { url = "https://files.pythonhosted.org/packages/e7/1a/0d590341b6ffa4b4aca83508e6b8db4761aaeacfc15a25ca3815876d4797/pydantic_core-2.46.5-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:4f8507560a9284e1370bb048ed4282012fbef4e8d109875b95e884d228552061", size = 1948231, upload-time = "2026-08-28T09:58:00.678Z" },
    { url = "https://files.pythonhosted.org/packages/7d/1d/02eb35761c51f2f7b1b042d6ab4cda6600f0c8c88a2243b3f734376201e5/pydantic_core-2.46.5-cp311-cp311-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:5f93c5fe914d75fbec9a49209b00da5f08e9e467d69da2b1510c81940cfd10be", size = 2020708, upload-time = "2026-08-28T09:58:02.267Z" },
    { url = "https://files.pythonhosted.org/packages/4a/ea/f86073830e35d508cc8ddf9c3d9e6e6840fcb88d34bf726b0b4710186f27/pydantic_core-2.46.5-cp311-cp311-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:aca6c767f552b21b10f774aeac128e828eafb796adfa1b666a18bf6321453c3a", size = 2194914, upload-time = "2026-08-28T09:58:03.934Z" },
    { url = "https://files.pythonhosted.org/packages/bb/d7/fc36240d7791ce90939e51608568c33bfdae26202016f9770c229a487d86/pydantic_core-2.46.5-cp311-cp311-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:701b2e04b560eeb4bddf7a25ab8ca476176e34fdbd9a0e18196f0d12d4685f0b", size = 2235622, upload-time = "2026-08-28T09:58:05.516Z" },
    { url = "https://files.pythonhosted.org/packages/cf/bc/3fa2d76b83162820a17da7f645b28d1cba99fc8e1e5fc6517067ec450fa1/pydantic_core-2.46.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:49776eab08766a08dfff7012f8b422dcd7e25e43b316eedf0477c24fcfa84b7c", size = 2062091, upload-time = "2026-08-28T09:58:07.135Z" },
    { url = "https://files.pythonhosted.org/packages/ab/9a/095d557bb492c90cd8a70a6dd048bf793d433d03d86c81c11e912e4cd049/pydantic_core-2.46.5-cp311-cp311-manylinux_2_31_riscv64.whl", hash = "sha256:a2468d93d181667a7abd66e1b64bb9f76f361b0fef8faddf687456453576f5ee", size = 2089904, upload-time = "2026-08-28T09:58:08.814Z" },
    { url = "https://files.pythonhosted.org/packages/24/98/7b76b1ad10a19a617a52aaa1d80e159115af939b095e86f8e756fd52e0df/pydantic_core-2.46.5-cp311-cp311-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:53feb344243bb9510a9dec7bf3cf1b64d88a98af5dc7872a5160465f8b198c8e", size = 2132244, upload-time = "2026-08-28T09:58:10.435Z" },
    { url = "https://files.pythonhosted.org/packages/20/32/7d6ca365fadba186a0c8f85de1a701663bce81efd309d9479be58687622f/pydantic_core-2.46.5-cp311-cp311-musllinux_1_1_aarch64.whl", hash = "sha256:cd5214352ae68f3b5e9af7768bdc5253695ee069675db3480518420b3be881f2", size = 2143901, upload-time = "2026-08-28T09:58:12.033Z" },
    { url = "https://files.pythonhosted.org/packages/f8/09/eb9a6aa57f22fd1541a9c0aa2a1f3aeef3ec65347d33e10a6da2f43e0ee9/pydantic_core-2.46.5-cp311-cp311-musllinux_1_1_armv7l.whl", hash = "sha256:9432f3598db432cb51c5b37fdbf29a60fcccc79e30d37a05022776a6bc4ab689", size = 2299425, upload-time = "2026-08-28T09:58:13.614Z" },
    { url = "https://files.pythonhosted.org/packages/8a/f9/548a5bb9d4ba8cd26e26daf48052236f6b38bb61e7b7241fbc3c995719eb/pydantic_core-2.46.5-cp311-cp311-musllinux_1_1_x86_64.whl", hash = "sha256:8feeac04b5794e513e710af2f9c87d49f31a6dc47967bb264a1fed61a8989bec", size = 2318566, upload-time = "2026-08-28T09:58:15.199Z" },
    { url = "https://files.pythonhosted.org/packages/4a/20/06454d18834c02c406c9133f1a3b485305fd9ee984f9636c2f730bef6a9d/pydantic_core-2.46.5-cp311-cp311-win32.whl", hash = "sha256:892a881d5f68c2b9ea304b7a6c2c60d9343df578a311b0f86b94bc8f1ffe8129", size = 1954258, upload-time = "2026-08-28T09:58:16.813Z" },
    { url = "https://files.pythonhosted.org/packages/9e/c2/718b9deb4b72453b5d8c7447a3b14cb77bef36917ef5f514e0948a4096a0/pydantic_core-2.46.5-cp311-cp311-win_amd64.whl", hash = "sha256:40375c2d05acec10323e45dfe2077ac44bc74659008614af5069034e2cfc781c", size = 2041030, upload-time = "2026-08-28T09:58:18.288Z" },
    { url = "https://files.pythonhosted.org/packages/67/ea/c1d1a5b72d6e1ff7f377a4d9199f6591f095beb5b409a8a5d89f7238d939/pydantic_core-2.46.5-cp311-cp311-win_arm64.whl", hash = "sha256:28a6a556cd3b6066bea827857f9d9cce027c96f776e512f544a581f9e42161f8", size = 2009234, upload-time = "2026-08-28T09:58:19.929Z" },
    { url = "https://files.pythonhosted.org/packages/82/3f/76358795aa7a8c6d4f36e2cb828ad1c90ee118e1393a9281664f5aade9d4/pydantic_core-2.46.5-cp312-cp312-macosx_10_12_x86_64.whl", hash = "sha256:b9fe6fb92520e3fd61f2e49000b6911b188824f089b75973ea06d6267f0b476d", size = 2076516, upload-time = "2026-08-28T09:58:21.576Z" },
    { url = "https://files.pythonhosted.org/packages/db/50/26b091836076ce4cb2fac264186936acc069e0595772cfd02a563bc4761a/pydantic_core-2.46.5-cp312-cp312-macosx_11_0_arm64.whl", hash = "sha256:a39ac25a9a2fa4072efdb429833c4a4c8009a51ff9eea3eeae131713cd27991e", size = 1922874, upload-time = "2026-08-28T09:58:23.766Z" },
    { url = "https://files.pythonhosted.org/packages/09/f0/2a8ce3849e299d44e2d2c196b6082643a3235565a735cb51db7a6261f614/pydantic_core-2.46.5-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:4fdc8b93a41521988916eeaa271173fcca7fa0803d62f87675aac8dcec1c8e29", size = 1951772, upload-time = "2026-08-28T09:58:25.435Z" },
    { url = "https://files.pythonhosted.org/packages/87/46/ac0dc8bdd9e6048183a14eb127764e7ad9240021c17513074a4711b0e31e/pydantic_core-2.46.5-cp312-cp312-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:b98134087d9de723658d17a42c7d0da8d6e2ef08015dee7dc93889047315f5e4", size = 2031832, upload-time = "2026-08-28T09:58:27.102Z" },
    { url = "https://files.pythonhosted.org/packages/c4/c2/339de5bef7be36301a2231eaa52e62163742c2281f11b5f4892bc79785cd/pydantic_core-2.46.5-cp312-cp312-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:e652ab17569c94bff5475520f907b7148b8c24036a8ebbe5cf7cf7493d28579a", size = 2208645, upload-time = "2026-08-28T09:58:28.948Z" },
    { url = "https://files.pythonhosted.org/packages/7b/a0/9ff22b797724262da14427abaed4dd1d864a139693fc5e7809114376a716/pydantic_core-2.46.5-cp312-cp312-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:d925f3d9afd05a8c0fb3a1031463a8d59ebe5e2afad297e29c78be19e13b4e62", size = 2265935, upload-time = "2026-08-28T09:58:30.625Z" },
    { url = "https://files.pythonhosted.org/packages/c0/a4/eb9409ec0736e50aa70a412f16c204ed149516846912f7e6724d4c73ee53/pydantic_core-2.46.5-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:0fc5be0abd4a407e200d844b404e33639a554e7bd0d448e7b9ae181be4789ac2", size = 2066284, upload-time = "2026-08-28T09:58:32.289Z" },
    { url = "https://files.pythonhosted.org/packages/c0/02/7f6156ffc926857f1c37c07d9a388682865a81830ab6a1b637082c25e399/pydantic_core-2.46.5-cp312-cp312-manylinux_2_31_riscv64.whl", hash = "sha256:816ff0a6550ffc06c098ccd2e0698600f9aa7da192a79eaa6f9af504a35db869", size = 2105889, upload-time = "2026-08-28T09:58:33.986Z" },
    { url = "https://files.pythonhosted.org/packages/92/b1/e781d357ebe09fc929f995700f1b3503e8897f1cece183ecb1300d4d67e9/pydantic_core-2.46.5-cp312-cp312-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:c7ea57fc63aa7da93a1bd2d644e6577befae10c52c4e36377635eea1056a74f5", size = 2158006, upload-time = "2026-08-28T09:58:35.647Z" },
    { url = "https://files.pythonhosted.org/packages/70/0a/644597d84ab400e50609c192120b85c9681c22d3a20461b9060a79be0a7a/pydantic_core-2.46.5-cp312-cp312-musllinux_1_1_aarch64.whl", hash = "sha256:efd62a42486f1bda5d24cb4f63d15a3c7768375fe83d36f9417b4ad7a2fb20b3", size = 2158408, upload-time = "2026-08-28T09:58:37.38Z" },
    { url = "https://files.pythonhosted.org/packages/1e/ee/ca3b7b3a4b3769ffe9ce9432a7c9be755de9593a46d3b0d54d0409323e44/pydantic_core-2.46.5-cp312-cp312-musllinux_1_1_armv7l.whl", hash = "sha256:2bc9419666990c06d7397831f2126a1ecc3594aaa3ff7de5bf2d066802f4e07b", size = 2309609, upload-time = "2026-08-28T09:58:39.22Z" },
    { url = "https://files.pythonhosted.org/packages/ce/52/39fa1f451486019524ca685020390e7ca351832fd874530ba30c8628e6dc/pydantic_core-2.46.5-cp312-cp312-musllinux_1_1_x86_64.whl", hash = "sha256:18a09e1e1011b462f2e32774f25859ef1223d5c2b0546a633cf56654710721e0", size = 2342618, upload-time = "2026-08-28T09:58:40.89Z" },
    { url = "https://files.pythonhosted.org/packages/81/5e/468fc630568c61dcef3cd47ad32ffbeed9af643f49208d1ea86ab4f890c4/pydantic_core-2.46.5-cp312-cp312-win32.whl", hash = "sha256:5cb482e9e84c851f4e623fe4acc1ced89168cf1fe18f7089db4548c8f5bbb65b", size = 1939475, upload-time = "2026-08-28T09:58:42.591Z" },
    { url = "https://files.pythonhosted.org/packages/cf/c9/4c19f41b84cf6b622a72fbeed7665b25d47a187d68d47d0d430c07f23268/pydantic_core-2.46.5-cp312-cp312-win_amd64.whl", hash = "sha256:5e81740c09e310f5aa5cbd3e434a01c154d4bef93241c7877b39f211d2b78ba8", size = 2043140, upload-time = "2026-08-28T09:58:44.272Z" },
    { url = "https://files.pythonhosted.org/packages/af/dd/0c1a050299147c746e5256db16d645ab5efd4f78c59937d581a0524e74a2/pydantic_core-2.46.5-cp312-cp312-win_arm64.whl", hash = "sha256:f7b0ec93a2893de856652154d73b7ba622f26fa97726487dcac373de5f4c6084", size = 1997729, upload-time = "2026-08-28T09:58:46.13Z" },
    { url = "https://files.pythonhosted.org/packages/f5/37/5abe39a8372a61d3dc3c1338fc504281c01b32fdb3169cd7187153b56d3e/pydantic_core-2.46.5-cp313-cp313-macosx_10_12_x86_64.whl", hash = "sha256:b7ca9034437b6022f941f4857459562ee00a560b97e7cce8a0ec5a74fc6766e0", size = 2075885, upload-time = "2026-08-28T09:58:47.856Z" },
    { url = "https://files.pythonhosted.org/packages/21/43/6323b1f8b217780454c61304bcd2b38ae4762f50754414124603ccc90bb2/pydantic_core-2.46.5-cp313-cp313-macosx_11_0_arm64.whl", hash = "sha256:f332f0e72a5a0400141f830744e141bf9f97917878dbe968669e8a7fefea78ff", size = 1922768, upload-time = "2026-08-28T09:58:49.58Z" },
    { url = "https://files.pythonhosted.org/packages/0f/a3/c05ca796e1197618a774b01e596aeedfefc2f7d8c01ae3054e910b120e8a/pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:193375f3548919d3f0b60936ca113ada3e38f264f91b9b8e0508efaad57be931", size = 1951241, upload-time = "2026-08-28T09:58:51.511Z" },
    { url = "https://files.pythonhosted.org/packages/68/32/33bc39ac705c52cffc908e8389f9754fdb208aea5c69cceddf4eb3ce99af/pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:79bdfa52f843137045b2d081cc05c120ba6665d29b7559c2c47690906f39279f", size = 2031975, upload-time = "2026-08-28T09:58:53.166Z" },
    { url = "https://files.pythonhosted.org/packages/b0/70/2333e885c0f6a67bc105c5916965dac9b57f2718ee20d81d1a06a4ebdc13/pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:24922243639cbdac66c75fcb6fd6495a9cb52b213d62f9a0d16f0310b1ff8038", size = 2208542, upload-time = "2026-08-28T09:58:55.017Z" },
    { url = "https://files.pythonhosted.org/packages/f7/ea/296debfb4264207bbda5936133892e027c0a58875ad53ebd512fba8ec3a2/pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:c76fe65e607be28c7fd4d56fc3c42b1583aa058ce3408b7ad0fd540171d31f9f", size = 2264692, upload-time = "2026-08-28T09:58:56.767Z" },
    { url = "https://files.pythonhosted.org/packages/d3/f2/9e4de77a6271e07a76d2d58b11c091a979c191ed2939bf80067568b369d2/pydantic_core-2.46.5-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:6f7b393a8b3da82f5c1fc0751e6d01ac6c55b93c18226a60bdfba4a724efafd1", size = 2066633, upload-time = "2026-08-28T09:58:58.531Z" },
    { url = "https://files.pythonhosted.org/packages/8d/db/f9e9d0c97445987b2084823d5c240de88087338f04fc2cfaa2df186b8049/pydantic_core-2.46.5-cp313-cp313-manylinux_2_31_riscv64.whl", hash = "sha256:7ac031912d54f3d83ef3b3eb98dfabc1608802e2202263d25957eeed40b94761", size = 2105235, upload-time = "2026-08-28T09:59:00.421Z" },
    { url = "https://files.pythonhosted.org/packages/07/c5/79169b047b3b2c3e99e04bc76372af9637e0bf6db638274fa927df96369e/pydantic_core-2.46.5-cp313-cp313-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:837b396ca3d7b74091ca623f6cbd8351bd42d670a79c2683e79fb089f06a2de5", size = 2157367, upload-time = "2026-08-28T09:59:02.442Z" },
    { url = "https://files.pythonhosted.org/packages/26/b5/ba6057afb7c291bd449f51b867f95aef2072941c4ce4e5c31d6ffd132d3b/pydantic_core-2.46.5-cp313-cp313-musllinux_1_1_aarch64.whl", hash = "sha256:5ee239d575f80b08eca11f6e20f90c4c695de7825c67eefe6091fbf20dda648e", size = 2158420, upload-time = "2026-08-28T09:59:04.2Z" },
    { url = "https://files.pythonhosted.org/packages/6e/28/2057abecaafdc22912afa819603a51f0a62d40643b7c4871c51721fea9be/pydantic_core-2.46.5-cp313-cp313-musllinux_1_1_armv7l.whl", hash = "sha256:e80675d75ae2cd14372cb65cad5400d9347a3d3f6c13000183f22dfd027283ed", size = 2309588, upload-time = "2026-08-28T09:59:06.048Z" },
    { url = "https://files.pythonhosted.org/packages/71/9d/881156dc404e27479c4246128d73538464cab4a239bec61995e227644c30/pydantic_core-2.46.5-cp313-cp313-musllinux_1_1_x86_64.whl", hash = "sha256:9c4b71f10dd532fb7a5cbc8f58707779e64f03a258c2bf8bfbaecfcd9970b519", size = 2341866, upload-time = "2026-08-28T09:59:08.539Z" },
    { url = "https://files.pythonhosted.org/packages/5a/38/d66f443a259f84d13babdceae568e572b0ed26da17ca5d0a649ebb110a67/pydantic_core-2.46.5-cp313-cp313-win32.whl", hash = "sha256:97bf8de4d541598c94a59344eeb988a94c08ff76b5723c41f6567ec18c7892ea", size = 1938580, upload-time = "2026-08-28T09:59:10.402Z" },
    { url = "https://files.pythonhosted.org/packages/2c/1e/1d5371213f4cc9a7ed70c0bfcc7911de22311ee99a662a56077d7292d2ac/pydantic_core-2.46.5-cp313-cp313-win_amd64.whl", hash = "sha256:15f4a94963c95accac15b7b657bb177d3ad82bb90b0d0526d9a9b85079925db5", size = 2041980, upload-time = "2026-08-28T09:59:12.396Z" },
    { url = "https://files.pythonhosted.org/packages/5a/48/4222d90b1c67568bace4dec6dca6271449c66de3595d72b6d098f5fde597/pydantic_core-2.46.5-cp313-cp313-win_arm64.whl", hash = "sha256:d22a945598fb91236b4dd793a6e42e4f3dd7740bb5aace5ebd7d4c08d13bb575", size = 1997213, upload-time = "2026-08-28T09:59:14.245Z" },
    { url = "https://files.pythonhosted.org/packages/8e/8a/14596f2a8367da50cf7cbac48169ee5d9c8e11d486a3b527082384630c72/pydantic_core-2.46.5-cp314-cp314-macosx_10_12_x86_64.whl", hash = "sha256:c1c43ad4339643d70ebb8124e1305a7dab423001eff58bb41a0f731adbc98355", size = 2074081, upload-time = "2026-08-28T09:59:16.141Z" },
    { url = "https://files.pythonhosted.org/packages/ae/d5/d8a4eb6d6c7f66b91dd37c576d76e9e60fba900caf5372c17bcf949febc2/pydantic_core-2.46.5-cp314-cp314-macosx_11_0_arm64.whl", hash = "sha256:1a353f84de772f423b5ffb11d7ae352fbbef0f446f3c0b0af0f8236d7233606e", size = 1920497, upload-time = "2026-08-28T09:59:18.065Z" },
    { url = "https://files.pythonhosted.org/packages/8e/26/092079428f86e927e030b2c0ced87df69dbb1c875cdeaa67bf42ea2be746/pydantic_core-2.46.5-cp314-cp314-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:5086029a57366b8cf81b130a43908738095c270c21a8d7f0e8bdfdb89718e2f3", size = 1952130, upload-time = "2026-08-28T09:59:20.476Z" },
    { url = "https://files.pythonhosted.org/packages/08/c3/8ec0e290a9ebaebd64047bf5fda94be835c6b1551b02437e4b76778fbcd7/pydantic_core-2.46.5-cp314-cp314-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:46c25dda9d092a06c08db76ffe0a197107904d0dfac653f7d5306bbcd6d6119c", size = 2026371, upload-time = "2026-08-28T09:59:22.227Z" },
    { url = "https://files.pythonhosted.org/packages/01/72/4fd20ad520fb8da0157f95b27a7eb05a72790ef08138e7701ac972c342ea/pydantic_core-2.46.5-cp314-cp314-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:37ea7b83c935e5b0d68c9449b82651accf78a10828b2c02b2f2d9e9496446c21", size = 2202822, upload-time = "2026-08-28T09:59:24.277Z" },
    { url = "https://files.pythonhosted.org/packages/31/b0/d16e0771206b29314f0d52198b720be21e8a99ab2bf11e3bc0d7c9cebdff/pydantic_core-2.46.5-cp314-cp314-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:e64e88d5585bea9ce95861079de72006c7fa6d3df4e3a3b65ba31eb979c15c9f", size = 2262756, upload-time = "2026-08-28T09:59:26.608Z" },
    { url = "https://files.pythonhosted.org/packages/2c/9b/59634b7ac631c63b2a37760eb6943af3e29573d6b59a4abc5e7f019d4cee/pydantic_core-2.46.5-cp314-cp314-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:54d510bac3ee52247af28ed4bb18a1e799f040ac60fd2bf5ccd4c92f1fbe786f", size = 2068352, upload-time = "2026-08-28T09:59:29.044Z" },
    { url = "https://files.pythonhosted.org/packages/08/7c/570abb1ad2155348dc754ea91be22e5aaa18eb6d69a6068f7c6f2679a6ed/pydantic_core-2.46.5-cp314-cp314-manylinux_2_31_riscv64.whl", hash = "sha256:a2a5e1d0ff29adddc9f6d6821a66302e4493f8ca898b715b6b1182c2c201ea0a", size = 2104777, upload-time = "2026-08-28T09:59:30.95Z" },
    { url = "https://files.pythonhosted.org/packages/8e/25/5bf74adc65a1ac5b7be3f6cb0bcb5433615c1598a801c19d830d84c98ded/pydantic_core-2.46.5-cp314-cp314-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:03b9666e41e35d8909852ba191a0607520f81b74eaf12ccf8737005dbb313821", size = 2156312, upload-time = "2026-08-28T09:59:32.604Z" },
    { url = "https://files.pythonhosted.org/packages/90/6a/2ef38830675e050121040618135564ed56b860b45433b02d9b4ebece46f3/pydantic_core-2.46.5-cp314-cp314-musllinux_1_1_aarch64.whl", hash = "sha256:a91c17edf6eea2402cb5457b4c89e99bc5ed1004aa34c4adf1d4258c1a5c22c2", size = 2150067, upload-time = "2026-08-28T09:59:34.453Z" },
    { url = "https://files.pythonhosted.org/packages/90/ef/a7dbb03a14a64c2a4621f989c615ed9a892535a6cad938fc27079f919d80/pydantic_core-2.46.5-cp314-cp314-musllinux_1_1_armv7l.whl", hash = "sha256:b49924c73a235e969511bf2aabdff3beebf9820931f646c80274d5d780010c47", size = 2304516, upload-time = "2026-08-28T09:59:36.194Z" },
    { url = "https://files.pythonhosted.org/packages/68/f8/6bb4c4b80e8a6fde1904c64a51c62a1d04fcdfa3ea521a66b2ddefa1d885/pydantic_core-2.46.5-cp314-cp314-musllinux_1_1_x86_64.whl", hash = "sha256:2cbd9a5eff05e51c447c34dfa4632145b26b09120cf04bd0c871e44c1a5e1c9a", size = 2335223, upload-time = "2026-08-28T09:59:37.931Z" },
    { url = "https://files.pythonhosted.org/packages/2a/80/f46b8c681195190b2c1f1c7c0a81abce60663e987613e09ef64d433dd96b/pydantic_core-2.46.5-cp314-cp314-win32.whl", hash = "sha256:2d5d76654becf5efd62c9e51c3756c67b49498b0c9a40884934c40807adbd074", size = 1934827, upload-time = "2026-08-28T09:59:39.836Z" },
    { url = "https://files.pythonhosted.org/packages/f7/3c/60674207246bc0a4009d2391b7c7251c7159f279c8d2ab8aae8ef46f3dee/pydantic_core-2.46.5-cp314-cp314-win_amd64.whl", hash = "sha256:fa10ef4112775900e7a0661068635eb67b2ab824fbde764de6e0e21982a93db0", size = 2042648, upload-time = "2026-08-28T09:59:41.792Z" },
    { url = "https://files.pythonhosted.org/packages/69/0c/117c562c7c1babdf44576b72a5e496906506c93690387ecfbca7c729ae2e/pydantic_core-2.46.5-cp314-cp314-win_arm64.whl", hash = "sha256:045ab3b6d308439e32b81cc173bba5b9018bc6ed896afd0c65b3b009b1699af5", size = 1989652, upload-time = "2026-08-28T09:59:43.702Z" },
    { url = "https://files.pythonhosted.org/packages/e8/66/9336ae58f9eb68c41d121894e52c4c89eccb07eb8f602a04ee9c3f37736a/pydantic_core-2.46.5-cp314-cp314t-macosx_10_12_x86_64.whl", hash = "sha256:8816f3d218beb4b787de5c9759c259b8fa61f9dec42dc7811f320a33771778b7", size = 2065829, upload-time = "2026-08-28T09:59:45.364Z" },
    { url = "https://files.pythonhosted.org/packages/c5/02/bc19b47a96c2d3109760711acf22369e56bd7e405ca52f7ade164d2ead57/pydantic_core-2.46.5-cp314-cp314t-macosx_11_0_arm64.whl", hash = "sha256:bce57638e08ac148e5778cce7feb968307a727d66f8e2274a543d0cf0c9ad6a3", size = 1905716, upload-time = "2026-08-28T09:59:47.18Z" },
    { url = "https://files.pythonhosted.org/packages/52/a4/70b47c0509923dd98ccfed04fb3e32ea3849c82a0ff2205bb41009b43c00/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:976e1128455aa595ea04c79ccfedff1aaeab96ee013fcc916bed120c4f0ad94f", size = 1934216, upload-time = "2026-08-28T09:59:49.241Z" },
    { url = "https://files.pythonhosted.org/packages/52/ab/aa03b65f7bb198585edf806b906c3223ecf1795543e39e23aec4cce27ad2/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:e7b891faeedeafba41b2983e5001a81b6a915b69544c7e7570d1989ce1c36ac7", size = 2010635, upload-time = "2026-08-28T09:59:51.692Z" },
    { url = "https://files.pythonhosted.org/packages/3c/8b/0da06343f30b84ec549aafd309c6456223d5dc8bd36af504c573faad561d/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:5f194189415698233dd1114a093a9b56e61e2c57e11b469be3b0506f46f0771c", size = 2209369, upload-time = "2026-08-28T09:59:53.582Z" },
    { url = "https://files.pythonhosted.org/packages/d6/5b/844c4defaa34a3df66eb9257087d121d70c201298b96abdf9f492fc2f1bf/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:82a36973cf8a2ef5406f4fe2edbf8ed0c99629535d959e0b100c76a32535a111", size = 2253238, upload-time = "2026-08-28T09:59:55.484Z" },
    { url = "https://files.pythonhosted.org/packages/f4/64/a4e536cb16d7f61a7fd3120b46c577fc7fa7325992f69c4f52bc786d77d8/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:cdbb78909f52b981d3b2d56b97328d71eb0b974c36bd77c920123a7ebb192829", size = 2065740, upload-time = "2026-08-28T09:59:58.038Z" },
    { url = "https://files.pythonhosted.org/packages/5f/75/aaa38c6bc2d085f6605b34eabdc6a8a4e0b2e61fc9c8e6e52b28e97b3125/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_31_riscv64.whl", hash = "sha256:52e24eacdb536cade636aa90fb851835222becff8484b7001fdc78cb0290f2aa", size = 2087425, upload-time = "2026-08-28T09:59:59.898Z" },
    { url = "https://files.pythonhosted.org/packages/55/ae/fcab4cfc39aba3689e1d20c8b5250ad280957022c09af2ed9cd585602a5e/pydantic_core-2.46.5-cp314-cp314t-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:37ae34309d7bd8c0d61ab839668058f2a7962ea1fc51d105d2db228fe0618034", size = 2139306, upload-time = "2026-08-28T10:00:03.057Z" },
    { url = "https://files.pythonhosted.org/packages/2d/f4/f1d03a4bc9d9acbc62f4d742b8a319af52f71885079868b2ff8e48a651ee/pydantic_core-2.46.5-cp314-cp314t-musllinux_1_1_aarch64.whl", hash = "sha256:0cdbada856a1c69a7624a64d3d9aefe79300bd6ef827b43a4f265010b9b55184", size = 2144589, upload-time = "2026-08-28T10:00:05.645Z" },
    { url = "https://files.pythonhosted.org/packages/83/f3/7a53bb1356de514a4cd295f25b6ac39237895620c0462d2592b76c16e114/pydantic_core-2.46.5-cp314-cp314t-musllinux_1_1_armv7l.whl", hash = "sha256:545f26c504b27c3758439a5e6d9349931f0a04f855668d5fe323c89e82300a38", size = 2288882, upload-time = "2026-08-28T10:00:07.931Z" },
    { url = "https://files.pythonhosted.org/packages/cd/94/5a81583660c175c59d49ffb09f4b3a44debeaf86a19fca664ae1cdd9ee32/pydantic_core-2.46.5-cp314-cp314t-musllinux_1_1_x86_64.whl", hash = "sha256:ff218293c9c806138dca139765e3b067621be52bcd93cdc14c7711be7ddc90a9", size = 2335210, upload-time = "2026-08-28T10:00:10.177Z" },
    { url = "https://files.pythonhosted.org/packages/5a/9f/5d685c2693b972d1a59c998586e8823712b66603aeff47ee60a4bdaafd37/pydantic_core-2.46.5-cp314-cp314t-win32.whl", hash = "sha256:97cf3eb53a8cccacf9d46686a0926186c9bfb5574f2ed66d3639d5fe117cd3a9", size = 1921180, upload-time = "2026-08-28T10:00:12.35Z" },
    { url = "https://files.pythonhosted.org/packages/70/12/5c94ee16d65a37a15f9e869f5e6256df111154491173801a4c5e800ab548/pydantic_core-2.46.5-cp314-cp314t-win_amd64.whl", hash = "sha256:d2f9fc07a8042a8f95925b35c4f04f469707c981fc33245b6ca187cf5d2dd290", size = 2020515, upload-time = "2026-08-28T10:00:14.774Z" },
    { url = "https://files.pythonhosted.org/packages/63/19/67830dda664e6bdf9285ee2e40f355d0d7d6b92aa0c42e8d217bb8d33d36/pydantic_core-2.46.5-cp314-cp314t-win_arm64.whl", hash = "sha256:acf8a67ba51f4ca9ddbd0e6b3000a65ac51ab734661778b3e7ba64d99a710f2f", size = 1989276, upload-time = "2026-08-28T10:00:16.984Z" },
    { url = "https://files.pythonhosted.org/packages/af/1e/ecca01fce348f7e8afa9572441ff6f7d1cc70d21e4859f33944d10877e1e/pydantic_core-2.46.5-graalpy311-graalpy242_311_native-macosx_10_12_x86_64.whl", hash = "sha256:c14ad3bdc85ee7f318742c457ca3968a92126d144b15721c759033bfb06296c2", size = 2075342, upload-time = "2026-08-28T10:00:51.353Z" },
    { url = "https://files.pythonhosted.org/packages/1f/4c/af80c7a8032dfc897040ad5cb772bebde529a381186499e6e29987f23f8c/pydantic_core-2.46.5-graalpy311-graalpy242_311_native-macosx_11_0_arm64.whl", hash = "sha256:0bddb4020d8f04175865ccd17eff3040874fc11fb593f424edb452653b4b947c", size = 1907219, upload-time = "2026-08-28T10:00:53.438Z" },
    { url = "https://files.pythonhosted.org/packages/be/3e/54d89e2b092e778716bf6153634ef479e955f48c261090be23aa1e0fb0b5/pydantic_core-2.46.5-graalpy311-graalpy242_311_native-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:2471fd51c61c610e1dcf7de44d7299283661654d11264ab4802b303368d69c47", size = 1953393, upload-time = "2026-08-28T10:00:55.58Z" },
    { url = "https://files.pythonhosted.org/packages/ea/89/828ee90cda28ce17bdefaa3a6eaf74fe430e113295a10e6126beca559d6c/pydantic_core-2.46.5-graalpy311-graalpy242_311_native-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:b10ec717381bdbfafef34607824db4c91de69ff085e4fca3b2af91b4fa17e68a", size = 2099024, upload-time = "2026-08-28T10:00:57.794Z" },
    { url = "https://files.pythonhosted.org/packages/df/dd/053c2e4303f791f3b8f8a14ab0b22008e8eb21d868c0c90b4f9be705b76a/pydantic_core-2.46.5-graalpy312-graalpy250_312_native-macosx_10_12_x86_64.whl", hash = "sha256:013d6f3483d81e02e7c328831808f336c8596ee33b4bd4026b9ffb1e960b8942", size = 2062540, upload-time = "2026-08-28T10:01:00.318Z" },
    { url = "https://files.pythonhosted.org/packages/d7/dd/a18df751a5e37dd51bfad7f68e766999125bebe68c9e1d10a493ad01bd63/pydantic_core-2.46.5-graalpy312-graalpy250_312_native-macosx_11_0_arm64.whl", hash = "sha256:e9c134bb666dd54b778b9fc0d2b50cbb7f979b9e3716f26a88c9ab3b6fc1dd0f", size = 1902040, upload-time = "2026-08-28T10:01:02.529Z" },
    { url = "https://files.pythonhosted.org/packages/b7/13/01d40f9d07ce8a779fd6e0bd8ad4fba91309500dd67b869e2e219d261a6d/pydantic_core-2.46.5-graalpy312-graalpy250_312_native-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:347ec774390c87326a2e4929d58d3f7e8763a104d5d35f4cd595a4c952366433", size = 1967479, upload-time = "2026-08-28T10:01:05.004Z" },
    { url = "https://files.pythonhosted.org/packages/fa/04/c81d4841331c2178b6fb09ae225425e110ed72d990c9fe556c4ec03d1013/pydantic_core-2.46.5-graalpy312-graalpy250_312_native-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:8e24d8f05fa2d28513d94e877e9c75ad66175376209b3977f916e240e623193c", size = 2111034, upload-time = "2026-08-28T10:01:07.345Z" },
    { url = "https://files.pythonhosted.org/packages/20/21/22102e9950b3049526d20e811b95396508377d87651edd2b80d2b3d28659/pydantic_core-2.46.5-pp311-pypy311_pp73-macosx_10_12_x86_64.whl", hash = "sha256:ab4b66edffb32d9e951efb3814bd104b8367a7501b81b955cacb5726d897389f", size = 2071333, upload-time = "2026-08-28T10:01:09.636Z" },
    { url = "https://files.pythonhosted.org/packages/d8/18/87aefa427d191e6d3ab1447f1efc1cdcac86af1069239b133e8a0fd7f7c9/pydantic_core-2.46.5-pp311-pypy311_pp73-macosx_11_0_arm64.whl", hash = "sha256:337639ba62a11acde6ef3aeb08c8ea755f8ef1fe5e513356c0f36a2b0d7568b0", size = 1912713, upload-time = "2026-08-28T10:01:12.285Z" },
    { url = "https://files.pythonhosted.org/packages/1f/93/fd89e9ad49b1805ca94d24ce1088b7d305f05c35ffafcedb9819d03588a0/pydantic_core-2.46.5-pp311-pypy311_pp73-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:413a717a410d0c817ef5b786a059415550b3794e1d0c2abffd9efb93a3d9f7b4", size = 2090926, upload-time = "2026-08-28T10:01:15.19Z" },
    { url = "https://files.pythonhosted.org/packages/6f/45/8e59dab6acf8d35f02f0a958980074f31038968bdb2c983fcae9d1efee03/pydantic_core-2.46.5-pp311-pypy311_pp73-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:1e449def1945a462c464331254e5a44fca7c3b4f9aedf59ec2f50f8066dd8e25", size = 2131303, upload-time = "2026-08-28T10:01:17.937Z" },
    { url = "https://files.pythonhosted.org/packages/d5/a5/e1d4dc5180dd887a9522efc1f8716b8692b7606b1d3273d7862eaf66be44/pydantic_core-2.46.5-pp311-pypy311_pp73-musllinux_1_1_aarch64.whl", hash = "sha256:a445486499897b88a7d6c310c88ed64dd37b1b59bfd7ae9107490bbb362f47d6", size = 2145128, upload-time = "2026-08-28T10:01:20.694Z" },
    { url = "https://files.pythonhosted.org/packages/c2/d7/ad493864a7fb21c0c4df98f965e2db430cb25a9d7369b5778d5016c09fd9/pydantic_core-2.46.5-pp311-pypy311_pp73-musllinux_1_1_armv7l.whl", hash = "sha256:2d330aaba8621b1edcec8ae2c4050f63b84ccf6d98723a8f212e9684713abf0e", size = 2294560, upload-time = "2026-08-28T10:01:23.495Z" },
    { url = "https://files.pythonhosted.org/packages/02/8e/b41c84c913f29973a268e6c2b5bbf13c95adb9956c126d10da11ba3b2bef/pydantic_core-2.46.5-pp311-pypy311_pp73-musllinux_1_1_x86_64.whl", hash = "sha256:b6acfb46a814762367fb7ba0828b0a17d441b92ce249a0e007474c9072662dda", size = 2317531, upload-time = "2026-08-28T10:01:26.334Z" },
    { url = "https://files.pythonhosted.org/packages/db/1d/068464f23075f66a8f1b806935e9cd9363ee446636ea70d2c22ee8659dbf/pydantic_core-2.46.5-pp311-pypy311_pp73-win_amd64.whl", hash = "sha256:d0a24b40877af2de4950252be9d21eaf7fb07660f3c2cae1f56c6b599ada5266", size = 2140686, upload-time = "2026-08-28T10:01:28.947Z" },
]

[[package]]
name = "typing-extensions"
version = "4.16.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz", hash = "sha256:dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5", size = 113555, upload-time = "2026-07-02T08:40:05.92Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/49/d3/b8441a820a491ddfc024b0b0cf0393375b75ea13866d9c66727e54c2fc80/typing_extensions-4.16.0-py3-none-any.whl", hash = "sha256:481caa481374e813c1b176ada14e97f1f67a4539ce9cfeb3f350d78d6370c2e8", size = 45571, upload-time = "2026-07-02T08:40:04.659Z" },
]

[[package]]
name = "typing-inspection"
version = "0.4.4"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "typing-extensions" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a3/26/b09b8010994eccc3c09092e6b34058f36a460eea2d4c3e8b910c695975a0/typing_inspection-0.4.4.tar.gz", hash = "sha256:547274fa6b0a561ccf549cc9524b999a578e737d015d8709d021f9d0d13bea47", size = 76928, upload-time = "2026-08-12T12:37:25.997Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/67/81/4add07e5172b7ac40d8ed5ff580409a7801a4fe26d529bdd915401dabfbe/typing_inspection-0.4.4-py3-none-any.whl", hash = "sha256:65b8397ba37ccbce054456aaccddfc91e6e3083c92824df348d96ca832f3f147", size = 14750, upload-time = "2026-08-12T12:37:24.648Z" },
]

[[package]]
name = "tzdata"
version = "2026.4"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/e4/31/3d74fa778a63b98b7374323befcc0be5ab3bd94afd4096a0124e7379152c/tzdata-2026.4.tar.gz", hash = "sha256:f1b8bd365d8d210c55353f4d7f8d6d8561c0ba50d704b700d195a9424bba0d79", size = 199350, upload-time = "2026-09-12T12:56:03.251Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/f9/bc/8737e8d54cf51106118039b83f485a4783112fab49ea9d044b234978a46e/tzdata-2026.4-py2.py3-none-any.whl", hash = "sha256:c2169a8b0a7a5e9674da5a135ccdfb2b3e671b333ed9fed17b41f73c34476e81", size = 347494, upload-time = "2026-09-12T12:56:01.67Z" },
]

[[package]]
name = "werkzeug"
version = "3.1.9"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "markupsafe" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a4/34/4dd12fc8bb7d61c91467ec3efe415ffa7d5456f799954b40c5bbaeae470e/werkzeug-3.1.9.tar.gz", hash = "sha256:55ca7c70a75689be937aa27f8ff4b018f06ff4838fc73045560bf0f5a1291060", size = 940188, upload-time = "2026-09-27T18:33:41.637Z" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/a1/38/df03f564f43cec2684823f3cccae1a652ee7face1cbaa76fb223096e64d7/werkzeug-3.1.9-py3-none-any.whl", hash = "sha256:6392e50c78460ba618e5b21f08a71f59c99ce99cdc6cf6e3dd7e6ccca8754fab", size = 228700, upload-time = "2026-09-27T18:33:39.685Z" },
]
FLASK_SCAFFOLD_FILE_0059

cp -- "$SCRIPT_SOURCE" scripts/flask-scaffold.sh

echo
echo "Created $APP_NAME"
echo
echo "Next:"
echo
echo "  cd $APP_NAME"
echo "  python -m venv .venv"
echo "  source .venv/bin/activate"
echo "  pip install -r requirements.txt"
echo "  python main.py"
echo