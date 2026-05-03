import pytest
import json
from app import app
from database import db, bcrypt 
# Point directly to the model files in your models folder
from models.user import User
from models.item import Item
from models.borrow_request import BorrowRequest
from models.report_item import ReportItem

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

# --------------- SIGNUP -------------------

def test_register_user(client):
    # Test that a new student can successfully register.
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

def test_successful_signup(client):
    # VAVT-02: User inputs correct information and @gmail.com extension.
    response = client.post('/api/register', json={
        "full_name": "Matthew T. Valila",
        "email": "matthewvalila03@gmail.com",
        "department": "Bachelor of Science in Information Technology",
        "password": "securepassword123"
    })
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Registration successful!"

def test_signup_fullname_with_special_character(client):
    # Unsuccessful signup because full name contains invalid special characters
    response = client.post('/api/register', json={
        "full_name": "Matthew Valila!", # Contains the '!' symbol
        "email": "matthew_valid@gmail.com",
        "department": "BSIT",
        "password": "securepassword123"
    })
    
    assert response.status_code == 400
    data = json.loads(response.data)
    # Check that the error message mentions the name
    assert "name" in data['message'].lower()

def test_signup_fullname_with_emoji(client):
    # Unsuccessful signup because full name contains an emoji
    response = client.post('/api/register', json={
        "full_name": "Matthew Valila 👨‍💻", # Contains an emoji
        "email": "matthew_valid2@gmail.com",
        "department": "BSIT",
        "password": "securepassword123"
    })
    
    assert response.status_code == 400
    data = json.loads(response.data)    
    assert "name" in data['message'].lower()

def test_signup_wrong_email_extension(client):
    # VAVT-03: Unsuccessful signup because email is not @gmail.com (@edu.ph).
    response = client.post('/api/register', json={
        "full_name": "Matthew T. Valila",
        "email": "matthewvalila03@edu.ph",
        "department": "Bachelor of Science in Information Technology",
        "password": "securepassword123"
    })
    # The test expects the backend to block this (Status 400). 
    # If your backend currently allows this, this test will FAIL, alerting you to fix app.py!
    assert response.status_code == 400
    assert "gmail.com" in json.loads(response.data).get('message', '').lower()

def test_signup_email_with_special_character(client):
    # VAVT-04/05: Unsuccessful signup because email contains invalid special characters
    response = client.post('/api/register', json={
        "full_name": "Matthew Valila",
        "email": "matthew#valila@gmail.com", # Contains the '#' symbol
        "department": "BSIT",
        "password": "securepassword123"
    })
    
    # We expect the server to block this and return a 400 Bad Request
    assert response.status_code == 400
    data = json.loads(response.data)
    assert "special character" in data['message'].lower() or "emoji" in data['message'].lower()

def test_signup_email_with_emoji(client):
    # VAVT-06: Unsuccessful signup because email contains an emoji
    response = client.post('/api/register', json={
        "full_name": "Matthew Valila",
        "email": "matthew😎@gmail.com", # Contains an emoji
        "department": "BSIT",
        "password": "securepassword123"
    })
    
    assert response.status_code == 400
    data = json.loads(response.data)
    assert "special character" in data['message'].lower() or "emoji" in data['message'].lower()

def test_signup_password_with_emoji(client):
    # VAVT-08: Unsuccessful signup because password contains an emoji
    response = client.post('/api/register', json={
        "full_name": "Matthew Valila",
        "email": "matthewvalila@gmail.com",
        "department": "BSIT",
        "password": "securepassword123😊" # Contains an emoji
    })
    
    assert response.status_code == 400
    data = json.loads(response.data)
    assert "emoji" in data['message'].lower()

def test_register_duplicate_email(client):
    # Test that the app blocks two users from using the same email.
    
    # 1. Register the first user
    client.post('/api/register', json={
        "full_name": "First User",
        "email": "clone@gmail.com",
        "department": "IT",
        "password": "password"
    })
    
    # 2. Try to register a second user with the exact same email
    response = client.post('/api/register', json={
        "full_name": "Copycat User",
        "email": "clone@gmail.com",  # Same email!
        "department": "Education",
        "password": "password123"
    })
    
    # 3. We EXPECT it to fail with a 400 status code
    assert response.status_code == 400
    
    # 4. Check that your app gave the correct error message
    import json
    data = json.loads(response.data)
    assert data['message'] == "Email already registered"

# --------------- LOGIN -------------------

def test_login_user(client):
    # Test that a registered user can log in.
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

def test_login_wrong_extension(client):
    # VAVT-12: Unsuccessful login because of wrong email extension.
    response = client.post('/api/login', json={
        "email": "matthewvalila03@edu.ph",
        "password": "securepassword123"
    })
    assert response.status_code == 401
    assert json.loads(response.data)['message'] == "Invalid email or password"

# --------------- DASHBOARD -------------------  

def test_search_bar_valid(client):
    # VAVT-15: Test the Search Bar by searching for 'Calculator'.
    # Setup: Create a User and an Item
    user = User(full_name="Admin", email="admin@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    item = Item(title="Casio Calculator", description="Scientific calc", quantity=1, 
                owner_name="Admin", department="IT", user_id=user.id, status="Available")
    db.session.add(item)
    db.session.commit()

    # Search for 'Calculator'
    response = client.get('/api/items?search=Calculator')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data) == 1
    assert "Calculator" in data[0]['title']

def test_filter_available_items(client):
    # VAVT-18: Test if the filters for 'Available' works correctly.
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
    assert len(data) == 1
    assert data[0]['status'] == "Available"
    assert data[0]['title'] == "Book"

# --------------- PROFILE -------------------  

def test_reset_password(client):
    # VAVT-63: Test if the reset password works correctly.
    from app import bcrypt
    
    # Register user with old password
    client.post('/api/register', json={
        "full_name": "Matthew T. Valila",
        "email": "matthewvalila03@gmail.com",
        "department": "BSIT",
        "password": "oldpassword"
    })
    user = User.query.filter_by(email="matthewvalila03@gmail.com").first()

    # Reset Password
    response = client.post('/api/user/reset_password', json={
        "email": "matthewvalila03@gmail.com",
        "current_user_id": user.id,
        "new_password": "newpassword123"
    })
    
    assert response.status_code == 200
    assert json.loads(response.data)['message'] == "Password reset successfully!"
    
    # Verify the hash actually changed and matches the new password
    updated_user = db.session.get(User, user.id)
    assert bcrypt.check_password_hash(updated_user.password, "newpassword123") == True
    
def test_update_profile_photo(client):
    # VAVT-62 & VAVT-64: Test updating the user's profile photo path.
    
    # 1. Setup: Register a user first
    client.post('/api/register', json={
        "full_name": "Matthew T. Valila",
        "email": "matthew_profile@gmail.com",
        "department": "BSIT",
        "password": "securepassword123"
    })
    
    # Grab that user from the database to get their ID
    user = User.query.filter_by(email="matthew_profile@gmail.com").first()

    # 2. Action: Send the new photo path to the update route
    response = client.post('/api/user/update', json={
        "id": user.id,
        "photo_path": "/assets/images/new_profile_pic.jpg"
    })
    
    # 3. Assertions: Check if the server responded correctly
    assert response.status_code == 200
    assert json.loads(response.data)['message'] == "Profile updated successfully!"
    
    # 4. Verify Database: Ensure the photo path actually changed in User.db
    # Note: Using the modern db.session.get() to avoid that yellow warning!
    updated_user = db.session.get(User, user.id)
    assert updated_user.photo_path == "/assets/images/new_profile_pic.jpg"

# --------------- MY ITEMS -------------------

def test_delete_my_item(client):
    # VAVT-24: Test if the Delete Button of the My Items Page works.
    user = User(full_name="User", email="user@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    item = Item(title="Whiteboard Marker", description="Black marker", owner_name="User", department="IT", user_id=user.id)
    db.session.add(item)
    db.session.commit()

    response = client.delete(f'/api/items/{item.id}')
    assert response.status_code == 200
    assert json.loads(response.data)['message'] == "Item deleted successfully!"
    assert Item.query.count() == 0

def test_update_item_name_valid(client):
    # VAVT-25: To test if the Update Form works accurately.
    user = User(full_name="User", email="user@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    item = Item(title="Old Marker", description="Black marker", owner_name="User", department="IT", user_id=user.id)
    db.session.add(item)
    db.session.commit()

    response = client.put(f'/api/items/{item.id}', json={
        "title": "Whiteboard Marker"
    })
    
    assert response.status_code == 200
    updated_item = db.session.get(Item, item.id)
    assert updated_item.title == "Whiteboard Marker"

# --------------- FAVORITES -------------------

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

# --------------- DEPARTMENT FILTERS -------------------

def test_department_filter(client):
    # VAVT-36 & VAVT-37: Test if the department filter works correctly.
    user1 = User(full_name="IT Student", email="it@gmail.com", department="IT", password="hash")
    user2 = User(full_name="Educ Student", email="educ@gmail.com", department="Education", password="hash")
    db.session.add_all([user1, user2])
    db.session.commit()
    
    item1 = Item(title="Laptop", description="Fast", owner_name="IT Student", department="IT", user_id=user1.id)
    item2 = Item(title="Chalk", description="White", owner_name="Educ Student", department="Education", user_id=user2.id)
    db.session.add_all([item1, item2])
    db.session.commit()

    # Apply Filter for 'Education'
    response = client.get('/api/items?department=Education')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['title'] == "Chalk"
    assert data[0]['dept'] == "Education"

# --------------- MESSAGES -------------------

def test_send_message(client):
    # VAVT-42 & VAVT-44: Test sending plain text and emoji messages.
    sender = User(full_name="Sender", email="sender@gmail.com", department="IT", password="hash")
    receiver = User(full_name="Receiver", email="receiver@gmail.com", department="IT", password="hash")
    db.session.add_all([sender, receiver])
    db.session.commit()

    # FIXED: Added the required 'chat_room_id' parameter
    response = client.post('/api/messages/send', json={
        "chat_room_id": 1,  
        "sender_id": sender.id,
        "receiver_id": receiver.id,
        "content": "Hello, nim utang na $400, baydi na ya 💯"
    })
    
    assert response.status_code == 201
    assert "sent" in json.loads(response.data)['message'].lower()

# --------------- REQUESTS -------------------

def test_submit_borrow_request(client):
    # Test that a user can request to borrow an item.
    user = User(full_name="Borrower Bob", email="bob@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()

    item = Item(title="Arduino Uno", description="Microcontroller", quantity=1, 
                owner_name="Admin", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()

    response = client.post('/api/borrow/request', json={
        "item_id": item.id,
        "borrower_id": user.id,
        "full_name": "Borrower Bob",
        "department": "IT",
        "start_date": "2026-04-10",
        "end_date": "2026-04-12",
        "meetup_location": "LNU Library"
    })

    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Borrow request submitted successfully!"

    saved_request = BorrowRequest.query.first()
    assert saved_request is not None
    assert saved_request.status == "Pending"

def test_accept_borrow_request(client):
    # VAVT-58: Test updating a request status.
    user = User(full_name="Lender", email="lender@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()

    item = Item(title="Project Huramay Docs", description="Paperwork", quantity=1, 
                owner_name="Lender", department="IT", user_id=user.id)
    db.session.add(item)
    db.session.commit()

    # Added required start/end dates so the DB doesn't crash
    req = BorrowRequest(item_id=item.id, borrower_id=2, full_name="Borrower", 
                        department="IT", status="Pending", meetup_location="LNU Kiosk",
                        start_date="2026-04-10", end_date="2026-04-12") 
    db.session.add(req)
    db.session.commit()

    # FIXED: Corrected the route URL from /respond/ to /request/
    response = client.put(f'/api/borrow/request/{req.id}', json={
        "status": "Accepted"
    })
    
    assert response.status_code == 200
    updated_req = db.session.get(BorrowRequest, req.id)
    assert updated_req.status == "Accepted"

# --------------- HISTORY & REVIEWS -------------------

def test_submit_review(client):
    # VAVT-49 & VAVT-52: Test if the review will accept text and star ratings.
    reviewer = User(full_name="Reviewer", email="reviewer@gmail.com", department="IT", password="hash")
    lender = User(full_name="Lender", email="lender@gmail.com", department="IT", password="hash")
    db.session.add_all([reviewer, lender])
    db.session.commit()

    # FIXED: We need to create a fake item to review first
    item = Item(title="Reviewed Item", description="Great item", owner_name="Lender", department="IT", user_id=lender.id)
    db.session.add(item)
    db.session.commit()

    # FIXED: Corrected the URL to /api/review and added 'item_id'
    response = client.post('/api/review', json={
        "reviewer_id": reviewer.id,
        "lender_id": lender.id,
        "item_id": item.id,
        "rating": 5,
        "review_text": "It is a helpful thing for us student 100%!"
    })
    
    assert response.status_code == 201

# --------------- REPORTS -------------------

def test_submit_report(client):
    # VAVT-55: Test if a user can successfully submit a report.
    reporter = User(full_name="Reporter", email="reporter@gmail.com", department="IT", password="hash")
    db.session.add(reporter)
    db.session.commit()

    item = Item(title="Broken Item", description="Scam", owner_name="Bad User", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()

    response = client.post('/api/report', json={
        "reporter_id": reporter.id,
        "item_id": item.id,
        "report_text": "This item is broken and the user is unresponsive."
    })
    
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Report submitted successfully!"

# ==========================================
# --------------- ADMIN MODULE -------------
# ==========================================

def test_admin_create_new_admin_success(client):
    # VAVT-18 (Admin PDF): Test if an admin can successfully create another admin.
    response = client.post('/api/admins/create', json={
        "full_name": "admin1",
        "email": "admin1@gmail.com",
        "password": "qwertyuiop"
    })
    
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['message'] == "Admin created successfully!"
    
    # Verify they were actually saved as an admin in the database
    new_admin = User.query.filter_by(email="admin1@gmail.com").first()
    assert new_admin is not None
    assert new_admin.is_admin == True
    assert new_admin.department == "Admin"

def test_admin_create_new_admin_invalid_email(client):
    # VAVT-19 (Admin PDF): Test if creating an admin fails with a non-gmail extension.
    # Note: Your backend /api/admins/create route needs to enforce the @gmail.com rule!
    response = client.post('/api/admins/create', json={
        "full_name": "admin1",
        "email": "admin1@lnu.edu.ph",
        "password": "qwertyuiop"
    })
    
    # Expecting the server to block this
    assert response.status_code == 400

def test_admin_get_all_reports(client):
    # Admin Dashboard requires fetching all reports submitted by users.
    reporter = User(full_name="Reporter", email="reporter@gmail.com", department="IT", password="hash")
    db.session.add(reporter)
    db.session.commit()

    item = Item(title="Broken Item", description="Scam", owner_name="Bad User", department="IT", user_id=1)
    db.session.add(item)
    db.session.commit()

    # Submit a fake report directly to the DB
    from app import ReportItem
    report = ReportItem(reporter_id=reporter.id, item_id=item.id, report_text="Bad item")
    db.session.add(report)
    db.session.commit()

    # Test the Admin route to fetch all reports
    response = client.get('/api/reports/all')
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert len(data) == 1
    assert data[0]['report_text'] == "Bad item"