from models import db, Role

def seed():
    db.connect(reuse_if_open=True)

    Role.get_or_create(name="user")
    Role.get_or_create(name="admin")

    db.close()

if __name__ == "__main__":
    seed()
