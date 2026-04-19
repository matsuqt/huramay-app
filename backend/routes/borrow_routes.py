# backend/routes/borrow_routes.py
from flask import Blueprint, request, jsonify
from database import db
from models.borrow_request import BorrowRequest
from models.item import Item
from models.report_item import ReportItem

# Create the Blueprint
borrow_bp = Blueprint('borrow', __name__)

# Helper function
def _item_to_dict(i):
    if not i: return {}
    return {
        "id": i.id,
        "title": i.title,
        "description": i.description,
        "quantity": i.quantity,
        "condition": i.condition,
        "image": i.item_image_path,
        "owner": i.owner_name,
        "dept": i.department,
        "status": i.status, 
        "user_id": i.user_id
    }

# --- BORROWING ROUTES ---
@borrow_bp.route('/api/borrow/request', methods=['POST'])
def request_borrow():
    try:
        data = request.get_json()
        new_request = BorrowRequest(
            item_id=data['item_id'], borrower_id=data['borrower_id'],
            full_name=data['full_name'], department=data['department'],
            start_date=data['start_date'], end_date=data['end_date'],
            proof_of_id_path=data.get('proof_of_id_path', ''),
            meetup_location=data.get('meetup_location', 'LNU Campus Only')
        )
        db.session.add(new_request)
        db.session.commit()
        return jsonify({"message": "Borrow request submitted successfully!"}), 201
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500

@borrow_bp.route('/api/borrow/requests/owner/<int:owner_id>', methods=['GET'])
def get_owner_requests(owner_id):
    requests = BorrowRequest.query.join(Item).filter(Item.user_id == owner_id).all()
    results = []
    for req in requests:
        results.append({
            "id": req.id, "item_id": req.item_id, "borrower_id": req.borrower_id,
            "full_name": req.full_name, "department": req.department,
            "start_date": req.start_date, "end_date": req.end_date,
            "proof_of_id_path": req.proof_of_id_path, "meetup_location": req.meetup_location,
            "status": req.status, "item": _item_to_dict(req.item) 
        })
    return jsonify(results), 200

@borrow_bp.route('/api/borrow/history/<int:borrower_id>', methods=['GET'])
def get_borrower_history(borrower_id):
    requests = BorrowRequest.query.filter_by(borrower_id=borrower_id).all()
    results = []
    for req in requests:
        results.append({
            "id": req.id, "item_id": req.item_id, "borrower_id": req.borrower_id,
            "full_name": req.full_name, "department": req.department,
            "start_date": req.start_date, "end_date": req.end_date,
            "status": req.status, "item": _item_to_dict(req.item) 
        })
    return jsonify(results), 200

@borrow_bp.route('/api/borrow/request/<int:req_id>', methods=['PUT'])
def update_request_status(req_id):
    data = request.get_json()
    new_status = data.get('status')
    req = BorrowRequest.query.get(req_id)
    if not req:
        return jsonify({"message": "Request not found"}), 404
        
    req.status = new_status
    
    if new_status == 'Accepted' and req.item:
        req.item.status = 'Borrowed'
    elif new_status == 'Returned' and req.item:
        req.item.status = 'Available'
        
    db.session.commit()
    return jsonify({"message": f"Request {new_status} successfully!"}), 200

# --- REPORTING ROUTES ---
@borrow_bp.route('/api/report', methods=['POST'])
def submit_report():
    try:
        data = request.get_json()
        new_report = ReportItem(
            reporter_id=data['reporter_id'],
            item_id=data['item_id'],
            report_text=data['report_text']
        )
        db.session.add(new_report)
        db.session.commit()
        return jsonify({"message": "Report submitted successfully!"}), 201
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500

@borrow_bp.route('/api/reports/all', methods=['GET'])
def get_all_reports():
    reports = ReportItem.query.order_by(ReportItem.timestamp.desc()).all()
    results = []
    for r in reports:
        if r.item and r.reporter:
            results.append({
                "report_id": r.id,
                "report_text": r.report_text,
                "timestamp": r.timestamp.strftime("%b %d, %Y"), 
                "reporter_name": r.reporter.full_name,
                "reporter_dept": r.reporter.department,
                "item_title": r.item.title,
                "item_image": r.item.item_image_path
            })
    return jsonify(results), 200