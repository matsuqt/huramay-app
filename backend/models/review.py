# backend/models/review.py
from database import db
from datetime import datetime, timedelta, timezone

def get_ph_time():
    return datetime.now(timezone.utc) + timedelta(hours=8)

class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    reviewer_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=False)
    lender_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)
    comment = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=get_ph_time)
    
    reviewer = db.relationship('User', foreign_keys=[reviewer_id])