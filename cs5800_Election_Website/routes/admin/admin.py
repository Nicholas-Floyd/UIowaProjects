
from flask import Blueprint, redirect, render_template, request, url_for

import auth
from .elections import elections
from .users import users
from .profile import profile
from .results import results

admin = Blueprint('admin', __name__,
                        template_folder='templates')
admin.register_blueprint(elections, url_prefix='/elections')
admin.register_blueprint(users, url_prefix='/users')
admin.register_blueprint(profile, url_prefix='/profile')
admin.register_blueprint(results, url_prefix='/results')

@admin.before_request
def before_request():
    auth._required_role('admin')

@admin.route('')
def home():
    return redirect(url_for('admin.elections.home'))