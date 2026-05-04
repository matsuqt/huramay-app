import pytest
import json
from app import app
from database import db
from models.user import User

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