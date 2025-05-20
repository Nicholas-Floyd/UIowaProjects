import os
import sqlite3
from werkzeug.security import generate_password_hash

DATABASE_PATH = 'instance/flaskr.sqlite'
BACKUP_PATH = 'instance/backup_flaskr.sqlite'

def update_password(username, new_password):
    if not os.path.exists(DATABASE_PATH):
        print(f"Error: Database file not found at {DATABASE_PATH}")
        return

    # Create a backup before making changes
    os.makedirs(os.path.dirname(BACKUP_PATH), exist_ok=True)
    os.system(f"cp {DATABASE_PATH} {BACKUP_PATH}")
    print(f"Backup created at {BACKUP_PATH}")

    # Connect to the database and update the password
    db = sqlite3.connect(DATABASE_PATH)
    hashed_password = generate_password_hash(new_password)
    cursor = db.execute('UPDATE users SET password = ? WHERE username = ?', (hashed_password, username))
    db.commit()
    db.close()

    if cursor.rowcount == 0:
        print(f"Error: No user found with username '{username}'.")
    else:
        print(f"Password for '{username}' has been successfully updated.")

if __name__ == "__main__":
    user = input("Enter username: ")
    new_pass = input("Enter new password: ")
    update_password(user, new_pass)
