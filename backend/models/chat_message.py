# backend/models/chat_message.py
from database import db
from datetime import datetime, timedelta, timezone

def get_ph_time():
    # Always returns the current time in the Philippines (UTC+8)
    return datetime.now(timezone.utc) + timedelta(hours=8)

class ChatMessage(db.Model):
    __tablename__ = 'chats'
    Message_ID = db.Column(db.Integer, primary_key=True)
    Chat_Room_ID = db.Column(db.Integer, nullable=False) 
    Sender_ID = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    Receiver_ID = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    Message_Text = db.Column(db.Text, nullable=False)
    Timestamp = db.Column(db.DateTime, default=get_ph_time)
    Is_Read = db.Column(db.Boolean, default=False)