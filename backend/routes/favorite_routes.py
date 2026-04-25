# backend/routes/favorite_routes.py
from flask import Blueprint, request, jsonify
from database import db
from models.favorite import Favorite

# Create the Blueprint
favorite_bp = Blueprint('favorites', __name__)

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

@favorite_bp.route('/api/favorites/toggle', methods=['POST'])
def toggle_favorite():
    data = request.get_json()
    uid = data.get('user_id')
    iid = data.get('item_id')
    
    existing = Favorite.query.filter_by(user_id=uid, item_id=iid).first()
    if existing:
        db.session.delete(existing)
        db.session.commit()
        return jsonify({"is_favorite": False, "message": "Removed from favorites"}), 200
    else:
        new_fav = Favorite(user_id=uid, item_id=iid)
        db.session.add(new_fav)
        db.session.commit()
        return jsonify({"is_favorite": True, "message": "Added to favorites"}), 201

@favorite_bp.route('/api/favorites/<int:user_id>', methods=['GET'])
def get_favorites(user_id):
    favs = Favorite.query.filter_by(user_id=user_id).all()
    return jsonify([_item_to_dict(f.item) for f in favs if f.item])

@favorite_bp.route('/api/favorites/check', methods=['POST'])
def check_favorite():
    data = request.get_json()
    exists = Favorite.query.filter_by(user_id=data.get('user_id'), item_id=data.get('item_id')).first()
    return jsonify({"is_favorite": exists is not None}), 200