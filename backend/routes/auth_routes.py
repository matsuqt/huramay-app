# backend/routes/auth_routes.py
from flask import Blueprint, request, jsonify
from database import db, bcrypt
from models.user import User
import re

# Create the Blueprint
auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        email_input = data.get('email', '')
        password_input = data.get('password', '')
        full_name_input = data.get('full_name', '')
        
        security_color = data.get('security_color', '').strip().lower()
        security_song = data.get('security_song', '').strip().lower()
        
        if not re.match(r'^[a-zA-Z\s\.]+$', full_name_input):
            return jsonify({"message": "Name cannot contain numbers, special characters, or emojis"}), 400

        # UPDATED: Allows both standard Gmail and the performance testing dummy domain
        if not re.match(r'^[a-zA-Z0-9._]+@(gmail\.com|huramay-dummy\.local)$', email_input):
            return jsonify({"message": "Email must be a @gmail.com or @huramay-dummy.local address"}), 400
            
        if re.search(r'[^\x00-\x7F]', password_input):
            return jsonify({"message": "Password cannot contain emojis"}), 400

        if User.query.filter_by(email=email_input).first():
            return jsonify({"message": "Email already registered"}), 400
            
        hashed_pass = bcrypt.generate_password_hash(password_input).decode('utf-8')
        new_user = User(
            full_name=full_name_input, 
            email=email_input, 
            department=data['department'], 
            password=hashed_pass,
            security_color=security_color,  
            security_song=security_song     
        )
        db.session.add(new_user)
        db.session.commit()
        return jsonify({"message": "Registration successful!"}), 201
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500

@auth_bp.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    
    if user and bcrypt.check_password_hash(user.password, data['password']):
        # Block disabled users from logging in
        if getattr(user, 'is_disabled', False):
            return jsonify({"message": "Your account has been disabled by an administrator."}), 403
            
        return jsonify({
            "id": user.id, "full_name": user.full_name, "email": user.email,               
            "department": user.department, "photo_path": user.photo_path,     
            "rating": user.rating, 
            "is_admin": user.email == 'admin@gmail.com' or user.is_admin,
            "message": "Login successful!"
        }), 200
    return jsonify({"message": "Invalid email or password"}), 401

@auth_bp.route('/api/user/update', methods=['POST'])
def update_profile():
    try:
        data = request.get_json()
        user_id = data.get('id')
        
        user = User.query.get(user_id)
        if not user:
            return jsonify({"message": "User not found"}), 404
            
        user.photo_path = data.get('photo_path', '')
        db.session.commit()
        
        return jsonify({"message": "Profile updated successfully!"}), 200
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500

@auth_bp.route('/api/user/reset_password', methods=['POST'])
def reset_password():
    try:
        data = request.get_json()
        user = User.query.get(data.get('current_user_id'))
        
        if not user or user.email != data.get('email'):
            return jsonify({"message": "Invalid user or email"}), 400
            
        hashed_pass = bcrypt.generate_password_hash(data.get('new_password')).decode('utf-8')
        user.password = hashed_pass
        db.session.commit()
        
        return jsonify({"message": "Password updated successfully"}), 200
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500

@auth_bp.route('/api/user/recover_account', methods=['POST'])
def recover_account():
    try:
        data = request.get_json()
        email = data.get('email', '').strip()
        color = data.get('security_color', '').strip().lower()
        song = data.get('security_song', '').strip().lower()
        new_password = data.get('new_password', '')

        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({"message": "Account not found."}), 404

        if getattr(user, 'is_disabled', False):
            return jsonify({"message": "Account disabled. Cannot recover password."}), 403

        if user.security_color != color or user.security_song != song:
            return jsonify({"message": "Security question answers are incorrect."}), 401

        if re.search(r'[^\x00-\x7F]', new_password):
            return jsonify({"message": "Password cannot contain emojis"}), 400

        user.password = bcrypt.generate_password_hash(new_password).decode('utf-8')
        db.session.commit()

        return jsonify({"message": "Password successfully updated! You can now log in."}), 200
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500