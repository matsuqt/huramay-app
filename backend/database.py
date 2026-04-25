# database.py
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt

# Initialize these here so they can be imported anywhere without causing loops
db = SQLAlchemy()
bcrypt = Bcrypt()