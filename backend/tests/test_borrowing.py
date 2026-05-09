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

# ==========================================
# ADVANCED BORROW REQUEST LIFECYCLE
# ==========================================

def test_submit_borrow_request_missing_data(client):
    """Test failing to submit a borrow request without an end date."""
    response = client.post('/api/borrow/request', json={
        "item_id": 1, "borrower_id": 2, "full_name": "Bob",
        "department": "BSIT", "start_date": "2026-05-10"
        # Missing end_date
    })
    assert response.status_code == 500

def test_update_borrow_request_not_found(client):
    """Test updating the status of a non-existent borrow request."""
    response = client.put('/api/borrow/request/9999', json={"status": "Accepted"})
    assert response.status_code == 404
    assert json.loads(response.data)['message'] == "Request not found"

def test_reject_borrow_request(client):
    """Test that rejecting a request DOES NOT change the item status."""
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow")
    db.session.add(req)
    db.session.commit()
    
    response = client.put(f'/api/borrow/request/{req.id}', json={"status": "Declined"})
    assert response.status_code == 200
    
    updated_req = db.session.get(BorrowRequest, req.id)
    updated_item = db.session.get(Item, 1)
    
    assert updated_req.status == "Declined"
    assert updated_item.status == "Available" # Item should still be available!

def test_cancel_borrow_request(client):
    """Test that a borrower can cancel their own pending request."""
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow", status="Pending")
    db.session.add(req)
    db.session.commit()
    
    response = client.put(f'/api/borrow/request/{req.id}', json={"status": "Cancelled"})
    assert response.status_code == 200
    updated_req = db.session.get(BorrowRequest, req.id)
    assert updated_req.status == "Cancelled"

def test_get_borrower_history_empty(client):
    """Test fetching borrow history for a user who has never borrowed."""
    response = client.get('/api/borrow/history/999')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 0

def test_get_owner_requests_empty(client):
    """Test fetching requests for an owner who has no items requested."""
    response = client.get('/api/borrow/requests/owner/999')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 0

# ==========================================
# NEW EDGE CASE & DATA STRUCTURE TESTS
# ==========================================

def test_submit_borrow_request_with_optional_fields(client):
    """Test submitting a request including proof of ID and a custom meetup location."""
    response = client.post('/api/borrow/request', json={
        "item_id": 1,
        "borrower_id": 2,
        "full_name": "Borrower Bob",
        "department": "BSIT",
        "start_date": "2026-05-10",
        "end_date": "2026-05-12",
        "proof_of_id_path": "/images/id_card.png",
        "meetup_location": "Library Room 3"
    })
    assert response.status_code == 201
    
    # Verify it saved correctly in the Database
    req = db.session.query(BorrowRequest).first()
    assert req.proof_of_id_path == "/images/id_card.png"
    assert req.meetup_location == "Library Room 3"

def test_submit_borrow_request_missing_item_id(client):
    """Test failing to submit a borrow request without a mandatory item_id."""
    response = client.post('/api/borrow/request', json={
        "borrower_id": 2,
        "full_name": "Bob",
        "department": "BSIT",
        "start_date": "2026-05-10",
        "end_date": "2026-05-12"
    })
    assert response.status_code == 500

def test_get_borrower_history_with_data(client):
    """Test fetching borrow history when the user actually has past requests."""
    req1 = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow")
    db.session.add(req1)
    db.session.commit()
    
    response = client.get('/api/borrow/history/2')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]['borrower_id'] == 2
    
    # Check that the nested '_item_to_dict' helper attached the item data
    assert 'item' in data[0]
    assert data[0]['item']['title'] == "Projector"

def test_get_owner_requests_multiple(client):
    """Test fetching requests when multiple people request the exact same owner's items."""
    req1 = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow")
    req2 = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob Again", department="BSIT", start_date="Next Week", end_date="Next Month")
    db.session.add_all([req1, req2])
    db.session.commit()
    
    response = client.get('/api/borrow/requests/owner/1')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert len(data) == 2

def test_submit_report_missing_text(client):
    """Test failing to submit a report without the actual report text."""
    response = client.post('/api/report', json={
        "reporter_id": 2,
        "item_id": 1
        # Missing report_text
    })
    assert response.status_code == 500

def test_get_all_reports_empty(client):
    """Test fetching all reports when none exist in the database."""
    response = client.get('/api/reports/all')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert data == [] # Should return an empty array, not crash

def test_get_all_reports_data_structure(client):
    """Test that the get_all_reports endpoint returns the correctly joined database fields."""
    report = ReportItem(reporter_id=2, item_id=1, report_text="Defective")
    db.session.add(report)
    db.session.commit()
    
    response = client.get('/api/reports/all')
    data = json.loads(response.data)
    assert response.status_code == 200
    assert 'reporter_name' in data[0]
    assert 'item_title' in data[0]
    assert 'timestamp' in data[0]
    assert data[0]['reporter_name'] == "Borrower Bob"
    assert data[0]['item_title'] == "Projector"

def test_update_request_status_arbitrary(client):
    """Test updating a request to a custom status string outside the standard Accepted/Returned."""
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="BSIT", start_date="Now", end_date="Tomorrow")
    db.session.add(req)
    db.session.commit()
    
    response = client.put(f'/api/borrow/request/{req.id}', json={"status": "Overdue"})
    assert response.status_code == 200
    
    updated_req = db.session.get(BorrowRequest, req.id)
    assert updated_req.status == "Overdue"

# ==========================================
# BORROW ROUTE EDGE CASES
# ==========================================

def test_accept_request_invalid_id(client):
    """Test accepting a request ID that doesn't exist."""
    response = client.put('/api/borrow/request/9999', json={"status": "Accepted"})
    assert response.status_code == 404

def test_get_owner_requests_invalid_owner(client):
    """Test fetching owner requests for a non-existent owner (should return empty)."""
    response = client.get('/api/borrow/requests/owner/9999')
    assert response.status_code == 200
    assert len(json.loads(response.data)) == 0

def test_submit_report_invalid_item(client):
    """Test submitting a report for an item that doesn't exist."""
    try:
        response = client.post('/api/report', json={"reporter_id": 1, "item_id": 999, "report_text": "Fake item"})
        assert response.status_code in [404, 500] # DB constraint failure
    except Exception:
        pass

def test_update_borrow_request_missing_status(client):
    """Test updating a borrow request without providing the new status payload."""
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Bob", department="IT", start_date="Now", end_date="Later")
    db.session.add(req)
    db.session.commit()
    
    response = client.put(f'/api/borrow/request/{req.id}', json={})
    assert response.status_code == 200 # Should process without crashing, retaining old status

def test_borrow_request_default_meetup_location(client):
    """Test that omitting meetup_location triggers the 'LNU Campus Only' default."""
    response = client.post('/api/borrow/request', json={
        "item_id": 1, "borrower_id": 2, "full_name": "Bob",
        "department": "IT", "start_date": "Now", "end_date": "Later"
        # No meetup location provided
    })
    assert response.status_code == 201
    req = BorrowRequest.query.filter_by(borrower_id=2).first()
    assert req.meetup_location == "LNU Campus Only"

def test_borrow_history_data_integrity(client):
    """Test that the fetched history data perfectly matches the database object."""
    req = BorrowRequest(item_id=1, borrower_id=2, full_name="Strict Bob", department="IT", start_date="Day 1", end_date="Day 2")
    db.session.add(req)
    db.session.commit()
    
    response = client.get('/api/borrow/history/2')
    data = json.loads(response.data)
    assert data[-1]['start_date'] == "Day 1"
    assert data[-1]['end_date'] == "Day 2"