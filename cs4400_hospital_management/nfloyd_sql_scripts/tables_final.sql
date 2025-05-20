-- create database team5project;
Drop database team5project;
CREATE DATABASE IF NOT EXISTS team5project;
USE team5project;

-- SELECT * FROM Patient;


-- SELECT * FROM Physician;

-- SELECT * FROM ClinicDepartment;
-- CALL GetAllClinics();

/*-- ---------
-- Drop in clean order (if rebuilding)
 DROP TABLE IF EXISTS PhysicianSpecializations;
 DROP TABLE IF EXISTS PhysicianDepartment;
 DROP TABLE IF EXISTS Physician;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Clinic;
DROP TABLE IF EXISTS Roles;
DROP TABLE IF EXISTS Specializations;
DROP TABLE IF EXISTS PhysicianRanks;
DROP TABLE IF EXISTS NurseDepartment;
DROP TABLE IF EXISTS NurseSpecializations;
DROP TABLE IF EXISTS Nurse;
DROP TABLE IF EXISTS Admin;
DROP TABLE IF EXISTS TimeSlot;
DROP TABLE IF EXISTS AppointmentTypes;
DROP TABLE IF EXISTS Appointment;
DROP TABLE IF EXISTS User;
-- -------*/
-- Clinic table
CREATE TABLE Clinic (
    ClinicID VARCHAR(255) PRIMARY KEY,
    ClinicName VARCHAR(255)
);

CREATE TABLE Department (
    DeptID VARCHAR(255) PRIMARY KEY,
    DeptName VARCHAR(255)
);

CREATE TABLE ClinicDepartment (
    ClinicID VARCHAR(255),
    DeptID VARCHAR(255),
    PRIMARY KEY (ClinicID, DeptID),
    FOREIGN KEY (ClinicID) REFERENCES Clinic(ClinicID),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);


-- Roles table
CREATE TABLE IF NOT EXISTS Roles (
    RoleID VARCHAR(50) PRIMARY KEY,
    RoleName VARCHAR(50) UNIQUE NOT NULL
);

-- Insert base roles
INSERT INTO Roles (RoleID, RoleName) VALUES
('R1', 'Patient'),
('R2', 'Physician'),
('R3', 'Nurse'),
('R4', 'Admin');

-- Specializations table
CREATE TABLE IF NOT EXISTS Specializations (
    SpecializationID VARCHAR(50) PRIMARY KEY,
    Specialization VARCHAR(255) NOT NULL
);

-- Insert base specializations
INSERT INTO Specializations (SpecializationID, Specialization) VALUES
('SP1', 'Cardiology'),
('SP2', 'Radiology'),
('SP3', 'Pediatrics'),
('SP4', 'General Surgery');

-- Physician Ranks table
CREATE TABLE IF NOT EXISTS PhysicianRanks (
    RankID VARCHAR(50) PRIMARY KEY,
    RankName VARCHAR(100) UNIQUE NOT NULL
);

-- Insert base physician ranks
INSERT INTO PhysicianRanks (RankID, RankName) VALUES
('PR1', 'Resident'),
('PR2', 'Attending'),
('PR3', 'Fellow'),
('PR4', 'Staff Physician'),
('PR5', 'Chief');

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

-- Patient table (updated with PatientAddress + InsurancePlanID)
CREATE TABLE IF NOT EXISTS Patient (
    PatientID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    InsurancePlanID VARCHAR(50),
    PatientAddress VARCHAR(100),
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

-- Physician table
CREATE TABLE IF NOT EXISTS Physician (
    PhysicianID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    PhysicianType VARCHAR(255),
    PhysicianRankID VARCHAR(50),
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (PhysicianRankID) REFERENCES PhysicianRanks(RankID)
);

-- PhysicianDepartment linking table
CREATE TABLE IF NOT EXISTS PhysicianDepartment (
    PhysicianID VARCHAR(50),
    DeptID VARCHAR(50),
    PRIMARY KEY (PhysicianID, DeptID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID) ON DELETE CASCADE,
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID) ON DELETE CASCADE
);

-- PhysicianSpecializations linking table
CREATE TABLE IF NOT EXISTS PhysicianSpecializations (
    PhysicianID VARCHAR(50),
    SpecializationID VARCHAR(50),
    PRIMARY KEY (PhysicianID, SpecializationID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (SpecializationID) REFERENCES Specializations(SpecializationID)
);

-- Nurse table
CREATE TABLE IF NOT EXISTS Nurse (
    NurseID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

-- Admin table
CREATE TABLE IF NOT EXISTS Admin (
    AdminID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) UNIQUE,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

-- TimeSlot table
CREATE TABLE IF NOT EXISTS TimeSlot (
    SlotID VARCHAR(50) PRIMARY KEY,
    DeptID VARCHAR(50),
    PhysicianID VARCHAR(50),
    StartTime DATETIME,
    EndTime DATETIME,
    Available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID)
);

-- AppointmentTypes table
CREATE TABLE IF NOT EXISTS AppointmentTypes (
    TypeID VARCHAR(50) PRIMARY KEY,
    TypeName VARCHAR(255),
    ApptDescription VARCHAR(255)
);

-- Appointment table
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
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- NurseDepartment linking table
CREATE TABLE IF NOT EXISTS NurseDepartment (
    NurseDeptID VARCHAR(50) PRIMARY KEY,
    NurseID VARCHAR(50),
    DeptID VARCHAR(50),
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- NurseSpecializations linking table
CREATE TABLE IF NOT EXISTS NurseSpecializations (
    NurseID VARCHAR(50),
    SpecializationID VARCHAR(50),
    PRIMARY KEY (NurseID, SpecializationID),
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID),
    FOREIGN KEY (SpecializationID) REFERENCES Specializations(SpecializationID)
);

CREATE TABLE SecurityQuestions (
    QuestionID VARCHAR(50) PRIMARY KEY,
    QuestionText VARCHAR(255) NOT NULL
);

CREATE TABLE UserSecurityAnswers (
    UserID VARCHAR(50),
    QuestionID VARCHAR(50),
    AnswerHash VARCHAR(255),  -- store securely, not plaintext!
    PRIMARY KEY (UserID, QuestionID),
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (QuestionID) REFERENCES SecurityQuestions(QuestionID)
);

INSERT INTO SecurityQuestions (QuestionID, QuestionText) VALUES
    ('Q1', 'What was the name of your first pet?'),
    ('Q2', 'What is your mother’s maiden name?'),
    ('Q3', 'What was the make of your first car?'),
    ('Q4', 'What city were you born in?'),
    ('Q5', 'What is your favorite food?'),
    ('Q6', 'What is the name of your elementary school?'),
    ('Q7', 'What is your favorite book?'),
    ('Q8', 'Who was your childhood best friend?'),
    ('Q9', 'What was the name of your first employer?'),
    ('Q10', 'What is the middle name of your oldest sibling?');


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



- ------------------------------------
-- INSURANCE & PAYMENT TABLES
-- ------------------------------------
CREATE TABLE IF NOT EXISTS InsurancePlan (
    InsurancePlanID VARCHAR(255) PRIMARY KEY,
    InsuranceProvIDer VARCHAR(255),
    Copay NUMERIC,
    Deductible NUMERIC,
    Coinsurance DECIMAL(5, 4),
    OOPmax NUMERIC
);

CREATE TABLE IF NOT EXISTS InsuranceCoverage (
    CoverageID VARCHAR(255) PRIMARY KEY,
    InsurancePlanID VARCHAR(255),
    CoverageType ENUM('Primary', 'Secondary'), 
    FOREIGN KEY (InsurancePlanID) REFERENCES InsurancePlan(InsurancePlanID)
);

CREATE TABLE IF NOT EXISTS Claim (
    ClaimID VARCHAR(255) PRIMARY KEY,
    BillID VARCHAR(255),
    PatientID VARCHAR(255),
    InsuranceCoverageID VARCHAR(255),
    ClaimCreationDate DATETIME,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (InsuranceCoverageID) REFERENCES InsuranceCoverage(CoverageID)
);














- ------------------------------------
-- PEOPLE TABLES
-- ------------------------------------

CREATE TABLE IF NOT EXISTS Staff(
    StaffID VARCHAR(255) PRIMARY KEY,
    StaffRole ENUM("Secretary", "Pharmacist", "Lab Technician", "Clinical Coordinator", "Administrative Assistant", "Billing Specialist"
    , "Social Worker", "Receptionist"),
    DeptID VARCHAR(255),
    UserID VARCHAR(50),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);
    
-- overall financial charge for a patient's care. multiple bills can be in a single invoice
CREATE TABLE IF NOT EXISTS Invoice (
    InvoiceID VARCHAR(255) PRIMARY KEY,
    PatientID VARCHAR(255),
    StaffID VARCHAR(255), -- who created the invoice?
    GrossCharge NUMERIC,
    TotalPayments NUMERIC,
    BalanceDue NUMERIC,
    DueDate DATETIME,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID)
);
CREATE TABLE IF NOT EXISTS ServiceBreakdown (
	ServiceBreakdownID VARCHAR(255) PRIMARY KEY, 
    StaffID VARCHAR(255), -- staff member making the service breakdown; billing specialist
    DeptID VARCHAR(255), 
    ServiceDescription VARCHAR(255), 
    ServiceDate DATETIME, 
    ServiceCost NUMERIC, -- before insurance payment
    Notes VARCHAR(255), 
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID), 
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);


-- indivIDual charges for a specific service provIDed to the patient
CREATE TABLE IF NOT EXISTS Bill (
    BillID VARCHAR(255) PRIMARY KEY,
    PatientID VARCHAR(255),
    InvoiceID VARCHAR(255),
    TotalCharge NUMERIC,
    DueDate DATETIME,
    PatientResponsibility NUMERIC,
    InsurancePayment NUMERIC,
    BalanceDue NUMERIC,
    PaymentStatus ENUM("PaID", "Pending", "Cancelled"), 
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (InvoiceID) REFERENCES Invoice(InvoiceID)
);


CREATE TABLE IF NOT EXISTS BillServiceDetail (
    BillID VARCHAR(255),
    ServiceBreakdownID VARCHAR(255),
    PRIMARY KEY (BillID, ServiceBreakdownID),
    FOREIGN KEY (BillID) REFERENCES Bill(BillID),
    FOREIGN KEY (ServiceBreakdownID) REFERENCES ServiceBreakdown(ServiceBreakdownID)
);

-- payment table is used whether by insurance or patient
CREATE TABLE IF NOT EXISTS Payment (
    PaymentID VARCHAR(255) PRIMARY KEY,
    PatientID VARCHAR(255),
    BillID VARCHAR(255),
    PaymentAmount NUMERIC,
    PaymentDate DATE,
    Payer ENUM("Patient", "Insurance"), 
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (BillID) REFERENCES Bill(BillID)
);

CREATE TABLE IF NOT EXISTS InsurancePaymentRelationship (
    InsurancePaymentID VARCHAR(255) PRIMARY KEY,
    InsurancePlanID VARCHAR(255),
    BillID VARCHAR(255),
    PaymentID VARCHAR(255),
    PaymentAmount NUMERIC,
    FOREIGN KEY (InsurancePlanID) REFERENCES InsurancePlan(InsurancePlanID),
    FOREIGN KEY (BillID) REFERENCES Bill(BillID),
    FOREIGN KEY (PaymentID) REFERENCES Payment(PaymentID)
);


CREATE TABLE IF NOT EXISTS PhysicianPatientRelationships (
    ApptID VARCHAR(255),
    PhysicianID VARCHAR(255),
    PatientID VARCHAR(255),
    RelationshipType VARCHAR(255), -- PCP, Specialist, etc.
    PRIMARY KEY (ApptID, PhysicianID, PatientID),
    FOREIGN KEY (ApptID) REFERENCES Appointment(ApptID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);









- ------------------------------------
-- SCHEDULING TABLES
-- ------------------------------------

CREATE TABLE IF NOT EXISTS PhysicianShift (
    ShiftID VARCHAR(255) PRIMARY KEY,
    PhysicianID VARCHAR(255),
    StaffID VARCHAR(255),
    DeptID VARCHAR(255),
    ShiftStartTime DATETIME,
    ShiftEndTime DATETIME,
    ShiftType ENUM("Day Shift", "Night Shift", "Evening Shift", "On Call", "Swing Shift", "Split Shift"),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

CREATE TABLE IF NOT EXISTS NurseShift (
    ShiftID VARCHAR(255) PRIMARY KEY,
    NurseID VARCHAR(255),
    StaffID VARCHAR(255),
    ShiftStartTime DATETIME,
    ShiftEndTime DATETIME,
    ShiftType ENUM("Day Shift", "Night Shift", "Evening Shift", "On Call", "Swing Shift", "Split Shift"),
    DeptID VARCHAR(255), 
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID),
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID) 
);


CREATE TABLE IF NOT EXISTS NurseShiftAppointments (
    NurseShiftID VARCHAR(255),
    ApptID VARCHAR(255),
    NurseID VARCHAR(255),
    PRIMARY KEY (NurseShiftID, ApptID, NurseID),
    FOREIGN KEY (NurseShiftID) REFERENCES NurseShift(ShiftID),
    FOREIGN KEY (ApptID) REFERENCES Appointment(ApptID),
    FOREIGN KEY (NurseID) REFERENCES Nurse(NurseID)
);









- ------------------------------------
---- APPOINTMENT PROCESS TABLES
-- ------------------------------------

CREATE TABLE IF NOT EXISTS Bed (
    BedID VARCHAR(255) PRIMARY KEY,
    PatientID VARCHAR(255),
    BedType ENUM("General", "ICU", "CCU", "Pediatric", "Maternity", "Surgical", "Trauma", "Birthing", "Psychiatric", "Geriatric", 
    "Transport", "Step-Down", "Rehabilitation", "Isolation", "Burn Unit"), 
    DeptID VARCHAR(255),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- also the SOAP document
CREATE TABLE IF NOT EXISTS AfterVisitSummary (
    SummaryID VARCHAR(255) PRIMARY KEY,
    PhysicianID VARCHAR(255),
    PatientID VARCHAR(255),
    VisibleToPatient BOOLEAN DEFAULT FALSE,
    Created DATETIME,
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

CREATE TABLE IF NOT EXISTS SubjectiveData (
    SubjectiveDataID VARCHAR(255) PRIMARY KEY,
    SummaryID VARCHAR(255),
    CC VARCHAR(255),  -- Chief Complaint
    HPI VARCHAR(255), -- History of Present Illness
    FOREIGN KEY (SummaryID) REFERENCES AfterVisitSummary(SummaryID)
);

CREATE TABLE IF NOT EXISTS ObjectiveData (
    ObjectiveDataID VARCHAR(255) PRIMARY KEY,
    SummaryID VARCHAR(255),
    FOREIGN KEY (SummaryID) REFERENCES AfterVisitSummary(SummaryID)
);

CREATE TABLE IF NOT EXISTS Vitals (
    VitalsID VARCHAR(255) PRIMARY KEY,
    ObjectiveDataID VARCHAR(255),
    VitalsDate DATETIME,
    BloodPressure VARCHAR(20),
    HeartRate NUMERIC,
    Temp NUMERIC(5, 3),
    FOREIGN KEY (ObjectiveDataID) REFERENCES ObjectiveData(ObjectiveDataID)
);


CREATE TABLE IF NOT EXISTS Assessment (
    AssessmentID VARCHAR(255) PRIMARY KEY,
    SummaryID VARCHAR(255),
    Assessment VARCHAR(255),
    FOREIGN KEY (SummaryID) REFERENCES AfterVisitSummary(SummaryID)
);

CREATE TABLE IF NOT EXISTS Plan (
    PlanID VARCHAR(255) PRIMARY KEY,
    SummaryID VARCHAR(255),
    CreatedDate DATETIME,
    FollowUp BOOLEAN,
    PlanStatus ENUM("Active", "Completed"),
    Notes VARCHAR(255),
    FOREIGN KEY (SummaryID) REFERENCES AfterVisitSummary(SummaryID)
    );
    
CREATE TABLE IF NOT EXISTS Pharmacy (
    PharmacyID VARCHAR(255) PRIMARY KEY,
    PharmacyName VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Prescription (
    PrescriptionID VARCHAR(255) PRIMARY KEY,
    DateOfIssue DATETIME, 
    DeliveryMethod VARCHAR(50),
    Refill BOOLEAN,
    PharmacyID VARCHAR(255),
    PatientID VARCHAR(255),
    PlanID VARCHAR(255),
    PhysicianID VARCHAR(255),
    PrescriptionStatus VARCHAR(50) DEFAULT "Pending",
    FOREIGN KEY (PharmacyID) REFERENCES Pharmacy(PharmacyID),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (PlanID) REFERENCES Plan(PlanID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID)
);

CREATE TABLE IF NOT EXISTS Medication (
    PrescriptionMedID VARCHAR(255) PRIMARY KEY, 
    PrescriptionID VARCHAR(255),
    MedicationName VARCHAR (50), 
    MedicationStrength VARCHAR(50), 
    Quantity VARCHAR(50),
    StartDate DATETIME,
    EndDate DATETIME, 
    DirectionsForUse VARCHAR(255),
    FOREIGN KEY (PrescriptionID) REFERENCES Prescription(PrescriptionID)
);

CREATE TABLE IF NOT EXISTS Orders (
    OrderID VARCHAR(255) PRIMARY KEY,
    PlanID VARCHAR(255),
    Results VARCHAR(255),
    OrderType VARCHAR(255),       -- Lab/Radiology/etc.
    Details VARCHAR(255),    -- Blood Test/MRI/etc.
    DateScheduled DATETIME,
    DateDone DATETIME,
    OrderStatus ENUM("Pending", "Completed", "Cancelled") DEFAULT 'Pending',
    FOREIGN KEY (PlanID) REFERENCES Plan(PlanID)
);

CREATE TABLE IF NOT EXISTS AppointmentSurvey (
    SurveyID VARCHAR(255) PRIMARY KEY,
    ApptID VARCHAR(255),
    SurveyDate DATETIME,
    Questions JSON, 
    SurveyStatus ENUM("Completed", "Pending", "Not required"),
    FOREIGN KEY (ApptID) REFERENCES Appointment(ApptID)
);

CREATE TABLE IF NOT EXISTS Lab (
    LabID VARCHAR(255) PRIMARY KEY,
    OrderID VARCHAR(255),
    ObjectiveDataID VARCHAR(255),
    StaffID VARCHAR(255),
    TestName VARCHAR(255), -- like "Hemoglobin"
    ResultDate DATETIME, 
    ResultValue NUMERIC, 
    Units VARCHAR(50), -- like "mg/dL"
    ResultInterpretation VARCHAR(255),
    LabStatus ENUM("Pending", "Completed", "Cancelled") DEFAULT "Pending",
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ObjectiveDataID) REFERENCES ObjectiveData(ObjectiveDataID),
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID)
);


-- ------------------------------------
-- NOTIFICATIONS TABLES
-- ------------------------------------

CREATE TABLE IF NOT EXISTS NotificationStatus (
    StatusID INT PRIMARY KEY AUTO_INCREMENT,
    StatusName VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS NotificationPriority (
    PriorityID INT PRIMARY KEY AUTO_INCREMENT,
    PriorityName VARCHAR(50) UNIQUE NOT NULL
);
    
CREATE TABLE IF NOT EXISTS Notification (
    NotificationID VARCHAR(255) PRIMARY KEY,
    UserID VARCHAR(50),
    MessageContent VARCHAR(500),
    DateCreated DATETIME,
    StatusID INT,
    PriorityID INT,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (StatusID) REFERENCES NotificationStatus(StatusID),
    FOREIGN KEY (PriorityID) REFERENCES NotificationPriority(PriorityID)

INSERT INTO AppointmentTypes (TypeID, TypeName, ApptDescription) VALUES
('T1', 'Annual Physical', 'General yearly checkup.'),
('T2', 'Specialist Consultation', 'Consult a specialist for specific issues.'),
('T3', 'Lab Work', 'Blood draws and lab tests.'),
('T4', 'Surgery Follow-up', 'Post-operative check-up.');