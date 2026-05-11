# backend/app.py
from flask import Flask
from flask_cors import CORS
from database import db, bcrypt
import os
basedir = os.path.abspath(os.path.dirname(__file__))

# Import your Blueprints
from routes.auth_routes import auth_bp
from routes.item_routes import item_bp
from routes.borrow_routes import borrow_bp
from routes.chat_routes import chat_bp
from routes.favorite_routes import favorite_bp
from routes.review_routes import review_bp
from routes.admin_routes import admin_bp

app = Flask(__name__)
CORS(app)

# Database Setup
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'instance', 'User.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize DB and Bcrypt with the app
db.init_app(app)
bcrypt.init_app(app)

# Register all routes (Blueprints)
app.register_blueprint(auth_bp)
app.register_blueprint(item_bp)
app.register_blueprint(borrow_bp) 
app.register_blueprint(chat_bp)
app.register_blueprint(favorite_bp)
app.register_blueprint(review_bp)
app.register_blueprint(admin_bp)

# Create tables if they don't exist
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)