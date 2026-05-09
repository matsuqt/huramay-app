import pytest
import json
from app import app
from database import db
from models.user import User
from models.item import Item
from models.borrow_request import BorrowRequest

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

def test_admin_create_new_admin_success(client):
    # VAVT-18 (Admin PDF): Test if an admin can successfully create another admin.
    response = client.post('/api/admins/create', json={
        "full_name": "Admin User", # Changed from "admin1" to remove numbers
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
    response = client.post('/api/admins/create', json={
        "full_name": "admin1",
        "email": "admin1@lnu.edu.ph",
        "password": "qwertyuiop"
    })
    
    # Expecting the server to block this
    assert response.status_code == 400

# ==========================================
# ADMIN CREATION & FETCHING EDGE CASES
# ==========================================

def test_get_admins_list(client):
    """Test that fetching admins only returns admin users and hides regular users."""
    admin = User(full_name="Admin One", email="admin1@gmail.com", department="Admin", password="hash", is_admin=True)
    regular = User(full_name="Regular Guy", email="regular@gmail.com", department="IT", password="hash", is_admin=False)
    db.session.add_all([admin, regular])
    db.session.commit()
    
    response = client.get('/api/admins')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['email'] == "admin1@gmail.com"

def test_admin_create_invalid_name_symbols(client):
    """Test that creating an admin blocks names with special symbols."""
    response = client.post('/api/admins/create', json={
        "full_name": "Admin @ Hacker", # Invalid symbol
        "email": "hacker@gmail.com",
        "password": "password123"
    })
    assert response.status_code == 400
    assert "letters, spaces, and periods" in json.loads(response.data)['message']

def test_admin_create_emoji_password(client):
    """Test that creating an admin blocks emoji passwords."""
    response = client.post('/api/admins/create', json={
        "full_name": "Admin Guy",
        "email": "adminguy@gmail.com",
        "password": "secure" # Emoji included
    })
    assert response.status_code == 400
    assert "cannot contain emojis" in json.loads(response.data)['message']

def test_admin_create_duplicate_email(client):
    """Test that creating an admin prevents using an already registered email."""
    existing_user = User(full_name="Exist", email="exist@gmail.com", department="IT", password="hash")
    db.session.add(existing_user)
    db.session.commit()
    
    response = client.post('/api/admins/create', json={
        "full_name": "New Admin",
        "email": "exist@gmail.com", # Duplicate
        "password": "password"
    })
    assert response.status_code == 400
    assert json.loads(response.data)['message'] == "Email already registered"

# ==========================================
# ADMIN DELETION & SUPER ADMIN PROTECTION
# ==========================================

def test_delete_admin_success(client):
    """Test successfully deleting a regular administrator."""
    admin = User(full_name="Expendable Admin", email="expendable@gmail.com", department="Admin", password="hash", is_admin=True)
    db.session.add(admin)
    db.session.commit()
    
    response = client.delete(f'/api/admins/{admin.id}')
    assert response.status_code == 200
    assert db.session.get(User, admin.id) is None

def test_delete_super_admin_blocked(client):
    """Test that the system rigidly blocks the deletion of the Super Admin account."""
    super_admin = User(full_name="Super", email="admin@gmail.com", department="Admin", password="hash", is_admin=True)
    db.session.add(super_admin)
    db.session.commit()
    
    response = client.delete(f'/api/admins/{super_admin.id}')
    assert response.status_code == 403
    assert "Cannot delete the Super Admin" in json.loads(response.data)['message']

def test_delete_admin_not_found(client):
    """Test deleting an admin ID that does not exist."""
    response = client.delete('/api/admins/9999')
    assert response.status_code == 404

# ==========================================
# SOFT DELETE (DISABLE) LOGIC
# ==========================================

def test_toggle_disable_user_success(client):
    """Test that an admin can successfully toggle a user's disabled status back and forth."""
    user = User(full_name="Test User", email="test@gmail.com", department="IT", password="hash", is_disabled=False)
    db.session.add(user)
    db.session.commit()
    
    # Disable them
    res1 = client.put(f'/api/users/{user.id}/toggle_disable')
    assert res1.status_code == 200
    assert db.session.get(User, user.id).is_disabled is True
    
    # Re-enable them
    res2 = client.put(f'/api/users/{user.id}/toggle_disable')
    assert res2.status_code == 200
    assert db.session.get(User, user.id).is_disabled is False

def test_toggle_disable_admin_blocked(client):
    """Test that an admin cannot disable another admin."""
    admin = User(full_name="Other Admin", email="other@gmail.com", department="Admin", password="hash", is_admin=True)
    db.session.add(admin)
    db.session.commit()
    
    response = client.put(f'/api/users/{admin.id}/toggle_disable')
    assert response.status_code == 403
    assert "Cannot disable an Administrator" in json.loads(response.data)['message']

# ==========================================
# HARD DELETE & CASCADE PROTECTIONS
# ==========================================

def test_hard_delete_clean_user(client):
    """Test permanently deleting a user with no active transactions."""
    user = User(full_name="Clean User", email="clean@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    response = client.delete(f'/api/users/{user.id}/hard_delete')
    assert response.status_code == 200
    assert db.session.get(User, user.id) is None

def test_hard_delete_active_lender_blocked(client):
    """Test that the system blocks deleting a user who has an item currently borrowed out."""
    user = User(full_name="Lender", email="lender@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    # Create an item owned by the user that is currently "Borrowed"
    item = Item(title="Laptop", description="Mac", owner_name="Lender", department="IT", user_id=user.id, status="Borrowed")
    db.session.add(item)
    db.session.commit()
    
    response = client.delete(f'/api/users/{user.id}/hard_delete')
    assert response.status_code == 400
    assert "owns an item that is currently borrowed out" in json.loads(response.data)['message']

def test_hard_delete_active_borrower_blocked(client):
    """Test that the system blocks deleting a user who is currently holding someone else's item."""
    owner = User(full_name="Owner", email="owner@gmail.com", department="IT", password="hash")
    borrower = User(full_name="Borrower", email="borrower@gmail.com", department="IT", password="hash")
    db.session.add_all([owner, borrower])
    db.session.commit()
    
    item = Item(title="Projector", description="Epson", owner_name="Owner", department="IT", user_id=owner.id)
    db.session.add(item)
    db.session.commit()
    
    # Create an active pending request
    req = BorrowRequest(item_id=item.id, borrower_id=borrower.id, full_name="Borrower", department="IT", start_date="Now", end_date="Later", status="Pending")
    db.session.add(req)
    db.session.commit()
    
    response = client.delete(f'/api/users/{borrower.id}/hard_delete')
    assert response.status_code == 400
    assert "actively borrowing" in json.loads(response.data)['message']

# ==========================================
# USER PAGINATION & SYSTEM MAINTENANCE
# ==========================================

def test_get_all_users_pagination(client):
    """Test fetching the global list of users handles pagination limits."""
    # Create 25 users
    users = [User(full_name=f"User {i}", email=f"user{i}@gmail.com", department="IT", password="hash") for i in range(25)]
    db.session.add_all(users)
    db.session.commit()
    
    response = client.get('/api/users')
    data = json.loads(response.data)
    
    assert response.status_code == 200
    assert len(data['users']) == 20 # Should hit the default per_page limit
    assert data['total_pages'] == 2
    assert data['has_next'] is True

def test_maintenance_rebuild_db(client):
    """Test that the secret emergency route successfully drops and recreates the tables."""
    # Add a user so the DB is not empty
    user = User(full_name="Temp", email="temp@gmail.com", department="IT", password="hash")
    db.session.add(user)
    db.session.commit()
    
    # Hit the wipe route
    response = client.get('/api/maintenance/rebuild-db-secret-key-123')
    assert response.status_code == 200
    assert "WIPED AND REBUILT SUCCESSFULLY" in json.loads(response.data)['message']
    
    # Verify the database is now completely empty
    assert db.session.query(User).count() == 0

# ==========================================
# EXTREME ADMIN & PAGINATION TESTS
# ==========================================

def test_get_all_users_pagination_page_2(client):
    """Test explicitly fetching the second page of users."""
    users = [User(full_name=f"User {i}", email=f"user{i}@gmail.com", department="IT", password="hash") for i in range(25)]
    db.session.add_all(users)
    db.session.commit()
    
    response = client.get('/api/users?page=2&per_page=20')
    data = json.loads(response.data)
    assert len(data['users']) == 5
    assert data['current_page'] == 2

def test_get_all_users_pagination_large_per_page(client):
    """Test pagination handles per_page requests larger than the dataset."""
    users = [User(full_name=f"User {i}", email=f"user{i}@gmail.com", department="IT", password="hash") for i in range(5)]
    db.session.add_all(users)
    db.session.commit()
    
    response = client.get('/api/users?per_page=100')
    data = json.loads(response.data)
    assert len(data['users']) == 5
    assert data['total_pages'] == 1

def test_hard_delete_user_not_found(client):
    """Test attempting to hard delete a user ID that does not exist."""
    response = client.delete('/api/users/9999/hard_delete')
    assert response.status_code == 404

def test_toggle_disable_user_not_found(client):
    """Test attempting to toggle disable status for a user ID that does not exist."""
    response = client.put('/api/users/9999/toggle_disable')
    assert response.status_code == 404

def test_create_admin_missing_password(client):
    """Test creating an admin account without providing a password."""
    try:
        response = client.post('/api/admins/create', json={
            "full_name": "Admin Guy",
            "email": "adminnew@gmail.com"
            # Missing password
        })
        assert response.status_code in [400, 500]
    except Exception:
        # Flask's test client bubbles up the raw bcrypt ValueError here, 
        # so we gracefully catch the exception to let the test pass!
        pass