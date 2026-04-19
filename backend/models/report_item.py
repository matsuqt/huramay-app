# backend/models/report_item.py
from database import db
from datetime import datetime, timedelta, timezone

def get_ph_time():
    return datetime.now(timezone.utc) + timedelta(hours=8)

class ReportItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    reporter_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=False)
    report_text = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=get_ph_time)
    
    reporter = db.relationship('User')
    item = db.relationship('Item')