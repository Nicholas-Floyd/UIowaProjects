from functools import wraps
from flask import abort, redirect, session
import flask

from database import Admin, Manager, Voter

def login(role, user):
    logout()
    if role == 'admin':
        session['role'] = 'admin'
        session['user_id'] = user.id
    elif role == 'voter':
        session['role'] = 'voter'
        session['user_id'] = user.id
    elif role == 'manager':
        session['role'] = 'manager'
        session['user_id'] = user.id
    else:
        raise Exception("Invalid user role.")

def logout():
    session.clear()

def is_logged_in() -> bool:
    return 'user_id' in session

def get_user():
    if not is_logged_in():
        raise Exception("User is not logged in.")
    if 'role' not in session:
        raise Exception("User role is not set.")
    if session['role'] == 'admin':
        return Admin.query.get(session['user_id'])
    elif session['role'] == 'voter':
        return Voter.query.get(session['user_id'])
    elif session['role'] == 'manager':
        return Manager.query.get(session['user_id'])
    else:
        raise Exception("Invalid user role.")
    
# decorator
def redirect_if_logged_in(redirect_url):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if is_logged_in():
                return redirect(redirect_url)
            return func(*args, **kwargs)
        return wrapper
    return decorator

# decorator
def redirect_role(role, redirect_url, url_for=False):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if url_for:
                _redirect_url = flask.url_for(redirect_url)
            else:
                _redirect_url = redirect_url
            if is_logged_in() and session['role'] == role:
                return redirect(_redirect_url)
            return func(*args, **kwargs)
        return wrapper
    return decorator

# decorator
def required_role(required_role, redirect_url=None):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            result = _required_role(required_role, redirect_url)
            if result:
                return result
            return func(*args, **kwargs)
        return wrapper
    return decorator

def _required_role(required_role, redirect_url=None):
    if isinstance(required_role, str):
        required_role = [required_role]
    if 'role' not in session or session['role'] not in required_role:
        if redirect_url:
            return redirect(redirect_url)
        abort(403)  # forbidden