import pytest
from flask import Flask
from sqlalchemy.exc import SQLAlchemyError
from database import db, Voter, Manager, Zipcode, Precinct
from werkzeug.security import generate_password_hash


@pytest.fixture
def client():
    app = Flask(__name__)
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.secret_key = 'test_secret_key'
    db.init_app(app)

    with app.app_context():
        db.create_all()

        # setup initial data
        voter = Voter(
            id="VOTER123",
            name="John Doe",
            email="johndoe@example.com",
            zip_code="12345",
            approved=False,
            password_hash=generate_password_hash("password123")
        )
        manager = Manager(
            id=1,
            name="Manager Jane",
            email="manager@example.com",
            approved=False
        )
        zipcode = Zipcode(zipcode="12345", precinct=Precinct(id=1, name="Test Precinct"))
        db.session.add_all([voter, manager, zipcode])
        db.session.commit()

        yield app.test_client()

        db.drop_all()


def test_search_voters(client):
    response = client.get('/users/search', query_string={'name': 'John'})
    assert response.status_code == 200
    assert b"John Doe" in response.data  # ensures voter is listed


def test_approve_voter_get(client):
    response = client.get('/users/approve')
    assert response.status_code == 200
    assert b"John Doe" in response.data  # ensures unapproved voter is listed


def test_approve_voter_post_approve(client):
    response = client.post('/users/approve', data={
        'action': 'approve',
        'voter_id': 'VOTER123'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Voter John Doe has been approved." in response.data

    # ensure the voter is now approved in the database
    voter = Voter.query.filter_by(id="VOTER123").first()
    assert voter.approved is True


def test_approve_voter_post_reject(client):
    response = client.post('/users/approve', data={
        'action': 'reject',
        'voter_id': 'VOTER123'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Voter John Doe has been rejected and removed." in response.data

    # ensure the voter is deleted from the database
    voter = Voter.query.filter_by(id="VOTER123").first()
    assert voter is None


def test_approve_manager_get(client):
    response = client.get('/users/approve/managers')
    assert response.status_code == 200
    assert b"Manager Jane" in response.data  # ensures unapproved manager is listed


def test_approve_manager_post_approve(client):
    response = client.post('/users/approve/managers', data={
        'action': 'approve',
        'manager_id': 1
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Manager Manager Jane has been approved." in response.data

    # ensure the manager is now approved in the database
    manager = Manager.query.filter_by(id=1).first()
    assert manager.approved is True


def test_approve_manager_post_reject(client):
    response = client.post('/users/approve/managers', data={
        'action': 'reject',
        'manager_id': 1
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Manager Manager Jane has been rejected and removed." in response.data

    # ensure the manager is deleted from the database
    manager = Manager.query.filter_by(id=1).first()
    assert manager is None
