# backend/models/item.py
from database import db

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    condition = db.Column(db.String(50), nullable=False, default="Good")
    item_image_path = db.Column(db.Text, nullable=True, default="")
    owner_name = db.Column(db.String(100), nullable=False)
    department = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(20), default="Available")
    
    # Foreign Key linking back to User
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)