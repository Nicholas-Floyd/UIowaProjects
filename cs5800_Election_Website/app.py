from flask import Flask, flash, redirect, render_template, request, session, url_for
from flask_migrate import Migrate
import auth
from database import db

# set current working directory
import os
os.chdir(os.path.dirname(__file__))


import json
with open('secrets.json') as f:
    data = json.load(f)
    db_password = data['password']

# create the app
app = Flask(__name__)
migrate = Migrate(directory='./database/migrations')
# configure the SQLite database, relative to the app instance folder
app.config["SQLALCHEMY_DATABASE_URI"] = f"mysql+pymysql://root:{db_password}@localhost:3306/elections"
app.secret_key = 'your_secret_key'  # Replace this with a secure secret key
# initialize the app with the extension
db.init_app(app)
migrate.init_app(app, db)

# import the routes. should do this after initializing the app/db
from routes import signup, login, admin, voter, manager
app.register_blueprint(signup, url_prefix='/signup')
app.register_blueprint(login, url_prefix='/login')
app.register_blueprint(admin, url_prefix='/admin')
app.register_blueprint(manager, url_prefix='/manager')
app.register_blueprint(voter)

import debug
debug.register_commands(app)
app.register_blueprint(debug.debug, url_prefix='/debug')

@app.before_request
def remove_trailing_slash():
    if request.path != '/' and request.path.endswith('/'):
        # strip trailing slash and redirect
        return redirect(request.path.rstrip('/'), code=301)
    
@app.cli.command('seed-data')
def seed_data():
    print("Data seeded successfully.")

@app.route('/')
def home():
    return redirect(url_for('voter.vote'))

@app.route('/logout')
def logout():
    auth.logout()
    flash("You have been logged out.")
    return redirect(url_for('login.voter'))

# if __name__ == '__main__':
#     app.run(debug=True)