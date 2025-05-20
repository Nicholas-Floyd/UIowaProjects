from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

db = SQLAlchemy(model_class=Base)

from .schema import (
    Manager,
    Precinct,
    Zipcode,
    Admin,
    Voter,
    Election,
    Race,
    Candidate,
    BallotVote
)