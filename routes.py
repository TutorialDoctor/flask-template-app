from flask import Blueprint, render_template, request, redirect, url_for, flash,  abort
from models import User,UserInfo,Item,UserItems,Role,BaseModel
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

# General Routes
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


# --- Dynamic CRUD Routes ---
@routes.route('/<resource>', methods=['GET', 'POST'])
@routes.route('/<resource>/<action>', methods=['GET', 'POST'])
@routes.route('/<resource>/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@routes.route('/<resource>/<int:id>/<action>', methods=['GET', 'POST'])
def resource_route(resource='users', id=None, action=None):
    model = resolve_model(resource)
    method = request.method

    # --- Collection Level: /<resource> ---
    if not id:
        if action == 'new' and method == 'GET':
            return render_action_template(resource, 'new')

        if method == 'POST':
            instance = model.create(**extract_form_data(model))
            return redirect(url_for('routes.resource_route', resource=resource, id=instance.id))

        if method == 'GET':
            return render_action_template(resource, 'index', objects=model.select())

    # --- Instance Level: /<resource>/<id> ---
    instance = get_instance_or_404(model, id)

    if action == 'edit' and method == 'GET':
        return render_action_template(resource, 'edit', object=instance)

    if action == 'delete' or method == 'DELETE':
        instance.delete_instance()
        return redirect(url_for('routes.resource_route', resource=resource))

    if method in ['POST', 'PUT'] or (action == 'edit' and method == 'POST'):
        for key, value in extract_form_data(model).items():
            setattr(instance, key, value)
        instance.save()
        return redirect(url_for('routes.resource_route', resource=resource, id=instance.id))

    if method == 'GET':
        return render_action_template(resource, 'show', object=instance)

    return "Invalid Request", 400


# Admin Routes
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
        return render_template('partials/_users_table.html', users=users)
        
    # Otherwise render full page layout
    return render_template('admin.html', active_tab='users', users=users)

@routes.route('/admin/items')
def admin_items():
    items = Item.select().order_by(Item.created_at.desc())
    
    if request.headers.get('HX-Request'):
        return render_template('partials/_items_table.html', items=items)
        
    return render_template('admin.html', active_tab='items', items=items)

@routes.route('/admin/roles')
def admin_roles():
    roles = Role.select()
    
    if request.headers.get('HX-Request'):
        return render_template('partials/_roles_table.html', roles=roles)
        
    return render_template('admin.html', active_tab='roles', roles=roles)

# --- Helper Functions ---
def resolve_model(resource):
    """Maps resource names ('posts') to Peewee models ('Post')."""
    target_class = ''.join(word.title() for word in resource.rstrip('s').split('_'))
    for model in BaseModel.__subclasses__():
        if model.__name__ == target_class:
            return model
    abort(404, description=f"Resource '{resource}' not found")

def get_instance_or_404(model, id):
    """Fetches model instance or raises 404."""
    try:
        return model.get_by_id(id)
    except DoesNotExist:
        abort(404, description=f"Item #{id} not found")

def extract_form_data(model):
    """Filters request form parameters to match model fields, ignoring 'id'."""
    fields = model._meta.fields
    return {k: v for k, v in request.form.items() if k in fields and k != 'id'}

def render_action_template(resource, template_type, **context):
    """Standardizes template rendering path: templates/<resource>/<type>.html"""
    return render_template(f'{resource}/{template_type}.html', resource=resource, **context)

def is_write_action(action, method):
    """Detects update/delete intents whether via HTTP methods or HTML form actions."""
    if method in ['POST', 'PUT', 'DELETE']:
        return True
    return action in ['edit', 'delete']


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