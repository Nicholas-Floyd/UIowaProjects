import pytest
from flask import Flask, session
from werkzeug.security import generate_password_hash
from database import db, Voter, Manager, Admin


@pytest.fixture
def client():
    app = Flask(__name__)
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.secret_key = 'test_secret_key'
    db.init_app(app)

    with app.app_context():
        db.create_all()
        # add test users
        voter = Voter(
            id='VOTER123',
            name='John Doe',
            email='john@example.com',
            password_hash=generate_password_hash('password123'),
            approved=True
        )
        manager = Manager(
            id=1,
            name='Manager Bob',
            email='bob@example.com',
            password_hash=generate_password_hash('securepassword'),
            approved=True
        )
        admin = Admin(
            id=1,
            name='Admin Alice',
            email='alice@example.com',
            password_hash=generate_password_hash('adminpassword')
        )
        db.session.add(voter)
        db.session.add(manager)
        db.session.add(admin)
        db.session.commit()

        yield app.test_client()

        db.drop_all()


def test_voter_login_success(client):
    response = client.post('/voter', data={
        'voter_id': 'VOTER123',
        'password': 'password123'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert 'voter' in session
    assert session['role'] == 'voter'


def test_voter_login_incorrect_password(client):
    response = client.post('/voter', data={
        'voter_id': 'VOTER123',
        'password': 'wrongpassword'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Incorrect password." in response.data


def test_voter_login_not_approved(client):
    # create an unapproved voter
    unapproved_voter = Voter(
        id='VOTER999',
        name='Jane Doe',
        email='jane@example.com',
        password_hash=generate_password_hash('password456'),
        approved=False
    )
    db.session.add(unapproved_voter)
    db.session.commit()

    response = client.post('/voter', data={
        'voter_id': 'VOTER999',
        'password': 'password456'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Voter not approved." in response.data


def test_manager_login_success(client):
    response = client.post('/manager', data={
        'email': 'bob@example.com',
        'password': 'securepassword'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert 'manager' in session
    assert session['role'] == 'manager'


def test_admin_login_success(client):
    response = client.post('/admin', data={
        'email': 'alice@example.com',
        'password': 'adminpassword'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert 'admin' in session
    assert session['role'] == 'admin'


def test_admin_login_user_not_found(client):
    response = client.post('/admin', data={
        'email': 'nonexistent@example.com',
        'password': 'password123'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"User not found." in response.data
