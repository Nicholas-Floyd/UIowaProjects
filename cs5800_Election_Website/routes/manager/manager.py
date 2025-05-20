from datetime import date
from flask import Blueprint, flash, redirect, render_template, request, url_for
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
import auth
from utils import render_template_with_prefix
from database import db, Voter, Zipcode, Election, BallotVote, Candidate

manager = Blueprint('manager', __name__,
                        template_folder='templates')
render_template = render_template_with_prefix('manager')

@manager.before_request
def before_request():
    auth._required_role('manager')

@manager.route('')
def home():
    return redirect(url_for('manager.elections'))

@manager.route('/elections', methods=['GET', 'POST'])
def elections():
    if request.method == 'POST':
        election_id = request.form.get('election_id')
        ballot_active = 'ballot_active' in request.form
        election = Election.query.get(election_id)
        if election:
            election.ballot_active = ballot_active
            db.session.commit()
            flash(f"Election '{election.title}' updated successfully.", 'success')
        else:
            flash("Election not found.", 'error')
        return redirect(url_for('manager.elections'))
    else:
        elections = Election.query.all()
        return render_template('manage/elections.html', elections=elections)

@manager.route('/search', methods=['GET', 'POST'])
def search():
    voter_id = request.args.get('voter_id')
    name = request.args.get('name')
    precinct = request.args.get('precinct')
    zipcode = request.args.get('zipcode')

    query = Voter.query

    if name:
        query = query.filter(Voter.name.ilike(f'%{name}%'))
    if voter_id:
        query = query.filter(Voter.id.ilike(f'%{voter_id}%'))
    if zipcode:
        query = query.filter(Voter.zip_code.ilike(f'%{zipcode}%'))

    voters = query.all()

    for voter in voters:
        voter_precinct = db.session.execute(select(Zipcode.precinct_id).where(Zipcode.zipcode == voter.zip_code)).scalars().first()
        voter.precinct = voter_precinct or 'N/A'

    if precinct:
        voters = [voter for voter in voters if precinct is None or str(voter.precinct) == precinct]

    return render_template('manage/search.html', voters=voters)

@manager.route('/approve', methods=['GET', 'POST'])
def approve():
    if request.method == 'POST':
        action = request.form.get('action')
        voter_id = request.form.get('voter_id')
        try:
            voter = Voter.query.filter_by(id=voter_id).first_or_404()
            if action == 'approve':
                voter.approved = True
                db.session.commit()
                flash(f'Voter {voter.name} has been approved.', 'success')
            elif action == 'reject':
                db.session.delete(voter)
                db.session.commit()
                flash(f'Voter {voter.name} has been rejected and removed.', 'danger')
        except SQLAlchemyError as e:
            db.session.rollback()
            flash('An error occurred while processing your request.', 'danger')
        return redirect(url_for('manager.approve'))

    unapproved_users = Voter.query.filter_by(approved=False).all()
    return render_template('manage/approve.html', voters=unapproved_users)

@manager.route('/results')
def results():
    elections = Election.query.all()
    for election in elections:
        election.url = url_for('manager.results_election', election_id=election.id)
    return render_template(
        'results/unselected.html',
        elections=elections,
        active_sidebar=''
    )

@manager.route('/results/<int:election_id>')
def results_election(election_id):
    # Get all completed elections for the sidebar
    today = date.today()
    completed_elections = Election.query.filter(Election.polling_date < today).all()
    for election in completed_elections:
        election.url = url_for('manager.results_election', election_id=election.id)

    # Check if the election exists and is completed
    election = Election.query.get(election_id)
    if not election or election.polling_date > today:
        flash('Election not found or not completed yet.')
        return redirect(url_for('manager.results_election', election_id=completed_elections[0].id if completed_elections else ''))

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
        'results/selected.html',
        election_result=election_result,
        elections=completed_elections,
        active_sidebar=election_id
    )

@manager.route('/profile', methods=['GET', 'POST'])
def profile():
    manager = auth.get_user()

    if request.method == 'POST':
        # Update manager information with form data
        manager.name = request.form.get('name')
        manager.email = request.form.get('email')
        # Commit changes to the database
        db.session.commit()
        flash('Your profile has been updated.', 'success')
        return redirect(url_for('manager.profile'))

    return render_template('profile.html', manager=manager)