from flask import Blueprint, flash, redirect, render_template, request, url_for
from database import db
import auth
from utils import render_template_with_prefix

profile = Blueprint('profile', __name__, template_folder='templates')
render_template = render_template_with_prefix('admin')

@profile.route('', methods=['GET', 'POST'])
def home():
    admin = auth.get_user()

    if request.method == 'POST':
        # Update admin information with form data
        admin.name = request.form.get('name')
        admin.email = request.form.get('email')
        # Commit changes to the database
        db.session.commit()
        flash('Your profile has been updated.', 'success')
        return redirect(url_for('admin.profile.home'))

    return render_template('profile.html', admin=admin)