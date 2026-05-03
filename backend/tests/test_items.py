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
            # Create a default user for item ownership
            user = User(full_name="Francis Villamor", email="francis@gmail.com", department="BSIT", password="hash")
            db.session.add(user)
            db.session.commit()
            yield client
            db.drop_all()

# ==========================================
# ITEM MANAGEMENT TESTS
# ==========================================

def test_create_item_success(client):
    response = client.post('/api/items', json={
        "title": "Arduino Uno",
        "description": "Microcontroller for IoT projects",
        "quantity": 1,
        "condition": "Good",
        "owner_name": "Francis Villamor",
        "department": "BSIT",
        "user_id": 1
    })
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Item posted successfully!"

def test_get_all_items(client):
    # Setup Item
    item = Item(title="Test Item", description="Desc", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.get('/api/items')
    assert response.status_code == 200
    assert len(json.loads(response.data)) == 1

def test_search_items_by_keyword(client):
    item1 = Item(title="Laptop Charger", description="Type C", owner_name="Francis", department="BSIT", user_id=1)
    item2 = Item(title="Whiteboard", description="With markers", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add_all([item1, item2])
    db.session.commit()
    
    response = client.get('/api/items?search=Charger')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['title'] == "Laptop Charger"

def test_filter_items_by_department(client):
    item1 = Item(title="Router", description="Cisco", owner_name="Francis", department="BSIT", user_id=1)
    item2 = Item(title="Whistle", description="Metal", owner_name="Coach", department="BPED", user_id=1)
    db.session.add_all([item1, item2])
    db.session.commit()
    
    response = client.get('/api/items?department=BPED')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['dept'] == "BPED"

def test_get_user_specific_items(client):
    item = Item(title="My Item", description="Mine", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.get('/api/items/user/1')
    assert response.status_code == 200
    assert json.loads(response.data)[0]['title'] == "My Item"

def test_update_item(client):
    item = Item(title="Old Title", description="Old Desc", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.put(f'/api/items/{item.id}', json={"title": "New Title", "condition": "Like New"})
    assert response.status_code == 200
    
    updated = db.session.get(Item, item.id)
    assert updated.title == "New Title"
    assert updated.condition == "Like New"

def test_delete_item(client):
    item = Item(title="To Delete", description="Gone", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.delete(f'/api/items/{item.id}')
    assert response.status_code == 200
    assert db.session.get(Item, item.id) is None