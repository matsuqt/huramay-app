import requests
from faker import Faker
import random

fake = Faker()

# --- TARGETING THE LIVE SERVER FOR APK DEPLOYMENT ---
BASE_URL = 'https://huramay-app.onrender.com/api'
REGISTER_URL = f'{BASE_URL}/register'
ITEMS_URL = f'{BASE_URL}/items'
BORROW_URL = f'{BASE_URL}/borrow' # Update this if your borrow route is named differently

DEPARTMENTS = [
    'Bachelor of Science in Information Technology',
    'Bachelor of Secondary Education',
    'Bachelor of Physical Education',
    'Faculty / Staff'
]

CAMPUS_ITEMS = [
    "Arduino Uno Starter Kit", "Scientific Calculator (Casio)", 
    "LNU PE Uniform (Medium)", "Data Structures Textbook", 
    "Acoustic Guitar", "Digital Multimeter", "Chess Set",
    "Volleyball", "Drawing Tablet", "Lab Goggles & Gown",
    "Raspberry Pi 4", "Tripod Stand", "Portable Ring Light"
]

def generate_presentation_seed():
    print("Starting LIVE SERVER deployment seed. This will take 10-20 minutes...")
    
    user_ids = []
    item_ids = []

    # 1. CREATE SUPER ADMIN
    admin_data = {
        'full_name': 'System Administrator',
        'email': 'admin@gmail.com',
        'department': 'Faculty / Staff',
        'password': 'Password123!',
        'security_color': 'blue',
        'security_song': 'bohemian rhapsody'
    }
    requests.post(REGISTER_URL, json=admin_data)
    print("Super Admin created.")

    # ---------------------------------------------------------
    # PHASE 1: CREATE 5,000 USERS
    # ---------------------------------------------------------
    print("\n[PHASE 1] Creating 5,000 Users...")
    current_db_id = 2 # Assuming admin is ID 1
    
    for i in range(5000):
        fake_name = fake.name()
        clean_name = ''.join(e for e in fake_name if e.isalnum() or e.isspace())
        email_username = clean_name.replace(' ', '').lower()
        fake_email = f"{email_username}{i}@gmail.com"
        user_dept = random.choice(DEPARTMENTS)
        
        user_data = {
            'full_name': clean_name, 'email': fake_email, 'department': user_dept,
            'password': 'Password123!', 'security_color': 'blue', 'security_song': 'bohemian rhapsody'
        }
        
        try:
            res = requests.post(REGISTER_URL, json=user_data)
            if res.status_code == 201:
                user_ids.append({'id': current_db_id, 'name': clean_name, 'dept': user_dept})
                current_db_id += 1
                if len(user_ids) % 500 == 0:
                    print(f"  -> Created {len(user_ids)}/5000 users...")
        except Exception as e:
            pass

    # ---------------------------------------------------------
    # PHASE 2: 3,000 AVAILABLE ITEMS (Posted by Users 1 to 3000)
    # ---------------------------------------------------------
    print("\n[PHASE 2] Creating 3,000 Available Items...")
    current_item_id = 1
    
    # Slice the first 3000 users to be the owners of these available items
    for i in range(3000):
        owner = user_ids[i]
        item_data = {
            'title': random.choice(CAMPUS_ITEMS),
            'description': f"Available for borrowing. {fake.sentence()}",
            'quantity': 1, 'condition': random.choice(['Excellent', 'Good', 'Fair']),
            'item_image_path': '', 'owner_name': owner['name'],
            'department': owner['dept'], 'user_id': owner['id'],
            'status': 'available' 
        }
        
        try:
            res = requests.post(ITEMS_URL, json=item_data)
            if res.status_code == 201:
                current_item_id += 1
                if i > 0 and i % 500 == 0:
                    print(f"  -> Created {i}/3000 available items...")
        except Exception as e:
            pass

    # ---------------------------------------------------------
    # PHASE 3: 1,000 BORROWED ITEMS & TRANSACTIONS
    # (Posted by Users 3001-4000, Borrowed by Users 4001-5000)
    # ---------------------------------------------------------
    print("\n[PHASE 3] Creating 1,000 Borrowed Items and Active Transactions...")
    transaction_count = 0
    
    for i in range(1000):
        # User 3001 to 4000 posts the item
        owner = user_ids[3000 + i]
        
        # User 4001 to 5000 borrows the item
        borrower = user_ids[4000 + i] 
        
        # 3a. Post the item
        item_data = {
            'title': random.choice(CAMPUS_ITEMS),
            'description': f"Currently borrowed item. {fake.sentence()}",
            'quantity': 1, 'condition': random.choice(['Excellent', 'Good', 'Fair']),
            'item_image_path': '', 'owner_name': owner['name'],
            'department': owner['dept'], 'user_id': owner['id'],
            'status': 'available' # Will be changed to borrowed by the transaction
        }
        
        try:
            item_res = requests.post(ITEMS_URL, json=item_data)
            if item_res.status_code == 201:
                target_item_id = current_item_id
                current_item_id += 1
                
                # 3b. Create the borrow transaction immediately
                borrow_data = {
                    'item_id': target_item_id,
                    'borrower_id': borrower['id'],
                    'borrow_duration_days': random.randint(1, 7)
                }
                
                borrow_res = requests.post(BORROW_URL, json=borrow_data)
                if borrow_res.status_code in [200, 201]:
                    transaction_count += 1
                    if transaction_count % 200 == 0:
                        print(f"  -> Created {transaction_count}/1000 active transactions...")
        except Exception as e:
            pass

    print(f"\n✅ DONE! Live Server seeded with {len(user_ids)} users, 3000 available items, and {transaction_count} active borrow transactions.")

if __name__ == '__main__':
    generate_presentation_seed()