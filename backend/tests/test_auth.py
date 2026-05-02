import pytest
import json
from app import app
from database import db, bcrypt
from models.user import User

# ==========================================
# FIXTURE: The Automatic Setup
# ==========================================
@pytest.fixture
def client():
    """Creates a fresh in-memory database for testing."""
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

# ==========================================
# 1. REGISTRATION TESTS
# ==========================================

def test_register_success(client):
    """Test successful registration with valid inputs."""
    response = client.post('/api/register', json={
        "full_name": "Francis M. Villamor",
        "email": "francis.valid@gmail.com",
        "department": "BSIT",
        "password": "securepassword123"
    })
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Registration successful!"

def test_register_invalid_name(client):
    """Test that names with numbers or special characters are blocked."""
    response = client.post('/api/register', json={
        "full_name": "Francis123!", # Invalid: contains numbers and !
        "email": "francis@gmail.com",
        "department": "BSIT",
        "password": "securepassword123"
    })
    assert response.status_code == 400
    assert "Name cannot contain numbers" in json.loads(response.data)['message']

def test_register_invalid_email(client):
    """Test that non-gmail or special character emails are blocked."""
    response = client.post('/api/register', json={
        "full_name": "Francis Villamor",
        "email": "francis@yahoo.com", # Invalid: not @gmail.com
        "department": "BSIT",
        "password": "securepassword123"
    })
    assert response.status_code == 400
    assert "not a @gmail.com address" in json.loads(response.data)['message']

def test_register_emoji_password(client):
    """Test that passwords containing emojis are blocked."""
    response = client.post('/api/register', json={
        "full_name": "Francis Villamor",
        "email": "francis@gmail.com",
        "department": "BSIT",
        "password": "password" # Invalid: contains emoji
    })
    assert response.status_code == 400
    assert "Password cannot contain emojis" in json.loads(response.data)['message']

def test_register_duplicate_email(client):
    """Test that duplicate emails are rejected."""
    client.post('/api/register', json={
        "full_name": "User One", "email": "duplicate@gmail.com",
        "department": "BSIT", "password": "password"
    })
    response = client.post('/api/register', json={
        "full_name": "User Two", "email": "duplicate@gmail.com",
        "department": "Educ", "password": "password"
    })
    assert response.status_code == 400
    assert json.loads(response.data)['message'] == "Email already registered"

# ==========================================
# 2. LOGIN TESTS
# ==========================================

def test_login_success(client):
    """Test successful login returns proper user data."""
    # 1. Setup User
    client.post('/api/register', json={
        "full_name": "Test User", "email": "testlogin@gmail.com",
        "department": "BSIT", "password": "testpassword"
    })
    
    # 2. Login
    response = client.post('/api/login', json={
        "email": "testlogin@gmail.com",
        "password": "testpassword"
    })
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['message'] == "Login successful!"
    assert data['full_name'] == "Test User"
    assert data['department'] == "BSIT"

def test_login_failure(client):
    """Test login fails with incorrect credentials."""
    response = client.post('/api/login', json={
        "email": "wrong@gmail.com",
        "password": "wrongpassword"
    })
    assert response.status_code == 401
    assert json.loads(response.data)['message'] == "Invalid email or password"

# ==========================================
# 3. PROFILE UPDATE & RESET TESTS
# ==========================================

def test_update_profile_photo(client):
    """Test updating a user's photo path."""
    client.post('/api/register', json={
        "full_name": "Photo User", "email": "photo@gmail.com",
        "department": "BSIT", "password": "password"
    })
    user = User.query.filter_by(email="photo@gmail.com").first()
    
    response = client.post('/api/user/update', json={
        "id": user.id,
        "photo_path": "new_base64_string_here"
    })
    
    assert response.status_code == 200
    assert json.loads(response.data)['message'] == "Profile updated successfully!"
    updated_user = db.session.get(User, user.id)
    assert updated_user.photo_path == "new_base64_string_here"

def test_reset_password(client):
    """Test resetting a user's password securely."""
    client.post('/api/register', json={
        "full_name": "Reset User", "email": "reset@gmail.com",
        "department": "BSIT", "password": "oldpassword"
    })
    user = User.query.filter_by(email="reset@gmail.com").first()
    
    response = client.post('/api/user/reset_password', json={
        "current_user_id": user.id,
        "email": "reset@gmail.com",
        "new_password": "newpassword123"
    })
    
    assert response.status_code == 200
    assert json.loads(response.data)['message'] == "Password updated successfully"
    
    # Verify hash was changed correctly
    updated_user = db.session.get(User, user.id)
    assert bcrypt.check_password_hash(updated_user.password, "newpassword123") == True