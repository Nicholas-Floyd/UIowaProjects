-- View All Lab Results for a Patient
DELIMITER //
CREATE PROCEDURE GetAllLabResults (
    IN in_PatientID INT
)
BEGIN
    SELECT *
    FROM Lab
    WHERE PatientID = in_PatientID
    ORDER BY ResultDate DESC;
END //
DELIMITER ;

-- View Detailed Lab Result by Test ID
DELIMITER //
CREATE PROCEDURE GetLabResultDetails (
    IN in_LabTestID INT
)
BEGIN
    SELECT *
    FROM Lab
    WHERE LabTestID = in_LabTestID;
END //
DELIMITER ;

-- View Lab Results Grouped by Status
DELIMITER //
CREATE PROCEDURE GetLabResultsByStatus (
    IN in_PatientID INT,
    IN in_Status VARCHAR(50)
)
BEGIN
    SELECT *
    FROM Lab
    WHERE PatientID = in_PatientID AND Status = in_Status
    ORDER BY ResultDate DESC;
END //
DELIMITER ;

