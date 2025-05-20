# ECE:4880 Portfolio Website

## Description

This project was developed as part of my Senior Design course to serve as a portfolio website for each member of our group. The site includes individual profile pages and a contact form with SMS-based messaging functionality.

## Features

- User login and authentication system
- Password reset functionality (works even when the server is offline)
- Contact form that stores messages on the website as individual routes, viewable at `/protected/messages`
- Lightweight database for user information
- Each group member has a personalized webpage displaying their prior projects

## My Contributions

I was fully responsible for the **backend implementation**, which included:

- Creating and securing all Flask routes
- Building the user management and password reset system
- Integrating and storing contact form submissions
- Managing the message routing logic

My teammates contributed to the **frontend**, using an external HTML/CSS template recommended by our professors. However, porting over the template introduced formatting issues that are still unresolved. The only frontend files I did not write are the individual `name.html` profile templates.

## Technologies Used

- Python (Flask)
- SQLite
- HTML/CSS (external template)
- SMS messaging (contact form backend)
