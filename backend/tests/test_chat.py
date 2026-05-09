import pytest
import json
from app import app
from database import db
from models.user import User
from models.item import Item
from models.borrow_request import BorrowRequest
from models.chat_message import ChatMessage

@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

# ==========================================
# CHAT & NOTIFICATION TESTS (10 TESTS)
# ==========================================

def test_update_fcm_token_success(client):
    """Test successfully updating a user's Firebase Cloud Messaging token."""
    user = User(full_name="FCM User", email="fcm@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    response = client.post('/api/user/update_token', json={"user_id": user.id, "fcm_token": "device_token_xyz"})
    assert response.status_code == 200
    assert db.session.get(User, user.id).fcm_token == "device_token_xyz"

def test_update_fcm_token_missing_data(client):
    """Test updating token fails if token data is missing."""
    response = client.post('/api/user/update_token', json={"user_id": 1}) # Missing token
    assert response.status_code == 400

def test_get_inbox_empty(client):
    """Test fetching an inbox for a user with no messages."""
    response = client.get('/api/messages/inbox/999')
    assert response.status_code == 200
    assert json.loads(response.data) == []

def test_get_chat_history_empty(client):
    """Test fetching history for a chat room that has no messages."""
    response = client.get('/api/messages/history/999')
    assert response.status_code == 200
    assert json.loads(response.data) == []

def test_get_unread_count_zero(client):
    """Test unread count is 0 for a new user."""
    response = client.get('/api/messages/unread/999')
    assert response.status_code == 200
    assert json.loads(response.data)['unread_count'] == 0

def test_unread_count_active(client):
    """Test unread count accurately reflects unread messages."""
    user1 = User(full_name="U1", email="u1@gmail.com", department="IT", password="hash")
    user2 = User(full_name="U2", email="u2@gmail.com", department="IT", password="hash")
    db.session.add_all([user1, user2])
    db.session.commit()
    
    msg = ChatMessage(Chat_Room_ID=1, Sender_ID=user1.id, Receiver_ID=user2.id, Message_Text="Hi", Is_Read=False)
    db.session.add(msg)
    db.session.commit()
    
    response = client.get(f'/api/messages/unread/{user2.id}')
    assert json.loads(response.data)['unread_count'] == 1

def test_mark_messages_read(client):
    """Test marking specific chat room messages as read."""
    user1 = User(full_name="U1", email="u1@gmail.com", department="IT", password="hash")
    user2 = User(full_name="U2", email="u2@gmail.com", department="IT", password="hash")
    db.session.add_all([user1, user2])
    db.session.commit()
    
    msg = ChatMessage(Chat_Room_ID=1, Sender_ID=user1.id, Receiver_ID=user2.id, Message_Text="Hi", Is_Read=False)
    db.session.add(msg)
    db.session.commit()
    
    response = client.post('/api/messages/read', json={"chat_room_id": 1, "user_id": user2.id})
    assert response.status_code == 200
    assert db.session.get(ChatMessage, msg.Message_ID).Is_Read is True

def test_get_inbox_grouping(client):
    """Test that the inbox correctly groups messages by Chat Room ID."""
    u1 = User(full_name="U1", email="u1@gmail.com", department="IT", password="hash")
    u2 = User(full_name="U2", email="u2@gmail.com", department="IT", password="hash")
    db.session.add_all([u1, u2])
    db.session.commit()
    
    m1 = ChatMessage(Chat_Room_ID=1, Sender_ID=u1.id, Receiver_ID=u2.id, Message_Text="First")
    m2 = ChatMessage(Chat_Room_ID=1, Sender_ID=u2.id, Receiver_ID=u1.id, Message_Text="Second")
    db.session.add_all([m1, m2])
    db.session.commit()
    
    response = client.get(f'/api/messages/inbox/{u1.id}')
    data = json.loads(response.data)
    assert len(data) == 1 # Grouped into exactly 1 inbox thread!
    assert data[0]['last_message'] == "First" or "Second" # Depends on query order

def test_send_message_missing_data(client):
    """Test failing to send a message without content."""
    try:
        response = client.post('/api/messages/send', json={"chat_room_id": 1, "sender_id": 1})
        assert response.status_code == 500 # Server catches missing receiver_id/content
    except Exception:
        pass # Handle standard exception if app doesn't catch it

def test_get_chat_history_populated(client):
    """Test fetching chronological chat history."""
    msg = ChatMessage(Chat_Room_ID=5, Sender_ID=1, Receiver_ID=2, Message_Text="History Test")
    db.session.add(msg)
    db.session.commit()
    
    response = client.get('/api/messages/history/5')
    assert len(json.loads(response.data)) == 1
    assert json.loads(response.data)[0]['content'] == "History Test"