# backend/routes/review_routes.py
from flask import Blueprint, request, jsonify
from database import db
from models.review import Review
from models.user import User

# Create the Blueprint
review_bp = Blueprint('reviews', __name__)

@review_bp.route('/api/review', methods=['POST'])
def submit_review():
    data = request.get_json()
    lender = User.query.get(data['lender_id'])
    
    if lender:
        new_rating = float(data['rating'])
        if lender.rating == 5.0:
            lender.rating = new_rating
        else:
            lender.rating = round((lender.rating + new_rating) / 2.0, 1)
            
        new_review = Review(
            reviewer_id=data['reviewer_id'],
            item_id=data['item_id'],
            lender_id=data['lender_id'],
            rating=int(new_rating),
            comment=data['review_text']
        )
        db.session.add(new_review)
        db.session.commit()
        return jsonify({"message": "Review submitted successfully!"}), 201
    return jsonify({"message": "Lender not found"}), 404

@review_bp.route('/api/reviews/item/<int:item_id>', methods=['GET'])
def get_item_reviews(item_id):
    reviews = Review.query.filter_by(item_id=item_id).order_by(Review.timestamp.desc()).all()
    results = []
    for r in reviews:
        results.append({
            "reviewer_name": r.reviewer.full_name if r.reviewer else "Unknown",
            "rating": r.rating,
            "comment": r.comment,
            "date": r.timestamp.strftime("%b %d, %Y")
        })
    return jsonify(results), 200