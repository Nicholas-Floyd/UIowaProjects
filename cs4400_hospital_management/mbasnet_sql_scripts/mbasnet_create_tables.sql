-- PERSON table
CREATE TABLE Person (
    PersonID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Address VARCHAR(255),
    Phone VARCHAR(15)
);

-- PATIENT table
CREATE TABLE Patient (
    PatientID INT PRIMARY KEY AUTO_INCREMENT,
    PersonID INT, 
    InsuranceID INT,
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    FOREIGN KEY (InsuranceID) REFERENCES Insurance(InsuranceID)
);

-- INSURANCE table
CREATE TABLE Insurance (
    InsuranceID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT,
    ProviderName VARCHAR(100),
    PolicyNumber VARCHAR(50),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

-- PHARMACY table
CREATE TABLE Pharmacy (
    PharmacyID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100),
    Address VARCHAR(255),
    Phone VARCHAR(15)
);

-- PRESCRIPTION table
CREATE TABLE Prescription (
    PrescriptionID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT,
    PhysicianID INT,
    PharmacyID INT,
    InsuranceID INT,
    MedicationName VARCHAR(100),
    MedicationStrength VARCHAR(50),
    DosageForm VARCHAR(50),
    QuantityPrescribed INT,
    NumberOfRefills INT,
    PaymentMethod VARCHAR(50),
    DeliveryMethod VARCHAR(50),
    DateOfIssue DATE,
    Status VARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (PhysicianID) REFERENCES Insurance(InsuranceID)
    FOREIGN KEY (PharmacyID) REFERENCES Pharmacy(PharmacyID)
);

-- PAYMENT table
CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT,
    PrescriptionID INT,
    Method VARCHAR(50),
    Amount DECIMAL(10, 2),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (PrescriptionID) REFERENCES Prescription(PrescriptionID)
);

-- DELIVERY table
CREATE TABLE Delivery (
    DeliveryID INT PRIMARY KEY AUTO_INCREMENT,
    PrescriptionID INT,
    Method VARCHAR(50),
    FOREIGN KEY (PrescriptionID) REFERENCES Prescription(PrescriptionID)
);

-- LAB table
CREATE TABLE Lab (
    LabTestID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT,
    PhysicianID INT,
    InsuranceID INT,
    TestName VARCHAR(100),
    Status VARCHAR(50),
    ResultDate DATE,
    ResultValue VARCHAR(100),
    Units VARCHAR(20),
    ResultInterpretation VARCHAR(100),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (PhysicianID) REFERENCES Physician(PhysicianID),
    FOREIGN KEY (InsuranceID) REFERENCES Insurance(InsuranceID)
);

-- NOTIFICATION table
CREATE TABLE Notification (
    NotificationID INT PRIMARY KEY AUTO_INCREMENT,
    PatientID INT,
    MessageContent TEXT,
    DateCreated DATETIME,
    Status VARCHAR(50),
    Priority VARCHAR(50),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);