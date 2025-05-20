import sqlite3
import click
from flask import current_app, g
from werkzeug.security import generate_password_hash
from flask.cli import with_appcontext

def get_db():
    """Get a database connection, creating one if it doesn't already exist."""
    if 'db' not in g:
        g.db = sqlite3.connect(
            current_app.config['DATABASE'],
            detect_types=sqlite3.PARSE_DECLTYPES
        )
        g.db.row_factory = sqlite3.Row  # Return rows as dictionaries for easier access
    return g.db

def close_db(e=None):
    """Close the database connection if it exists."""
    db = g.pop('db', None)
    if db is not None:
        db.close()

def init_db():
    """Initialize the database by applying the schema and inserting default data."""
    db = get_db()
    try:
        # Read and execute the schema.sql file
        with current_app.open_resource('Database/schema.sql') as f:
            schema = f.read().decode('utf8')
            print("Applying the following schema:")
            print(schema)
            db.executescript(schema)
        print("Database schema applied successfully.")

        # Insert default users
        default_user = ('defaultUser', generate_password_hash('Fall2024Lab3'))
        team_members = [
            ('Nick', generate_password_hash('password1')),
            ('Alex', generate_password_hash('password2')),
            ('Michael', generate_password_hash('password3')),
            ('Robby', generate_password_hash('password4'))
        ]
        db.executemany(
            'INSERT OR REPLACE INTO users (username, password) VALUES (?, ?)',
            [default_user] + team_members
        )
        db.commit()
        print("Default users inserted successfully.")
        print(f"Initializing database at: {current_app.config['DATABASE']}")
    except FileNotFoundError:
        print("Error: schema.sql file not found. Make sure it exists in the 'Database' directory.")
    except sqlite3.Error as e:
        print(f"SQLite error occurred: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")

@click.command('init-db')
@with_appcontext
def init_db_command():
    """Clear existing data and create new tables."""
    try:
        init_db()
        click.echo('Initialized the database.')
    except Exception as e:
        click.echo(f"Failed to initialize the database: {e}")

def init_app(app):
    """Register the database functions and CLI commands with the app."""
    app.teardown_appcontext(close_db)
    app.cli.add_command(init_db_command)
