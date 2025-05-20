import pytest
from datetime import datetime, date
from werkzeug.security import generate_password_hash
from database import db, Voter, Election, Precinct, Zipcode, Candidate, BallotVote, Race
from flask import Flask

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
        voter = Voter(
            id=1,
            name='Test Voter',
            email='test@example.com',
            zip_code='12345',
            password_hash=generate_password_hash('password123')
        )
        precinct = Precinct(id=1, name='Test Precinct')
        zipcode = Zipcode(zipcode='12345', precinct=precinct)
        election = Election(
            id=1,
            title="Test Election",
            polling_date=datetime.now().date(),
            ballot_active=True
        )
        race = Race(id=1, name='Test Race', election=election, precinct=precinct)
        candidate = Candidate(id=1, name='Candidate A', race=race)

        db.session.add_all([voter, precinct, zipcode, election, race, candidate])
        db.session.commit()

        yield app.test_client()

        db.drop_all()


def test_vote_view(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    response = client.get('/vote')
    assert response.status_code == 200
    assert b'Test Election' in response.data  # Ensure the election is listed


def test_vote_election_valid(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    response = client.get('/vote/1')
    assert response.status_code == 200
    assert b'Test Race' in response.data  # Ensure the race is listed


def test_vote_election_invalid_id(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    response = client.get('/vote/999')
    assert response.status_code == 200
    assert b'Invalid election ID.' in response.data


def test_vote_submission(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    response = client.post('/vote/1', data={'race_1': '1'}, follow_redirects=True)
    assert response.status_code == 200
    assert b'Your vote has been recorded.' in response.data
    assert BallotVote.query.count() == 1


def test_vote_already_voted(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    client.post('/vote/1', data={'race_1': '1'})
    response = client.post('/vote/1', data={'race_1': '1'}, follow_redirects=True)
    assert response.status_code == 200
    assert b'You have already voted in race' in response.data


def test_profile_update(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    response = client.post('/profile', data={
        'name': 'Updated Name',
        'email': 'updated@example.com',
        'age': '30',
        'address': 'New Address',
        'zip_code': '67890'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Your profile has been updated.' in response.data
    voter = Voter.query.get(1)
    assert voter.name == 'Updated Name'
    assert voter.email == 'updated@example.com'
    assert voter.zip_code == '67890'


def test_results_view(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    response = client.get('/results')
    assert response.status_code == 200
    assert b'Test Election' in response.data  # Ensure the election is listed


def test_results_election_view(client):
    client.post('/login', data={'email': 'test@example.com', 'password': 'password123'})
    client.post('/vote/1', data={'race_1': '1'})  # Cast a vote
    response = client.get('/results/1')
    assert response.status_code == 200
    assert b'Candidate A' in response.data  # Ensure candidate results are shown
