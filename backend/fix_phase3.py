import requests
import time
import random

BASE_URL = 'https://huramay-app.onrender.com/api'
BORROW_URL = f'{BASE_URL}/borrow' # <--- DOUBLE CHECK THIS NAME!

def fix_phase_3():
    print("Starting Phase 3 FIX: Creating 1,000 Transactions...")
    
    # We assume users 4001-5000 are the borrowers
    # and items 1-1000 are the targets
    success_count = 0
    
    for i in range(1000):
        borrower_id = 4001 + i
        item_id = i + 1
        
        borrow_data = {
            'item_id': item_id,
            'borrower_id': borrower_id,
            'borrow_duration_days': random.randint(1, 7)
        }
        
        try:
            res = requests.post(BORROW_URL, json=borrow_data)
            if res.status_code in [200, 201]:
                success_count += 1
                if success_count % 50 == 0:
                    print(f"  -> {success_count}/1000 transactions fixed...")
            else:
                # This will tell us EXACTLY why it's failing
                if i == 0: print(f"Error from server: {res.status_code} - {res.text}")
            
            # Slow down to prevent Render from crashing
            time.sleep(0.5) 
            
        except Exception as e:
            print(f"Request failed: {e}")

    print(f"Finished! Added {success_count} transactions.")

if __name__ == '__main__':
    fix_phase_3()