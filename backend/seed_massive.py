import random
from datetime import datetime, timedelta
from faker import Faker
from app import app
from database import db, bcrypt
from models.user import User
from models.item import Item
from models.borrow_request import BorrowRequest

# Force Faker to use Filipino names and locations
fake = Faker('fil_PH')

# Constants
TOTAL_USERS = 5000
TOTAL_ITEMS = 3000
BORROWED_ITEMS = 1800

# Exactly matches your Flutter dropdown list
DEPARTMENTS = [
    'Bachelor of Elementary Education', 'Bachelor of Early Childhood Education', 
    'Bachelor of Special Needs Education', 'Bachelor of Technology and Livelihood Education', 
    'Bachelor of Physical Education', 'Bachelor of Secondary Education major in English', 
    'Bachelor of Secondary Education major in Filipino', 'Bachelor of Secondary Education major in Mathematics', 
    'Bachelor of Secondary Education major in Science', 'Bachelor of Secondary Education major in Social Studies', 
    'Bachelor of Secondary Education major in Values Education', 'Teacher Certificate Program (TCP)', 
    'Bachelor of Library and Information Science', 'Bachelor of Arts in Communication', 
    'Bachelor of Music in Music Education', 'Bachelor of Science in Information Technology', 
    'Bachelor of Arts in English Language', 'Bachelor of Arts in Political Science', 
    'Bachelor of Science in Biology', 'Bachelor of Science in Social Work', 
    'Bachelor of Science in Tourism Management', 'Bachelor of Science in Hospitality Management', 
    'Bachelor of Science in Entrepreneurship', 'Faculty / Staff'
]
CONDITIONS = ["New", "Like New", "Good", "Fair"]

# --- NEW: REALISTIC EDUCATIONAL RESOURCES BY DEPARTMENT ---
DEPARTMENT_ITEMS = {
    'Bachelor of Elementary Education': [
        {"title": "Math Flashcards Set", "description": "A complete set of addition, subtraction, multiplication, and division flashcards for grades 1-6."},
        {"title": "Storybook Collection", "description": "A bundle of 10 classic children's storybooks perfect for reading comprehension exercises."},
        {"title": "Visual Aids Materials", "description": "Large, colorful charts for teaching the basic alphabet, phonics, and numbers."},
        {"title": "Phonics Reading Blocks", "description": "Wooden blocks with letters to help children construct words and learn basic phonics."}
    ],
    'Bachelor of Early Childhood Education': [
        {"title": "Montessori Wooden Blocks", "description": "Educational blocks designed for fine motor skill development in toddlers."},
        {"title": "Sensory Play Kit", "description": "Includes kinetic sand, textured balls, and safe sorting tools for early learners."},
        {"title": "Alphabet Tracing Board", "description": "A reusable wooden board with a stylus for practicing letter tracing and writing."},
        {"title": "Child Development Textbook", "description": "Essential reading for understanding cognitive milestones and psychology in early childhood."}
    ],
    'Bachelor of Special Needs Education': [
        {"title": "Braille Alphabet Cards", "description": "Standard braille teaching cards for visually impaired inclusive education."},
        {"title": "Sensory Fidget Kit", "description": "A collection of noise-canceling headphones and tactile toys for sensory processing needs."},
        {"title": "Visual Schedule Board", "description": "A magnetic board with customizable icons for children with Autism Spectrum Disorder."},
        {"title": "SPED Teaching Strategies Book", "description": "Comprehensive guide on differentiated instruction and individualized education plans (IEP)."}
    ],
    'Bachelor of Technology and Livelihood Education': [
        {"title": "Basic Electronics Toolkit", "description": "Includes a soldering iron, multimeter, wire strippers, and basic breadboard components."},
        {"title": "Drafting Tools Set", "description": "T-square, triangles, compasses, and drafting scales for technical drawing."},
        {"title": "Culinary Arts Knife Set", "description": "A professional-grade 5-piece knife set with a protective carrying roll."},
        {"title": "Sewing Machine Kit", "description": "Portable sewing kit with varying threads, needles, and a fabric cutting shear."}
    ],
    'Bachelor of Physical Education': [
        {"title": "Agility Cones and Ladders", "description": "Standard physical training equipment for improving footwork and agility."},
        {"title": "Fox40 Pealess Whistle", "description": "Professional referee whistle with lanyard, perfect for outdoor class management."},
        {"title": "Anatomy and Kinesiology Textbook", "description": "Detailed guide on human muscle movement and exercise science."},
        {"title": "Sports First Aid Kit", "description": "Complete med-kit with cold compresses, athletic tape, and bandages."}
    ],
    'Bachelor of Secondary Education major in English': [
        {"title": "The Norton Anthology of English Literature", "description": "Volume 1 and 2 of the definitive guide to classic English literature."},
        {"title": "Advanced Grammar Workbook", "description": "Extensive exercises on syntax, morphology, and complex sentence structures."},
        {"title": "Shakespeare Complete Works", "description": "An unabridged collection of William Shakespeare's plays and sonnets."},
        {"title": "ESL Teaching Flashcards", "description": "Vocabulary and situational flashcards designed for teaching English as a Second Language."}
    ],
    'Bachelor of Secondary Education major in Filipino': [
        {"title": "Noli Me Tangere (Annotated)", "description": "Filipino translation with comprehensive chapter analysis and vocabulary guides."},
        {"title": "El Filibusterismo (Annotated)", "description": "The sequel to Noli Me Tangere, complete with historical context notes."},
        {"title": "UP Diksiyonaryong Filipino", "description": "The official and most comprehensive dictionary of the Filipino language."},
        {"title": "Retorika at Balarila Textbook", "description": "A deep dive into Filipino rhetoric, grammar, and effective communication."}
    ],
    'Bachelor of Secondary Education major in Mathematics': [
        {"title": "Scientific Calculator (Casio fx-991EX)", "description": "Advanced ClassWiz calculator allowed in board examinations."},
        {"title": "Advanced Calculus Textbook", "description": "Comprehensive guide covering limits, derivatives, and multidimensional integrals."},
        {"title": "Geometry Compass and Protractor Set", "description": "High-precision metal compass and drafting tools for blackboard use."},
        {"title": "Number Theory and Logic Book", "description": "Advanced college-level mathematics textbook focusing on proofs and logic."}
    ],
    'Bachelor of Secondary Education major in Science': [
        {"title": "Laboratory Goggles and Apron", "description": "Standard personal protective equipment (PPE) for chemistry and biology labs."},
        {"title": "Organic Chemistry Model Kit", "description": "3D molecular model building kit for visualizing carbon structures and bonds."},
        {"title": "Microscope Slide Set", "description": "25 prepared biological slides including plant cells and animal tissues."},
        {"title": "Physics Dissection Kit", "description": "Stainless steel scalpel, forceps, and scissors inside a sterile case."}
    ],
    'Bachelor of Secondary Education major in Social Studies': [
        {"title": "World History Atlas", "description": "Detailed historical maps covering ancient civilizations to the modern era."},
        {"title": "Philippine Constitution Book", "description": "The 1987 Philippine Constitution with annotations and case studies."},
        {"title": "Asian History Reference Material", "description": "Comprehensive textbook on the geopolitical history of Southeast Asia."},
        {"title": "Political Science Fundamentals", "description": "Introduction to governance, state policies, and political theories."}
    ],
    'Bachelor of Secondary Education major in Values Education': [
        {"title": "Ethics and Morality Textbook", "description": "Philosophical readings on ethics, human values, and moral dilemmas."},
        {"title": "Values Education Curriculum Guide", "description": "DepEd aligned teaching modules for EsP (Edukasyon sa Pagpapakatao)."},
        {"title": "Psychology of Human Development", "description": "Understanding cognitive and moral development across different human life stages."},
        {"title": "Counseling Basics Guide", "description": "A beginner's manual on active listening and student counseling techniques."}
    ],
    'Teacher Certificate Program (TCP)': [
        {"title": "Principles of Teaching Textbook", "description": "Foundational theories and methodologies for aspiring educators."},
        {"title": "Educational Psychology Reviewer", "description": "Key concepts on how students learn, retain information, and develop."},
        {"title": "Assessment of Learning Guide", "description": "Manual on creating effective rubrics, exams, and grading systems."},
        {"title": "Classroom Management Manual", "description": "Strategies for maintaining discipline and an engaging learning environment."}
    ],
    'Bachelor of Library and Information Science': [
        {"title": "Dewey Decimal Classification Guide", "description": "The complete manual for indexing and organizing library collections."},
        {"title": "Library Cataloging Textbook", "description": "Standard rules for bibliographic description and metadata creation."},
        {"title": "Information Literacy Textbook", "description": "Techniques for assessing, retrieving, and evaluating digital information."},
        {"title": "Archival Management Guide", "description": "Best practices for preserving historical documents and fragile manuscripts."}
    ],
    'Bachelor of Arts in Communication': [
        {"title": "DSLR Camera (Canon EOS)", "description": "Standard DSLR camera used for photojournalism and videography projects."},
        {"title": "Rode VideoMic Go", "description": "Directional microphone for clear audio recording during interviews."},
        {"title": "Broadcasting Scriptwriting Guide", "description": "Format and structure guidelines for TV and Radio scriptwriting."},
        {"title": "Media Ethics Textbook", "description": "Discussions on journalism standards, libel laws, and media responsibility."}
    ],
    'Bachelor of Music in Music Education': [
        {"title": "Acoustic Guitar", "description": "Standard classical acoustic guitar for music theory and performance classes."},
        {"title": "Digital Metronome and Tuner", "description": "Essential tool for maintaining tempo and pitch accuracy."},
        {"title": "Music Theory Textbook", "description": "Comprehensive guide to reading notes, harmony, and chord progressions."},
        {"title": "Conductor's Baton", "description": "Lightweight fiberglass baton with a cork handle for choral directing."}
    ],
    'Bachelor of Science in Information Technology': [
        {"title": "Arduino Uno Starter Kit", "description": "Includes breadboard, LEDs, resistors, and jumper wires for IoT projects."},
        {"title": "Raspberry Pi 4 Model B", "description": "Microcomputer used for server hosting, programming, and networking setups."},
        {"title": "Networking Crimping Tool Kit", "description": "Includes RJ45 connectors, crimper, and a LAN cable tester."},
        {"title": "Data Structures and Algorithms Book", "description": "The ultimate guide for Java and Python programming fundamentals."}
    ],
    'Bachelor of Arts in English Language': [
        {"title": "Introduction to Linguistics Textbook", "description": "Study of language structure, syntax, and semantics."},
        {"title": "Phonetics and Phonology Guide", "description": "Detailed charts of the International Phonetic Alphabet (IPA)."},
        {"title": "Sociolinguistics Reader", "description": "Exploring how language impacts society, culture, and identity."},
        {"title": "English Semantics Coursebook", "description": "Understanding meaning, idioms, and pragmatics in the English language."}
    ],
    'Bachelor of Arts in Political Science': [
        {"title": "Philippine Political Law Textbook", "description": "In-depth study of the branches of government and state powers."},
        {"title": "Introduction to International Relations", "description": "Theories on global politics, diplomacy, and foreign policy."},
        {"title": "Public Administration Guide", "description": "Understanding bureaucracy, public policy making, and local governance."},
        {"title": "The Prince by Niccolo Machiavelli", "description": "Classic literature required for political theory and philosophy classes."}
    ],
    'Bachelor of Science in Biology': [
        {"title": "Human Anatomy Atlas", "description": "Highly detailed visual guide of the human skeletal and muscular systems."},
        {"title": "Microbiology Laboratory Manual", "description": "Procedures for culturing bacteria, staining, and microscope handling."},
        {"title": "Genetics Textbook", "description": "Comprehensive textbook covering DNA replication and Mendelian inheritance."},
        {"title": "Pocket Magnifier & Forceps", "description": "Fieldwork tools used for examining botanical and entomological specimens."}
    ],
    'Bachelor of Science in Social Work': [
        {"title": "Social Work Practice Textbook", "description": "Foundational guide on ethics, intervention, and client assessment."},
        {"title": "Community Organizing Guide", "description": "Techniques for mobilizing communities and grassroots advocacy."},
        {"title": "Human Behavior in the Social Environment", "description": "Psychosocial approaches to understanding human development."},
        {"title": "Case Management Manual", "description": "Standardized templates for client profiling, counseling, and referrals."}
    ],
    'Bachelor of Science in Tourism Management': [
        {"title": "Global Tourism Geography Book", "description": "Detailed maps and cultural insights of top international tourist destinations."},
        {"title": "Tour Guiding Techniques Manual", "description": "Best practices for leading tours, public speaking, and itinerary planning."},
        {"title": "Airline Ticketing Guide", "description": "Introduction to Amadeus and Sabre global distribution systems (GDS)."},
        {"title": "Hospitality and Tourism Law", "description": "Legal frameworks, liabilities, and rights in the travel industry."}
    ],
    'Bachelor of Science in Hospitality Management': [
        {"title": "Bartending Mixology Toolkit", "description": "Includes a shaker, jigger, strainer, and muddler for beverage preparation."},
        {"title": "Food and Beverage Service Manual", "description": "Guidelines on fine dining table setup, etiquette, and wine pairing."},
        {"title": "Chef's Uniform and Toque", "description": "Standard clean white culinary uniform required for kitchen laboratory."},
        {"title": "Commercial Cooking Guide", "description": "Recipes and safety standards for large-scale kitchen operations."}
    ],
    'Bachelor of Science in Entrepreneurship': [
        {"title": "Business Plan Development Guide", "description": "Step-by-step manual for feasibility studies and startup pitching."},
        {"title": "Principles of Marketing Textbook", "description": "Core concepts in consumer behavior, branding, and digital marketing."},
        {"title": "Financial Accounting Basics", "description": "Ledger notebooks and guides for basic bookkeeping and financial statements."},
        {"title": "Microeconomics Textbook", "description": "Understanding supply, demand, and market structures for business owners."}
    ],
    'Faculty / Staff': [
        {"title": "Laser Pointer / Wireless Presenter", "description": "USB clicker for controlling PowerPoint presentations during lectures."},
        {"title": "Whiteboard Marker Bulk Set", "description": "A set of 12 refillable whiteboard markers and erasers."},
        {"title": "Ergonomic Office Chair Cushion", "description": "Lumbar support pillow for long hours of grading and desk work."},
        {"title": "Heavy Duty Hole Puncher", "description": "For organizing thick syllabi, modules, and student record binders."}
    ]
}

def seed_massive_data():
    with app.app_context():
        print("🚨 Generating realistic, department-specific educational data...")
        
        valid_hashed_password = bcrypt.generate_password_hash("Huramay@26").decode('utf-8')

        # ==========================================
        # 1. SEED 5,000 USERS
        # ==========================================
        print(f"\n[1/3] Generating {TOTAL_USERS} Validated Filipino Users...")
        users = []
        for i in range(TOTAL_USERS):
            full_name = fake.name()
            safe_email_prefix = full_name.replace(" ", "").replace(".", "").lower()
            safe_email = f"{safe_email_prefix}{i}@gmail.com"

            user = User(
                full_name=full_name,
                email=safe_email,
                department=random.choice(DEPARTMENTS),
                password=valid_hashed_password,
                rating=round(random.uniform(3.0, 5.0), 1),
                is_admin=False,
                age=random.randint(18, 25),
                security_color=fake.color_name().lower(),
                security_song="Buwan" 
            )
            users.append(user)
            
            if len(users) >= 1000:
                db.session.add_all(users)
                db.session.commit()
                users = []
                
        if users:
            db.session.add_all(users)
            db.session.commit()
            
        print("✅ 5,000 Users successfully seeded!")

        all_users = db.session.query(User.id, User.full_name, User.department).all()
        user_ids = [u.id for u in all_users]
        user_data_map = {u.id: {"name": u.full_name, "dept": u.department} for u in all_users}

        # ==========================================
        # 2. SEED 3,000 DEPARTMENT-SPECIFIC ITEMS
        # ==========================================
        print(f"\n[2/3] Generating {TOTAL_ITEMS} Department-Specific Educational Items...")
        items = []
        for i in range(TOTAL_ITEMS):
            owner_id = random.choice(user_ids)
            owner_info = user_data_map[owner_id]
            owner_dept = owner_info["dept"]
            
            # Fetch realistic items that match the user's specific department
            dept_items = DEPARTMENT_ITEMS.get(owner_dept, [
                {"title": "Educational Resource", "description": "Standard university learning material."}
            ])
            selected_item = random.choice(dept_items)
            
            status = "Borrowed" if i < BORROWED_ITEMS else "Available"
            
            item = Item(
                title=selected_item["title"],
                description=selected_item["description"],
                quantity=random.randint(1, 2), # Makes it realistic (1 or 2 items)
                condition=random.choice(CONDITIONS),
                owner_name=owner_info["name"],
                department=owner_dept, # Ensures the item's department perfectly matches the owner
                status=status,
                user_id=owner_id
            )
            items.append(item)
            
            if len(items) >= 1000:
                db.session.add_all(items)
                db.session.commit()
                items = []

        if items:
            db.session.add_all(items)
            db.session.commit()
        print("✅ 3,000 Accurate Educational Items successfully seeded!")

        # ==========================================
        # 3. SEED 1,800 BORROW REQUESTS
        # ==========================================
        print(f"\n[3/3] Generating {BORROWED_ITEMS} active Borrow Requests...")
        borrowed_items = Item.query.filter_by(status="Borrowed").all()
        requests = []
        
        for item in borrowed_items:
            borrower_id = random.choice(user_ids)
            while borrower_id == item.user_id:
                borrower_id = random.choice(user_ids)
                
            borrower_info = user_data_map[borrower_id]
            
            start_date = (datetime.now() - timedelta(days=random.randint(1, 5))).strftime("%Y-%m-%d")
            end_date = (datetime.now() + timedelta(days=random.randint(1, 5))).strftime("%Y-%m-%d")

            borrow_req = BorrowRequest(
                item_id=item.id,
                borrower_id=borrower_id,
                full_name=borrower_info["name"],
                department=borrower_info["dept"],
                start_date=start_date,
                end_date=end_date,
                meetup_location="LNU Campus Main Gate",
                status="Accepted" 
            )
            requests.append(borrow_req)

            if len(requests) >= 500:
                db.session.add_all(requests)
                db.session.commit()
                requests = []
                
        if requests:
            db.session.add_all(requests)
            db.session.commit()

        print("✅ 1,800 Active Borrow Requests successfully seeded!")
        print("\n🎉 ALL DONE! Your database is now populated with Highly Realistic LNU Educational Data.")

if __name__ == "__main__":
    seed_massive_data()