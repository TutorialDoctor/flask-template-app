from models import Role, User, Post, Forum
import datetime
from modules.FakeUser import FakeUser
from extensions import db

def seed():
    with db.atomic():
        db.connect(reuse_if_open=True)

        fake_user = FakeUser.get_data()
        User.get_or_create(
            first_name = fake_user[0],
            last_name = fake_user[1],
            email= fake_user[2],
            password="password"
        )

        Role.get_or_create(name="user")
        Role.get_or_create(name="admin")

        user1, _ = User.get_or_create(
                            first_name="Admin",
                            last_name="Admin",
                            email="admin@gmail.com",
                            password="password",
                        )
        user2, _ = User.get_or_create(
            first_name="Bob",
            last_name="Henry",
            email="bob@gmail.com",
            password="password",
        )
        user3, _ = User.get_or_create(
                    first_name="Alice",
                    last_name="Smith",
                    email="alice@email.com",
                    password="password",
                )

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

    db.close()
    print("Database seeded successfully!")

if __name__ == "__main__":
    seed()
