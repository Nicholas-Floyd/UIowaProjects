import pytest
from datetime import datetime
from flask import Flask
from database import db, Election, Race, Precinct, Candidate, Zipcode, Manager


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
        manager = Manager(id=1, name="Manager One", approved=True)
        zipcode1 = Zipcode(zipcode='12345')
        zipcode2 = Zipcode(zipcode='67890')
        db.session.add_all([manager, zipcode1, zipcode2])
        db.session.commit()

        yield app.test_client()

        db.drop_all()


def test_create_election(client):
    response = client.post('/elections', data={
        'title': 'Test Election',
        'polling_date': '2024-12-25',
        'ballot_active': 'true',
        'races': []
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Election created successfully.' in response.data
    election = Election.query.filter_by(title='Test Election').first()
    assert election is not None
    assert election.polling_date == datetime.strptime('2024-12-25', '%Y-%m-%d').date()


def test_create_race(client):
    response = client.post('/elections/races', data={
        'title': 'Test Race',
        'precincts': [],
        'candidates': []
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Please select at least one precinct.' in response.data

    # add precincts and candidates, then retry
    precinct = Precinct(id=1, name='Test Precinct')
    candidate = Candidate(id=1, name='Test Candidate', party='Independent', statement='Test Statement')
    db.session.add_all([precinct, candidate])
    db.session.commit()

    response = client.post('/elections/races', data={
        'title': 'Test Race',
        'precincts': [1],
        'candidates': [1]
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Race created successfully.' in response.data
    race = Race.query.filter_by(name='Test Race').first()
    assert race is not None
    assert race.precincts[0].id == 1
    assert race.candidates[0].id == 1


def test_create_precinct(client):
    response = client.post('/elections/precincts', data={
        'name': 'Test Precinct',
        'natural_geography': 'Test Region',
        'manager_id': 1,
        'state_official': 'Official Name',
        'zipcodes': ['12345', '67890']
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Precinct created and zip codes assigned successfully.' in response.data
    precinct = Precinct.query.filter_by(name='Test Precinct').first()
    assert precinct is not None
    assert len(precinct.zipcodes) == 2
    assert precinct.zipcodes[0].zipcode == '12345'


def test_create_candidate(client):
    response = client.post('/elections/candidates', data={
        'name': 'John Doe',
        'party': 'Independent',
        'statement': 'My mission is to serve.'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Candidate created successfully.' in response.data
    candidate = Candidate.query.filter_by(name='John Doe').first()
    assert candidate is not None
    assert candidate.party == 'Independent'
    assert candidate.statement == 'My mission is to serve.'


def test_get_candidates(client):
    candidate = Candidate(id=1, name='Candidate A', party='Party A', statement='Test Statement')
    db.session.add(candidate)
    db.session.commit()

    response = client.get('/elections/candidates')
    assert response.status_code == 200
    assert b'Candidate A' in response.data


def test_get_precincts(client):
    precinct = Precinct(id=1, name='Precinct A', natural_geography='Region A', manager_id=1)
    db.session.add(precinct)
    db.session.commit()

    response = client.get('/elections/precincts')
    assert response.status_code == 200
    assert b'Precinct A' in response.data


def test_get_races(client):
    race = Race(id=1, name='Race A')
    db.session.add(race)
    db.session.commit()

    response = client.get('/elections/races')
    assert response.status_code == 200
    assert b'Race A' in response.data


def test_get_elections(client):
    election = Election(id=1, title='Election A', polling_date=datetime.now().date(), ballot_active=False)
    db.session.add(election)
    db.session.commit()

    response = client.get('/elections')
    assert response.status_code == 200
    assert b'Election A' in response.data
