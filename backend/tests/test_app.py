import pytest
import json
# Import your app and database from your main app.py file
from app import app, db, User, Item, BorrowRequest

# ==========================================
# 1. SETUP: The "Test Client" Fixture
# ==========================================
@pytest.fixture
def client():
    """
    This sets up a 'fake' version of your app that runs entirely in RAM.
    It uses a temporary memory database so it NEVER touches your real User.db!
    """
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:' # Temporary DB
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    with app.test_client() as client:
        with app.app_context():
            # Create all tables in the temporary database
            db.create_all()
            
            yield client # This pauses here and runs your tests
            
            # After tests finish, destroy the temporary database
            db.drop_all()

# ==========================================
# 2. THE TESTS
# ==========================================

def test_register_user(client):
    """Test that a new student can successfully register."""
    response = client.post('/api/register', json={
        "full_name": "Matthew Valila",
        "email": "matthew@gmail.com",
        "department": "Information Technology",
        "password": "securepassword123"
    })
    
    # Check that the server responded with 201 Created
    assert response.status_code == 201
    
    # Check that the success message matches exactly
    data = json.loads(response.data)
    assert data['message'] == "Registration successful!"

def test_login_user(client):
    """Test that a registered user can log in."""
    # Step 1: Register a user first
    client.post('/api/register', json={
        "full_name": "Karyle",
        "email": "karyle@gmail.com",
        "department": "Education",
        "password": "mypassword"
    })

    # Step 2: Try to log in with those credentials
    response = client.post('/api/login', json={
        "email": "karyle@gmail.com",
        "password": "mypassword"
    })

    assert response.status_code == 200
    data = json.loads(response.data)
    
    # Verify the backend sent back the correct user data
    assert data['message'] == "Login successful!"
    assert data['full_name'] == "Karyle"
    assert data['department'] == "Education"

def test_submit_borrow_request(client):
    """Test that a user can request to borrow an item."""
    
    # Step 1: Manually add an Item and a User to the temporary database
    user = User(full_name="Borrower Bob", email="bob@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()

    item = Item(title="Arduino Uno", description="Microcontroller", quantity=1, 
                owner_name="Admin", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()

    # Step 2: Send the borrow request to the API
    response = client.post('/api/borrow/request', json={
        "item_id": item.id,
        "borrower_id": user.id,
        "full_name": "Borrower Bob",
        "department": "IT",
        "start_date": "2026-04-10",
        "end_date": "2026-04-12",
        "meetup_location": "LNU Library"
    })

    # Step 3: Check the API response
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Borrow request submitted successfully!"

    # Step 4: Verify it actually saved to the database correctly
    saved_request = BorrowRequest.query.first()
    assert saved_request is not None
    assert saved_request.status == "Pending"
    assert saved_request.meetup_location == "LNU Library"