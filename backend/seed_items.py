import sqlite3
import requests
import random
from faker import Faker

fake = Faker()

# Connect directly to your local database to get the real user names and IDs
conn = sqlite3.connect('instance/User.db')
cursor = conn.cursor()
cursor.execute("SELECT id, full_name, department FROM user")
users = cursor.fetchall()
conn.close()

# The URL to your LOCAL running backend
API_URL = 'http://127.0.0.1:5000/api/items'

# Realistic items
ITEMS = [
    'Arduino Uno R3', 'Raspberry Pi 4', 'Dell Latitude Laptop', 
    'Epson Projector', 'Tournament Chess Set', 'Traditional Angklung', 
    'Mechanical Keyboard', 'Wireless Mouse', 'Cat6 Ethernet Cable', 
    'USB-C Hub', 'Drawing Tablet', 'Digital Camera'
]

def generate_items():
    print(f"Starting to generate items for {len(users)} users...")
    success_count = 0

    for user in users:
        user_id = user[0]
        full_name = user[1]
        department = user[2]
        
        item_title = random.choice(ITEMS)
        
        item_data = {
            'title': item_title,
            'description': f"A standard {item_title} in good working order. Available for borrowing.",
            'quantity': random.randint(1, 2),
            'condition': random.choice(['Excellent', 'Good', 'Fair']),
            'item_image_path': '', 
            'owner_name': full_name,
            'department': department,
            'user_id': user_id
        }
        
        try:
            response = requests.post(API_URL, json=item_data)
            if response.status_code == 201:
                success_count += 1
                print(f"[{success_count}/{len(users)}] Created '{item_title}' for {full_name}")
            else:
                print(f"Failed to create item: {response.text}")
        except Exception as e:
            print(f"Connection Error: {e}")

    print(f"\nDone! Successfully seeded {success_count} items to the database.")

if __name__ == '__main__':
    generate_items()