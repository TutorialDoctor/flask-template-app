from flask import Flask
from flask_caching import Cache
from peewee import SqliteDatabase
from config import DevelopmentConfig
import os

app = Flask(__name__)
app.config.from_object(DevelopmentConfig)
cache = Cache()
db = SqliteDatabase(app.config['PEEWEE_DATABASE_URI'])

# 3. Define allowed file extensions
ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}

# Ensure the upload directory actually exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)