import pytest
import json
from app import app
from database import db
from models.user import User
from models.item import Item
from models.borrow_request import BorrowRequest
from models.report_item import ReportItem

@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            # Setup Owner (ID: 1), Borrower (ID: 2), and an Item (ID: 1)
            owner = User(full_name="Owner", email="owner@gmail.com", department="BSIT", password="hash")
            borrower = User(full_name="Borrower Bob", email="bob@gmail.com", department="BSIT", password="hash")
            db.session.add_all([owner, borrower])
            db.session.commit()
            
            item = Item(title="Projector", description="Epson", owner_name="Owner", department="BSIT", user_id=owner.id)
            db.session.add(item)
            db.session.commit()
            
            yield client
            db.drop_all()

# ==========================================
# BORROW REQUEST TESTS
# ==========================================

def test_submit_borrow_request(client):
    response = client.post('/api/borrow/request', json={
        "item_id": 1,
        "borrower_id": 2,
        "full_name": "Borrower Bob",
        "department": "BSIT",
        "start_date": "2026-05-10",
        "end_date": "2026-05-12",
        "meetup_location": "LNU Campus Only"
    })
    assert response.status_code == 201
    assert json.loads(response.data)['message'] == "Borrow request submitted successfully!"

def test_get_owner_requests(client):
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow")
    db.session.add(req)
    db.session.commit()
    
    # Owner ID is 1
    response = client.get('/api/borrow/requests/owner/1')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['borrower_id'] == 2

def test_accept_request_changes_item_status(client):
    """Crucial logic test: Accepting a request should change the item to 'Borrowed'"""
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow")
    db.session.add(req)
    db.session.commit()
    
    response = client.put(f'/api/borrow/request/{req.id}', json={"status": "Accepted"})
    assert response.status_code == 200
    
    updated_req = db.session.get(BorrowRequest, req.id)
    updated_item = db.session.get(Item, 1)
    
    assert updated_req.status == "Accepted"
    assert updated_item.status == "Borrowed"

def test_return_request_changes_item_status(client):
    """Returning a borrowed item should make it 'Available' again"""
    # Force item to Borrowed status first
    item = db.session.get(Item, 1)
    item.status = "Borrowed"
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow", status="Accepted")
    db.session.add(req)
    db.session.commit()
    
    client.put(f'/api/borrow/request/{req.id}', json={"status": "Returned"})
    
    updated_item = db.session.get(Item, 1)
    assert updated_item.status == "Available"

# ==========================================
# REPORTING TESTS
# ==========================================

def test_submit_report(client):
    response = client.post('/api/report', json={
        "reporter_id": 2,
        "item_id": 1,
        "report_text": "Item is broken"
    })
    assert response.status_code == 201
    assert db.session.query(ReportItem).count() == 1

def test_get_all_reports(client):
    report = ReportItem(reporter_id=2, item_id=1, report_text="Defective")
    db.session.add(report)
    db.session.commit()
    
    response = client.get('/api/reports/all')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['report_text'] == "Defective"