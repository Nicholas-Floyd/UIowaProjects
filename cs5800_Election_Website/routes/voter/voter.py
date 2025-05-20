from datetime import date, datetime
from flask import Blueprint, flash, redirect, render_template, request, url_for
from sqlalchemy import func
import auth
from database import db, Election, Precinct, Zipcode, Candidate, BallotVote, Race
from utils import render_template_with_prefix

voter = Blueprint('voter', __name__,
                        template_folder='templates')
render_template = render_template_with_prefix('voter')

@voter.route('/vote')
@auth.required_role('voter')
def vote():
    # get all elections
    elections = Election.query.all()
    for election in elections:
        election.url = url_for('voter.vote_election', election_id=election.id)
    elections = [election for election in elections if election.polling_date == datetime.now().date()]

    return render_template(
        'vote/vote_unselected.html',
        elections=elections,
        active_sidebar=''
    )

@voter.route('/vote/<int:election_id>', methods=['GET', 'POST'])
@auth.required_role('voter')
def vote_election(election_id):
    elections = Election.query.all()
    for election in elections:
        election.url = url_for('voter.vote_election', election_id=election.id)
    elections = [election for election in elections if election.polling_date == datetime.now().date()]

    # Check if selected id is valid
    if not [elections for election in elections if election.id == election_id]:
        flash("Invalid election ID.", 'danger')
        return render_template(
            'vote/vote.html',
            elections=elections,
            active_sidebar=election_id
        )

    # Get the current voter
    voter = auth.get_user()

    # Get the election and check if it's active
    election = Election.query.get(election_id)
    if not election or not election.ballot_active:
        flash("This election is not currently active.", 'danger')
        return render_template(
            'vote/vote.html',
            elections=elections,
            active_sidebar=election_id,
            races=[]
        )

    # Get voter's precinct via zip code
    user_zipcode = Zipcode.query.filter_by(zipcode=voter.zip_code).first()
    if not user_zipcode or not user_zipcode.precinct:
        flash("Your zip code does not correspond to any precinct.", 'danger')
        return render_template(
            'vote/vote.html',
            elections=elections,
            active_sidebar=election_id,
            races=[]
        )
    precinct = user_zipcode.precinct

    # Get races in this election and precinct
    races = [race for race in precinct.races if race.election_id == election_id]
    
    # Check if already voted
    for race in races:
        vote = BallotVote.query.filter_by(voter_id=voter.id, race_id=race.id).first()
        if vote:
            return render_template(
                'vote/vote_voted.html',
                elections=elections,
                active_sidebar=election_id,
            )

    if request.method == 'POST':
        # Process the submitted votes
        votes = []
        for race in races:
            # The name of the input is 'race_<race.id>'
            candidate_id = request.form.get(f'race_{race.id}')
            if not candidate_id:
                # No candidate selected for this race, skip or handle accordingly
                continue
            try:
                candidate_id = int(candidate_id)
            except ValueError:
                flash(f"Invalid candidate ID for race {race.name}.", 'danger')
                return redirect(url_for('voter.vote_election', election_id=election_id))
            candidate = Candidate.query.get(candidate_id)
            if not candidate or candidate not in race.candidates:
                flash(f"Invalid candidate selected for race {race.name}.", 'danger')
                return redirect(url_for('voter.vote_election', election_id=election_id))

            # Check if the voter has already voted in this race
            existing_vote = BallotVote.query.filter_by(voter_id=voter.id, race_id=race.id).first()
            if existing_vote:
                flash(f"You have already voted in race {race.name}.", 'danger')
                return redirect(url_for('voter.vote_election', election_id=election_id))

            # Create a new BallotVote
            ballot_vote = BallotVote(
                voter_id=voter.id,
                race_id=race.id,
                candidate_id=candidate.id,
                timestamp=datetime.now()
            )
            votes.append(ballot_vote)

        if not votes:
            flash("No votes were submitted.", 'warning')
            return redirect(url_for('voter.vote_election', election_id=election_id))

        # Save all votes to the database
        try:
            for vote in votes:
                db.session.add(vote)
            db.session.commit()
            flash("Your vote has been recorded.", 'success')
            return redirect(url_for('voter.vote_election', election_id=election_id))
        except Exception as e:
            db.session.rollback()
            flash("An error occurred while recording your vote. Please try again.", 'danger')
            return redirect(url_for('voter.vote_election', election_id=election_id))

    return render_template(
        'vote/vote.html',
        elections=elections,
        active_sidebar=election_id,
        races=races
    )

@voter.route('/summary/<int:election_id>')
@auth.required_role('voter')
def summary(election_id):
    # Get the current voter
    voter = auth.get_user()

    # Get the election
    election = Election.query.get(election_id)
    if not election:
        return "Election not found."

    # Get all races in the election
    races = election.races

    vote_summary = []
    for race in races:
        ballot_vote = BallotVote.query.filter_by(voter_id=voter.id, race_id=race.id).first()
        if not ballot_vote:
            continue
        vote_summary.append({
            "race_name": race.name,
            "candidate_name": ballot_vote.candidate.name,
            "candidate_party": ballot_vote.candidate.party if ballot_vote.candidate.party else "N/A",
            "timestamp": ballot_vote.timestamp
        })

    if not vote_summary:
        return "Election not found."
    
    timestamp = datetime.strftime(vote_summary[0]['timestamp'], "%Y-%m-%d %H:%M:%S")

    return render_template('vote/vote_summary.html', vote_summary=vote_summary, timestamp=timestamp, voter=voter.name, election=election.title)

@voter.route('/results')
@auth.required_role('voter')
def results():
    elections = Election.query.all()
    for election in elections:
        election.url = url_for('voter.results_election', election_id=election.id)

    voter = auth.get_user()
    today = date.today()
    voter_election_ids = db.session.query(
        Election.id
    ).join(Race).join(BallotVote).filter(
        BallotVote.voter_id == voter.id,
        Election.polling_date < today
    ).distinct().all()
    voter_election_ids = [id for (id,) in voter_election_ids]

    elections = Election.query.filter(Election.id.in_(voter_election_ids)).all()

    return render_template(
        'results/result_unselected.html', 
        elections=elections, 
        active_sidebar=''
    )

@voter.route('/results/<int:election_id>')
@auth.required_role('voter')
def results_election(election_id):
    elections = Election.query.all()
    for election in elections:
        election.url = url_for('voter.results_election', election_id=election.id)

    voter = auth.get_user()
    today = date.today()
    voter_election_ids = db.session.query(
        Election.id
    ).join(Race).join(BallotVote).filter(
        BallotVote.voter_id == voter.id,
        Election.polling_date < today
    ).distinct().all()
    voter_election_ids = [id for (id,) in voter_election_ids]

    elections = Election.query.filter(Election.id.in_(voter_election_ids)).all()

    # Check if the selected election is in the list
    if election_id not in voter_election_ids:
        flash('You have not voted in this election or it is not completed yet.', 'danger')
        return render_template(
            'results/result_unselected.html',
            elections=elections,
            active_sidebar=''
        )
    
    # Get the selected election
    election = Election.query.get(election_id)

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
        'results/result.html',
        election_result=election_result,
        elections=elections,
        active_sidebar=election_id
    )

@voter.route('/profile', methods=['GET', 'POST'])
@auth.required_role('voter')
def profile():
    voter = auth.get_user()

    if request.method == 'POST':
        # Update voter information with form data
        voter.name = request.form.get('name')
        voter.email = request.form.get('email')
        voter.age = request.form.get('age')
        voter.address = request.form.get('address')

        # if zip code does not exist, create a new one
        zip_code = request.form.get('zip_code')
        if not Zipcode.query.filter_by(zipcode=zip_code).first():
            new_zip_code = Zipcode(zipcode=zip_code)
            db.session.add(new_zip_code)
            db.session.commit()
        voter.zip_code = zip_code

        # Commit changes to the database
        db.session.commit()
        flash('Your profile has been updated.', 'success')
        return redirect(url_for('voter.profile'))

    return render_template('profile.html', voter=voter)