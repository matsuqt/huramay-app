# backend/models/user.py
from database import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    department = db.Column(db.String(100), nullable=False)
    password = db.Column(db.String(255), nullable=False)
    photo_path = db.Column(db.Text, nullable=True, default="")
    rating = db.Column(db.Float, default=5.0) 
    is_admin = db.Column(db.Boolean, default=False)
    age = db.Column(db.Integer, nullable=True) 
    fcm_token = db.Column(db.Text, nullable=True)
    
    security_color = db.Column(db.String(100), nullable=True)
    security_song = db.Column(db.String(100), nullable=True) 
    
    # NEW: Soft Delete / Account Disable
    is_disabled = db.Column(db.Boolean, default=False)
    
    # Relationships
    items = db.relationship('Item', backref='owner', lazy=True)
    favorites = db.relationship('Favorite', backref='user', lazy=True)