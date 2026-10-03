from extensions import db
from models import User

from models import (
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
    UserItem,
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
    UserItem,
    UserInfo,
]
    
def initialize_database():
    db.connect(reuse_if_open=True)
    db.create_tables(TABLES, safe=True)
    # Seed here?
