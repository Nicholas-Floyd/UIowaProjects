import pytest
from datetime import date, datetime
from flask import Flask, session
from werkzeug.security import generate_password_hash
from sqlalchemy.exc import SQLAlchemyError
from database import db, Manager, Voter, Zipcode, Election, Precinct, Candidate, BallotVote, Race

@pytest.fixture
def client():
    app = Flask(__name__)
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.secret_key = 'test_secret_key'
    db.init_app(app)

    with app.app_context():
        db.create_all()

        # setup test data
        manager = Manager(
            id=1,
            name='Test Manager',
            email='manager@example.com',
            password_hash=generate_password_hash('managerpass'),
            approved=True
        )
        voter = Voter(
            id='VOTER123',
            name='John Doe',
            email='john@example.com',
            zip_code='12345',
            approved=False,
            password_hash=generate_password_hash('password123')
        )
        precinct = Precinct(id=1, name='Test Precinct')
        zipcode = Zipcode(zipcode='12345', precinct=precinct)
        election = Election(
            id=1,
            title="Test Election",
            polling_date=datetime.now().date(),
            ballot_active=False
        )
        race = Race(id=1, name='Test Race', election=election, precinct=precinct)
        candidate = Candidate(id=1, name='Candidate A', race=race)

        db.session.add_all([manager, voter, precinct, zipcode, election, race, candidate])
        db.session.commit()

        # simulate manager login
        with app.test_client() as client:
            with client.session_transaction() as sess:
                sess['role'] = 'manager'
                sess['manager'] = manager.id
            yield client

        db.drop_all()

def test_manager_home_redirect(client):
    response = client.get('/manager/')
    assert response.status_code == 302
    assert response.location.endswith('/manager/elections')

def test_manager_elections_get(client):
    response = client.get('/manager/elections')
    assert response.status_code == 200
    assert b'Test Election' in response.data  # Ensure the election is listed

def test_manager_elections_post(client):
    # Activate an election
    response = client.post('/manager/elections', data={
        'election_id': '1',
        'ballot_active': 'on'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b"Election 'Test Election' updated successfully." in response.data
    election = Election.query.get(1)
    assert election.ballot_active is True

def test_manager_search_voter_by_name(client):
    response = client.get('/manager/search', query_string={'name': 'John Doe'})
    assert response.status_code == 200
    assert b'John Doe' in response.data

def test_manager_search_voter_by_id(client):
    response = client.get('/manager/search', query_string={'voter_id': 'VOTER123'})
    assert response.status_code == 200
    assert b'John Doe' in response.data

def test_manager_approve_get(client):
    response = client.get('/manager/approve')
    assert response.status_code == 200
    assert b'John Doe' in response.data  # Unapproved voter should be listed

def test_manager_approve_post_approve(client):
    response = client.post('/manager/approve', data={
        'action': 'approve',
        'voter_id': 'VOTER123'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Voter John Doe has been approved.' in response.data
    voter = Voter.query.get('VOTER123')
    assert voter.approved is True

def test_manager_approve_post_reject(client):
    # First, add a new unapproved voter
    unapproved_voter = Voter(
        id='VOTER456',
        name='Jane Smith',
        email='jane@example.com',
        zip_code='67890',
        approved=False,
        password_hash=generate_password_hash('password456')
    )
    db.session.add(unapproved_voter)
    db.session.commit()

    response = client.post('/manager/approve', data={
        'action': 'reject',
        'voter_id': 'VOTER456'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Voter Jane Smith has been rejected and removed.' in response.data
    voter = Voter.query.get('VOTER456')
    assert voter is None  # Voter should be deleted

def test_manager_results_view(client):
    # Set polling_date in the past to make the election completed
    election = Election.query.get(1)
    election.polling_date = date(2000, 1, 1)
    db.session.commit()

    response = client.get('/manager/results')
    assert response.status_code == 200
    assert b'Test Election' in response.data

def test_manager_results_election_view(client):
    # Cast a vote to have some results
    voter = Voter.query.get('VOTER123')
    voter.approved = True
    db.session.commit()
    with client.session_transaction() as sess:
        sess['role'] = 'voter'
        sess['voter'] = voter.id

    client.post('/voter/vote/1', data={'race_1': '1'})

    # Switch back to manager session
    with client.session_transaction() as sess:
        sess['role'] = 'manager'
        sess['manager'] = 1

    response = client.get('/manager/results/1')
    assert response.status_code == 200
    assert b'Candidate A' in response.data
    assert b'Winner' in response.data

def test_manager_profile_get(client):
    response = client.get('/manager/profile')
    assert response.status_code == 200
    assert b'Test Manager' in response.data

def test_manager_profile_post(client):
    response = client.post('/manager/profile', data={
        'name': 'Updated Manager',
        'email': 'updated_manager@example.com'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Your profile has been updated.' in response.data
    manager = Manager.query.get(1)
    assert manager.name == 'Updated Manager'
    assert manager.email == 'updated_manager@example.com'
