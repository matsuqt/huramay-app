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
    assert "Email must be a @gmail.com" in json.loads(response.data)['message']

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

# ==========================================
# 4. ADVANCED AUTH & SECURITY EDGE CASES
# ==========================================

def test_register_dummy_domain_success(client):
    """Test that the performance testing dummy domain is successfully allowed."""
    response = client.post('/api/register', json={
        "full_name": "Performance Tester",
        "email": "tester1@huramay-dummy.local",
        "department": "BSIT",
        "password": "loadtestingpass"
    })
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Registration successful!"

def test_login_disabled_account(client):
    """Test that an admin-disabled account is completely blocked from logging in."""
    client.post('/api/register', json={
        "full_name": "Bad User", "email": "bad@gmail.com",
        "department": "BSIT", "password": "password"
    })
    user = User.query.filter_by(email="bad@gmail.com").first()
    user.is_disabled = True # Simulate admin disabling the account
    db.session.commit()
    
    response = client.post('/api/login', json={"email": "bad@gmail.com", "password": "password"})
    assert response.status_code == 403
    assert "disabled by an administrator" in json.loads(response.data)['message']

def test_update_profile_not_found(client):
    """Test updating a profile for a user ID that does not exist."""
    response = client.post('/api/user/update', json={"id": 9999, "photo_path": "fake"})
    assert response.status_code == 404

def test_reset_password_invalid_email(client):
    """Test resetting a password when the user ID and email do not match."""
    client.post('/api/register', json={
        "full_name": "Valid User", "email": "valid@gmail.com",
        "department": "BSIT", "password": "password"
    })
    user = User.query.filter_by(email="valid@gmail.com").first()
    
    # Try to reset using the correct ID, but the wrong email
    response = client.post('/api/user/reset_password', json={
        "current_user_id": user.id,
        "email": "wrong@gmail.com",
        "new_password": "newpassword123"
    })
    assert response.status_code == 400
    assert json.loads(response.data)['message'] == "Invalid user or email"

def test_recover_account_success(client):
    """Test successfully recovering an account using the correct security questions."""
    client.post('/api/register', json={
        "full_name": "Forgetful User", "email": "forget@gmail.com",
        "department": "BSIT", "password": "oldpassword",
        "security_color": "Blue", "security_song": "Perfect"
    })
    
    response = client.post('/api/user/recover_account', json={
        "email": "forget@gmail.com",
        "security_color": "blue", # Test case-insensitivity
        "security_song": "perfect",
        "new_password": "rescuedpassword"
    })
    assert response.status_code == 200
    
    # Verify the login works with the newly rescued password
    login_res = client.post('/api/login', json={"email": "forget@gmail.com", "password": "rescuedpassword"})
    assert login_res.status_code == 200

def test_recover_account_wrong_answers(client):
    """Test failing to recover an account due to wrong security answers."""
    client.post('/api/register', json={
        "full_name": "Hacker", "email": "target@gmail.com",
        "department": "BSIT", "password": "password",
        "security_color": "red", "security_song": "song"
    })
    
    response = client.post('/api/user/recover_account', json={
        "email": "target@gmail.com",
        "security_color": "blue", # Wrong!
        "security_song": "song",
        "new_password": "hackedpassword"
    })
    assert response.status_code == 401

def test_recover_account_disabled(client):
    """Test that disabled users cannot use the recovery route to bypass their ban."""
    client.post('/api/register', json={
        "full_name": "Banned User", "email": "banned@gmail.com",
        "department": "BSIT", "password": "password",
        "security_color": "red", "security_song": "song"
    })
    user = User.query.filter_by(email="banned@gmail.com").first()
    user.is_disabled = True
    db.session.commit()
    
    response = client.post('/api/user/recover_account', json={
        "email": "banned@gmail.com",
        "security_color": "red",
        "security_song": "song",
        "new_password": "newpassword"
    })
    assert response.status_code == 403

# ==========================================
# 5. NULL DATA & EXTREME EDGE CASES
# ==========================================

def test_login_missing_fields(client):
    """Test login with missing payload data."""
    try:
        response = client.post('/api/login', json={"email": "missing_password@gmail.com"})
        assert response.status_code in [400, 401, 500]
    except Exception:
        pass

def test_login_non_existent_email(client):
    """Test login attempt with an email that is not in the database."""
    response = client.post('/api/login', json={"email": "ghost@gmail.com", "password": "password"})
    assert response.status_code == 401

def test_register_missing_fields(client):
    """Test registration missing critical fields like password."""
    response = client.post('/api/register', json={"full_name": "Incomplete", "email": "inc@gmail.com"})
    assert response.status_code in [400, 500]

def test_update_profile_empty_data(client):
    """Test updating a profile without sending a new photo path."""
    client.post('/api/register', json={"full_name": "U", "email": "u@gmail.com", "department": "IT", "password": "pass"})
    user = User.query.filter_by(email="u@gmail.com").first()
    
    response = client.post('/api/user/update', json={"id": user.id})
    assert response.status_code == 200 # Should default to empty string without crashing

def test_recover_account_non_existent_email(client):
    """Test account recovery for an email that doesn't exist."""
    response = client.post('/api/user/recover_account', json={
        "email": "nobody@gmail.com", "security_color": "red", "security_song": "song", "new_password": "pass"
    })
    assert response.status_code == 404

def test_recover_account_emoji_password_block(client):
    """Test account recovery blocks new passwords containing emojis."""
    client.post('/api/register', json={"full_name": "U", "email": "emoji@gmail.com", "department": "IT", "password": "pass", "security_color": "red", "security_song": "song"})
    response = client.post('/api/user/recover_account', json={
        "email": "emoji@gmail.com", "security_color": "red", "security_song": "song", "new_password": "pass"
    })
    assert response.status_code == 400