use team5project; 


-- FILL TABLES WITH DUMMY DATA TO DEMO STORED PROCEDURES:

INSERT INTO Clinic (ClinicID, ClinicName) VALUES 
('CL001', 'Sleep Clinic'),
('CL002', 'Main Hospital'),
('CL003', 'Iowa River Landing');

INSERT INTO Department (DeptID, DeptName) VALUES 
('DEPT001', 'Psychology'),
('DEPT002', 'Radiology'),
('DEPT003', 'Pediatrics'),
('DEPT004', 'General Surgery'),
('DEPT005', 'Family Medicine'),
('DEPT006', 'Obstetrics & Gynecology'),
('DEPT007', 'Billing');

INSERT INTO ClinicDepartment (ClinicID, DeptID) VALUES
('CL001', 'DEPT001'),
('CL001', 'DEPT002'),
('CL002', 'DEPT003'),
('CL003', 'DEPT004'),
('CL002', 'DEPT005'),
('CL003', 'DEPT006'),
('CL002', 'DEPT007');

-- Users (Patients)
INSERT INTO User (UserID, Username, FirstName, LastName, Email, PasswordHash, RoleID, Phone, Gender, Sex, DOB)
VALUES 
('U001', 'bailey.j', 'Bailey', 'Johnson', 'bailey.j@example.com', 'hashedpwd1', 'R1', '555-1111', 'Female', 'Female', '1990-04-12'),
('U002', 'will.s', 'Will', 'Smith', 'bob.s@example.com', 'hashedpwd2', 'R1', '555-2222', 'Female', 'Male', '1985-08-23'),
('U003', 'charlie.b', 'Charlie', 'Brown', 'charlie.b@example.com', 'hashedpwd3', 'R1', '555-3333', 'Male', 'Male', '1978-02-10'),
('U004', 'dana.n', 'Dana', 'Scarlet', 'dana.n@example.com', 'hashedpwd4', 'R1', '555-4444', 'Female', 'Female', '1992-11-04'),
('U005', 'alex.g', 'Alex', 'Red', 'alex.g@example.com', 'hashedpwd5', 'R1', '555-5555', 'Non-Binary', 'Male', '2000-01-15');

-- Patient
INSERT INTO Patient (PatientID, UserID, InsurancePlanID, PatientAddress) VALUES
('P001', 'U001', 'INS001', '123 Elm St'),
('P002', 'U002', 'INS002', '456 Oak St'),
('P003', 'U003', 'INS002', '789 Maple St'),
('P004', 'U004', 'INS003', '321 Birch St'),
('P005', 'U005', 'INS004', '654 Cedar St');

INSERT INTO InsurancePlan (InsurancePlanID, InsuranceProvider, Copay, Deductible, Coinsurance, OOPmax) VALUES 
('INS001', 'Aetna', 30.00, 200.00, 0.2000, 2000.00),
('INS002', 'BlueCross', 20.00, 750.00, 0.1500, 2500.00);

INSERT INTO InsuranceCoverage (CoverageID, InsurancePlanID, CoverageType) VALUES 
('COV001', 'INS001', 'Primary'),
('COV002', 'INS002', 'Primary');

-- Users (Physicians)
INSERT INTO User (UserID, Username, FirstName, LastName, Email, PasswordHash, RoleID, Phone, Gender, Sex, DOB)
VALUES 
('U006', 'frank.f', 'Frank', 'Fern', 'frank.f@example.com', 'hashedpwd6', 'R2', NULL, NULL, NULL, NULL),
('U007', 'violet.l', 'Violet', 'Lee', 'violet.l@example.com', 'hashedpwd7', 'R2', NULL, NULL, NULL, NULL),
('U008', 'joseph.d', 'Joseph', 'DuBois', 'joseph.d@example.com', 'hashedpwd8', 'R2', NULL, NULL, NULL, NULL),
('U009', 'lisa.f', 'Lisa', 'Frank', 'lisa.f@example.com', 'hashedpwd9', 'R2', NULL, NULL, NULL, NULL),
('U010', 'eric.e', 'Eric', 'Eric', 'eric.e@example.com', 'hashedpwd10', 'R2', NULL, NULL, NULL, NULL);

-- Physician
INSERT INTO Physician (PhysicianID, UserID, PhysicianType, PhysicianRankID) VALUES
('PH001', 'U006', 'MD', 'PR4'),
('PH002', 'U007', 'DO', 'PR1'),
('PH003', 'U008', 'MD', 'PR1'),
('PH004', 'U009', 'MD', 'PR4'),
('PH005', 'U010', 'MD', 'PR2');

-- Department Mapping
INSERT INTO PhysicianDepartment (PhysicianID, DeptID) VALUES
('PH001', 'DEPT001'),
('PH002', 'DEPT002'),
('PH003', 'DEPT003'),
('PH004', 'DEPT005'),
('PH005', 'DEPT006');

-- Specialization Mapping
INSERT INTO PhysicianSpecializations (PhysicianID, SpecializationID) VALUES
('PH001', 'SP1'),
('PH002', 'SP2'),
('PH003', 'SP1'),
('PH004', 'SP3'),
('PH005', 'SP4');

-- Users (Nurses)
INSERT INTO User (UserID, Username, FirstName, LastName, Email, PasswordHash, RoleID, Phone, Gender, Sex, DOB)
VALUES 
('U011', 'hannah.m', 'Hannah', 'Maroon', 'hannah.m@example.com', 'hashedpwd11', 'R3', NULL, NULL, NULL, NULL),
('U012', 'james.l', 'James', 'Lime', 'james.l@example.com', 'hashedpwd12', 'R3', NULL, NULL, NULL, NULL),
('U013', 'sofia.b', 'Sofia', 'Burgundy', 'sofia.b@example.com', 'hashedpwd13', 'R3', NULL, NULL, NULL, NULL);

-- Nurses
INSERT INTO Nurse (NurseID, UserID) VALUES 
('N001', 'U011'),
('N002', 'U012'),
('N003', 'U013');

-- NurseDepartment mapping
INSERT INTO NurseDepartment (NurseDeptID, NurseID, DeptID) VALUES
('ND001', 'N001', 'DEPT001'),
('ND002', 'N002', 'DEPT005'),
('ND003', 'N003', 'DEPT006');

INSERT INTO Staff (StaffID, StaffRole, DeptID) VALUES 
('ST001', 'Receptionist', 'DEPT001'),
('ST002', 'Lab Technician', 'DEPT002'),
('ST003', 'Billing Specialist', 'DEPT001'),
('ST004', 'Receptionist', 'DEPT005'),
('ST005', 'Clinical Coordinator', 'DEPT006');

INSERT INTO TimeSlot (SlotID, DeptID, PhysicianID, StartTime, EndTime, Available) VALUES 
('TS001', 'DEPT001', 'PH001', '2024-12-06 09:00:00', '2024-12-06 09:30:00', FALSE),
('TS002', 'DEPT002', 'PH003', '2024-12-07 14:00:00', '2024-12-07 14:30:00', TRUE),
('TS003', 'DEPT005', 'PH003', '2024-12-10 11:00:00', '2024-12-10 11:30:00', TRUE),
('TS004', 'DEPT006', 'PH005', '2024-12-11 13:00:00', '2024-12-11 13:30:00', TRUE);

INSERT INTO AppointmentTypes (TypeID, TypeName, ApptDescription) VALUES 
('AT001', 'Office Visit', 'Routine checkup and evaluation'),
('AT002', 'Cardiology Follow-up', 'Review heart-related symptoms and test results'),
('AT003', 'Annual Physical', 'General yearly health check-up'),
('AT004', 'Prenatal Visit', 'Checkup during pregnancy');

INSERT INTO Appointment (ApptID, PatientID, SlotID, TypeID, DeptID, ApptDate, ApptStatus, PhysicianID, CheckinStatus, SurveyCompleted) VALUES 
('APT001', 'P001', 'TS001', 'AT002', 'DEPT001', '2024-12-06 09:00:00', 'Completed', 'PH001', TRUE, TRUE),
('APT002', 'P004', 'TS003', 'AT003', 'DEPT005', '2024-12-10 11:00:00', 'Completed', 'PH004', TRUE, TRUE),
('APT003', 'P005', 'TS004', 'AT004', 'DEPT006', '2024-12-11 13:00:00', 'Scheduled', 'PH005', FALSE, FALSE);

INSERT INTO PhysicianShift (ShiftID, PhysicianID, StaffID, DeptID, ShiftStartTime, ShiftEndTime, ShiftType) VALUES 
('SH001', 'PH001', 'ST003', 'DEPT001', '2024-12-06 08:00:00', '2024-12-06 16:00:00', 'Day Shift'),
('SH002', 'PH004', 'ST004', 'DEPT005', '2024-12-10 08:00:00', '2024-12-10 16:00:00', 'Day Shift'),
('SH003', 'PH005', 'ST005', 'DEPT006', '2024-12-11 08:00:00', '2024-12-11 17:00:00', 'Day Shift');

INSERT INTO NurseShift (ShiftID, NurseID, StaffID, ShiftStartTime, ShiftEndTime, ShiftType, DeptID) VALUES 
('NSH001', 'N001', 'ST001', '2024-12-06 08:00:00', '2024-12-06 16:00:00', 'Day Shift', 'DEPT001'),
('NSH002', 'N002', 'ST004', '2024-12-10 08:00:00', '2024-12-10 16:00:00', 'Day Shift', 'DEPT005'),
('NSH003', 'N003', 'ST005', '2024-12-11 08:00:00', '2024-12-11 17:00:00', 'Day Shift', 'DEPT006');

INSERT INTO NurseShiftAppointments (NurseShiftID, ApptID, NurseID) VALUES 
('NSH001', 'APT001', 'N001'),
('NSH002', 'APT002', 'N002'),
('NSH003', 'APT003', 'N003');

INSERT INTO Pharmacy (PharmacyID, PharmacyName) VALUES 
('PHARM001', 'Wellness Pharmacy');

INSERT INTO AppointmentSurvey (SurveyID, ApptID, SurveyDate, Questions, SurveyStatus) VALUES 
('SURV001', 'APT001', '2024-12-06 12:00:00', NULL, 'Completed');

INSERT INTO Bed (BedID, PatientID, BedType, DeptID) VALUES 
('BED001', NULL, 'General', 'DEPT001'),
('BED002', NULL, 'ICU', 'DEPT005'),
('BED003', NULL, 'Maternity', 'DEPT006');













-- DEMO STORED PROCEDURES
	
    -- TRYING APPOINTMENT STORED PROCEDURES
    SELECT * FROM Appointment WHERE ApptID = 'APT006'; -- should be null 
    CALL ScheduleAppointment (
        'APT006',       -- ApptID
        'P003',         -- PatientID
        'TS003',        -- SlotID
        'AT001',        -- TypeID
        'DEPT002',      -- DeptID
        'PH002',        -- PhysicianID
        '2025-05-10 10:30:00'  -- ApptDate
    );
	SELECT * FROM Appointment WHERE ApptID = 'APT006'; 
	CALL RescheduleAppointment('APT003', 'TS002', 'PH003', 'DEPT002'); 
    SELECT * FROM Appointment WHERE ApptID = 'APT006';  
    CALL  CheckInAndSurvey('APT006', TRUE);
    SELECT * FROM Appointment WHERE ApptID = 'APT006'; -- should show CheckinStatus and SurveyCompleted as True (==1)
    CALL  CheckInAndSurvey('APT006', TRUE); -- should pop up with an error since they're already checked in 
    CALL  CheckInAndSurvey('APT005', TRUE); -- should pop up with an error since this appointment doesn't exist
    CALL CancelAppointment ('APT006');
    SELECT * FROM Appointment WHERE ApptID = 'APT006'; -- ApptID "APT006" should be "cancelled"
    CALL GetAllAvailableTimeSlots();

    
      -- CREATING NEW PHYSICIAN SHIFTS/NURSE SHIFT/PATIENTS/ETC. AND UPDATING PATIENT INFO
    SELECT * FROM Bed WHERE BedID = 'BED004'; -- should not return anything--we will make this bed
    CALL  CreateBed ('BED004', 'Burn Unit', 'DEPT005');
    SELECT * FROM Bed WHERE BedID = 'BED004'; -- the new bed should be listed here 
    CALL CreateBed('BED001', 'Burn Unit', 'DEPT005'); -- should throw an error since this bed already exists
    CALL AssignBedToPatient('BED004', 'P001');
    SELECT * FROM Bed WHERE BedID = 'BED004';
    CALL ModifyBed('BED004', 'Rehabilitation', 'DEPT005');
    SELECT * FROM Bed WHERE BedID = 'BED004';
    CALL DeleteBed('BED004'); -- Should throw an error since the bed is assigned to a patient
	SELECT * FROM Bed WHERE BedID = 'BED001';
	CALL DeleteBed('BED002'); -- should work since no patient is assigned to this bed
    SELECT * FROM BED WHERE BedID = 'BED002'; -- should return null since the bed has been deleted
  
	CALL AddPhysicianShift ('SH004', 'PH001', 'ST001', 'DEPT002', '2024-06-10 08:00:00', '2024-06-10 16:00:00', 'Day Shift'); -- should let you know the shift was added
	SELECT * FROM PhysicianShift WHERE PhysicianID = 'PH001'; -- shows all slots for physician PH001, including the one we just created
    CALL ModifyPhysicianShift ('SH004', '2024-06-10 08:00:00', '2024-06-10 16:00:00', 'On Call'); 
    CALL DeletePhysicianShift ('SH004');  
	SELECT * FROM PhysicianShift WHERE ShiftID = 'SH004'; -- should be null
    
    CALL AddNurseShift('NSH004', 'N001', 'ST001', 'DEPT001', '2024-06-10 08:00:00', '2024-06-10 16:00:00', 'Day Shift'); -- should tell you the shift was added
    SELECT * FROM NurseShift WHERE NurseID = 'N001'; -- should show this new shift 'NSH004' in addition to the other shift this nurse has
	CALL ModifyNurseShift ('NSH004', '2024-06-10 08:00:00', '2024-06-10 16:00:00', 'On Call'); 
    SELECT * FROM NurseShift WHERE NurseID = 'N001';
    CALL DeleteNurseShift ('NSH004');  
    SELECT * FROM PhysicianShift WHERE ShiftID = 'NSH004'; -- should be null



    select * from User;
    CALL AddUserProfile(
        'U014', -- UserID 
        'hazel.greene',     -- Username
        'Hazel',        -- FirstName
        'Greene',       -- LastName
        'hazel.greene@example.com', -- Email
        'abcde',        -- password hash
        'R4',           -- RoleID for Admin/Staff
        '555-6666',     -- Phone
        'Female',       -- Gender
        'Female',       -- Sex
        '1990-06-12'    -- DOB
    );
    CALL AddStaff('U014','ST006', 'Pharmacist', 'DEPT003');-- should successfully update
	CALL AddStaff('U014','ST006', 'Pharmacist', 'DEPT003'); -- error; duplicates the PK
    SELECT StaffID FROM Staff;



    CALL AddUserProfile(
        'U015', -- UserID 
        'thomas.blue', -- Username
        'Thomas',        -- FirstName
        'Blue',       -- LastName
        'thomas.blue@example.com', -- Email
        'hashedpassword123',        -- password hash
        'R3',           -- RoleID
        '540-6296',     -- Phone
        'Male',       -- Gender
        'Male',       -- Sex
        '1998-06-12'    -- DOB
    );
    CALL AddNurse('U015', 'N005', 'DEPT002');   
    SELECT NurseID FROM Nurse;
    
    CALL AddUserProfile(
        'U016', -- UserID 
        'leif.rust', -- Username
        'Lief',        -- FirstName
        'Rust',       -- LastName
        'lief.rust@example.com', -- Email
        'hashedpassword321',        -- password hash
        'R2',           -- RoleID
        '540-6396',     -- Phone
        'Male',       -- Gender
        'Male',       -- Sex
        '1998-06-12'    -- DOB
    );
    
   CALL AddPhysician(
    'U016',       -- pUserID
    'PH006',      -- pPhysicianID
    'MD',         -- pPhysicianType
    'PR2',      -- pPhysicianRankID 
    'DEPT002',    -- pDeptID 
    'SP2'       -- pSpecializationID 
); -- should successfully update
   
    SELECT PhysicianID FROM PHYSICIAN;
    CALL GetRoster();
    CALL GetPhysicianAvailability('PH003');
    CALL  GetAllAvailableTimeSlots();
   
   CALL AddUserProfile(
        'U017', -- UserID 
        'bailey.black', -- Username
        'Bailey',        -- FirstName
        'Black',       -- LastName
        'bailey.black@example.com', -- Email
        'hashedpassword321',        -- password hash
        'R1',           -- RoleID
        '540-6396',     -- Phone
        'Female',       -- Gender
        'Female',       -- Sex
        '1990-04-03'    -- DOB
    );
   CALL AddOrUpdatePatientProfile('P007', 'U017', 'INS001');
   SELECT * FROM Patient; -- should see new ID 'P007'
    CALL updatePatientAddress ('P007', '221 Bunny St');
    SELECT PatientAddress FROM PATIENT WHERE PatientID = 'P007'; -- should show new address change
    CALL UpdatePatientInsurance('P007', 'INS002');
    SELECT InsurancePlanID FROM PATIENT WHERE PatientID = 'P007'; -- should show updated insuranceplanid



    
    -- APPOINTMENT PROCESS FROM SOAP TO BILLING AND PAYMENT
	CALL AssignBedToPatient('BED003', 'P007'); 
	SELECT * FROM Bed; -- should see the update
    CALL AssignBedToPatient('BED003', 'P007'); -- shouldn't work since bed is already occupied
	CALL insertSOAPsummary('SUM004', 'PH003', 'P007', False);
	SELECT * FROM AfterVisitSummary WHERE SummaryID = 'SUM004'; -- should show new After-Visit-Summary info
    CALL AddSubjectiveData('SUBJ004', 'SUM004', 'Pregnancy follow-up', '10 weeks pregnant. Reports mild nausea and fatigue, no alarming symptoms.');
    CALL AddObjectiveData ('SUM004', 'OBJ004'); -- should tell you objective data has been inserted
    CALL AddObjectiveData ('SUM004', 'OBJ004'); -- shouldn't work; duplicate objective data
	CALL AddVitals('VIT001', 'OBJ004', '2024-12-06 09:10:00', '120/80', 72, 98.6);
    CALL AddVitals('VIT002', 'OBJ004', '2024-12-06 09:10:00', '120/80', 72, 98.6); -- should work; there can be many vitals per objective data
    SELECT * FROM ObjectiveData;
    SELECT * FROM Vitals;
	CALL AddAssessment ('A004', 'SUM004', 'Healthy pregnancy, mild first trimester symptoms');
    CALL AddPlan('PL004', 'SUM004', '2024-12-11 14:40:00', TRUE, 'Active', 'Continue prenatal care, schedule ultrasound at 12 weeks');
	CALL CreateLabOrder('ORD004', 'PL004', 'Imaging', 'ultrasound', '2024-12-18 09:30:00', 'Pending');
	CALL EnterLabResult('LAB004', 'OBJ004', 'hCG Quant', NULL, 'mIU/mL', '2024-12-11 13:30:00', 'ORD004', 'ST002');
	CALL PrescribeMedication (
        'RX004', 
        'Prenatal Vitamin', 
        1, 
        30, 
        '2024-12-11', 
        '2025-01-11', 
        TRUE, 
        'PHARM001', 
        'P007', 
        'PL004', 
        'PH003', 
        'Once Daily'
    );
    SELECT * FROM Prescription WHERE PatientID = 'P007';
    SELECT * FROM Medication WHERE PrescriptionID = 'RX004';
    CALL DischargePatient('P007');
    SELECT * FROM Bed WHERE PatientID = 'P007'; -- should be null since patient was discharged
    SET SQL_SAFE_UPDATES = 0;
    CALL MakeSOAPVisibleToPatient ('SUM004', 'P007');
    SELECT * FROM AfterVisitSummary WHERE PatientID = 'P007'; -- should show VisibleToPatient as True (= 1)
	CALL InsertServiceBreakdown(
		'SB004',          -- ServiceBreakdownID
		'ST003',          -- StaffID 
		'DEPT006',         -- DeptID 
		'Prenatal Consultation and Lab Order',  -- ServiceDescription
		'2024-12-11 14:45:00',                  -- ServiceDate 
		150.00,                                 -- ServiceCost 
		'Routine follow-up visit with ultrasound lab order'  -- Notes
	);	
    
    
    
  

    
    SELECT * FROM ServiceBreakdown WHERE ServiceBreakdownID = 'SB004';
	CALL createInvoice(
		'INV004',        -- InvoiceID (used in bill)
		'P007',          -- PatientID
		'ST003',         -- StaffID 
		'2025-01-11'     -- DueDate
	);
    
    SELECT * FROM Invoice WHERE PatientID = 'P007'; -- empty; no charge, payments, or balance due
    CALL createBill(
		'BILL001',       -- BillID
		'P007',          -- PatientID
		'SB004',        -- ServiceBreakdownID 
        'INV004',		-- InvoiceID
		'2025-01-11'     -- DueDate
	);	
   SELECT * FROM Bill WHERE PatientID = 'P007'; -- patientresponsibility is less than Aetna's deductible, so this shows that the patient responsibility caps at totalcharge
    CALL InsertServiceBreakdown(
		'SB005',          -- ServiceBreakdownID
		'ST003',          -- StaffID 
		'DEPT006',         -- DeptID (assuming OB/GYN dept; use actual dept ID)
		'Prenatal Consultation and Lab Order',  -- ServiceDescription
		'2024-12-11 14:45:00',                  -- ServiceDate (same as plan date)
		1000.00,                                 -- ServiceCost (example value)
		'Routine follow-up visit with ultrasound lab order'  -- Notes
	);	
  
  CALL createBill(
		'BILL002',       -- BillID
		'P007',          -- PatientID
		'SB005',        -- ServiceBreakdownID 
        'INV004',		-- InvoiceID
		'2025-01-11'     -- DueDate
	);	
    SELECT * FROM Bill WHERE BillID = 'BILL002';   -- here the deductible was less than the totalcharge, so we see how the math plays out for patientresponsibility, insurancepayment, and balancedue
    SELECT * FROM Invoice WHERE PatientID = 'P007'; -- shows how calling the createbill stored procedure also updates the invoice
    CALL CreateClaim(
		'CL004',                 -- ClaimID
		'P007',                  -- PatientID
		'COV001',                -- InsuranceCoverageID 
		'2024-12-11 15:00:00'   -- ClaimCreationDate
	);
    SELECT * FROM Claim WHERE PatientID = 'P007';
    CALL MakeInsurancePayment(
    'PAY005',           -- PaymentID
    'INS001',           -- InsurancePlanID 
    'P007',             -- PatientID
    'BILL002',          -- BillID
    'CL004',            -- ClaimID
    100.00,             -- Amount 
    '2024-12-12',       -- PaymentDate
    'INSPAY004'         
	); 
    SELECT * FROM InsurancePaymentRelationship;
    CALL MakePatientPayment(
		'PAY006',         -- PaymentID
		'P007',           -- PatientID
		'BILL001',        -- BillID 
		'CL003',          -- ClaimID 
		150.00,            -- Amount 
		'2024-12-12'     -- PaymentDate
	);
    
    -- all different ways to see what payments have been made where: 
    SELECT * FROM Payment WHERE PatientID = 'P007';
    CALL PatientOutstandingBills('P007');
    SELECT * FROM Bill; -- PaymentStatus on bill BILL001 should say "Paid" now
    SELECT * FROM Invoice;
	CALL ViewInsurancePayments('P007');
    CALL ViewPatientPayments('P007');
   
   -- View bills and invoices for a patient
   CALL BillRetrieval('P007');
   CALL InvoiceRetrieval('P007');