from datetime import datetime
from flask import Blueprint, render_template, request, redirect, url_for, abort
from flask_login import login_user, login_required, logout_user
from peewee import DoesNotExist

from models import User, UserInfo, Item, UserItem, Role, BaseModel
from modules.BaseModule import BaseModule
from modules.ScriptRunner import ScriptRunner
from modules.PasswordGenerator import PasswordGenerator


routes = Blueprint("routes", __name__, static_folder="static", template_folder="templates")
auth = Blueprint("auth", __name__, static_folder="static", template_folder="templates")


# --- General Routes ---

@routes.route("/ping", methods=["GET"])
def ping():
    password = PasswordGenerator.generate_passwords(includes=['tutorial', 'doctor', 'github', '2026'])
    return f"PONG \n{ScriptRunner.run_python('test.py')}{BaseModule.name}\nPassword: \n{password}"

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


# --- Dynamic CRUD Route ---

@routes.route('/<resource>', methods=['GET', 'POST'])
@routes.route('/<resource>/<action>', methods=['GET', 'POST'])
@routes.route('/<resource>/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@routes.route('/<resource>/<int:id>/<action>', methods=['GET', 'POST'])
def resource_route(resource='users', id=None, action=None):
    model = resolve_model(resource)
    method = request.method

    # Collection Level: /<resource>
    if not id:
        if action == 'new' and method == 'GET':
            return render_action_template(resource, 'new', **get_m2m_context(resource))

        if method == 'POST':
            instance = model.create(**type_cast_form_data(model))
            sync_m2m_relations(resource, instance, request.form)
            return redirect(url_for('routes.resource_route', resource=resource, id=instance.id))

        if method == 'GET':
            return render_action_template(resource, 'index', objects=model.select())

    # Instance Level: /<resource>/<id>
    instance = get_instance_or_404(model, id)

    if action == 'edit' and method == 'GET':
        return render_action_template(resource, 'edit', object=instance, **get_m2m_context(resource, instance))

    if action == 'delete' or method == 'DELETE':
        instance.delete_instance()
        return redirect(url_for('routes.resource_route', resource=resource))

    if method in ['POST', 'PUT'] or (action == 'edit' and method == 'POST'):
        for key, value in type_cast_form_data(model).items():
            setattr(instance, key, value)
        instance.save()

        sync_m2m_relations(resource, instance, request.form)
        return redirect(url_for('routes.resource_route', resource=resource, id=instance.id))

    if method == 'GET':
        return render_action_template(resource, 'show', object=instance)

    return "Invalid Request", 400


# --- Admin Routes ---

def _render_admin_tab(tab_name, query, partial_template):
    """Helper to reduce HTMX vs Full Layout boilerplate across admin routes."""
    if request.headers.get('HX-Request'):
        return render_template(partial_template, **{tab_name: query})
    return render_template('admin.html', active_tab=tab_name, **{tab_name: query})

@routes.route('/admin')
@routes.route('/admin/users')
def admin_users():
    return _render_admin_tab('users', User.select().order_by(User.created_at.desc()), 'partials/_users_table.html')

@routes.route('/admin/items')
def admin_items():
    return _render_admin_tab('items', Item.select().order_by(Item.created_at.desc()), 'partials/_items_table.html')

@routes.route('/admin/roles')
def admin_roles():
    return _render_admin_tab('roles', Role.select(), 'partials/_roles_table.html')


# --- Helper Functions ---

def resolve_model(resource):
    """Maps singular/plural route resources to Peewee model classes dynamically."""
    target_name = ''.join(word.title() for word in resource.rstrip('s').split('_'))
    for model in BaseModel.__subclasses__():
        if model.__name__ == target_name:
            return model
    abort(404, description=f"Resource '{resource}' not found")

def get_instance_or_404(model, id):
    """Fetches a database record by ID or raises a 404 error."""
    try:
        return model.get_by_id(id)
    except DoesNotExist:
        abort(404, description=f"Record #{id} not found in {model.__name__}")

def type_cast_form_data(model):
    """Filters request form data against model fields and cleans empty strings."""
    valid_fields = model._meta.fields
    data = {}
    for key, value in request.form.items():
        if key in valid_fields and key != 'id':
            # Convert empty form strings to None so Peewee won't fail type checks
            data[key] = value if value != '' else None
    return data

def render_action_template(resource, template_type, **context):
    """Renders standardized path: templates/<resource>/<template_type>.html"""
    return render_template(f'{resource}/{template_type}.html', resource=resource, **context)

def get_m2m_context(resource, instance=None):
    """Provides related model datasets and current IDs for multi-select rendering."""
    if resource == 'users':
        return {
            'all_items': Item.select(),
            'current_item_ids': [i.id for i in instance.items] if instance else []
        }
    if resource == 'items':
        return {
            'all_users': User.select(),
            'current_user_ids': [u.id for u in instance.users] if instance else []
        }
    return {}

def sync_m2m_relations(resource, instance, form_data):
    """Performs bulk delete and bulk insert on the UserItem junction table."""
    m2m_config = {
        'users': ('item_ids', UserItem.user, 'item'),
        'items': ('user_ids', UserItem.item, 'user')
    }

    if resource not in m2m_config:
        return

    form_key, filter_field, target_field = m2m_config[resource]
    selected_ids = form_data.getlist(form_key, type=int)

    # 1. Clear existing junction links
    UserItem.delete().where(filter_field == instance).execute()

    # 2. Bulk insert new junction links
    if selected_ids:
        rows = [{filter_field.name: instance.id, target_field: target_id} for target_id in selected_ids]
        UserItem.insert_many(rows).execute()


# --- Authentication Routes ---

@auth.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        return render_template("auth/login.html")

    email = request.form.get("email")
    password = request.form.get("password")
    user = User.get_or_none(User.email == email)

    if not user:
        return render_template("auth/login.html", message="Invalid User"), 404

    if user.password != password:
        return render_template("auth/login.html", message="Invalid Password")

    login_user(user)
    return redirect(url_for("routes.home"))

@auth.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "GET":
        return render_template("auth/register.html")

    email = request.form.get("email")
    if User.get_or_none(User.email == email):
        return render_template("auth/register.html", message="User already exists")

    new_user = User.create(
        email=email,
        password=request.form.get("password"),
        first_name=request.form.get("first_name"),
        last_name=request.form.get("last_name")
    )

    login_user(new_user)
    return redirect(url_for("routes.home"))

@auth.route("/logout", methods=["GET"])
@login_required
def logout():
    logout_user()
    return redirect(url_for("auth.login"))