
import random

import click
from flask import Blueprint, redirect, session, url_for
import auth
from database import db, Voter, Zipcode, Candidate, Admin, Manager
from werkzeug.security import generate_password_hash

debug = Blueprint('debug', __name__)

FIRST_NAMES = [
    "John",
    "Jane",
    "Alice",
    "Bob",
    "Charlie",
    "David",
    "Eve",
    "Frank",
    "Grace",
    "Heidi",
    "Ivan",
    "Judy",
    "Kevin",
    "Laura",
    "Michael",
    "Nancy",
    "Oscar",
    "Peggy",
    "Quincy",
    "Rita",
    "Steve",
    "Tina",
    "Ursula",
    "Victor",
    "Wendy",
    "Xander",
    "Yvonne",
    "Zack",
]

LAST_NAMES = [
    "Smith",
    "Johnson",
    "Williams",
    "Jones",
    "Brown",
    "Davis",
    "Miller",
    "Wilson",
    "Moore",
    "Taylor",
    "Anderson",
    "Thomas",
    "Jackson",
]

ZIPCODES = [
    '12345',
    '52241',
    '99999',
    '00000',
    '11111',
    '22222',
    '33333',
    '44444',
]

def register_commands(app):
    @app.cli.command('add-admin')
    @click.argument('name')
    @click.argument('email')
    @click.argument('password')
    def add_admin(name, email, password):
        password_hash = generate_password_hash(password)
        admin = Admin(name=name, email=email, password_hash=password_hash)
        db.session.add(admin)
        db.session.commit()
        print("Admin added successfully.")

    @app.cli.command('generate-voters')
    @click.argument('n', type=int)
    def generate_voters(n):
        for _ in range(n):
            voter_id = random.randint(1000000, 9999999)
            name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
            email = f"{name.replace(' ', '.').lower()}@example.com"
            age = random.randint(18, 100)
            password_hash = generate_password_hash(f"Password1!")
            zip_code = random.choice(ZIPCODES)

            # insert zipcode if it doesn't exist
            if not Zipcode.query.get(zip_code):
                zipcode = Zipcode(zipcode=zip_code)
                db.session.add(zipcode)
                db.session.commit()

            voter = Voter(id=voter_id, name=name, email=email, age=age, password_hash=password_hash, zip_code=zip_code)
            db.session.add(voter)
        db.session.commit()
        print(f"Generated {n} voters.")

    @app.cli.command('generate-candidates')
    @click.argument('n', type=int)
    def generate_candidates(n):
        for _ in range(n):
            name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
            party = random.choice(['Democrat', 'Republican', 'Independent'])
            candidate = Candidate(name=name, party=party)
            db.session.add(candidate)
        db.session.commit()
        print(f"Generated {n} candidates.")

@debug.route('')
def home():
    return {key: value for key, value in session.items()}

@debug.route('/login_admin')
def debug_login_admin():
    auth.logout()
    user = Admin.query.first()
    auth.login('admin', user)
    return redirect(url_for('admin.home'))

@debug.route('/login_voter')
def debug_login_voter():
    auth.logout()
    user = Voter.query.filter(Voter.id == '07YXBCT6EF').first()
    auth.login('voter', user)
    return redirect(url_for('voter.vote'))

@debug.route('/login_manager')
def debug_login_manager():
    auth.logout()
    user = Manager.query.first()
    auth.login('manager', user)
    return redirect(url_for('manager.home'))