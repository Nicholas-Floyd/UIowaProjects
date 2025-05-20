-- Insert sample Persons
INSERT INTO Person (FirstName, LastName, Address, Phone)
VALUES 
('John', 'Doe', '123 Main St, Springfield, IL 62704', '555-1234'),
('Emily', 'Carter', '456 Healthway Blvd, Springfield, IL 62704', '555-5678');

-- Insert sample Patients (assume Emily is a physician, John is a patient)
INSERT INTO Patient (PersonID, InsuranceID)
VALUES (1, NULL);  -- Link to John

-- Insert sample Physicians
INSERT INTO Physician (PersonID)
VALUES (2);  -- Link to Emily

-- Insert sample Insurance (assign to patient)
INSERT INTO Insurance (PatientID, ProviderName, PolicyNumber)
VALUES (1, 'Blue Cross Blue Shield', 'BCBS123456');

-- Update Patient with InsuranceID after insurance is created
UPDATE Patient SET InsuranceID = 1 WHERE PatientID = 1;

-- Insert sample Pharmacy
INSERT INTO Pharmacy (Name, Address, Phone)
VALUES ('Springfield Pharmacy', '789 Med Plaza, Springfield, IL 62704', '555-9012');

-- Insert sample Prescription
INSERT INTO Prescription (
    PatientID, PhysicianID, PharmacyID, InsuranceID,
    MedicationName, MedicationStrength, DosageForm,
    QuantityPrescribed, DirectionsForUse, NumberOfRefills,
    PaymentMethod, DeliveryMethod, DateOfIssue
)
VALUES (
    1, 1, 1, 1,
    'Amoxicillin', '500mg', 'Capsule',
    30, 'Take 1 capsule three times daily', 1,
    'Insurance', 'Pickup', '2025-04-20'
);

-- Insert sample Payment
INSERT INTO Payment (PatientID, PrescriptionID, Method, Amount)
VALUES (1, 1, 'Insurance', 0.00);

-- Insert sample Delivery
INSERT INTO Delivery (PrescriptionID, Method)
VALUES (1, 'Pickup');

-- Insert sample Lab test
INSERT INTO Lab (
    PatientID, PhysicianID, InsuranceID,
    TestName, Status
)
VALUES (
    1, 1, 1,
    'CBC Blood Test', 'Pending'
);

-- Insert sample Notification
INSERT INTO Notification (PatientID, MessageContent, DateCreated, Status, Priority)
VALUES (
    1, 'Your prescription has been filled.', NOW(), 'Unread', 'Normal'
);
