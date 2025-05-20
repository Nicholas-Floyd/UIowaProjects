-- create database team5project; 
use team5project;  
-- DROP DATABASE team5project;
SELECT * FROM Appointment;

-- SELECT * FROM Patient;
-- SELECT * FROM PhysicianSpecializations;
SELECT * FROM Appointment;
-- ------------------------------------
-- DROP TABLES IN CORRECT ORDER
-- ------------------------------------
DROP TABLE IF EXISTS Appointment;
DROP TABLE IF EXISTS AppointmentTypes;
DROP TABLE IF EXISTS TimeSlot;
DROP TABLE IF EXISTS PhysicianDepartment;
DROP TABLE IF EXISTS Nurse;
DROP TABLE IF EXISTS Physician;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Admin;
DROP TABLE IF EXISTS User;
DROP TABLE IF EXISTS Roles;
DROP TABLE IF EXISTS Specializations;
DROP TABLE IF EXISTS ClinicDepartment;


SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------
-- CLINIC & DEPARTMENT TABLES
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Clinic (
    Clinic_ID VARCHAR(255) PRIMARY KEY,
    Clinic_Name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Department (
    Dept_ID VARCHAR(255) PRIMARY KEY,
    Clinic_ID VARCHAR(255),
    Dept_Name VARCHAR(255),
    FOREIGN KEY (Clinic_ID) REFERENCES CLINIC(Clinic_ID)
);

-- ------------------------------------
-- ROLES TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Roles (
    RoleID VARCHAR(50) PRIMARY KEY,
    RoleName VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO Roles (RoleID, RoleName) VALUES
('R1', 'Patient'),
('R2', 'Physician'),
('R3', 'Nurse'),
('R4', 'Admin');

-- ------------------------------------
-- SPECIALIZATIONS TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Specializations (
    Specialization_ID VARCHAR(50) PRIMARY KEY,
    Specialization VARCHAR(255) NOT NULL
);

INSERT INTO Specializations (Specialization_ID, Specialization) VALUES
('SP1', 'Cardiology'),
('SP2', 'Radiology'),
('SP3', 'Pediatrics'),
('SP4', 'General Surgery');

-- ------------------------------------
-- PHYSICIAN RANKS TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS PhysicianRanks (
    RankID VARCHAR(50) PRIMARY KEY,
    RankName VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO PhysicianRanks (RankID, RankName) VALUES
('PR1', 'Resident'),
('PR2', 'Attending'),
('PR3', 'Fellow'),
('PR4', 'Staff Physician'),
('PR5', 'Chief');

-- ------------------------------------
-- USER TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS User (
    UserID VARCHAR(50) PRIMARY KEY,
    Username VARCHAR(255) UNIQUE NOT NULL,
    FirstName VARCHAR(255),
    LastName VARCHAR(255),
    Email VARCHAR(255) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    RoleID VARCHAR(50),
    Phone VARCHAR(20),
    Gender VARCHAR(20),
    Sex VARCHAR(20),
    DOB DATE,
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

-- ------------------------------------
-- PATIENT TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Patient (
    PatientID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    InsurancePlanID VARCHAR(50),
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

-- ------------------------------------
-- PHYSICIAN TABLE
-- (NO longer has DeptID directly)
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Physician (
    PhysicianID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    PhysicianType VARCHAR(255),
    PhysicianRankID VARCHAR(50),
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (PhysicianRankID) REFERENCES PhysicianRanks(RankID)
);


-- ------------------------------------
-- PHYSICIAN DEPARTMENT LINKING TABLE (NEW!)
-- ------------------------------------
CREATE TABLE IF NOT EXISTS PhysicianDepartment (
    PhysicianID VARCHAR(50),
    DeptID VARCHAR(50),
    PRIMARY KEY (PhysicianID, DeptID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID) ON DELETE CASCADE,
    FOREIGN KEY (DeptID) REFERENCES Department(Dept_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS PhysicianSpecializations (
    PhysicianID VARCHAR(50),
    SpecializationID VARCHAR(50),
    PRIMARY KEY (PhysicianID, SpecializationID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (SpecializationID) REFERENCES Specializations(Specialization_ID)
);

-- ------------------------------------
-- NURSE TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Nurse (
    NurseID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

-- ------------------------------------
-- ADMIN TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Admins (
    AdminID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

-- ------------------------------------
-- TIME SLOT TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS TimeSlot (
    SlotID VARCHAR(50) PRIMARY KEY,
    DeptID VARCHAR(50),
    PhysicianID VARCHAR(50),
    StartTime DATETIME,
    EndTime DATETIME,
    Available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (DeptID) REFERENCES Department(Dept_ID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID)
);

-- ------------------------------------
-- APPOINTMENT TYPES TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS AppointmentTypes (
    TypeID VARCHAR(50) PRIMARY KEY,
    TypeName VARCHAR(255),
    ApptDescription VARCHAR(255)
);

-- ------------------------------------
-- APPOINTMENT TABLE
-- ------------------------------------
CREATE TABLE IF NOT EXISTS Appointment (
    ApptID VARCHAR(50) PRIMARY KEY,
    PatientID VARCHAR(50),
    PhysicianID VARCHAR(50),
    SlotID VARCHAR(50),
    TypeID VARCHAR(50),
    DeptID VARCHAR(50),
    ApptDate DATETIME,
    ApptStatus ENUM('Scheduled', 'Completed', 'Cancelled', 'Rescheduled') DEFAULT 'Scheduled',
    CheckinStatus BOOLEAN DEFAULT FALSE,
    SurveyCompleted BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (SlotID) REFERENCES TimeSlot(SlotID),
    FOREIGN KEY (TypeID) REFERENCES AppointmentTypes(TypeID),
    FOREIGN KEY (DeptID) REFERENCES Department(Dept_ID)
);

CREATE TABLE IF NOT EXISTS NurseDepartment (
    NurseDeptID VARCHAR(50) PRIMARY KEY,
    NurseID VARCHAR(50),
    DeptID VARCHAR(50),
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID),
    FOREIGN KEY (DeptID) REFERENCES Department(Dept_ID)
);

CREATE TABLE IF NOT EXISTS NurseSpecializations (
    NurseID VARCHAR(50),
    SpecializationID VARCHAR(50),
    PRIMARY KEY (NurseID, SpecializationID),
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID),
    FOREIGN KEY (SpecializationID) REFERENCES Specializations(Specialization_ID)
);



-- ------------------------------------
-- Insert Initial Admin User
-- ------------------------------------
INSERT INTO User (
    UserID, Username, FirstName, LastName, Email, PasswordHash, RoleID, Phone, Gender, Sex, DOB
) VALUES (
    'admin-uuid-001', 'admin', 'Super', 'Admin', 'admin@example.com',
    '$pbkdf2-sha256$29000$abcdef$abcdef1234567890abcdef1234567890abcdef',  -- dummy placeholder
    'R4', NULL, NULL, NULL, '1990-01-01'
);

-- Set correct admin password
UPDATE User
SET PasswordHash = 'scrypt:32768:8:1$Oa3dcD9H47zSH1yu$aee9015b1bba0dc6343abf36a7ab5e9ac7345cd2f219ac58fcd22bfa5be53b200c6500be2cd7bcebad7e65b4ea212b49eed423fb8b0d86fc6887d67b2c307fc0'
WHERE Username = 'admin';

-- ------------------------------------
-- Insert Example Clinics and Departments
-- ------------------------------------
INSERT INTO CLINIC (Clinic_ID, Clinic_Name) VALUES
('CL1', 'Coralville'),
('CL2', 'Iowa City');

INSERT INTO DEPARTMENT (Dept_ID, Clinic_ID, Dept_Name) VALUES
('D1', 'CL1', 'Cardiology'),
('D2', 'CL1', 'Pediatrics'),
('D3', 'CL2', 'Oncology'),
('D4', 'CL2', 'Neurology');


INSERT INTO AppointmentTypes (TypeID, TypeName, ApptDescription) VALUES
('T1', 'Annual Physical', 'General yearly checkup.'),
('T2', 'Specialist Consultation', 'Consult a specialist for specific issues.'),
('T3', 'Lab Work', 'Blood draws and lab tests.'),
('T4', 'Surgery Follow-up', 'Post-operative check-up.');

INSERT INTO TimeSlot (SlotID, DeptID, PhysicianID, StartTime, EndTime, Available) VALUES
('TS1', 'D1', 'aef25a64-2494-11f0-8d73-00ff1a756e6a', '2025-05-01 09:00:00', '2025-05-01 09:30:00', TRUE),
('TS2', 'D1', 'aef25a64-2494-11f0-8d73-00ff1a756e6a', '2025-05-01 10:00:00', '2025-05-01 10:30:00', TRUE),
('TS3', 'D2', '991c45e5-2494-11f0-8d73-00ff1a756e6a', '2025-05-02 13:00:00', '2025-05-02 13:30:00', TRUE);


CREATE TABLE IF NOT EXISTS Physician (
    PhysicianID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    PhysicianType VARCHAR(255),
    PhysicianRankID VARCHAR(50),
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (PhysicianRankID) REFERENCES PhysicianRanks(RankID)
);


