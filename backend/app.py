from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_bcrypt import Bcrypt
from datetime import datetime, timedelta, timezone
import os

def get_ph_time():
    # Always returns the current time in the Philippines (UTC+8)
    return datetime.now(timezone.utc) + timedelta(hours=8)

app = Flask(__name__)
CORS(app)
bcrypt = Bcrypt(app)

# Database Setup
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///User.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# --- MODELS ---
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    department = db.Column(db.String(100), nullable=False)
    password = db.Column(db.String(255), nullable=False)
    photo_path = db.Column(db.String(255), nullable=True, default="")
    rating = db.Column(db.Float, default=5.0) 
    is_admin = db.Column(db.Boolean, default=False)
    items = db.relationship('Item', backref='owner', lazy=True)
    favorites = db.relationship('Favorite', backref='user', lazy=True)

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    condition = db.Column(db.String(50), nullable=False, default="Good")
    item_image_path = db.Column(db.String(255), nullable=True, default="")
    owner_name = db.Column(db.String(100), nullable=False)
    department = db.Column(db.String(100), nullable=False)
    status = db.Column(db.String(20), default="Available")
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

class Favorite(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=False)
    item = db.relationship('Item')

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

class ChatMessage(db.Model):
    __tablename__ = 'chats'
    Message_ID = db.Column(db.Integer, primary_key=True)
    Chat_Room_ID = db.Column(db.Integer, nullable=False) 
    Sender_ID = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    Receiver_ID = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    Message_Text = db.Column(db.Text, nullable=False)
    Timestamp = db.Column(db.DateTime, default=get_ph_time)
    Is_Read = db.Column(db.Boolean, default=False) 

class ReportItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    reporter_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=False)
    report_text = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=get_ph_time)
    reporter = db.relationship('User')
    item = db.relationship('Item')

class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    reviewer_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey('item.id'), nullable=False)
    lender_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    rating = db.Column(db.Integer, nullable=False)
    comment = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=get_ph_time)
    
    reviewer = db.relationship('User', foreign_keys=[reviewer_id])

with app.app_context():
    db.create_all()

# --- AUTH ROUTES ---
@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        # --- NEW FIX: Check for @gmail.com extension ---
        if not data['email'].endswith('@gmail.com'):
            return jsonify({"message": "Email must have an extension of @gmail.com"}), 400
        # -----------------------------------------------

        if User.query.filter_by(email=data['email']).first():
            return jsonify({"message": "Email already registered"}), 400
            
        hashed_pass = bcrypt.generate_password_hash(data['password']).decode('utf-8')
        new_user = User(full_name=data['full_name'], email=data['email'], 
                        department=data['department'], password=hashed_pass)
        db.session.add(new_user)
        db.session.commit()
        return jsonify({"message": "Registration successful!"}), 201
    except:
        return jsonify({"message": "Server Error"}), 500

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data['email']).first()
    if user and bcrypt.check_password_hash(user.password, data['password']):
        return jsonify({
            "id": user.id, "full_name": user.full_name, "email": user.email,               
            "department": user.department, "photo_path": user.photo_path,     
            "rating": user.rating, 
            "is_admin": user.email == 'admin@gmail.com' or user.is_admin,
            "message": "Login successful!"
        }), 200
    return jsonify({"message": "Invalid email or password"}), 401

# --- PROFILE ROUTES ---
@app.route('/api/user/update', methods=['POST'])
def update_profile():
    data = request.get_json()
    user = db.session.get(User, data['id'])
    if user:
        user.photo_path = data.get('photo_path', user.photo_path)
        db.session.commit()
        return jsonify({"message": "Profile updated successfully!"}), 200
    return jsonify({"message": "User not found"}), 404

@app.route('/api/user/reset_password', methods=['POST'])
def reset_password():
    data = request.get_json()
    user = User.query.filter_by(email=data.get('email'), id=data.get('current_user_id')).first()
    if user:
        hashed_pass = bcrypt.generate_password_hash(data['new_password']).decode('utf-8')
        user.password = hashed_pass
        db.session.commit()
        return jsonify({"message": "Password reset successfully!"}), 200
    return jsonify({"message": "Verification failed. You can only reset your own account."}), 403

# --- ITEM ROUTES ---
@app.route('/api/items', methods=['GET', 'POST'])
def handle_items():
    if request.method == 'POST':
        try:
            data = request.get_json()
            new_item = Item(
                title=data['title'], description=data['description'],
                quantity=int(data.get('quantity', 1)), condition=data.get('condition', 'Good'),
                item_image_path=data.get('item_image_path', ''), owner_name=data['owner_name'],
                department=data['department'], user_id=data['user_id']
            )
            db.session.add(new_item)
            db.session.commit()
            return jsonify({"message": "Item posted successfully!"}), 201
        except Exception as e:
            return jsonify({"message": f"Server Error: {str(e)}"}), 500
    
    status_filter = request.args.get('status')
    search_keyword = request.args.get('search')
    dept_filter = request.args.get('department') 
    
    query = Item.query
    if status_filter and status_filter != 'All':
        query = query.filter_by(status=status_filter)
    if dept_filter:
        query = query.filter_by(department=dept_filter)
    if search_keyword:
        search_term = f"%{search_keyword}%"
        query = query.filter(Item.title.ilike(search_term) | Item.description.ilike(search_term))
        
    all_items = query.all()
    return jsonify([_item_to_dict(i) for i in all_items])

@app.route('/api/items/user/<int:user_id>', methods=['GET'])
def get_user_items(user_id):
    items = Item.query.filter_by(user_id=user_id).all()
    return jsonify([_item_to_dict(i) for i in items])

@app.route('/api/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    item = Item.query.get(item_id)
    if not item: return jsonify({"message": "Item not found"}), 404
    data = request.get_json()
    item.title = data.get('title', item.title)
    item.description = data.get('description', item.description)
    item.department = data.get('department', item.department) 
    item.condition = data.get('condition', item.condition)
    item.status = data.get('status', item.status)
    item.item_image_path = data.get('item_image_path', item.item_image_path) 
    db.session.commit()
    return jsonify({"message": "Item updated successfully!"}), 200

@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    item = Item.query.get(item_id)
    if not item: return jsonify({"message": "Item not found"}), 404
    db.session.delete(item)
    db.session.commit()
    return jsonify({"message": "Item deleted successfully!"}), 200

# --- FAVORITE ROUTES ---
@app.route('/api/favorites/toggle', methods=['POST'])
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

@app.route('/api/favorites/<int:user_id>', methods=['GET'])
def get_favorites(user_id):
    favs = Favorite.query.filter_by(user_id=user_id).all()
    return jsonify([_item_to_dict(f.item) for f in favs if f.item])

@app.route('/api/favorites/check', methods=['POST'])
def check_favorite():
    data = request.get_json()
    exists = Favorite.query.filter_by(user_id=data.get('user_id'), item_id=data.get('item_id')).first()
    return jsonify({"is_favorite": exists is not None}), 200

# --- BORROWING & REPORTING ROUTES ---
@app.route('/api/borrow/request', methods=['POST'])
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

@app.route('/api/borrow/requests/owner/<int:owner_id>', methods=['GET'])
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

@app.route('/api/borrow/history/<int:borrower_id>', methods=['GET'])
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

@app.route('/api/borrow/request/<int:req_id>', methods=['PUT'])
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

@app.route('/api/report', methods=['POST'])
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

@app.route('/api/reports/all', methods=['GET'])
def get_all_reports():
    # FIX 1: Lowercase 't' in ReportItem.timestamp
    reports = ReportItem.query.order_by(ReportItem.timestamp.desc()).all()
    results = []
    for r in reports:
        if r.item and r.reporter:
            results.append({
                "report_id": r.id,
                "report_text": r.report_text,
                # FIX 2: Lowercase 't' in r.timestamp
                "timestamp": r.timestamp.strftime("%b %d, %Y"), 
                "reporter_name": r.reporter.full_name,
                "reporter_dept": r.reporter.department,
                "item_title": r.item.title,
                "item_image": r.item.item_image_path
            })
    return jsonify(results), 200

# --- REVIEWS API ---
@app.route('/api/review', methods=['POST'])
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

@app.route('/api/reviews/item/<int:item_id>', methods=['GET'])
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

# --- CHATS / MESSAGING ROUTES ---
@app.route('/api/messages/inbox/<int:user_id>', methods=['GET'])
def get_inbox(user_id):
    messages = ChatMessage.query.filter(
        (ChatMessage.Sender_ID == user_id) | (ChatMessage.Receiver_ID == user_id)
    ).order_by(ChatMessage.Timestamp.desc()).all()
    
    inbox = {}
    for m in messages:
        if m.Chat_Room_ID not in inbox:
            other_id = m.Receiver_ID if m.Sender_ID == user_id else m.Sender_ID
            other_user = User.query.get(other_id)
            req = BorrowRequest.query.get(m.Chat_Room_ID)
            item_title = req.item.title if req and req.item else "Unknown Item"
            
            unread = ChatMessage.query.filter_by(
                Chat_Room_ID=m.Chat_Room_ID, 
                Receiver_ID=user_id, 
                Is_Read=False
            ).count()
            
            inbox[m.Chat_Room_ID] = {
                "chat_room_id": m.Chat_Room_ID,
                "other_id": other_id,
                "other_name": other_user.full_name if other_user else "Unknown",
                "item_name": item_title,
                "last_message": m.Message_Text,
                "timestamp": m.Timestamp.strftime("%I:%M %p"),
                "unread_count": unread
            }
    return jsonify(list(inbox.values())), 200

@app.route('/api/messages/history/<int:room_id>', methods=['GET'])
def get_chat_history(room_id):
    messages = ChatMessage.query.filter_by(Chat_Room_ID=room_id).order_by(ChatMessage.Timestamp.asc()).all()
    return jsonify([{
        "sender_id": m.Sender_ID,
        "content": m.Message_Text,
        "timestamp": m.Timestamp.strftime("%I:%M %p")
    } for m in messages]), 200

@app.route('/api/messages/send', methods=['POST'])
def send_message():
    data = request.get_json()
    new_msg = ChatMessage(
        Chat_Room_ID=data['chat_room_id'],
        Sender_ID=data['sender_id'],
        Receiver_ID=data['receiver_id'],
        Message_Text=data['content']
    )
    db.session.add(new_msg)
    db.session.commit()
    return jsonify({"message": "Sent!"}), 201

@app.route('/api/messages/unread/<int:user_id>', methods=['GET'])
def get_unread_count(user_id):
    count = ChatMessage.query.filter_by(Receiver_ID=user_id, Is_Read=False).count()
    return jsonify({"unread_count": count}), 200

@app.route('/api/messages/read', methods=['POST'])
def mark_messages_read():
    data = request.get_json()
    room_id = data.get('chat_room_id')
    user_id = data.get('user_id')
    
    unread_msgs = ChatMessage.query.filter_by(Chat_Room_ID=room_id, Receiver_ID=user_id, Is_Read=False).all()
    for msg in unread_msgs:
        msg.Is_Read = True
    db.session.commit()
    return jsonify({"message": "Marked as read"}), 200

# --- ADMIN ROUTES ---
@app.route('/api/admins', methods=['GET'])
def get_admins():
    admins = User.query.filter((User.is_admin == True) | (User.email == 'admin@gmail.com')).all()
    return jsonify([{
        "id": a.id, 
        "full_name": a.full_name, 
        "email": a.email
    } for a in admins]), 200

@app.route('/api/admins/create', methods=['POST'])
def create_admin():
    data = request.get_json()
    if User.query.filter_by(email=data['email']).first():
        return jsonify({"message": "Email already registered"}), 400
    
    hashed_pass = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    new_admin = User(
        full_name=data['full_name'], 
        email=data['email'], 
        department="Admin", 
        password=hashed_pass, 
        is_admin=True
    )
    db.session.add(new_admin)
    db.session.commit()
    return jsonify({"message": "Admin created successfully!"}), 201

@app.route('/api/admins/<int:admin_id>', methods=['DELETE'])
def delete_admin(admin_id):
    admin_to_delete = User.query.get(admin_id)
    if not admin_to_delete:
        return jsonify({"message": "Admin not found"}), 404
        
    if admin_to_delete.email == 'admin@gmail.com':
        return jsonify({"message": "Access Denied: Cannot delete the Super Admin"}), 403
        
    db.session.delete(admin_to_delete)
    db.session.commit()
    return jsonify({"message": "Admin deleted successfully"}), 200

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)