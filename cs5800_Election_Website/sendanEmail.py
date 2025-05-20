import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Email setup
sender_email = "team8esp32devkitv@gmail.com"
password = "expsswrd"  # Use your app password here

def send_email(receiver_email, status):
    # Create the email
    message = MIMEMultipart("alternative")
    message["Subject"] = "Election Website Verification"
    message["From"] = sender_email
    message["To"] = receiver_email

    # Body of the email
    email_body = f"Your request has been {status}."

    # Attach the text to the email
    text_part = MIMEText(email_body, "plain")
    message.attach(text_part)

    # Send the email
    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            print("Connecting to the server...")
            server.login(sender_email, password)
            print("Logged in successfully.")
            server.sendmail(sender_email, receiver_email, message.as_string())
            print("Email sent successfully!")
    except smtplib.SMTPAuthenticationError:
        print("Error: Authentication failed. Check your username and app password.")
    except Exception as e:
        print(f"Error sending email: {e}")
