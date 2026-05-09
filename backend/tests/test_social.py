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

# ==========================================
# REVIEW LOGIC & EDGE CASES
# ==========================================

def test_submit_review_lender_not_found(client):
    """Test attempting to review a lender ID that doesn't exist."""
    response = client.post('/api/review', json={
        "reviewer_id": 1,
        "lender_id": 9999, # Does not exist
        "item_id": 1,
        "rating": 5,
        "review_text": "Good"
    })
    assert response.status_code == 404
    assert json.loads(response.data)['message'] == "Lender not found"

def test_review_rating_average_calculation(client):
    """Test that the first review overrides the 5.0 default, and the second review averages correctly."""
    reviewer = User(full_name="Reviewer", email="reviewer@gmail.com", department="IT", password="hash")
    lender = User(full_name="Lender", email="lender@gmail.com", department="IT", password="hash")
    db.session.add_all([reviewer, lender])
    db.session.commit()
    
    # Lender starts at default 5.0
    assert lender.rating == 5.0
    
    # 1st Review: Gives a 3.0. Because lender is at default 5.0, it should completely overwrite it to 3.0
    client.post('/api/review', json={
        "reviewer_id": reviewer.id, "lender_id": lender.id, "item_id": 1, "rating": 3, "review_text": "Okay"
    })
    assert db.session.get(User, lender.id).rating == 3.0
    
    # 2nd Review: Gives a 5.0. It should now average the existing 3.0 and new 5.0 to make 4.0
    client.post('/api/review', json={
        "reviewer_id": reviewer.id, "lender_id": lender.id, "item_id": 1, "rating": 5, "review_text": "Better"
    })
    assert db.session.get(User, lender.id).rating == 4.0

def test_get_item_reviews_success(client):
    """Test fetching reviews for an item and verifying the nested user data format."""
    reviewer = User(full_name="Alice", email="alice@gmail.com", department="IT", password="hash")
    lender = User(full_name="Bob", email="bob@gmail.com", department="IT", password="hash")
    item = Item(title="Pen", description="Blue", owner_name="Bob", department="IT", user_id=2)
    db.session.add_all([reviewer, lender, item])
    db.session.commit()
    
    client.post('/api/review', json={
        "reviewer_id": reviewer.id, "lender_id": lender.id, "item_id": item.id, "rating": 5, "review_text": "Great pen!"
    })
    
    response = client.get(f'/api/reviews/item/{item.id}')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['reviewer_name'] == "Alice" # Verifies the relationship mapping worked
    assert data[0]['comment'] == "Great pen!"

def test_get_item_reviews_empty(client):
    """Test fetching reviews for an item that has not been reviewed yet."""
    response = client.get('/api/reviews/item/999')
    assert response.status_code == 200
    assert json.loads(response.data) == [] # Should not crash, just return empty list

# ==========================================
# ADVANCED FAVORITE TESTS
# ==========================================

def test_get_favorites_empty(client):
    """Test fetching favorites for a user who has none."""
    response = client.get('/api/favorites/999')
    assert response.status_code == 200
    assert len(json.loads(response.data)) == 0

def test_check_favorite_true(client):
    """Test the boolean check endpoint returns True when an item is favorited."""
    user = User(full_name="User", email="u@gmail.com", department="IT", password="hash")
    item = Item(title="Item", description="Desc", owner_name="Admin", department="IT", user_id=1)
    db.session.add_all([user, item])
    db.session.commit()
    
    client.post('/api/favorites/toggle', json={"user_id": user.id, "item_id": item.id})
    
    response = client.post('/api/favorites/check', json={"user_id": user.id, "item_id": item.id})
    assert json.loads(response.data)['is_favorite'] is True

def test_check_favorite_false(client):
    """Test the boolean check endpoint returns False when an item is not favorited."""
    response = client.post('/api/favorites/check', json={"user_id": 999, "item_id": 999})
    assert json.loads(response.data)['is_favorite'] is False

def test_get_favorites_populated(client):
    """Test fetching actual item data through the favorites relationship."""
    user = User(full_name="User", email="u@gmail.com", department="IT", password="hash")
    item = Item(title="Fav Data", description="Desc", owner_name="Admin", department="IT", user_id=1)
    db.session.add_all([user, item])
    db.session.commit()
    client.post('/api/favorites/toggle', json={"user_id": user.id, "item_id": item.id})
    
    response = client.get(f'/api/favorites/{user.id}')
    data = json.loads(response.data)
    assert len(data) == 1
    assert data[0]['title'] == "Fav Data"