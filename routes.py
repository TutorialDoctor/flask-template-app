from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, abort
from flask_login import login_user, login_required, logout_user
from peewee import DoesNotExist

from models import User, UserInfo, Item, UserItem, Role, BaseModel
from modules.BaseModule import BaseModule
from modules.ScriptRunner import ScriptRunner
from modules.PasswordGenerator import PasswordGenerator


routes = Blueprint(
    "routes",
    __name__,
    static_folder="static",
    template_folder="templates"
)

auth = Blueprint(
    "auth",
    __name__,
    static_folder="static",
    template_folder="templates"
)


RELATIONSHIPS = {
    "users": [
        {
            "form_key": "item_ids",
            "junction": UserItem,
            "parent": UserItem.user,
            "child": UserItem.item,
            "context": "items",
            "model": Item,
        }
    ],

    "items": [
        {
            "form_key": "user_ids",
            "junction": UserItem,
            "parent": UserItem.item,
            "child": UserItem.user,
            "context": "users",
            "model": User,
        }
    ],
}


# -------------------------------------------------------------------
# General Routes
# -------------------------------------------------------------------

@routes.route("/ping", methods=["GET"])
def ping():
    password = PasswordGenerator.generate_passwords(
        includes=["tutorial", "doctor", "github", "2026"]
    )

    return (
        f"PONG \n"
        f"{ScriptRunner.run_python('test.py')}"
        f"{BaseModule.name}\n"
        f"Password: \n{password}"
    )


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


# -------------------------------------------------------------------
# Dynamic CRUD
# -------------------------------------------------------------------

@routes.route("/<resource>", methods=["GET", "POST"])
@routes.route("/<resource>/<action>", methods=["GET", "POST"])
@routes.route("/<resource>/<int:id>", methods=["GET", "PUT", "DELETE"])
@routes.route("/<resource>/<int:id>/<action>", methods=["GET", "POST"])
def crud(resource="users", id=None, action=None):
    model = get_model(resource)

    if id is None:
        return handle_collection(model, resource, action)

    record = get_record(model, id)

    return handle_record(model, resource, record, action)


def handle_collection(model, resource, action):
    if action == "new" and request.method == "GET":
        return render_resource(
            resource,
            "new",
            **relationship_context(resource)
        )

    if request.method == "POST":
        record = model.create(**form_data(model))

        sync_relationships(
            resource,
            record,
            request.form
        )

        return redirect(
            url_for(
                "routes.crud",
                resource=resource,
                id=record.id
            )
        )

    if request.method == "GET":
        return render_resource(
            resource,
            "index",
            objects=model.select()
        )

    return "Invalid Request", 400


def handle_record(model, resource, record, action):
    if action == "edit" and request.method == "GET":
        return render_resource(
            resource,
            "edit",
            object=record,
            **relationship_context(resource, record)
        )

    if action == "delete" or request.method == "DELETE":
        record.delete_instance()

        return redirect(
            url_for(
                "routes.crud",
                resource=resource
            )
        )

    if request.method in ["POST", "PUT"]:
        for key, value in form_data(model).items():
            setattr(record, key, value)

        record.save()

        sync_relationships(
            resource,
            record,
            request.form
        )

        return redirect(
            url_for(
                "routes.crud",
                resource=resource,
                id=record.id
            )
        )

    if request.method == "GET":
        return render_resource(
            resource,
            "show",
            object=record
        )

    return "Invalid Request", 400


# -------------------------------------------------------------------
# Admin Routes
# -------------------------------------------------------------------

def render_admin_tab(tab, query, template):
    if request.headers.get("HX-Request"):
        return render_template(
            template,
            **{tab: query}
        )

    return render_template(
        "admin.html",
        active_tab=tab,
        **{tab: query}
    )


@routes.route("/admin")
@routes.route("/admin/users")
def admin_users():
    return render_admin_tab(
        "users",
        User.select().order_by(User.created_at.desc()),
        "partials/_users_table.html"
    )


@routes.route("/admin/items")
def admin_items():
    return render_admin_tab(
        "items",
        Item.select().order_by(Item.created_at.desc()),
        "partials/_items_table.html"
    )


@routes.route("/admin/roles")
def admin_roles():
    return render_admin_tab(
        "roles",
        Role.select(),
        "partials/_roles_table.html"
    )


# -------------------------------------------------------------------
# CRUD Helpers
# -------------------------------------------------------------------

def get_model(resource):
    if resource.endswith("ies"):
        model_name = resource[:-3].title() + "y"
    else:
        model_name = "".join(
            word.title()
            for word in resource.rstrip("s").split("_")
        )

    for model in BaseModel.__subclasses__():
        if model.__name__ == model_name:
            return model

    abort(
        404,
        description=f"Resource '{resource}' not found"
    )


def get_record(model, id):
    try:
        return model.get_by_id(id)
    except DoesNotExist:
        abort(
            404,
            description=f"Record #{id} not found in {model.__name__}"
        )


def form_data(model):
    fields = model._meta.fields
    data = {}

    for key, value in request.form.items():
        if key in fields and key != "id":
            data[key] = value if value != "" else None

    return data


def render_resource(resource, template, **context):
    return render_template(
        f"{resource}/{template}.html",
        resource=resource,
        **context
    )


def relationship_context(resource, record=None):
    context = {}

    for relationship in RELATIONSHIPS.get(resource, []):
        model = relationship["model"]
        context_key = relationship["context"]

        context[f"all_{context_key}"] = model.select()

        if record is None:
            context[f"current_{context_key}_ids"] = []
            continue

        junction = relationship["junction"]
        parent = relationship["parent"]
        child = relationship["child"]

        query = (
            junction
            .select(getattr(junction, child.name))
            .where(parent == record)
        )

        context[f"current_{context_key}_ids"] = [
            getattr(row, child.name).id
            for row in query
        ]

    return context


def sync_relationships(resource, record, form):
    for relationship in RELATIONSHIPS.get(resource, []):
        form_key = relationship["form_key"]
        junction = relationship["junction"]
        parent = relationship["parent"]
        child = relationship["child"]

        selected_ids = form.getlist(
            form_key,
            type=int
        )

        junction.delete().where(
            parent == record
        ).execute()

        if not selected_ids:
            continue

        rows = [
            {
                parent.name: record.id,
                child.name: selected_id
            }
            for selected_id in selected_ids
        ]

        junction.insert_many(rows).execute()


# -------------------------------------------------------------------
# Authentication Routes
# -------------------------------------------------------------------

@auth.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        return render_template("auth/login.html")

    email = request.form.get("email")
    password = request.form.get("password")

    user = User.get_or_none(User.email == email)

    if not user:
        return render_template(
            "auth/login.html",
            message="Invalid User"
        ), 404

    if user.password != password:
        return render_template(
            "auth/login.html",
            message="Invalid Password"
        )

    login_user(user)

    return redirect(url_for("routes.home"))


@auth.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "GET":
        return render_template("auth/register.html")

    email = request.form.get("email")

    if User.get_or_none(User.email == email):
        return render_template(
            "auth/register.html",
            message="User already exists"
        )

    user = User.create(
        email=email,
        password=request.form.get("password"),
        first_name=request.form.get("first_name"),
        last_name=request.form.get("last_name")
    )

    login_user(user)

    return redirect(url_for("routes.home"))


@auth.route("/logout", methods=["GET"])
@login_required
def logout():
    logout_user()

    return redirect(url_for("auth.login"))