from werkzeug.security import generate_password_hash

hashed = generate_password_hash("123")
print(hashed)
