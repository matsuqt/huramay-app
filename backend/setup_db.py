from app import app
from database import db

with app.app_context():
    # This command forcefully deletes every existing table in the active database
    db.drop_all() 
    
    # This command rebuilds the empty, fresh tables
    db.create_all()
    
    print("SUCCESS: Active database found, completely wiped, and rebuilt fresh!")