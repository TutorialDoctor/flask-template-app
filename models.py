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
    state = CharField(null=True)
    city = CharField(null=True)
    family_members = CharField(null=True)
    friends = CharField(null=True)
    website = CharField(null=True)
    weight = IntegerField(null=True)
    height = IntegerField(null=True)

    class Meta:
        table_name = "user_info"


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
    info = ForeignKeyField(UserInfo, backref="user", null=True)

    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    @property
    def items(self):
        return Item.select().join(UserItem).where(UserItem.user == self)

    class Meta:
        table_name = "users"

# One-To-Many
class Item(BaseModel):
    name = CharField(null=True)
    numeral = IntegerField(null=True)
    numeral_name = CharField(null=True)  # cost, count, price
    description = CharField(null=True)
    image_url = CharField(null=True)
    item_type = CharField(null=True)
    created_at = DateTimeField(default=datetime.now)
    updated_at = DateTimeField(default=datetime.now)

    @property
    def users(self):
        return User.select().join(UserItem).where(UserItem.item == self)

    class Meta:
        table_name = "items"


# Many-To-Many
class UserItem(BaseModel):
    user = ForeignKeyField(
        User, backref="user_links", null=True, on_delete="CASCADE"
    )  # <-- Changed from 'items'
    item = ForeignKeyField(
        Item, backref="item_links", null=True, on_delete="CASCADE"
    )  # <-- Changed from 'users'

    class Meta:
        table_name = "user_items"


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
    user = ForeignKeyField(User, backref="images", null=True)
    title = CharField(null=True)
    description = TextField(null=True)
    url = CharField(null=True)
    data = BlobField(null=True)
    extension = CharField(null=True)

    class Meta:
        table_name = "images"


class Videos(BaseModel):
    user = ForeignKeyField(User, backref="videos", null=True)
    title = CharField(null=True)
    description = TextField(null=True)
    url = CharField(null=True)
    data = BlobField(null=True)
    extension = CharField(null=True)

    class Meta:
        table_name = "videos"


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
        indexes = ((("friender", "friendee"), True),)


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
