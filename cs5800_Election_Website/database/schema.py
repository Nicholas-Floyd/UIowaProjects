from sqlalchemy import (
    TEXT, Boolean, Column, DateTime, Integer, String, Date, ForeignKey, Table, Float
)
from sqlalchemy.orm import relationship
from . import db

Base = db.Model

# Association tables for many-to-many relationships
race_precincts = Table(
    'race_precincts', Base.metadata,
    Column('race_id', Integer, ForeignKey('race.id'), primary_key=True),
    Column('precinct_id', Integer, ForeignKey('precinct.id'), primary_key=True)
)

race_candidates = Table(
    'race_candidates', Base.metadata,
    Column('candidate_id', Integer, ForeignKey('candidate.id'), primary_key=True),
    Column('race_id', Integer, ForeignKey('race.id'), primary_key=True)
)

class Manager(Base):
    __tablename__ = 'manager'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    approved = Column(Boolean, nullable=False, default=False)

    precincts = relationship('Precinct', back_populates='manager')

class Precinct(Base):
    __tablename__ = 'precinct'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    natural_geography = Column(String(255), nullable=True)
    manager_id = Column(Integer, ForeignKey('manager.id'))
    state_official = Column(String(255), nullable=True)

    manager = relationship('Manager', back_populates='precincts')
    zipcodes = relationship('Zipcode', back_populates='precinct')
    races = relationship('Race', secondary=race_precincts, back_populates='precincts')

class Zipcode(Base):
    __tablename__ = 'zipcode'
    zipcode = Column(String(10), primary_key=True)
    precinct_id = Column(Integer, ForeignKey('precinct.id'))

    precinct = relationship('Precinct', back_populates='zipcodes')

class Admin(Base):
    __tablename__ = 'admin'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)

class Voter(Base):
    __tablename__ = 'voter'
    id = Column(String(255), primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True)
    age = Column(Integer, nullable=False)
    address = Column(String(255), nullable=True)
    zip_code = Column(String(10), ForeignKey('zipcode.zipcode'), nullable=True)
    identification1 = Column(String(50), nullable=True)
    identification2 = Column(String(50), nullable=True)
    identification1_type = Column(String(50), nullable=True)
    identification2_type = Column(String(50), nullable=True)
    password_hash = Column(String(255), nullable=False)
    approved = Column(Boolean, nullable=False, default=False)

    ballots = relationship('BallotVote', back_populates='voter')

class Election(Base):
    __tablename__ = 'election'
    id = Column(Integer, primary_key=True)
    title = Column(String(100), nullable=False)
    polling_date = Column(Date, nullable=False)
    ballot_active = Column(Boolean, nullable=False, default=False)

    races = relationship('Race', back_populates='election')

class Race(Base):
    __tablename__ = 'race'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    election_id = Column(Integer, ForeignKey('election.id'))

    election = relationship('Election', back_populates='races')
    candidates = relationship('Candidate', secondary=race_candidates, back_populates='races')
    precincts = relationship('Precinct', secondary=race_precincts, back_populates='races')
    ballots = relationship('BallotVote', back_populates='race')

class Candidate(Base):
    __tablename__ = 'candidate'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    party = Column(String(50), nullable=True)
    statement = Column(TEXT, nullable=True)

    races = relationship('Race', secondary=race_candidates, back_populates='candidates')
    ballots = relationship('BallotVote', back_populates='candidate')

class BallotVote(Base):
    __tablename__ = 'ballot_vote'
    voter_id = Column(String(255), ForeignKey('voter.id'), primary_key=True)
    race_id = Column(Integer, ForeignKey('race.id'), primary_key=True)
    candidate_id = Column(Integer, ForeignKey('candidate.id'))
    timestamp = Column(DateTime, nullable=False)

    voter = relationship('Voter', back_populates='ballots')
    race = relationship('Race', back_populates='ballots')
    candidate = relationship('Candidate', back_populates='ballots')
