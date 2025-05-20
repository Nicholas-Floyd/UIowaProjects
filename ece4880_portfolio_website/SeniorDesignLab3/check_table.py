import sqlite3

def check_tables():
    db_path = " C:\Users\LTNic\Documents\SeniorDesignLab3Repo\SeniorDesignLab3\instance\flaskr.sqlite"  # Ensure this matches your DATABASE path
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # List tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    print("Tables in the database:")
    print(tables)

    # Check contents of the `users` table
    cursor.execute("SELECT * FROM users;")
    users = cursor.fetchall()
    print("\nUsers table content:")
    print(users)

    conn.close()

if __name__ == "__main__":
    check_tables()
