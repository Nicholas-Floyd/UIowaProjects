import secrets
import string
from flask import Blueprint, flash, redirect, render_template, request, url_for
from sqlalchemy import select
from database import db, Voter, Manager, Zipcode
from werkzeug.security import generate_password_hash

signup = Blueprint('signup', __name__,
                        template_folder='templates')

@signup.route('')
def home():
    # redirect to voter
    return redirect(url_for('signup.voter'))

@signup.route('/voter', methods=['GET', 'POST'])
def voter():
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        address = request.form['address']
        zip_code = request.form['zip_code']
        identification1_type = request.form['identification1_type']
        identification1_number = request.form['identification1_number']
        identification2_type = request.form['identification2_type']
        identification2_number = request.form['identification2_number']

        email = request.form['email']
        password = request.form['password']

        if int(age) < 18:
            flash('You must be 18 or older to register.')
            return redirect(url_for('signup'))
        
        if identification1_type == identification2_type:
            flash('Identification types must be different.')
            return redirect(url_for('signup'))
        
        user_query = select(Voter).where(Voter.email == email)
        existing_user = db.session.execute(user_query).scalars().first()
        if existing_user:
            flash('Email already registered.')
            return redirect(url_for('signup'))
        
        existing_id1 = db.session.execute(select(Voter).where(
            (Voter.identification1_type == identification1_type) &
            (Voter.identification1 == identification1_number)
        )).scalars().first()
        existing_id2 = db.session.execute(select(Voter).where(
            (Voter.identification2_type == identification2_type) &
            (Voter.identification2 == identification2_number)
        )).scalars().first()
        if existing_id1 or existing_id2:
            flash('Identification number already in use.')
            return redirect(url_for('signup'))
        
        voter_id = generate_unique_voter_id()
        password_hash = generate_password_hash(password)

        # if zipcode doesn't exist, create it
        zipcode = db.session.execute(select(Zipcode).where(Zipcode.zipcode == zip_code)).scalars().first()
        if not zipcode:
            zipcode = Zipcode(zipcode=zip_code)
            db.session.add(zipcode)
            db.session.commit()

        new_user = Voter(
            id=voter_id,
            name=name,
            email=email,
            age=age,
            address=address,
            zip_code=zip_code,
            identification1=identification1_number,
            identification1_type=identification1_type,
            identification2=identification2_number,
            identification2_type=identification2_type,
            password_hash=password_hash
        )

        db.session.add(new_user)
        db.session.commit()

        flash(f'Signup successful! Your Voter ID is: {voter_id}')
        return redirect(url_for('login.voter'))
        
    return render_template('signup/voter.html')

@signup.route('/manager', methods=['GET', 'POST'])
def manager():
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        password = request.form['password']

        password_hash = generate_password_hash(password)

        id = secrets.randbelow(9000000) + 1000000

        new_user = Manager(
            id=id,
            name=name,
            email=email,
            password_hash=password_hash
        )

        db.session.add(new_user)
        db.session.commit()

        flash('Signup successful!')
        return redirect(url_for('login.manager'))
    return render_template('signup/manager.html')

def generate_unique_voter_id(length=10):
    characters = string.ascii_uppercase + string.digits
    voter_id = ''.join(secrets.choice(characters) for _ in range(length))
    return voter_id