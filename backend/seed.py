import requests
from faker import Faker
import random

fake = Faker()

# The URL to your LIVE Render API
API_URL = 'https://huramay-app.onrender.com/api/register'

# Standard departments from your app
DEPARTMENTS = [
    'Bachelor of Science in Information Technology',
    'Bachelor of Secondary Education',
    'Bachelor of Physical Education',
    'Faculty / Staff'
]

def generate_fake_users(amount=200):
    print(f"Starting to generate {amount} users...")
    success_count = 0
    
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
            'age': random.randint(18, 60) # Populating your custom age row
        }
        
        # Send the data to your live server
        try:
            response = requests.post(API_URL, json=user_data)
            if response.status_code == 201:
                success_count += 1
                print(f"[{success_count}/{amount}] Created: {fake_email}")
            else:
                print(f"Failed to create {fake_email}: {response.text}")
        except Exception as e:
            print(f"Connection Error: {e}")

    print(f"\nDone! Successfully seeded {success_count} users to the cloud.")

if __name__ == '__main__':
    generate_fake_users(200)