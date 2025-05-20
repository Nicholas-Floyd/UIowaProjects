# Hospital Management System

## Description

This project focused on designing and implementing a relational database system for a hospital management platform, using concepts learned in class such as:

- Entity-Relationship (ER) modeling
- Functional dependency analysis and normalization to **Third Normal Form (3NF)**
- Implementation of **stored procedures**, **user roles**, and **data integrity constraints**
- Integration with a **Flask web application** using Python and MySQL

## My Contributions

I was primarily responsible for:

- **Authentication and Authorization:** Secure login system using stored procedures and role-based access control
- **Role Management:** Supporting Admin, Physician, Nurse, and Patient roles with separate permissions
- **Appointment System:** Implemented logic for scheduling and managing patient–physician appointments via stored procedures

In addition, I supported my teammates by:

- Helping integrate all components into a unified **Flask web app**
- Merging independently developed schemas into a single normalized SQL script
- Using basic **HTML and Flask templates** to build a functional front end for demo purposes

## Demo

🎥 You can view a walkthrough of the features I implemented here:  
[![Hospital Management Demo](https://img.youtube.com/vi/re-OU_wMCuQ/0.jpg)](https://youtu.be/re-OU_wMCuQ)



# For Flask Project
We are using local instances of the database so make sure to run the database scripts to have tables and procedures created. 
Set to correct directory (cd Hospital-Management)

# Pull latest changes
git pull

# Create the Virtual Environment
python -m venv venv

Activate it:

# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install the dependencies
pip install -r requirements.txt
pip freeze > requirements.txt

# Create a .env file in root
add this to the file:

"# Flask settings"
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=this-should-be-long-and-random

"#  MySQL Database connection (used in mysql.connector.connect)"
DB_HOST=localhost
DB_USER=root
DB_PASS=your-mysql-password
DB_NAME=team5project


DATABASE_URL=mysql+pymysql://root:yourpassword@localhost/team5project


# Now run (make sure in venv still)
flask run

# .gitignore is already setup already 
To be sure it should have 
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.env

# Pushing
Be careful not to accidentally push your venv, .env, or __pycache__ to git. Terminal is best way to push to not accidentally push wrong stuff. For ex git add "file" will add what files you want to add and git commit m should actually push it. Can use git status to double check what is currently being committed or not. 
