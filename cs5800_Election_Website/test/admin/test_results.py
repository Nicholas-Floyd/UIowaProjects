import pytest
from datetime import date, datetime, timedelta
from flask import Flask
from database import db, Election, BallotVote, Candidate, Race


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
        past_date = date.today() - timedelta(days=30)
        future_date = date.today() + timedelta(days=30)

        # elections
        completed_election = Election(id=1, title="Completed Election", polling_date=past_date)
        upcoming_election = Election(id=2, title="Upcoming Election", polling_date=future_date)

        # races
        race = Race(id=1, name="Test Race", election=completed_election)

        # candidates
        candidate1 = Candidate(id=1, name="Candidate A", race=race)
        candidate2 = Candidate(id=2, name="Candidate B", race=race)

        # votes
        vote1 = BallotVote(voter_id=1, race_id=1, candidate_id=1, timestamp=datetime.now())
        vote2 = BallotVote(voter_id=2, race_id=1, candidate_id=2, timestamp=datetime.now())
        vote3 = BallotVote(voter_id=3, race_id=1, candidate_id=1, timestamp=datetime.now())

        db.session.add_all([completed_election, upcoming_election, race, candidate1, candidate2, vote1, vote2, vote3])
        db.session.commit()

        yield app.test_client()

        db.drop_all()


def test_home_view(client):
    response = client.get('/results')
    assert response.status_code == 200
    assert b"Completed Election" in response.data
    assert b"Upcoming Election" not in response.data


def test_results_election_view(client):
    response = client.get('/results/1')  # completed election
    assert response.status_code == 200
    assert b"Test Race" in response.data
    assert b"Candidate A" in response.data
    assert b"Candidate B" in response.data

    # ensure the winner is correctly calculated
    assert b"Winner" in response.data  # indicates the winner is displayed
    assert b"Candidate A" in response.data  # as Candidate A has 2 votes


def test_results_upcoming_election(client):
    response = client.get('/results/2')  # upcoming election
    assert response.status_code == 302  # redirect expected
    assert b"Election not found or not completed yet." in response.data


def test_results_nonexistent_election(client):
    response = client.get('/results/999')  # non-existent election
    assert response.status_code == 302  # redirect expected
    assert b"Election not found or not completed yet." in response.data
