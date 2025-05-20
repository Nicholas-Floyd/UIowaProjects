import os
import sqlite3
from flask import Flask, render_template, request, jsonify, current_app, g, redirect, url_for, flash, session
from flask.cli import with_appcontext
import click
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
from . import init_app, get_db
from email.mime.text import MIMEText
import smtplib
from flask_wtf.csrf import CSRFProtect



from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField



class ContactForm(FlaskForm):
    message = StringField('Message')
    submit = SubmitField('Send')

instance_path = os.path.join(os.getcwd(), 'instance')

if not os.path.exists(instance_path):
    os.makedirs(instance_path)

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY")
csrf = CSRFProtect(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
app.config['DATABASE'] = os.path.join('instance', 'flaskr.sqlite')

# Initialize the app
init_app(app)


#app.secret_key = os.environ.get('FLASK_SECRET_KEY')

#app.config['DATABASE'] = os.path.join('instance', 'flaskr.sqlite')

init_app(app)  # Call this to register commands and teardown logic

PHONE_NUMBERS = {
    'nick': '13195303682',
    'alex': '13199308672',
    'michael': '15155203034',
    'robby': None,  # Currently unknown
}


@csrf.exempt
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Retrieve form data
        username = request.form.get('username')
        password = request.form.get('password')

        db = get_db()
        user = db.execute('SELECT * FROM users WHERE username = ?', (username,)).fetchone()

        if user and check_password_hash(user['password'], password):
            # Store user info in session
            session['logged_in'] = True
            session['username'] = user['username']
            flash('Login successful!', 'success')
            return redirect(url_for('protected'))
        else:
            flash('Invalid username or password', 'error')
            return redirect(url_for('login'))

    # If GET request, just show the login form
    return render_template('login.html')

@csrf.exempt
@app.route('/logout')
def logout():
    # Clear session data
    session.clear()
    flash('You have been logged out.', 'info')
    return redirect(url_for('login'))

@csrf.exempt
@app.route('/')

def index():
    return render_template('index.html')

@csrf.exempt
@app.route('/protected')
def protected():
    if not session.get('logged_in'):
        flash('You must be logged in to access this page.', 'error')
        return redirect(url_for('login'))
    return render_template('protected.html', username=session.get('username'))

@csrf.exempt
@app.route('/protected/messages')
def list_messages():
    if not session.get('logged_in'):
        flash('You must be logged in to access this page.', 'error')
        return redirect(url_for('login'))
    directory = 'protected/messages'
    if not os.path.exists(directory):
        os.makedirs(directory)
    # Get all message files
    messages = []
    for filename in os.listdir(directory):
        if filename.endswith('.html'):
            name = filename.split('_')[0]  # Extract the team member name from the filename
            messages.append({'filename': filename, 'name': name})
    return render_template('messages.html', messages=messages)

@csrf.exempt
@app.route('/protected/messages/<filename>')
def view_message(filename):
    if not session.get('logged_in'):
        flash('You must be logged in to access this page.', 'error')
        return redirect(url_for('login'))
    directory = 'protected/messages'
    file_path = os.path.join(directory, filename)
    if not os.path.exists(file_path):
        flash('Message not found.', 'error')
        return redirect(url_for('list_messages'))
    with open(file_path, 'r') as f:
        content = f.read()
    return render_template('message_view.html', content=content)

@csrf.exempt
@app.route('/team_member/<name>')
def team_member(name):
    valid_names = ['nick', 'alex', 'michael', 'robby']
    name = name.lower()
    form = ContactForm()

    if form.validate_on_submit():
        # If the form is submitted, redirect to the contact route
        return redirect(url_for('contact', name=name))

    if name in valid_names:
        return render_template(f'{name}.html', name=name.capitalize(), form=form)
    else:
        return render_template('404.html'), 404


def send_sms_via_email(phone_number, message):
    smtp_server = 'smtp.gmail.com'
    smtp_port = 587
    sender_email = 'team8esp32devkitv@gmail.com'
    sender_password = 'expsswrd'

    msg = MIMEText(message)
    msg['From'] = sender_email
    msg['To'] = f'{phone_number}@email.uscc.net'  # Adjust carrier domain as needed
    msg['Subject'] = 'SMS Notification'

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        print("SMS sent successfully!")
    except Exception as e:
        print(f"Failed to send SMS: {e}")

@csrf.exempt
@app.route('/contact/<name>', methods=['POST'])
def contact(name):

    # Check if the name exists in the PHONE_NUMBERS dictionary
    if name not in PHONE_NUMBERS:
        flash('Invalid team member.', 'error')
        return redirect(url_for('index'))

    phone_number = PHONE_NUMBERS.get(name)
    if not phone_number:
        flash('Phone number not available for this team member.', 'error')
        return redirect(url_for('team_member', name=name))

    # Get the message from the form
    message = request.form.get('message').strip()
    if not message:
        flash('Message cannot be empty.', 'error')
        return redirect(url_for('team_member', name=name))

    # Create a timestamped and sanitized file name
    timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    safe_name = ''.join(c for c in name if c.isalnum())
    directory = 'protected/messages'
    os.makedirs(directory, exist_ok=True)
    file_path = os.path.join(directory, f'{safe_name}_{timestamp}.html')

    try:
        # Save the message as a web page
        with open(file_path, 'w') as f:
            f.write(f'<p>{message}</p><p>Timestamp: {timestamp}</p>')

        # Send the SMS
        formatted_message = f"{message}\nTimestamp: {timestamp}"
        send_sms_via_email(phone_number, formatted_message)

        flash('Message sent successfully via SMS and saved!', 'success')
    except Exception as e:
        print(f"Error handling contact form: {e}")
        flash('An error occurred while processing your request.', 'error')

    return redirect(url_for('team_member', name=name))



#if __name__ == '__main__':
    # This block should only run in local development.
 #   app.run(debug=True)



