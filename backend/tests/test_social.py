import pytest
import json
from app import app
from database import db
from models.user import User
from models.item import Item

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

def test_toggle_favorite(client):
    # VAVT-39 & VAVT-40: Test adding and removing an item from favorites.
    user = User(full_name="Liker", email="liker@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()

    item = Item(title="Guitar", description="Acoustic", owner_name="Liker", department="Music", user_id=user.id)
    db.session.add(item)
    db.session.commit()

    # Add to favorites
    res_add = client.post('/api/favorites/toggle', json={"user_id": user.id, "item_id": item.id})
    assert res_add.status_code in [200, 201]
    
    # Remove from favorites
    res_remove = client.post('/api/favorites/toggle', json={"user_id": user.id, "item_id": item.id})
    assert res_remove.status_code == 200

def test_send_message(client):
    # VAVT-42 & VAVT-44: Test sending plain text and emoji messages.
    sender = User(full_name="Sender", email="sender@gmail.com", department="IT", password="hash")
    receiver = User(full_name="Receiver", email="receiver@gmail.com", department="IT", password="hash")
    db.session.add_all([sender, receiver])
    db.session.commit()

    response = client.post('/api/messages/send', json={
        "chat_room_id": 1,  
        "sender_id": sender.id,
        "receiver_id": receiver.id,
        "content": "Hello, nim utang na $400, baydi na ya 脹"
    })
    
    assert response.status_code == 201
    assert "sent" in json.loads(response.data)['message'].lower()

def test_submit_review(client):
    # VAVT-49 & VAVT-52: Test if the review will accept text and star ratings.
    reviewer = User(full_name="Reviewer", email="reviewer@gmail.com", department="IT", password="hash")
    lender = User(full_name="Lender", email="lender@gmail.com", department="IT", password="hash")
    db.session.add_all([reviewer, lender])
    db.session.commit()

    item = Item(title="Reviewed Item", description="Great item", owner_name="Lender", department="IT", user_id=lender.id)
    db.session.add(item)
    db.session.commit()

    response = client.post('/api/review', json={
        "reviewer_id": reviewer.id,
        "lender_id": lender.id,
        "item_id": item.id,
        "rating": 5,
        "review_text": "It is a helpful thing for us student 100%!"
    })
    
    assert response.status_code == 201