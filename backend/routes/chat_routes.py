# backend/routes/chat_routes.py
from flask import Blueprint, request, jsonify
from database import db
from models.chat_message import ChatMessage
from models.user import User
from models.borrow_request import BorrowRequest

# Create the Blueprint
chat_bp = Blueprint('chat', __name__)

@chat_bp.route('/api/messages/inbox/<int:user_id>', methods=['GET'])
def get_inbox(user_id):
    messages = ChatMessage.query.filter(
        (ChatMessage.Sender_ID == user_id) | (ChatMessage.Receiver_ID == user_id)
    ).order_by(ChatMessage.Timestamp.desc()).all()
    
    inbox = {}
    for m in messages:
        if m.Chat_Room_ID not in inbox:
            other_id = m.Receiver_ID if m.Sender_ID == user_id else m.Sender_ID
            other_user = User.query.get(other_id)
            req = BorrowRequest.query.get(m.Chat_Room_ID)
            item_title = req.item.title if req and req.item else "Unknown Item"
            
            unread = ChatMessage.query.filter_by(
                Chat_Room_ID=m.Chat_Room_ID, 
                Receiver_ID=user_id, 
                Is_Read=False
            ).count()
            
            inbox[m.Chat_Room_ID] = {
                "chat_room_id": m.Chat_Room_ID,
                "other_id": other_id,
                "other_name": other_user.full_name if other_user else "Unknown",
                "item_name": item_title,
                "last_message": m.Message_Text,
                "timestamp": m.Timestamp.strftime("%I:%M %p"),
                "unread_count": unread
            }
    return jsonify(list(inbox.values())), 200

@chat_bp.route('/api/messages/history/<int:room_id>', methods=['GET'])
def get_chat_history(room_id):
    messages = ChatMessage.query.filter_by(Chat_Room_ID=room_id).order_by(ChatMessage.Timestamp.asc()).all()
    return jsonify([{
        "sender_id": m.Sender_ID,
        "content": m.Message_Text,
        "timestamp": m.Timestamp.strftime("%I:%M %p")
    } for m in messages]), 200

@chat_bp.route('/api/messages/send', methods=['POST'])
def send_message():
    data = request.get_json()
    new_msg = ChatMessage(
        Chat_Room_ID=data['chat_room_id'],
        Sender_ID=data['sender_id'],
        Receiver_ID=data['receiver_id'],
        Message_Text=data['content']
    )
    db.session.add(new_msg)
    db.session.commit()
    return jsonify({"message": "Sent!"}), 201

@chat_bp.route('/api/messages/unread/<int:user_id>', methods=['GET'])
def get_unread_count(user_id):
    count = ChatMessage.query.filter_by(Receiver_ID=user_id, Is_Read=False).count()
    return jsonify({"unread_count": count}), 200

@chat_bp.route('/api/messages/read', methods=['POST'])
def mark_messages_read():
    data = request.get_json()
    room_id = data.get('chat_room_id')
    user_id = data.get('user_id')
    
    unread_msgs = ChatMessage.query.filter_by(Chat_Room_ID=room_id, Receiver_ID=user_id, Is_Read=False).all()
    for msg in unread_msgs:
        msg.Is_Read = True
    db.session.commit()
    return jsonify({"message": "Marked as read"}), 200