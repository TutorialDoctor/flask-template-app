from flask import Blueprint, render_template, request, redirect, url_for, flash
from models import User,UserInfo,Item,UserItems
from datetime import datetime
from extensions import cache
from flask_login import (
    login_user,
    login_required,
    logout_user,
)

routes = Blueprint("routes", __name__, static_folder="static", template_folder="templates")
auth = Blueprint("auth", __name__, static_folder="static", template_folder="templates")

    
# General routes
@routes.route("/ping", methods=["GET"])
def ping():
    return "pong"


@routes.route("/", methods=["GET"])
@login_required
def home():
    user = User.get_or_none(User.email == "td@gmail.com")
    return render_template("index.html", user=user)


@routes.route("/about", methods=["GET"])
def about():
    return render_template("about.html")


@routes.route("/contact", methods=["GET"])
def contact():
    return render_template("contact.html")


# Create user
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


# Edit user
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


# New user
@routes.route("/users/new", methods=["GET"])
@login_required
def new_user():
    return render_template("users/new.html")

# Delete user
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