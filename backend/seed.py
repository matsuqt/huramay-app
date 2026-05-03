import requests
from faker import Faker
import random
import time

fake = Faker()

# Pointing to your LIVE cloud server
REGISTER_URL = 'https://huramay-app.onrender.com/api/register'
ITEMS_URL = 'https://huramay-app.onrender.com/api/items'

DEPARTMENTS = [
    'Bachelor of Science in Information Technology',
    'Bachelor of Secondary Education',
    'Bachelor of Physical Education',
    'Faculty / Staff'
]

# Realistic items a student might lend or borrow on campus
CAMPUS_ITEMS = [
    "Arduino Uno Starter Kit", "Scientific Calculator (Casio)", 
    "LNU PE Uniform (Medium)", "Data Structures Textbook", 
    "Acoustic Guitar", "Digital Multimeter", "Chess Set",
    "Volleyball", "Drawing Tablet", "Lab Goggles & Gown",
    "Calculus 101 Book", "Raspberry Pi 4", "Tripod Stand",
    "System Analysis Book", "Portable Ring Light"
]

def generate_users_and_items(amount=200):
    print(f"Starting to generate {amount} users and items. This may take a few minutes...")
    
    # 1. CREATE THE DEFAULT SUPER ADMIN FIRST (ID = 1)
    admin_data = {
        'full_name': 'System Administrator',
        'email': 'admin@gmail.com',
        'department': 'Faculty / Staff',
        'password': 'Password123!',
        'security_color': 'blue',
        'security_song': 'bohemian rhapsody'
    }
    try:
        res = requests.post(REGISTER_URL, json=admin_data)
        if res.status_code == 201:
            print("Successfully created Super Admin (admin@gmail.com) [ID: 1]")
        else:
            print("Admin might already exist, continuing...")
    except Exception as e:
        print(f"Failed to connect to server: {e}")
        return

    # User ID counter (Starts at 2 because Admin is 1)
    # Since the DB is fresh, SQLite will assign IDs sequentially.
    current_user_id = 2 
    success_count = 0
    
    # 2. SEED THE RANDOM USERS & ITEMS
    for i in range(amount):
        # --- GENERATE USER ---
        fake_name = fake.name()
        clean_name = ''.join(e for e in fake_name if e.isalnum() or e.isspace() or e == '.')
        fake_email = f"{clean_name.replace(' ', '.').replace('..', '.').lower()}@gmail.com"
        user_dept = random.choice(DEPARTMENTS)
        
        user_data = {
            'full_name': clean_name,
            'email': fake_email,
            'department': user_dept,
            'password': 'Password123!', 
            'security_color': 'blue',            
            'security_song': 'bohemian rhapsody' 
        }
        
        try:
            # Register the user
            user_res = requests.post(REGISTER_URL, json=user_data)
            
            if user_res.status_code == 201:
                # --- GENERATE ITEM FOR THIS USER ---
                item_title = random.choice(CAMPUS_ITEMS)
                
                item_data = {
                    'title': item_title,
                    'description': f"Available for borrowing. {fake.sentence(nb_words=8)}",
                    'quantity': 1,
                    'condition': random.choice(['Excellent', 'Good', 'Fair']),
                    'item_image_path': '', # Leaves image blank so UI shows a default icon
                    'owner_name': clean_name,
                    'department': user_dept,
                    'user_id': current_user_id
                }
                
                # Post the item
                item_res = requests.post(ITEMS_URL, json=item_data)
                
                if item_res.status_code == 201:
                    success_count += 1
                    print(f"[{success_count}/{amount}] User created: {fake_email} | Item posted: {item_title}")
                else:
                    print(f"User created, but item failed: {item_res.text}")
                
                # Increment the ID tracker for the next person
                current_user_id += 1
                
                # Small sleep to prevent overwhelming the free Render server
                time.sleep(0.5) 
                
            else:
                print(f"Failed to create user {fake_email}: {user_res.text}")
                
        except Exception as e:
            print(f"Connection Error on loop {i}: {e}")

    print(f"\nDone! Successfully seeded {success_count} users and {success_count} items to the LIVE cloud database.")

if __name__ == '__main__':
    generate_users_and_items(200)