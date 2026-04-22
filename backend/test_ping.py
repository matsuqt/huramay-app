import requests

# WARNING: Make sure 'receiver_id' matches the ID of the user currently logged into your emulator!
# If your emulator is logged in as User 1, leave this as 1.
payload = {
    "chat_room_id": 1,
    "sender_id": 1,   # CHANGED TO 1: You are sending a message to yourself so the backend doesn't crash!
    "receiver_id": 1, # YOU (The emulator)
    "content": "Hey! Did this notification from Python work?"
}

print("Sending simulated message to backend...")
try:
    # URL stays 127.0.0.1 because this Python script is running on your laptop, not the emulator
    response = requests.post("http://127.0.0.1:5000/api/messages/send", json=payload)
    print("Status Code:", response.status_code)
    print("Backend Response:", response.json())
except Exception as e:
    print("Error connecting to server:", e)