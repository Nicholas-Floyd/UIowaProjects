from datetime import date
from flask import Blueprint, flash, redirect, render_template, request, url_for
from sqlalchemy import func
from utils import render_template_with_prefix
from database import db, Election, BallotVote, Candidate

results = Blueprint('results', __name__, template_folder='templates')
render_template = render_template_with_prefix('admin/results')


@results.route('')
def home():
    elections = Election.query.filter(Election.polling_date < date.today()).all()
    for election in elections:
        election.url = url_for('admin.results.results_election', election_id=election.id)
    return render_template(
        'unselected.html',
        elections=elections,
        active_sidebar=''
    )

@results.route('/<int:election_id>')
def results_election(election_id):
    # Get all completed elections for the sidebar
    today = date.today()
    completed_elections = Election.query.filter(Election.polling_date < today).all()
    for election in completed_elections:
        election.url = url_for('admin.results.results_election', election_id=election.id)

    # Check if the election exists and is completed
    election = Election.query.get(election_id)
    if not election or election.polling_date > today:
        flash('Election not found or not completed yet.')
        return redirect(url_for('admin.results.results_election', election_id=completed_elections[0].id if completed_elections else ''))

    # Build the election result data
    election_result = {
        'election': election,
        'races': []
    }

    for race in election.races:
        # Compute vote counts for each candidate in the race
        vote_counts = db.session.query(
            BallotVote.candidate_id, func.count(BallotVote.candidate_id)
        ).filter(
            BallotVote.race_id == race.id
        ).group_by(
            BallotVote.candidate_id
        ).all()
        vote_counts_dict = {candidate_id: count for candidate_id, count in vote_counts}

        # Determine the maximum vote count
        if vote_counts:
            max_votes = max(vote_counts_dict.values())
            # Get the winner(s)
            winner_candidate_ids = [candidate_id for candidate_id, count in vote_counts_dict.items() if count == max_votes]
            winner_candidates = Candidate.query.filter(Candidate.id.in_(winner_candidate_ids)).all()
        else:
            winner_candidates = []

        race_result = {
            'race': race,
            'winner_candidates': winner_candidates,
            'vote_counts': vote_counts_dict,
        }
        election_result['races'].append(race_result)

    return render_template(
        'selected.html',
        election_result=election_result,
        elections=completed_elections,
        active_sidebar=election_id
    )