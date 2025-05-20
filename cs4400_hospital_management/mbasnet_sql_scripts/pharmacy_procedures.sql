-- Add a New Prescription
DELIMITER //
CREATE PROCEDURE AddPrescription (
    IN in_PatientID INT,
    IN in_PhysicianID INT,
    IN in_PharmacyID INT,
    IN in_InsuranceID INT,
    IN in_MedicationName VARCHAR(100),
    IN in_MedicationStrength VARCHAR(50),
    IN in_DosageForm VARCHAR(50),
    IN in_QuantityPrescribed INT,
    IN in_DirectionsForUse TEXT,
    IN in_NumberOfRefills INT,
    IN in_PaymentMethod VARCHAR(50),
    IN in_DeliveryMethod VARCHAR(50),
    IN in_DateOfIssue DATE
)
BEGIN
    INSERT INTO Prescription (
        PatientID, PhysicianID, PharmacyID, InsuranceID,
        MedicationName, MedicationStrength, DosageForm,
        QuantityPrescribed, DirectionsForUse, NumberOfRefills,
        PaymentMethod, DeliveryMethod, DateOfIssue 
    ) VALUES (
        in_PatientID, in_PhysicianID, in_PharmacyID, in_InsuranceID,
        in_MedicationName, in_MedicationStrength, in_DosageForm,
        in_QuantityPrescribed, in_DirectionsForUse, in_NumberOfRefills,
        in_PaymentMethod, in_DeliveryMethod, in_DateOfIssue
    );
END //
DELIMITER ;

-- Update Prescription Status
DELIMITER //
CREATE PROCEDURE UpdatePrescriptionStatus (
    IN in_PrescriptionID INT,
    IN in_Status VARCHAR(50)
)
BEGIN
    UPDATE Prescription
    SET Status = in_Status
    WHERE PrescriptionID = in_PrescriptionID;
END //
DELIMITER ;

-- View All Prescription for a Patient (sorted by date)
DELIMITER //
CREATE PROCEDURE GetPrescriptionsByPatient (
    IN in_PatientID INT
)
BEGIN
    SELECT *
    FROM Prescription
    WHERE PatientID = in_PatientID
    ORDER BY DateOfIssue DESC;
END //
DELIMITER ;

-- Record a Payment
DELIMITER // CREATE PROCEDURE RecordPayment (
    IN in_PatientID INT,
    IN in_PrescriptionID INT,
    IN in_Method VARCHAR(50),
    IN in_Amount DECIMAL(10, 2)
)
BEGIN
    INSERT INTO Payment (Patient ID, PrescriptionID, Method, Amount)
    VALUES (in_PatientID, in_PrescriptionID, in_Method, in_Amount);
END //
DELIMITER ;

-- Update Payment Method or Amount
DELIMITER //
CREATE PROCEDURE UpdatePayment (
    IN in_PaymentID INT,
    IN in_Method VARCHAR(50),
    IN in_Amount DECIMAL(10, 2)
)
BEGIN
    UPDATE Payment
    SET Method = in_Method,
        Amount = in_Amount
    WHERE PaymentID = in_PaymentID;
END //
DELIMITER ;

-- Get Total Amount Paid by a Patient
DELIMITER //
CREATE PROCEDURE GetTotalPaidByClient (
    IN in_PatientID INT
)
BEGIN
    SELECT SUM(Amount) AS TotalPaid
    FROM Payment
    WHERE PatientID = in_PatientID;
END //
DELIMITER ;

-- Change Delivery Method
DELIMITER //
CREATE PROCEDURE UpdateDeliveryMethod (
    IN in_DeliveryID INT,
    IN in_Method VARCHAR(50)
)
BEGIN
    UPDATE Delivery
    SET Method = in_Method
    WHERE DeliveryID = in_DeliveryID;
END //
DELIMITER ;

-- List Prescriptions Scheduled for Delivery
DELIMITER //
CREATE PROCEDURE GetPrescriptionsForDelivery ()
BEGIN
    SELECT p.*
    FROM Prescription p 
    JOIN Delivery d ON p.PrescriptionID = d.PrescriptionID
    WHERE d.Method = 'Delivery';
END //
DELIMITER ;