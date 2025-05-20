import pytest
from flask import Flask
from werkzeug.security import check_password_hash
from database import db, Voter, Manager, Zipcode


@pytest.fixture
def client():
    app = Flask(__name__)
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    db.init_app(app)

    with app.app_context():
        db.create_all()
        yield app.test_client()
        db.drop_all()


def test_voter_signup_success(client):
    response = client.post('/voter', data={
        'name': 'John Doe',
        'age': '25',
        'address': '123 Main St',
        'zip_code': '12345',
        'identification1_type': 'Driver License',
        'identification1_number': 'DL12345678',
        'identification2_type': 'Passport',
        'identification2_number': 'P123456789',
        'email': 'john@example.com',
        'password': 'password123'
    })
    assert response.status_code == 302  # should redirect on success
    assert Voter.query.count() == 1
    voter = Voter.query.first()
    assert voter.name == 'John Doe'
    assert check_password_hash(voter.password_hash, 'password123')


def test_voter_signup_underage(client):
    response = client.post('/voter', data={
        'name': 'Jane Doe',
        'age': '17',
        'address': '123 Main St',
        'zip_code': '12345',
        'identification1_type': 'Driver License',
        'identification1_number': 'DL12345678',
        'identification2_type': 'Passport',
        'identification2_number': 'P123456789',
        'email': 'jane@example.com',
        'password': 'password123'
    })
    assert response.status_code == 302
    assert b'You must be 18 or older to register.' in response.data
    assert Voter.query.count() == 0


def test_voter_signup_duplicate_email(client):
    client.post('/voter', data={
        'name': 'John Doe',
        'age': '25',
        'address': '123 Main St',
        'zip_code': '12345',
        'identification1_type': 'Driver License',
        'identification1_number': 'DL12345678',
        'identification2_type': 'Passport',
        'identification2_number': 'P123456789',
        'email': 'john@example.com',
        'password': 'password123'
    })
    response = client.post('/voter', data={
        'name': 'Jane Doe',
        'age': '30',
        'address': '456 Elm St',
        'zip_code': '67890',
        'identification1_type': 'ID Card',
        'identification1_number': 'ID12345678',
        'identification2_type': 'Passport',
        'identification2_number': 'P987654321',
        'email': 'john@example.com',
        'password': 'password456'
    })
    assert response.status_code == 302
    assert b'Email already registered.' in response.data
    assert Voter.query.count() == 1


def test_manager_signup_success(client):
    response = client.post('/manager', data={
        'name': 'Manager Bob',
        'email': 'bob@example.com',
        'password': 'securepassword'
    })
    assert response.status_code == 302  # should redirect on success
    assert Manager.query.count() == 1
    manager = Manager.query.first()
    assert manager.name == 'Manager Bob'
    assert check_password_hash(manager.password_hash, 'securepassword')


def test_voter_signup_invalid_identifications(client):
    response = client.post('/voter', data={
        'name': 'John Doe',
        'age': '25',
        'address': '123 Main St',
        'zip_code': '12345',
        'identification1_type': 'Driver License',
        'identification1_number': 'DL12345678',
        'identification2_type': 'Driver License',  # same type as id1
        'identification2_number': 'DL98765432',
        'email': 'john@example.com',
        'password': 'password123'
    })
    assert response.status_code == 302
    assert b'Identification types must be different.' in response.data
    assert Voter.query.count() == 0
