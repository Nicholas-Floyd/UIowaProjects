import pytest
from flask import Flask
from database import db, Admin
from werkzeug.security import generate_password_hash


@pytest.fixture
def client():
    app = Flask(__name__)
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.secret_key = 'test_secret_key'
    db.init_app(app)

    with app.app_context():
        db.create_all()

        # setup test admin
        admin = Admin(
            id=1,
            name='Admin User',
            email='admin@example.com',
            password_hash=generate_password_hash('adminpassword')
        )
        db.session.add(admin)
        db.session.commit()

        # simulate admin login
        with app.test_client() as client:
            with client.session_transaction() as sess:
                sess['role'] = 'admin'
                sess['admin'] = admin.id
            yield client

        db.drop_all()


def test_profile_view(client):
    response = client.get('/profile')
    assert response.status_code == 200
    assert b'Admin User' in response.data  # Ensure the admin's name is displayed
    assert b'admin@example.com' in response.data  # Ensure the admin's email is displayed


def test_profile_update(client):
    response = client.post('/profile', data={
        'name': 'Updated Admin',
        'email': 'updated_admin@example.com'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Your profile has been updated.' in response.data

    # Verify the admin's information was updated in the database
    admin = Admin.query.get(1)
    assert admin.name == 'Updated Admin'
    assert admin.email == 'updated_admin@example.com'
