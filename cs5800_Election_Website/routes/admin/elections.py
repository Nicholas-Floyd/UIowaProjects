from flask import Blueprint, flash, redirect, render_template, request, url_for
import auth
from database import db, Candidate, Election, Race, Precinct, Manager, Zipcode, Voter
from utils import render_template_with_prefix
from datetime import datetime

elections = Blueprint('elections', __name__, template_folder='templates')
render_template = render_template_with_prefix('admin/elections')

@elections.route('', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        # Get form data
        name = request.form.get('title')
        polling_date = request.form.get('polling_date')
        race_ids = request.form.getlist('races')
        ballot_active = request.form.get('ballot_active', False)
        
        # Validate form data
        if not name or not polling_date:
            flash('Please fill out all required fields.', 'warning')
            return redirect(url_for('admin.elections.home'))
        if not race_ids:
            flash('Please select at least one race.', 'warning')
            return redirect(url_for('admin.elections.home'))
        
        # Convert polling_date to date object
        try:
            polling_date = datetime.strptime(polling_date, '%Y-%m-%d').date()
        except ValueError:
            flash('Invalid date format. Please use YYYY-MM-DD.', 'warning')
            return redirect(url_for('admin.elections.home'))
        
        # Convert ballot_active to boolean
        ballot_active = ballot_active == 'true'
        
        # Create new Election instance
        new_election = Election(
            title=name,
            polling_date=polling_date,
            ballot_active=ballot_active
        )
        
        # Add to database
        try:
            db.session.add(new_election)
            db.session.commit()

            # Assign selected races to the new election
            if race_ids:
                races = Race.query.filter(Race.id.in_(race_ids)).all()
                for race in races:
                    race.election_id = new_election.id
                db.session.commit()

            flash('Election created successfully.', 'success')
        except Exception as e:
            db.session.rollback()
            flash('An error occurred while adding the election.', 'danger')
        
        return redirect(url_for('admin.elections.home'))
    else:
        # GET request: Fetch all elections
        elections_list = Election.query.all()
        races_list = Race.query.filter(Race.election_id == None).all()
        return render_template('elections.html', elections=elections_list, races=races_list)

@elections.route('/races', methods=['GET', 'POST'])
def races():
    if request.method == 'POST':
        # Get form data
        name = request.form.get('title')
        precinct_ids = request.form.getlist('precincts')  # List of selected precinct IDs
        candidate_ids = request.form.getlist('candidates')  # List of selected candidate IDs

        # Validate form data
        if not name:
            flash('Please fill out all required fields.', 'warning')
            return redirect(url_for('admin.elections.races'))
        if not precinct_ids:
            flash('Please select at least one precinct.', 'warning')
            return redirect(url_for('admin.elections.races'))
        if not candidate_ids:
            flash('Please select at least one candidate.', 'warning')
            return redirect(url_for('admin.elections.races'))

        # Create new Race instance
        new_race = Race(
            name=name,
        )

        # Fetch precinct and candidate objects from the database
        precincts = Precinct.query.filter(Precinct.id.in_(precinct_ids)).all()
        candidates = Candidate.query.filter(Candidate.id.in_(candidate_ids)).all()

        # Associate precincts and candidates with the race
        new_race.precincts = precincts
        new_race.candidates = candidates

        # Add to database
        try:
            db.session.add(new_race)
            db.session.commit()
            flash('Race created successfully.', 'success')
        except Exception as e:
            db.session.rollback()
            flash(f'An error occurred while adding the race: {str(e)}', 'danger')

        return redirect(url_for('admin.elections.races'))
    else:
        # GET request: Fetch all races, elections, precincts, and candidates for the form
        races_list = Race.query.all()
        elections_list = Election.query.all()
        precincts_list = Precinct.query.all()
        candidates_list = Candidate.query.all()
        return render_template(
            'races.html',
            races=races_list,
            elections=elections_list,
            precincts=precincts_list,
            candidates=candidates_list
        )

@elections.route('/precincts', methods=['GET', 'POST'])
def precincts():
    if request.method == 'POST':
        # Get form data
        name = request.form.get('name')
        natural_geography = request.form.get('natural_geography')
        manager_id = request.form.get('manager_id')
        state_official = request.form.get('state_official')
        zipcodes_input = request.form.getlist('zipcodes')

        # Validate form data
        if not name:
            flash('Please provide a name for the precinct.', 'warning')
            return redirect(url_for('admin.elections.precincts'))

        # Create new Precinct instance
        new_precinct = Precinct(
            name=name,
            natural_geography=natural_geography,
            manager_id=manager_id if manager_id else None,
            state_official=state_official
        )

        # Add to the database
        try:
            db.session.add(new_precinct)
            db.session.commit()

            # Assign zip codes to the precinct
            if zipcodes_input:
                for zc in zipcodes_input:
                    # Check if zipcode already exists
                    existing_zipcode = Zipcode.query.filter_by(zipcode=zc).first()
                    if existing_zipcode:
                        existing_zipcode.precinct_id = new_precinct.id
                    else:
                        new_zipcode = Zipcode(
                            zipcode=zc,
                            precinct_id=new_precinct.id
                        )
                        db.session.add(new_zipcode)
                db.session.commit()
            flash('Precinct created and zip codes assigned successfully.', 'success')
        except Exception as e:
            db.session.rollback()
            flash(f'An error occurred while adding the precinct: {str(e)}', 'danger')

        return redirect(url_for('admin.elections.precincts'))
    else:
        # GET request: Fetch all precincts and managers for the form
        precincts_list = Precinct.query.all()
        managers_list = Manager.query.filter(Manager.approved == True).all()
        # get all zipcodes
        zip_codes = Zipcode.query.filter(Zipcode.precinct_id == None).all()
        zip_codes = [zc.zipcode for zc in zip_codes]
        return render_template('precincts.html', precincts=precincts_list, managers=managers_list, zip_codes=zip_codes)

@elections.route('/candidates', methods=['GET', 'POST'])
def candidates():
    if request.method == 'POST':
        # Get form data
        name = request.form.get('name')
        party = request.form.get('party')
        statement = request.form.get('statement')
        
        # Validate form data
        if not name or not party or not statement:
            flash('Please fill out all fields.', 'warning')
            return redirect(url_for('admin.elections.candidates'))
        
        # Create a new Candidate instance
        new_candidate = Candidate(
            name=name, 
            party=party,
            statement=statement
            )
        
        # Add to the database
        try:
            db.session.add(new_candidate)
            db.session.commit()
            flash('Candidate created successfully.', 'success')
        except Exception as e:
            db.session.rollback()
            flash('An error occurred while adding the candidate.', 'danger')
        
        return redirect(url_for('admin.elections.candidates'))
    else:
        # GET request: Fetch all candidates
        candidates = Candidate.query.all()
        return render_template('candidates.html', candidates=candidates)