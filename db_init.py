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
    UserInfo
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
    UserInfo
]

def initialize_database():
    db.connect(reuse_if_open=True)
    db.create_tables(TABLES, safe=True)