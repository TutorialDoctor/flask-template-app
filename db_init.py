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
