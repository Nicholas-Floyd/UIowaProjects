
from flask import Blueprint, flash, redirect, render_template, request, session, url_for
from sqlalchemy import select
from database import db, Voter, Manager, Admin
from werkzeug.security import check_password_hash
import auth

login = Blueprint('login', __name__,
                        template_folder='templates')

@login.route('')
@auth.redirect_role('admin', 'admin.home', url_for=True)
@auth.redirect_role('voter', 'voter.vote', url_for=True)
def home():
    return redirect(url_for('login.voter'))

@login.route('/voter', methods=['GET', 'POST'])
@auth.redirect_role('admin', 'admin.home', url_for=True)
@auth.redirect_role('voter', 'voter.vote', url_for=True)
def voter():
    if request.method == 'POST':
        voter_id = request.form['voter_id']
        password = request.form['password']
        
        # check if the email exists in the database
        select_query = select(Voter).where(Voter.id == voter_id)
        user = db.session.execute(select_query).scalars().first()

        if not user:
            flash("User not found.")
            return redirect(url_for('login.voter'))
        
        # check if the password is correct
        if not check_password_hash(user.password_hash, password):
            flash("Incorrect password.")
            return redirect(url_for('login.voter'))
        
        # check if the user is approved
        if not user.approved:
            flash("Voter not approved.")
            return redirect(url_for('login.voter'))
        
        auth.login('voter', user)
        
        return redirect(url_for('voter.vote'))
    return render_template('login/voter.html')

@login.route('/manager', methods=['GET', 'POST'])
@auth.redirect_role('admin', 'admin.home', url_for=True)
@auth.redirect_role('voter', 'voter.vote', url_for=True)
def manager():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        # check if the email exists in the database
        select_query = select(Manager).where(Manager.email == email)
        user = db.session.execute(select_query).scalars().first()

        if not user:
            flash("User not found.")
            return redirect(url_for('login.manager'))
        
        # check if the password is correct
        if not check_password_hash(user.password_hash, password):
            flash("Incorrect password.")
            return redirect(url_for('login.manager'))
        
        # check if the user is approved
        if not user.approved:
            flash("Manager not approved.")
            return redirect(url_for('login.manager'))
        
        auth.login('manager', user)
        
        return redirect(url_for('manager.home'))
    return render_template('login/manager.html')

@login.route('/admin', methods=['GET', 'POST'])
@auth.redirect_role('admin', 'admin.home', url_for=True)
@auth.redirect_role('voter', 'voter.vote', url_for=True)
def admin():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        # check if the email exists in the database
        select_query = select(Admin).where(Admin.email == email)
        user = db.session.execute(select_query).scalars().first()

        if not user:
            flash("User not found.")
            return redirect(url_for('login.admin'))
        
        # check if the password is correct
        if not check_password_hash(user.password_hash, password):
            flash("Incorrect password.")
            return redirect(url_for('login.admin'))
        
        auth.login('admin', user)
        
        return redirect(url_for('admin.home'))
    return render_template('login/admin.html')