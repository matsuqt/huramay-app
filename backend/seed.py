import requests
from faker import Faker
import random

fake = Faker()

# The URL to your LOCAL running backend
API_URL = 'https://huramay-app.onrender.com/api/register'

# Standard departments from your app
DEPARTMENTS = [
    'Bachelor of Science in Information Technology',
    'Bachelor of Secondary Education',
    'Bachelor of Physical Education',
    'Faculty / Staff'
]

def generate_fake_users(amount=50): # I lowered this to 50 so it seeds much faster for local testing!
    print(f"Starting to generate {amount} users...")
    success_count = 0
    
    # 1. CREATE THE DEFAULT SUPER ADMIN FIRST
    admin_data = {
        'full_name': 'System Administrator',
        'email': 'admin@gmail.com',
        'department': 'Faculty / Staff',
        'password': 'Password123!',
        'security_color': 'blue',
        'security_song': 'bohemian rhapsody'
    }
    try:
        res = requests.post(API_URL, json=admin_data)
        if res.status_code == 201:
            print("Successfully created Super Admin (admin@gmail.com)")
    except Exception as e:
        print("Failed to create Super Admin. Server might not be running.")
    
    # 2. SEED THE RANDOM USERS
    for i in range(amount):
        # Generate realistic fake data
        fake_name = fake.name()
        # Remove special characters from name to pass your strict Regex validator!
        clean_name = ''.join(e for e in fake_name if e.isalnum() or e.isspace() or e == '.')
        
        # Create a unique @gmail.com email
        fake_email = f"{clean_name.replace(' ', '.').replace('..', '.').lower()}@gmail.com"
        
        user_data = {
            'full_name': clean_name,
            'email': fake_email,
            'department': random.choice(DEPARTMENTS),
            'password': 'Password123!', # Standard password for all test accounts
            'security_color': 'blue',            # DEFAULT RECOVERY COLOR
            'security_song': 'bohemian rhapsody' # DEFAULT RECOVERY SONG
        }
        
        # Send the data to your local server
        try:
            response = requests.post(API_URL, json=user_data)
            if response.status_code == 201:
                success_count += 1
                print(f"[{success_count}/{amount}] Created: {fake_email}")
            else:
                print(f"Failed to create {fake_email}: {response.text}")
        except Exception as e:
            print(f"Connection Error: {e}")

    print(f"\nDone! Successfully seeded {success_count} users to the database.")

if __name__ == '__main__':
    generate_fake_users(50)