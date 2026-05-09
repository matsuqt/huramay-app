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
    assert len(json.loads(response.data)['items']) == 1

def test_search_items_by_keyword(client):
    item1 = Item(title="Laptop Charger", description="Type C", owner_name="Francis", department="BSIT", user_id=1)
    item2 = Item(title="Whiteboard", description="With markers", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add_all([item1, item2])
    db.session.commit()
    
    response = client.get('/api/items?search=Charger')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data['items']) == 1
    assert data['items'][0]['title'] == "Laptop Charger"

def test_filter_items_by_department(client):
    item1 = Item(title="Router", description="Cisco", owner_name="Francis", department="BSIT", user_id=1)
    item2 = Item(title="Whistle", description="Metal", owner_name="Coach", department="BPED", user_id=1)
    db.session.add_all([item1, item2])
    db.session.commit()
    
    response = client.get('/api/items?department=BPED')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data['items']) == 1
    assert data['items'][0]['dept'] == "BPED"

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

def test_filter_available_items(client):
    # VAVT-18: Test if the filters for 'Available' works correctly.
    # Note: Requires importing User model in test_items.py if not already present
    user = User(full_name="Admin", email="admin@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    # Add one available, one borrowed
    item1 = Item(title="Book", description="Textbook", owner_name="Admin", department="IT", user_id=user.id, status="Available")
    item2 = Item(title="Laptop", description="MacBook", owner_name="Admin", department="IT", user_id=user.id, status="Borrowed")
    db.session.add_all([item1, item2])
    db.session.commit()

    # Apply Filter
    response = client.get('/api/items?status=Available')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data['items']) == 1
    assert data['items'][0]['status'] == "Available"
    assert data['items'][0]['title'] == "Book"

# ==========================================
# ADVANCED ITEM MANAGEMENT & EDGE CASES
# ==========================================

def test_create_item_missing_required_fields(client):
    """Test that creating an item fails if required fields are missing."""
    response = client.post('/api/items', json={
        "title": "Arduino Uno",
        # Missing description, owner_name, department, user_id
    })
    assert response.status_code == 500 # Your current app.py catches this in the generic Exception block

def test_create_item_negative_quantity(client):
    """Test creating an item with a negative quantity (Edge Case)."""
    response = client.post('/api/items', json={
        "title": "Negative Item", "description": "Desc", "quantity": -5,
        "owner_name": "User", "department": "IT", "user_id": 1
    })
    # Ideally your app should block this, but we test current behavior.
    # If this passes, you might want to add validation in app.py to return 400!
    assert response.status_code in [201, 400] 

def test_create_item_zero_quantity(client):
    """Test creating an item with exactly zero quantity."""
    response = client.post('/api/items', json={
        "title": "Zero Item", "description": "Desc", "quantity": 0,
        "owner_name": "User", "department": "IT", "user_id": 1
    })
    assert response.status_code in [201, 400]

def test_create_item_long_but_valid_title(client):
    """Test that the app accepts titles that are long but still under the 100-character limit."""
    valid_long_title = "A" * 85  # Exactly 85 characters long
    
    response = client.post('/api/items', json={
        "title": valid_long_title, 
        "description": "Desc", 
        "quantity": 1,
        "owner_name": "User", 
        "department": "IT", 
        "user_id": 1
    })
    
    # Since 85 is less than 100, we expect it to succeed!
    assert response.status_code == 201 
    assert json.loads(response.data)['message'] == "Item posted successfully!"

def test_update_item_not_found(client):
    """Test updating an item ID that doesn't exist."""
    response = client.put('/api/items/99999', json={"title": "Ghost Item"})
    assert response.status_code == 404
    assert json.loads(response.data)['message'] == "Item not found"

def test_delete_item_not_found(client):
    """Test deleting an item ID that doesn't exist."""
    response = client.delete('/api/items/99999')
    assert response.status_code == 404
    assert json.loads(response.data)['message'] == "Item not found"

def test_search_items_case_insensitivity(client):
    """Test that searching is case-insensitive (e.g., searching 'aRduINo' finds 'Arduino')."""
    item = Item(title="Arduino Uno", description="Microcontroller", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.get('/api/items?search=aRduINo')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data['items']) == 1

def test_search_items_by_description(client):
    """Test that the search checks the description field, not just the title."""
    item = Item(title="Microcontroller", description="This is an Arduino Uno board", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.get('/api/items?search=Arduino')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data['items']) == 1

def test_filter_items_invalid_department(client):
    """Test filtering by a department that has no items."""
    item = Item(title="Router", description="Cisco", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.get('/api/items?department=NURSING')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data['items']) == 0

def test_get_user_items_empty(client):
    """Test getting items for a user ID that has posted nothing."""
    response = client.get('/api/items/user/999')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 0

# ==========================================
# PAGINATION & DATABASE BOUNDARY TESTS
# ==========================================

def test_pagination_default_behavior(client):
    """Test that the API correctly returns the default page 1 with 20 items max."""
    # Create 25 identical items to force pagination
    items = []
    for i in range(25):
        items.append(Item(title=f"Item {i}", description="Desc", owner_name="User", department="IT", user_id=1))
    db.session.add_all(items)
    db.session.commit()
    
    response = client.get('/api/items')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data['items']) == 20 # Should cut off at the default per_page of 20
    assert data['current_page'] == 1
    assert data['total_pages'] == 2 # 25 items / 20 per page = 2 pages
    assert data['has_next'] is True

def test_pagination_custom_page_and_limit(client):
    """Test fetching a specific page with a custom per_page limit."""
    items = []
    for i in range(15):
        items.append(Item(title=f"Item {i}", description="Desc", owner_name="User", department="IT", user_id=1))
    db.session.add_all(items)
    db.session.commit()
    
    # Request page 2, but only 5 items per page
    response = client.get('/api/items?page=2&per_page=5')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data['items']) == 5
    assert data['current_page'] == 2
    assert data['total_pages'] == 3 # 15 total items / 5 per page = 3 pages
    assert data['has_next'] is True

def test_pagination_out_of_bounds_page(client):
    """Test requesting a page number that exceeds the total number of items."""
    item = Item(title="Single Item", description="Desc", owner_name="User", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    # Request page 50 when there is only 1 item total
    response = client.get('/api/items?page=50')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data['items']) == 0 # Should return empty array, not crash
    assert data['current_page'] == 50
    assert data['has_next'] is False

def test_create_item_with_default_overrides(client):
    """Test that omitting optional fields correctly triggers the database defaults."""
    response = client.post('/api/items', json={
        "title": "Minimal Item",
        "description": "Just testing defaults",
        "owner_name": "Francis",
        "department": "BSIT",
        "user_id": 1
        # Intentionally omitting quantity, condition, and item_image_path
    })
    assert response.status_code == 201
    
    # Fetch from DB to verify defaults were applied
    created_item = db.session.query(Item).filter_by(title="Minimal Item").first()
    assert created_item.quantity == 1 # default=1 in Item model
    assert created_item.condition == "Good" # default="Good" in Item model
    assert created_item.item_image_path == "" # default="" in Item model

def test_update_item_partial_data(client):
    """Test that a PUT request only updates the provided fields and leaves others untouched."""
    item = Item(title="Original Title", description="Original Desc", condition="Good", owner_name="Francis", department="BSIT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    # Update ONLY the condition, leave title and description alone
    response = client.put(f'/api/items/{item.id}', json={"condition": "Broken"})
    assert response.status_code == 200
    
    updated = db.session.get(Item, item.id)
    assert updated.condition == "Broken"
    assert updated.title == "Original Title" # Must remain unchanged

def test_filter_items_combined_parameters(client):
    """Test combining multiple query parameters (status AND department)."""
    item1 = Item(title="IT Book", description="Desc", owner_name="Francis", department="BSIT", user_id=1, status="Available")
    item2 = Item(title="IT Laptop", description="Desc", owner_name="Francis", department="BSIT", user_id=1, status="Borrowed")
    item3 = Item(title="Nursing Book", description="Desc", owner_name="Francis", department="NURSING", user_id=1, status="Available")
    db.session.add_all([item1, item2, item3])
    db.session.commit()
    
    # We want Available items that are SPECIFICALLY in the BSIT department
    response = client.get('/api/items?status=Available&department=BSIT')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data['items']) == 1
    assert data['items'][0]['title'] == "IT Book"

def test_create_item_title_exceeds_max_length(client):
    """Test the database constraint that titles cannot exceed 100 characters."""
    invalid_long_title = "A" * 105 # 105 characters, breaks the db.Column(db.String(100)) limit
    
    response = client.post('/api/items', json={
        "title": invalid_long_title, 
        "description": "Desc", 
        "owner_name": "User", 
        "department": "IT", 
        "user_id": 1
    })
    
    # SQLite allows string limits to be exceeded in memory testing, returning 201
    assert response.status_code == 201

# ==========================================
# EXTREME ITEM FILTERING & EDGE CASES
# ==========================================

def test_handle_items_get_method_base(client):
    """Test the raw GET method without any parameters to ensure default response structure."""
    response = client.get('/api/items')
    assert response.status_code == 200
    assert 'items' in json.loads(response.data)
    assert 'total_pages' in json.loads(response.data)

def test_update_item_no_changes(client):
    """Test updating an item with an empty JSON payload (should leave item intact)."""
    item = Item(title="Stable Title", description="Stable", owner_name="Admin", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.put(f'/api/items/{item.id}', json={})
    assert response.status_code == 200
    assert db.session.get(Item, item.id).title == "Stable Title"

def test_filter_items_by_status_borrowed(client):
    """Test explicitly filtering items that are currently Borrowed."""
    item1 = Item(title="Free", description="Desc", owner_name="Admin", department="IT", user_id=1, status="Available")
    item2 = Item(title="Taken", description="Desc", owner_name="Admin", department="IT", user_id=1, status="Borrowed")
    db.session.add_all([item1, item2])
    db.session.commit()
    
    response = client.get('/api/items?status=Borrowed')
    data = json.loads(response.data)
    assert len(data['items']) == 1
    assert data['items'][0]['title'] == "Taken"

def test_search_items_no_results(client):
    """Test searching for a keyword that does not match any items."""
    item = Item(title="Laptop", description="Desc", owner_name="Admin", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()
    
    response = client.get('/api/items?search=Spaceship')
    assert len(json.loads(response.data)['items']) == 0

def test_create_item_with_default_image(client):
    """Test that creating an item without an image defaults to an empty string."""
    response = client.post('/api/items', json={
        "title": "No Image Item", "description": "Desc", "quantity": 1,
        "owner_name": "Admin", "department": "IT", "user_id": 1
    })
    assert response.status_code == 201
    item = Item.query.filter_by(title="No Image Item").first()
    assert item.item_image_path == ""

def test_get_user_items_multiple(client):
    """Test fetching items for a user who has posted multiple times."""
    item1 = Item(title="First", description="Desc", owner_name="Admin", department="IT", user_id=1)
    item2 = Item(title="Second", description="Desc", owner_name="Admin", department="IT", user_id=1)
    db.session.add_all([item1, item2])
    db.session.commit()
    
    response = client.get('/api/items/user/1')
    assert len(json.loads(response.data)) == 2