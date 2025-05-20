USE team5project;

DROP PROCEDURE IF EXISTS CompletePhysicianProfile;
DROP PROCEDURE IF EXISTS AddUserProfile;
DROP PROCEDURE IF EXISTS VerifyUserLogin;
DROP PROCEDURE IF EXISTS CheckUsernameExists;
DROP PROCEDURE IF EXISTS ChangeUserPassword;
DROP PROCEDURE IF EXISTS GetAvailableSlotsByPhysician;
DROP PROCEDURE IF EXISTS GetPhysiciansByDepartment;
DROP PROCEDURE IF EXISTS GetPhysicianAppointments;
DROP PROCEDURE IF EXISTS AddTimeSlot;
DROP PROCEDURE IF EXISTS GetPatientAppointments;
DROP PROCEDURE IF EXISTS CancelAppointment;
DROP PROCEDURE IF EXISTS RescheduleAppointment;
DROP PROCEDURE IF EXISTS GetAppointmentDetails;
DROP PROCEDURE IF EXISTS InsertNurseDepartment;
DROP PROCEDURE IF EXISTS GetAllAppointments;
DROP PROCEDURE IF EXISTS GetAllClinics;
DROP PROCEDURE IF EXISTS AddClinic;
DROP PROCEDURE IF EXISTS EditClinic;
DROP PROCEDURE IF EXISTS GetAllDepartments;
DROP PROCEDURE IF EXISTS AddDepartment;
DROP PROCEDURE IF EXISTS EditDepartment;
DROP PROCEDURE IF EXISTS GetAllSpecializations;
DROP PROCEDURE IF EXISTS AddSpecialization;
DROP PROCEDURE IF EXISTS EditSpecialization;
DROP PROCEDURE IF EXISTS AssignSpecializationByRole;
DROP PROCEDURE IF EXISTS GetUsersWithSpecializations;
DROP PROCEDURE IF EXISTS RemoveSpecializationFromUser;
DROP PROCEDURE IF EXISTS GetUserSpecializationRows;
DROP PROCEDURE IF EXISTS RemoveDepartmentFromClinic;
DROP PROCEDURE IF EXISTS GetClinicDepartmentLinks;
DROP PROCEDURE IF EXISTS GetAllPatients;
DROP PROCEDURE IF EXISTS GetAvailableSlotsByDepartment;
DROP PROCEDURE IF EXISTS GetDepartmentsForPhysician;
DROP PROCEDURE IF EXISTS GetNurseIDByUserID;
DROP PROCEDURE IF EXISTS GetDepartmentsByNurseID;
DROP PROCEDURE IF EXISTS ScheduleAppointmentForPatient;

DELIMITER //
CREATE PROCEDURE AddUserProfile(
    IN p_UserID VARCHAR(50), IN p_Username VARCHAR(50), IN p_FirstName VARCHAR(255), IN p_LastName VARCHAR(255),
    IN p_Email VARCHAR(255), IN p_PasswordHash VARCHAR(255), IN p_RoleID VARCHAR(50), IN p_Phone VARCHAR(20),
    IN p_Gender VARCHAR(20), IN p_Sex VARCHAR(20), IN p_DOB DATE)
BEGIN
    START TRANSACTION;
    IF EXISTS (SELECT 1 FROM User WHERE Username = p_Username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username is already taken.';
    END IF;
    IF EXISTS (SELECT 1 FROM User WHERE Email = p_Email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email is already registered.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleID = p_RoleID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid role selected.';
    END IF;

    INSERT INTO User (UserID, Username, FirstName, LastName, Email, PasswordHash, RoleID, Phone, Gender, Sex, DOB )
    VALUES (p_UserID, p_Username, p_FirstName, p_LastName, p_Email, p_PasswordHash,p_RoleID, p_Phone, p_Gender, p_Sex, p_DOB);

    CASE p_RoleID
        WHEN 'R1' THEN INSERT INTO Patient (PatientID, UserID) VALUES (UUID(), p_UserID);
        WHEN 'R2' THEN INSERT INTO Physician (PhysicianID, UserID) VALUES (UUID(), p_UserID);
        WHEN 'R3' THEN INSERT INTO Nurse (NurseID, UserID) VALUES (UUID(), p_UserID);
        WHEN 'R4' THEN INSERT INTO Admin (AdminID, UserID) VALUES (UUID(), p_UserID);
    END CASE;

    COMMIT;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE VerifyUserLogin(
    IN p_Username VARCHAR(50)
)
BEGIN
    SELECT 
        u.UserID, u.Username, u.PasswordHash, r.RoleName, u.FirstName, u.LastName
    FROM User u
    JOIN Roles r ON u.RoleID = r.RoleID
    WHERE u.Username = p_Username;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE CheckUsernameExists(
IN p_Username VARCHAR(50))
BEGIN
    SELECT COUNT(*) AS Count
    FROM User
    WHERE Username = p_Username;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE ChangeUserPassword(
    IN p_UserID VARCHAR(50),
    IN p_NewHash VARCHAR(255)
)
BEGIN
    UPDATE User
    SET PasswordHash = p_NewHash
    WHERE UserID = p_UserID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE CompletePhysicianProfile(
    IN p_UserID VARCHAR(50),IN p_DeptIDs TEXT,IN p_PhysicianType VARCHAR(255),IN p_PhysicianRankID VARCHAR(50),IN p_SpecializationID VARCHAR(50))
BEGIN
    DECLARE physician_id VARCHAR(50);
    DECLARE dept_id VARCHAR(50);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE dept_cursor CURSOR FOR
        SELECT value FROM JSON_TABLE(p_DeptIDs, '$[*]' COLUMNS(value VARCHAR(50) PATH '$')) AS jt;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    START TRANSACTION;

    SELECT PhysicianID INTO physician_id
    FROM Physician
    WHERE UserID = p_UserID;
    UPDATE Physician
    SET PhysicianType = p_PhysicianType, PhysicianRankID = p_PhysicianRankID WHERE UserID = p_UserID;

    DELETE FROM PhysicianDepartment WHERE PhysicianID = physician_id;
    OPEN dept_cursor;
    dept_loop: LOOP
        FETCH dept_cursor INTO dept_id;
        IF done THEN LEAVE dept_loop; END IF;
        INSERT INTO PhysicianDepartment (PhysicianID, DeptID)
        VALUES (physician_id, dept_id);
    END LOOP;
    CLOSE dept_cursor;

    DELETE FROM PhysicianSpecializations WHERE PhysicianID = physician_id;
    INSERT INTO PhysicianSpecializations (PhysicianID, SpecializationID)
    VALUES (physician_id, p_SpecializationID);
    COMMIT;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetPhysiciansByDepartment(
    IN p_DeptID VARCHAR(50) )
BEGIN
    SELECT p.PhysicianID, u.FirstName, u.LastName FROM Physician p JOIN User u ON p.UserID = u.UserID
    WHERE p.PhysicianID IN (
        SELECT PhysicianID FROM PhysicianDepartment WHERE DeptID = p_DeptID);
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAvailableSlotsByPhysician(
    IN p_PhysicianID VARCHAR(50))
BEGIN
    SELECT SlotID, StartTime, EndTime FROM TimeSlot
    WHERE PhysicianID = p_PhysicianID AND Available = TRUE;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetPhysicianAppointments(
    IN p_PhysicianID VARCHAR(50), IN p_Mode VARCHAR(20) )
BEGIN
    SELECT 
        a.ApptID, p.FirstName AS PatientFirstName, p.LastName AS PatientLastName, d.Dept_Name,
        a.ApptDate, at.TypeName, a.ApptStatus FROM Appointment a
    JOIN Patient pt ON a.PatientID = pt.PatientID JOIN User p ON pt.UserID = p.UserID
    JOIN Department d ON a.DeptID = d.Dept_ID JOIN AppointmentTypes at ON a.TypeID = at.TypeID
    WHERE a.PhysicianID = p_PhysicianID
      AND (
            (p_Mode = 'upcoming' AND a.ApptDate >= NOW() AND a.ApptStatus IN ('Scheduled', 'Rescheduled'))
         OR (p_Mode = 'past' AND a.ApptDate < NOW() AND a.ApptStatus = 'Completed')
         OR (p_Mode = 'cancelled' AND a.ApptStatus = 'Cancelled')
      )
    ORDER BY a.ApptDate ASC;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE AddTimeSlot(
    IN p_SlotID VARCHAR(50), IN p_DeptID VARCHAR(50), IN p_PhysicianID VARCHAR(50), IN p_StartTime DATETIME, IN p_EndTime DATETIME)
BEGIN
    INSERT INTO TimeSlot (SlotID, DeptID, PhysicianID, StartTime, EndTime, Available) VALUES (p_SlotID, p_DeptID, p_PhysicianID, p_StartTime, p_EndTime, TRUE);
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetPatientAppointments(
    IN p_PatientID VARCHAR(50), IN p_Mode VARCHAR(20) )
BEGIN
    IF p_Mode = 'upcoming' THEN
        SELECT 
            a.ApptID, d.Dept_Name, CONCAT(doc.FirstName, ' ', doc.LastName) AS PhysicianName,
            a.ApptDate, at.TypeName, a.ApptStatus
        FROM Appointment a JOIN Department d ON a.DeptID = d.Dept_ID JOIN Physician p ON a.PhysicianID = p.PhysicianID
        JOIN User doc ON p.UserID = doc.UserID JOIN AppointmentTypes at ON a.TypeID = at.TypeID
        WHERE a.PatientID = p_PatientID
          AND a.ApptDate >= NOW()  
        ORDER BY a.ApptDate ASC;

    ELSEIF p_Mode = 'past' THEN
        SELECT 
            a.ApptID, d.Dept_Name, CONCAT(doc.FirstName, ' ', doc.LastName) AS PhysicianName,
            a.ApptDate, at.TypeName, a.ApptStatus
        FROM Appointment a JOIN Department d ON a.DeptID = d.Dept_ID JOIN Physician p ON a.PhysicianID = p.PhysicianID JOIN User doc ON p.UserID = doc.UserID
        JOIN AppointmentTypes at ON a.TypeID = at.TypeID WHERE a.PatientID = p_PatientID
		AND a.ApptDate < NOW()  ORDER BY a.ApptDate DESC;
    END IF;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE CancelAppointment(
    IN p_ApptID VARCHAR(50))
BEGIN
    START TRANSACTION;
    UPDATE Appointment
    SET ApptStatus = 'Cancelled'
    WHERE ApptID = p_ApptID;
    UPDATE TimeSlot SET Available = TRUE
    WHERE SlotID = (SELECT SlotID FROM Appointment WHERE ApptID = p_ApptID);
    COMMIT;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE RescheduleAppointment(
    IN p_ApptID VARCHAR(50), IN p_NewSlotID VARCHAR(50), IN p_NewPhysicianID VARCHAR(50), IN p_DeptID VARCHAR(50))
BEGIN
    DECLARE new_start_time DATETIME;
    DECLARE old_slot_id VARCHAR(50);
    START TRANSACTION;
    SELECT StartTime INTO new_start_time
    FROM TimeSlot WHERE SlotID = p_NewSlotID;

    SELECT SlotID INTO old_slot_id FROM Appointment WHERE ApptID = p_ApptID;
    
    UPDATE Appointment
    SET
        SlotID = p_NewSlotID, PhysicianID = p_NewPhysicianID, ApptDate = new_start_time, DeptID = p_DeptID, ApptStatus = 'Rescheduled'
    WHERE ApptID = p_ApptID;

    UPDATE TimeSlot SET Available = TRUE
    WHERE SlotID = old_slot_id;

    UPDATE TimeSlot SET Available = FALSE
    WHERE SlotID = p_NewSlotID;
    COMMIT;
END //
DELIMITER ;
DELIMITER //

CREATE PROCEDURE GetAppointmentDetails(
    IN p_ApptID VARCHAR(50))
BEGIN
    SELECT 
        a.ApptID, CONCAT(u.FirstName, ' ', u.LastName) AS PhysicianName, d.Dept_Name,
        d.Dept_ID, at.TypeName, a.ApptDate, a.ApptStatus
    FROM Appointment a JOIN Physician p ON a.PhysicianID = p.PhysicianID
    JOIN User u ON p.UserID = u.UserID JOIN Department d ON a.DeptID = d.Dept_ID
    JOIN AppointmentTypes at ON a.TypeID = at.TypeID
    WHERE a.ApptID = p_ApptID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE InsertNurseDepartment(
    IN p_NurseID VARCHAR(50), IN p_DeptID VARCHAR(50))
BEGIN
    INSERT INTO NurseDepartment (NurseDeptID, NurseID, DeptID) VALUES (UUID(), p_NurseID, p_DeptID);
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAllAppointments()
BEGIN
    SELECT 
        a.ApptID, CONCAT(p_user.FirstName, ' ', p_user.LastName) AS PatientName, CONCAT(doc_user.FirstName, ' ', doc_user.LastName) AS PhysicianName,
        d.Dept_Name, at.TypeName, a.ApptDate, a.ApptStatus
    FROM Appointment a
    JOIN Patient pt ON a.PatientID = pt.PatientID JOIN User p_user ON pt.UserID = p_user.UserID
    JOIN Physician ph ON a.PhysicianID = ph.PhysicianID JOIN User doc_user ON ph.UserID = doc_user.UserID
    JOIN Department d ON a.DeptID = d.Dept_ID JOIN AppointmentTypes at ON a.TypeID = at.TypeID
    ORDER BY a.ApptDate DESC;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAllClinics()
BEGIN
    SELECT Clinic_ID, Clinic_Name FROM Clinic
    ORDER BY 
        CASE 
            WHEN Clinic_Name REGEXP '^[a-zA-Z]' THEN 0
            ELSE 1
        END,
        Clinic_Name ASC;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE AddClinic(
    IN p_ClinicID VARCHAR(50), IN p_ClinicName VARCHAR(255))
BEGIN
    INSERT INTO Clinic (Clinic_ID, Clinic_Name) VALUES (p_ClinicID, p_ClinicName);
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE EditDepartment(
    IN p_DeptID VARCHAR(255), IN p_NewName VARCHAR(255))
BEGIN
    UPDATE DEPARTMENT SET Dept_Name = p_NewName
    WHERE Dept_ID = p_DeptID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE EditClinic(
    IN p_ClinicID VARCHAR(255), IN p_NewName VARCHAR(255))
BEGIN
    UPDATE CLINIC SET Clinic_Name = p_NewName
    WHERE Clinic_ID = p_ClinicID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAllDepartments()
BEGIN
    SELECT 
        d.Dept_ID, d.Dept_Name, GROUP_CONCAT(c.Clinic_Name ORDER BY c.Clinic_Name SEPARATOR ', ') AS Clinic_Names
    FROM Department d JOIN ClinicDepartment cd ON d.Dept_ID = cd.Dept_ID
    JOIN Clinic c ON cd.Clinic_ID = c.Clinic_ID GROUP BY d.Dept_ID, d.Dept_Name
    ORDER BY 
        CASE 
            WHEN d.Dept_Name REGEXP '^[a-zA-Z]' THEN 0
            ELSE 1
        END,
        d.Dept_Name ASC;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE AddDepartment(
    IN p_DeptID VARCHAR(50), IN p_DeptName VARCHAR(255), IN p_ClinicID VARCHAR(255))
BEGIN
    START TRANSACTION;
    INSERT INTO Department (Dept_ID, Dept_Name) VALUES (p_DeptID, p_DeptName);
    INSERT INTO ClinicDepartment (DeptID, ClinicID) VALUES (p_DeptID, p_ClinicID);
    COMMIT;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAllSpecializations()
BEGIN
    SELECT * FROM Specializations
    ORDER BY 
        CASE 
            WHEN Specialization REGEXP '^[a-zA-Z]' THEN 0
            ELSE 1
        END,
        Specialization ASC;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE AddSpecialization(
    IN p_SpecID VARCHAR(50), IN p_Name VARCHAR(255))
BEGIN
    INSERT INTO Specializations (Specialization_ID, Specialization) VALUES (p_SpecID, p_Name);
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE EditSpecialization(
    IN p_SpecID VARCHAR(50), IN p_NewName VARCHAR(255))
BEGIN
    UPDATE Specializations
    SET Specialization = p_NewName WHERE Specialization_ID = p_SpecID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetUsersWithSpecializations()
BEGIN
    SELECT * FROM (
        SELECT 
            u.Username, u.FirstName, u.LastName, 'Physician' AS Role,
            GROUP_CONCAT(s.Specialization ORDER BY s.Specialization SEPARATOR ', ') AS Specializations
        FROM Physician p JOIN User u ON p.UserID = u.UserID LEFT JOIN PhysicianSpecializations ps ON p.PhysicianID = ps.PhysicianID
        LEFT JOIN Specializations s ON ps.SpecializationID = s.Specialization_ID GROUP BY u.UserID, u.Username, u.FirstName, u.LastName

        UNION

        SELECT 
            u.Username, u.FirstName, u.LastName, 'Nurse' AS Role,
            GROUP_CONCAT(s.Specialization ORDER BY s.Specialization SEPARATOR ', ') AS Specializations
        FROM Nurse n JOIN User u ON n.UserID = u.UserID LEFT JOIN NurseSpecializations ns ON n.NurseID = ns.NurseID
        LEFT JOIN Specializations s ON ns.SpecializationID = s.Specialization_ID GROUP BY u.UserID, u.Username, u.FirstName, u.LastName
    ) AS combined_users
    ORDER BY Role, LastName, FirstName;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE AssignSpecializationByRole(
    IN p_Username VARCHAR(255), IN p_SpecID VARCHAR(50))
BEGIN
    DECLARE user_id_local VARCHAR(50);
    DECLARE role_id_local VARCHAR(50);
    DECLARE entity_id VARCHAR(50);

    SELECT UserID, RoleID INTO user_id_local, role_id_local
    FROM User WHERE Username = p_Username;
    IF role_id_local = 'R2' THEN -- Physician 
        SELECT PhysicianID INTO entity_id FROM Physician
        WHERE UserID = user_id_local;
        INSERT IGNORE INTO PhysicianSpecializations (PhysicianID, SpecializationID)
        VALUES (entity_id, p_SpecID);
    ELSEIF role_id_local = 'R3' THEN -- Nurse
        SELECT NurseID INTO entity_id FROM Nurse
        WHERE UserID = user_id_local;
        INSERT IGNORE INTO NurseSpecializations (NurseID, SpecializationID)
        VALUES (entity_id, p_SpecID);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only Physicians or Nurses can be assigned specializations.';
    END IF;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE RemoveSpecializationFromUser(
    IN p_Username VARCHAR(255), IN p_SpecID VARCHAR(50))
BEGIN
    DECLARE user_id_local VARCHAR(50);
    DECLARE role_id_local VARCHAR(50);
    DECLARE target_id VARCHAR(50);

    SELECT UserID, RoleID INTO user_id_local, role_id_local FROM User
    WHERE Username = p_Username;

    IF role_id_local = 'R2' THEN
        SELECT PhysicianID INTO target_id FROM Physician WHERE UserID = user_id_local;
        DELETE FROM PhysicianSpecializations WHERE PhysicianID = target_id AND SpecializationID = p_SpecID;

    ELSEIF role_id_local = 'R3' THEN
        SELECT NurseID INTO target_id FROM Nurse WHERE UserID = user_id_local;
        DELETE FROM NurseSpecializations WHERE NurseID = target_id AND SpecializationID = p_SpecID;

    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not Nurse or Physician';
    END IF;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetUserSpecializationRows()
BEGIN
    SELECT * FROM (
        SELECT 
            u.Username, u.FirstName, u.LastName,
            'Physician' AS Role, s.Specialization, s.Specialization_ID
        FROM Physician p JOIN User u ON p.UserID = u.UserID
        JOIN PhysicianSpecializations ps ON p.PhysicianID = ps.PhysicianID
        JOIN Specializations s ON ps.SpecializationID = s.Specialization_ID

        UNION ALL

        SELECT 
            u.Username, u.FirstName, u.LastName,
            'Nurse' AS Role, s.Specialization, s.Specialization_ID
        FROM Nurse n JOIN User u ON n.UserID = u.UserID
		JOIN NurseSpecializations ns ON n.NurseID = ns.NurseID
        JOIN Specializations s ON ns.SpecializationID = s.Specialization_ID
    ) AS all_specializations
    ORDER BY Role, LastName, FirstName, Specialization;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetClinicDepartmentLinks()
BEGIN
    SELECT 
        c.Clinic_ID, c.Clinic_Name, d.Dept_ID, d.Dept_Name
    FROM Clinic c JOIN ClinicDepartment cd ON c.Clinic_ID = cd.Clinic_ID
    JOIN Department d ON cd.Dept_ID = d.Dept_ID ORDER BY c.Clinic_Name, d.Dept_Name;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE RemoveDepartmentFromClinic(
    IN p_ClinicID VARCHAR(50), IN p_DeptID VARCHAR(50))
BEGIN
    DELETE FROM ClinicDepartment WHERE Clinic_ID = p_ClinicID AND Dept_ID = p_DeptID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAllPatients()
BEGIN
    SELECT 
        pt.PatientID, u.UserID, u.Username, u.FirstName, u.LastName
    FROM Patient pt JOIN User u ON pt.UserID = u.UserID ORDER BY u.LastName, u.FirstName;
END //
DELIMITER ; 
DELIMITER //
CREATE PROCEDURE GetAvailableSlotsByDepartment(IN p_DeptID VARCHAR(50))
BEGIN
    SELECT 
        ts.SlotID, ts.StartTime, ts.EndTime, ts.DeptID,
        p.PhysicianID, u.FirstName, u.LastName
    FROM TimeSlot ts
    JOIN Physician p ON ts.PhysicianID = p.PhysicianID
	JOIN User u ON p.UserID = u.UserID WHERE ts.Available = TRUE AND ts.DeptID = p_DeptID AND ts.StartTime >= NOW();
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetDepartmentsForPhysician(IN p_UserID VARCHAR(50))
BEGIN
    SELECT d.Dept_ID, d.Dept_Name FROM Physician p
    JOIN PhysicianDepartment pd ON p.PhysicianID = pd.PhysicianID
    JOIN Department d ON pd.DeptID = d.Dept_ID WHERE p.UserID = p_UserID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetNurseIDByUserID(IN p_UserID VARCHAR(50))
BEGIN
    SELECT NurseID FROM Nurse WHERE UserID = p_UserID;
END;
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetDepartmentsByNurseID(
    IN p_NurseID VARCHAR(50))
BEGIN
    SELECT d.Dept_ID, d.Dept_Name FROM NurseDepartment nd
    JOIN Department d ON nd.DeptID = d.Dept_ID WHERE nd.NurseID = p_NurseID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE ScheduleAppointmentForPatient(
    IN p_UserID VARCHAR(50), IN p_SlotID VARCHAR(50),
    IN p_PhysicianID VARCHAR(50), IN p_TypeID VARCHAR(50)
)
BEGIN
    DECLARE appt_id VARCHAR(50);
    DECLARE patient_id VARCHAR(50);
    DECLARE dept_id VARCHAR(50);
    DECLARE slot_available BOOLEAN;

    SET appt_id = UUID();

    SELECT PatientID INTO patient_id FROM Patient WHERE UserID = p_UserID;

    SELECT DeptID, Available INTO dept_id, slot_available
    FROM TimeSlot WHERE SlotID = p_SlotID FOR UPDATE;

    IF slot_available = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slot already booked.';
    END IF;

    INSERT INTO Appointment (
        ApptID, PatientID, PhysicianID, SlotID, TypeID, DeptID, ApptDate, ApptStatus, CheckinStatus, SurveyCompleted)
    SELECT appt_id, patient_id, p_PhysicianID, p_SlotID, p_TypeID,
			DeptID, StartTime, 'Scheduled', FALSE, FALSE
    FROM TimeSlot WHERE SlotID = p_SlotID;

    UPDATE TimeSlot SET Available = FALSE WHERE SlotID = p_SlotID;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetNurseIDByUserID(
    IN p_UserID VARCHAR(50))
BEGIN
    SELECT NurseID FROM Nurse
    WHERE UserID = p_UserID;
END //
DELIMITER ;

