# backend/models/borrow_request.py
from database import db

class BorrowRequest(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=False)
    borrower_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    department = db.Column(db.String(100), nullable=False)
    start_date = db.Column(db.String(50), nullable=False)
    end_date = db.Column(db.String(50), nullable=False)
    proof_of_id_path = db.Column(db.String(255), nullable=True, default="")
    meetup_location = db.Column(db.String(255), nullable=False, default="LNU Campus Only")
    status = db.Column(db.String(50), default="Pending") 
    
    item = db.relationship('Item')
    borrower = db.relationship('User')