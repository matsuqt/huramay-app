# backend/routes/item_routes.py
from flask import Blueprint, request, jsonify
from database import db
from models.item import Item

# Create the Blueprint
item_bp = Blueprint('items', __name__)

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

@item_bp.route('/api/items', methods=['GET', 'POST'])
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

@item_bp.route('/api/items/user/<int:user_id>', methods=['GET'])
def get_user_items(user_id):
    items = Item.query.filter_by(user_id=user_id).all()
    return jsonify([_item_to_dict(i) for i in items])

@item_bp.route('/api/items/<int:item_id>', methods=['PUT'])
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

@item_bp.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    item = Item.query.get(item_id)
    if not item: return jsonify({"message": "Item not found"}), 404
    db.session.delete(item)
    db.session.commit()
    return jsonify({"message": "Item deleted successfully!"}), 200