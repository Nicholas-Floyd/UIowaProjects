from typing import List
from flask import Blueprint, flash, redirect, render_template, request, url_for
from sqlalchemy import select
import auth
from database import db, Voter, Precinct, Zipcode, Manager
from utils import render_template_with_prefix
from sqlalchemy.exc import SQLAlchemyError

users = Blueprint('users', __name__,
                        template_folder='templates')
render_template = render_template_with_prefix('admin/users')

@users.route('')
def home():
    return redirect(url_for('admin.users.search'))

@users.route('/search')
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

    return render_template('search.html', voters=voters)

@users.route('/approve', methods=['GET', 'POST'])
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
        return redirect(url_for('admin.users.approve'))

    unapproved_users = Voter.query.filter_by(approved=False).all()
    return render_template('approve_users.html', voters=unapproved_users)

@users.route('/approve/managers', methods=['GET', 'POST'])
def approve_managers():
    if request.method == 'POST':
        action = request.form.get('action')
        manager_id = request.form.get('manager_id')
        try:
            manager = Manager.query.filter_by(id=manager_id).first_or_404()
            if action == 'approve':
                manager.approved = True
                db.session.commit()
                flash(f'Manager {manager.name} has been approved.', 'success')
            elif action == 'reject':
                db.session.delete(manager)
                db.session.commit()
                flash(f'Manager {manager.name} has been rejected and removed.', 'danger')
        except SQLAlchemyError as e:
            db.session.rollback()
            flash('An error occurred while processing your request.', 'danger')
        return redirect(url_for('admin.users.approve'))

    unapproved_managers = Manager.query.filter_by(approved=False).all()
    return render_template('approve_managers.html', managers=unapproved_managers)