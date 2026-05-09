# backend/routes/admin_routes.py
from models.favorite import Favorite
from models.report_item import ReportItem
from flask import Blueprint, request, jsonify
from database import db, bcrypt
from models.user import User
from models.item import Item
from models.borrow_request import BorrowRequest
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
    
    full_name_input = data.get('full_name', '')
    email_input = data.get('email', '')
    password_input = data.get('password', '')
    
    if not re.match(r'^[a-zA-Z\s.]+$', full_name_input):
        return jsonify({"message": "Full name can only contain letters, spaces, and periods."}), 400

    if not re.match(r'^[a-zA-Z0-9._]+@gmail\.com$', email_input):
        return jsonify({"message": "Email must be a valid @gmail.com address without emojis."}), 400
        
    if re.search(r'[^\x00-\x7F]', password_input):
        return jsonify({"message": "Password cannot contain emojis."}), 400

    if User.query.filter_by(email=email_input).first():
        return jsonify({"message": "Email already registered"}), 400
    
    hashed_pass = bcrypt.generate_password_hash(password_input).decode('utf-8')
    new_admin = User(
        full_name=full_name_input, 
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

# ==================== SOFT DELETE (DISABLE) ====================
@admin_bp.route('/api/users/<int:user_id>/toggle_disable', methods=['PUT'])
def toggle_disable_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404
    
    if user.email == 'admin@gmail.com' or getattr(user, 'is_admin', False):
        return jsonify({"message": "Access Denied: Cannot disable an Administrator."}), 403
        
    try:
        current_status = getattr(user, 'is_disabled', False)
        user.is_disabled = not current_status
        db.session.commit()
        
        action_msg = "enabled and can log in." if current_status else "disabled and locked out."
        return jsonify({"message": f"User account has been {action_msg}"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error updating user status", "error": str(e)}), 500


# ==================== HARD DELETE ====================
@admin_bp.route('/api/users/<int:user_id>/hard_delete', methods=['DELETE'])
def hard_delete_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404
    
    if user.email == 'admin@gmail.com' or getattr(user, 'is_admin', False):
        return jsonify({"message": "Access Denied"}), 403
        
    try:
        active_lending = Item.query.filter(
            Item.user_id == user_id,
            db.func.lower(Item.status) == 'borrowed'
        ).first()
        
        if active_lending:
            return jsonify({"message": "Cannot delete: User owns an item that is currently borrowed out."}), 400
            
        active_borrowing = BorrowRequest.query.filter(
            BorrowRequest.borrower_id == user_id,
            db.func.lower(BorrowRequest.status).in_([
                'pending', 'approved', 'borrowed', 'accepted', 'active', 'ongoing'
            ])
        ).first()
        
        if active_borrowing:
            return jsonify({"message": f"Cannot delete: User is actively borrowing (Status: {active_borrowing.status})."}), 400
            
        Favorite.query.filter_by(user_id=user_id).delete()          
        ReportItem.query.filter_by(reporter_id=user_id).delete()    
        BorrowRequest.query.filter_by(borrower_id=user_id).delete() 
        Item.query.filter_by(user_id=user_id).delete()              
        db.session.delete(user)                                     
        db.session.commit()
        
        return jsonify({"message": "User permanently wiped from system."}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error deleting user", "error": str(e)}), 500

# ==================== UPDATED: PAGINATED GET USERS ====================
@admin_bp.route('/api/users', methods=['GET'])
def get_all_users():
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        pagination = User.query.paginate(page=page, per_page=per_page, error_out=False)
        
        user_list = []
        for user in pagination.items:
            is_admin_flag = user.email == 'admin@gmail.com' or getattr(user, 'is_admin', False)
            
            user_list.append({
                "id": user.id,
                "full_name": user.full_name,
                "email": user.email,
                "department": user.department,
                "rating": user.rating,
                "age": getattr(user, 'age', 'N/A'),
                "is_admin": is_admin_flag,
                "is_disabled": getattr(user, 'is_disabled', False)
            })
            
        return jsonify({
            "users": user_list,
            "total_pages": pagination.pages,
            "current_page": pagination.page,
            "has_next": pagination.has_next,
            "total_count": pagination.total
        }), 200
    except Exception as e:
        return jsonify({"message": f"Server Error: {str(e)}"}), 500
    

# ==================== SECRET MAINTENANCE ROUTE ====================
@admin_bp.route('/api/maintenance/rebuild-db-secret-key-123', methods=['GET'])
def rebuild_database_live():
    try:
        db.drop_all() 
        db.create_all()
        return jsonify({
            "status": "success",
            "message": "LIVE DATABASE WIPED AND REBUILT SUCCESSFULLY WITH NEW COLUMNS!"
        }), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500