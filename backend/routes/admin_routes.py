# backend/routes/admin_routes.py
from flask import Blueprint, request, jsonify
from database import db, bcrypt
from models.user import User
from models.item import Item
import re

# Create the Blueprint
admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/api/admins', methods=['GET'])
def get_admins():
    admins = User.query.filter((User.is_admin == True) | (User.email == 'admin@gmail.com')).all()
    return jsonify([{
        "id": a.id, 
        "full_name": a.full_name, 
        "email": a.email
    } for a in admins]), 200

@admin_bp.route('/api/admins/create', methods=['POST'])
def create_admin():
    data = request.get_json()
    email_input = data.get('email', '')
    
    # Strict Regex Checks for Admin Creation
    if not re.match(r'^[a-zA-Z0-9._]+@gmail\.com$', email_input):
        return jsonify({"message": "Email contains special characters or emojis, or is not a @gmail.com address"}), 400
    if re.search(r'[^\x00-\x7F]', data.get('password', '')):
        return jsonify({"message": "Password cannot contain emojis"}), 400

    if User.query.filter_by(email=email_input).first():
        return jsonify({"message": "Email already registered"}), 400
    
    hashed_pass = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    new_admin = User(
        full_name=data['full_name'], 
        email=email_input, 
        department="Admin", 
        password=hashed_pass, 
        is_admin=True
    )
    db.session.add(new_admin)
    db.session.commit()
    return jsonify({"message": "Admin created successfully!"}), 201

@admin_bp.route('/api/admins/<int:admin_id>', methods=['DELETE'])
def delete_admin(admin_id):
    admin_to_delete = User.query.get(admin_id)
    if not admin_to_delete:
        return jsonify({"message": "Admin not found"}), 404
        
    if admin_to_delete.email == 'admin@gmail.com':
        return jsonify({"message": "Access Denied: Cannot delete the Super Admin"}), 403
        
    db.session.delete(admin_to_delete)
    db.session.commit()
    return jsonify({"message": "Admin deleted successfully"}), 200

@admin_bp.route('/api/users/<int:user_id>', methods=['DELETE'])
def ban_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404
    
    if user.email == 'admin@gmail.com':
        return jsonify({"message": "Access Denied"}), 403
        
    try:
        Item.query.filter_by(user_id=user_id).delete()
        db.session.delete(user)
        db.session.commit()
        return jsonify({"message": "User and their items have been banned/deleted"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error banning user", "error": str(e)}), 500