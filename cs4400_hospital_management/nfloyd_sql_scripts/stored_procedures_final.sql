use team5project;  


-- Joe and general stored procedures
DELIMITER //
CREATE PROCEDURE BillRetrieval(IN in_patient_id VARCHAR(255))
BEGIN
    SELECT 
        b.BillID,
        b.InvoiceID,
        b.TotalCharge,
        b.PatientResponsibility,
        b.InsurancePayment,
        b.BalanceDue,
        b.PaymentStatus,
        b.DueDate,
        GROUP_CONCAT(sb.ServiceDescription SEPARATOR '; ') AS ServicesRendered
    FROM Bill b
    LEFT JOIN BillServiceDetail bsd ON b.BillID = bsd.BillID
    LEFT JOIN ServiceBreakdown sb ON bsd.ServiceBreakdownID = sb.ServiceBreakdownID
    WHERE b.PatientID = in_patient_id
    GROUP BY b.BillID;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE InvoiceRetrieval(IN in_patient_id VARCHAR(255))
BEGIN
    SELECT 
        i.InvoiceID,
        i.GrossCharge,
        i.TotalPayments,
        i.BalanceDue,
        i.DueDate,
        i.StaffID
    FROM Invoice i
    WHERE i.PatientID = in_patient_id;
END //
DELIMITER ;

DELIMITER // 
CREATE PROCEDURE ScheduleAppointment (
	IN pApptID VARCHAR(50),
	IN pPatientID VARCHAR(50),
	IN pSlotID VARCHAR(50),
	IN pTypeID VARCHAR(50),
	IN pDeptID VARCHAR(50),
	IN pPhysicianID VARCHAR(50),
	IN pApptDate DATETIME  
)
BEGIN
	DECLARE IsSlotAvailable BOOLEAN;
	START TRANSACTION;
    
	-- Check if the time slot is available
	SELECT Available INTO IsSlotAvailable
	FROM TimeSlot
	WHERE SlotID = pSlotID
	FOR UPDATE;

	IF IsSlotAvailable = FALSE THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Time slot is not Available';
    	ROLLBACK;
	ELSE
    	-- Insert the appointment with the provIDed appointment date
    	INSERT INTO Appointment (
        	ApptID, PatientID, SlotID, TypeID, DeptID, ApptDate, PhysicianID, CheckinStatus, SurveyCompleted, ApptStatus
    	)
    	VALUES (
        	pApptID, pPatientID, pSlotID, pTypeID, pDeptID, pApptDate, pPhysicianID, FALSE, FALSE, 'Scheduled'
    	);

    	 INSERT INTO NurseShiftAppointments (NurseShiftID, ApptID, NurseID)
    	 SELECT ShiftID, pApptID, NurseID
    	 FROM NurseShift
    	 WHERE DeptID = pDeptID AND ShiftStartTime = (SELECT StartTime FROM TimeSlot WHERE SlotID = pSlotID);

    	-- Mark the Appointment time slot as unavailable
    	UPDATE TimeSlot
    	SET Available = FALSE
    	WHERE SlotID = pSlotID;

    	COMMIT;
	END IF;
END // 
DELIMITER ;




/*
DELIMITER //
CREATE PROCEDURE RescheduleAppointment (
    IN pApptID VARCHAR(50),
    IN pNewSlotID VARCHAR(50)
)
BEGIN
    DECLARE oldSlotID VARCHAR(50);
    DECLARE newSlotAvailable BOOLEAN;

    START TRANSACTION;

    -- Retrieve the old slot ID before doing any updates
    SELECT SlotID INTO oldSlotID
    FROM Appointment
    WHERE ApptID = pApptID;

    -- Check if the new slot is available
    SELECT Available INTO newSlotAvailable
    FROM TimeSlot
    WHERE SlotID = pNewSlotID
    FOR UPDATE;

    IF newSlotAvailable = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New slot is unavailable.';
        ROLLBACK;
    END IF;

    -- Update the appointment with the new slot ID and the new appointment date
    UPDATE Appointment
    SET SlotID = pNewSlotID,
        ApptDate = (SELECT StartTime FROM TimeSlot WHERE SlotID = pNewSlotID),
        ApptStatus = 'Rescheduled'
    WHERE ApptID = pApptID;

    -- Mark the new slot as unavailable
    UPDATE TimeSlot
    SET Available = FALSE
    WHERE SlotID = pNewSlotID;

    -- Mark the old slot as available
    UPDATE TimeSlot
    SET Available = TRUE
    WHERE SlotID = oldSlotID;

    -- Commit the changes
    COMMIT;

END //
DELIMITER ;
*/
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
-- CANCEL Appointment
DELIMITER //
CREATE PROCEDURE CancelAppointment (
    IN pApptID VARCHAR(50)
)
BEGIN
    DECLARE currentApptStatus VARCHAR(50);
    DECLARE vSlotID VARCHAR(50);
    DECLARE exit handler for sqlexception
    BEGIN
        ROLLBACK;
    END;

    -- Check if the Appointment exists and fetch the current status and time slot
    SELECT ApptStatus, SlotID INTO currentApptStatus, vSlotID
    FROM Appointment
    WHERE ApptID = pApptID;

    -- if appointment not found
    IF currentApptStatus IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment not found.';
    END IF;

    START TRANSACTION;
    -- Set Appointment status as cancelled
    UPDATE Appointment
    SET ApptStatus = 'Cancelled'
    WHERE ApptID = pApptID;
    -- Set TimeSlot as Available
    UPDATE TimeSlot
    SET Available = TRUE
    WHERE SlotID = vSlotID;

    COMMIT;
END //
DELIMITER ;










-- CHECK IN FOR Appointment AND COMPLETE Survey
DELIMITER //
CREATE PROCEDURE CheckInAndSurvey(
    IN pApptID VARCHAR(50),
    IN pSurveyCompleted BOOLEAN
)
BEGIN
    DECLARE currentCheckInStatus BOOLEAN;
    DECLARE currentSurveyStatus ENUM('Completed', 'Pending', 'Not required');

    -- Retrieve current check-in status from Appointment table
    SELECT CheckinStatus INTO currentCheckInStatus
    FROM Appointment
    WHERE ApptID = pApptID;

    -- If appointment is not found, raise an error
    IF currentCheckInStatus IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment not found.';
    END IF;

    -- If already checked in, raise an error
    IF currentCheckInStatus = TRUE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment has already been checked in.';
    END IF;

    -- Check if a survey exists for the appointment
    SELECT SurveyStatus INTO currentSurveyStatus
    FROM AppointmentSurvey
    WHERE ApptID = pApptID;

    START TRANSACTION;
    UPDATE Appointment
    SET CheckinStatus = TRUE,
        SurveyCompleted = pSurveyCompleted
    WHERE ApptID = pApptID;

    IF pSurveyCompleted = TRUE THEN
        UPDATE AppointmentSurvey
        SET SurveyStatus = 'Completed'
        WHERE ApptID = pApptID;
    END IF;

    COMMIT;

END //
DELIMITER ;

-- VIEW Available Appointment TIME SLOTS
DELIMITER //
CREATE PROCEDURE GetAllAvailableTimeSlots()
BEGIN
	SELECT SlotID, StartTime, EndTime, PhysicianID
	FROM TimeSlot
	WHERE Available = TRUE
	ORDER BY StartTime;
END //
DELIMITER ;

-- drop procedure createBill;
-- CREATE A BILL
DELIMITER //
CREATE PROCEDURE createBill(
    IN pBillID VARCHAR(50),
    IN pPatientID VARCHAR(50),
    IN pServiceBreakdownID VARCHAR(50),  
    IN pInvoiceID VARCHAR(50),
    IN pDueDate DATE
)
BEGIN
    DECLARE totalcharge DECIMAL(10, 2);
    DECLARE copay DECIMAL(10, 2);
    DECLARE deductible DECIMAL(10, 2);
    DECLARE coinsurance DECIMAL(5, 2); -- stored as decimal (e.g. 0.2 for 20%)
    DECLARE oopmax DECIMAL(10, 2);
    DECLARE remainingbill DECIMAL(10, 2);
    DECLARE insurancepayment DECIMAL(10, 2);
    DECLARE patientpayment DECIMAL(10, 2);
    DECLARE insuranceplanID VARCHAR(50);
    DECLARE paymentstatus VARCHAR(20);
    DECLARE balancedue DECIMAL(10, 2);

    -- 1. Get service cost and insurance plan details
    SELECT
        sb.ServiceCost,
        p.InsurancePlanID,
        ip.Copay,
        ip.Deductible,
        ip.Coinsurance,
        ip.OOPmax
    INTO
        totalcharge,
        insuranceplanID,
        copay,
        deductible,
        coinsurance,
        oopmax
    FROM ServiceBreakdown sb
    JOIN Patient p ON p.PatientID = pPatientID
    JOIN InsurancePlan ip ON ip.InsurancePlanID = p.insurancePlanID
    WHERE sb.ServiceBreakdownID = pServiceBreakdownID AND p.PatientID = pPatientID;



SELECT
    sb.ServiceCost,
    p.insurancePlanID,
    ip.Copay,
    ip.Deductible,
    ip.Coinsurance,
    ip.OOPmax
FROM ServiceBreakdown sb
JOIN Patient p ON p.PatientID = 'P007'
JOIN InsurancePlan ip ON ip.InsurancePlanID = p.insurancePlanID
WHERE sb.ServiceBreakdownID = 'SB004' AND p.PatientID = 'P007';



    -- 2. Payment calculations
    IF totalcharge <= deductible THEN
        -- Patient pays full amount if charge is under deductible
        SET patientpayment = totalcharge;
        SET insurancepayment = 0;
    ELSE
        SET remainingbill = totalcharge - deductible;
        SET insurancepayment = remainingbill * (1 - coinsurance);
        SET patientpayment = copay + deductible + (remainingbill * coinsurance);

        -- Enforce out-of-pocket max
        IF patientpayment > oopmax THEN
            SET patientpayment = oopmax;
            SET insurancepayment = totalcharge - oopmax;
        END IF;
    END IF;

    -- 3. Balance due is what the patient and insurance owe
    SET balancedue = totalcharge;

    -- 4. Determine payment status
    IF balancedue <= 0 THEN
        SET paymentstatus = 'PaID';
    ELSE
        SET paymentstatus = 'Pending';
    END IF;

    -- 5. Insert the bill record
    INSERT INTO Bill (
        BillID, PatientID, InvoiceID,
        TotalCharge, DueDate, PatientResponsibility,
        InsurancePayment, BalanceDue, PaymentStatus)
    VALUES (
        pBillID, pPatientID, pinvoiceID,
        totalcharge, pDueDate, patientpayment,
        insurancepayment, balancedue, paymentstatus);

    -- 6. Link the bill with service breakdown details
    INSERT INTO BillServiceDetail (BillID, ServiceBreakdownID)
    VALUES (pBillID, pServiceBreakdownID);

    -- 7. Update invoice totals (if this exists)
    CALL UpdateInvoiceTotals(pBillID);
END //
DELIMITER ;


-- ADD SERVICE BREAKDOWN
DELIMITER //
CREATE PROCEDURE InsertServiceBreakdown (
    IN pServiceBreakdownID VARCHAR(255),
    IN pStaffID VARCHAR(255),
    IN pDeptID VARCHAR(255),
    IN pServiceDescription VARCHAR(255),
    IN pServiceDate DATETIME,
    IN pServiceCost NUMERIC,
    IN pNotes VARCHAR(255)
)
BEGIN
    DECLARE StaffExists INT;
    DECLARE DeptExists INT;

    START TRANSACTION;

    SELECT COUNT(*) INTO StaffExists
    FROM Staff
    WHERE StaffID = pStaffID
    FOR UPDATE;

    IF StaffExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Staff ID does not exist';
        ROLLBACK;
    END IF;

    SELECT COUNT(*) INTO DeptExists
    FROM Department
    WHERE DeptID = pDeptID
    FOR UPDATE;

    IF DeptExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Department ID does not exist';
        ROLLBACK;
    END IF;

    INSERT INTO ServiceBreakdown (
        ServiceBreakdownID, 
        StaffID, 
        DeptID, 
        ServiceDescription, 
        ServiceDate, 
        ServiceCost, 
        Notes
    )
    VALUES (
        pServiceBreakdownID, 
        pStaffID, 
        pDeptID, 
        pServiceDescription, 
        pServiceDate, 
        pServiceCost, 
        pNotes
    );

    COMMIT;
END //
DELIMITER ;

-- MAKE A Claim
DELIMITER //
CREATE PROCEDURE CreateClaim (
    IN pClaimID VARCHAR(255),
    IN pPatientID VARCHAR(255),
    IN pInsuranceCoverageID VARCHAR(255),
    IN pClaimCreationDate DATETIME
)
BEGIN
    DECLARE PatientExists INT;
    DECLARE CoverageExists INT;

    START TRANSACTION;

    SELECT COUNT(*) INTO PatientExists
    FROM Patient
    WHERE PatientID = pPatientID
    FOR UPDATE;

    IF PatientExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient does not exist';
        ROLLBACK;
    END IF;
    
    SELECT COUNT(*) INTO CoverageExists
    FROM INSURANCECOVERAGE
    WHERE CoverageID = pInsuranceCoverageID
    FOR UPDATE;

    IF CoverageExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insurance coverage does not exist';
        ROLLBACK;
    END IF;

    INSERT INTO Claim (
        ClaimID, 
        PatientID, 
        InsuranceCoverageID, 
        ClaimCreationDate
    )
    VALUES (
        pClaimID, 
        pPatientID, 
        pInsuranceCoverageID, 
        pClaimCreationDate
    );

    COMMIT;
END //
DELIMITER ;

-- GENERATE Invoice
DELIMITER //
CREATE PROCEDURE createInvoice(
	IN pInvoiceID VARCHAR(50),
	IN pPatientID VARCHAR(50),
	IN pStaffID VARCHAR(50),
	IN pDueDate DATE
)
BEGIN
	DECLARE grosscharge DECIMAL(10, 2) DEFAULT 0;
	DECLARE totalPayments DECIMAL(10, 2) DEFAULT 0;
	DECLARE balancedue DECIMAL(10, 2) DEFAULT 0;

	-- 1. Calculate gross charge (sum of all Bill charges connected to this Invoice)
	SELECT COALESCE(SUM(b.TotalCharge), 0)
	INTO grosscharge
	FROM Bill b
	WHERE b.InvoiceID = pInvoiceID;

	-- 2. Calculate total Payments made (from both Patient & insurance) toward any Bill in the Invoice
	SELECT COALESCE(SUM(p.PaymentAmount), 0)
	INTO totalPayments
	FROM Payment p
	JOIN Bill b ON b.BillID = p.BillID
	WHERE b.InvoiceID = pInvoiceID;

	-- 3. Calculate remaining balance due
	SET balancedue = grosscharge - totalPayments;

	-- 4. Insert the Invoice record
	INSERT INTO Invoice (
    	InvoiceID, PatientID, StaffID, GrossCharge, TotalPayments, BalanceDue, DueDate
	)
	VALUES (
    	pInvoiceID, pPatientID, pStaffID, grosscharge, totalPayments, balancedue, pDueDate
	);
END //
DELIMITER ;

-- update Invoice after a Payment is made
DELIMITER //
CREATE PROCEDURE UpdateInvoiceTotals(
	IN pBillID VARCHAR(50)
)
BEGIN
	DECLARE vInvoiceID VARCHAR(50);
	DECLARE vGrossCharge DECIMAL(10,2);
	DECLARE vTotalPayments DECIMAL(10,2);
	DECLARE vBalanceDue DECIMAL(10,2);

	-- 1. Get the Invoice ID from the Bill
	SELECT InvoiceID INTO vInvoiceID
	FROM Bill
	WHERE BillID = pBillID;

	-- 2. Calculate total charge for the Invoice
	SELECT COALESCE(SUM(TotalCharge), 0)
	INTO vGrossCharge
	FROM Bill
	WHERE InvoiceID = vInvoiceID;

	-- 3. Calculate total Payments across all Bills in that Invoice
	SELECT COALESCE(SUM(p.PaymentAmount), 0)
	INTO vTotalPayments
	FROM Payment p
	JOIN Bill b ON b.BillID = p.BillID
	WHERE b.InvoiceID = vInvoiceID;

	-- 4. Calculate balance due
	SET vBalanceDue = vGrossCharge - vTotalPayments;

	-- 5. Update the Invoice record
	UPDATE Invoice
	SET GrossCharge = vGrossCharge,
		TotalPayments = vTotalPayments,
		BalanceDue = vBalanceDue
	WHERE InvoiceID = vInvoiceID;
END //
DELIMITER ;

-- Patient PAYS Bill
DELIMITER //
CREATE PROCEDURE MakePatientPayment(
    IN pPaymentID VARCHAR(50),
    IN pPatientID VARCHAR(50),
    IN pBillID VARCHAR(50),
    IN pClaimID VARCHAR(50),
    IN pAmount DECIMAL(10, 2),
    IN pPaymentDate DATE
)
BEGIN
    DECLARE vBalance DECIMAL(10, 2);
    DECLARE vNewBalance DECIMAL(10, 2);

    IF NOT EXISTS (SELECT 1 FROM Patient WHERE PatientID = pPatientID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient not found';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Bill WHERE BillID = pBillID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bill not found';
    END IF;

    SELECT BalanceDue INTO vBalance FROM Bill WHERE BillID = pBillID;

    IF pAmount > vBalance THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment exceeds outstanding balance';
    END IF;

    SET vNewBalance = vBalance - pAmount;

    INSERT INTO Payment (
        PaymentID, PatientID, BillID, 
        PaymentAmount, PaymentDate, Payer
    ) VALUES (
        pPaymentID, pPatientID, pBillID, 
        pAmount, pPaymentDate, 'Patient'
    );

    UPDATE Bill
    SET
        BalanceDue = vNewBalance,
        PaymentStatus = CASE
            WHEN vNewBalance <= 0 THEN 'PaID'
            ELSE 'Pending'
        END
    WHERE BillID = pBillID;
    CALL UpdateInvoiceTotals(pBillID);
END //
DELIMITER ;

-- INSURANCE Payment
DELIMITER //
CREATE PROCEDURE MakeInsurancePayment(
    IN pPaymentID VARCHAR(50),
    IN pInsurancePlanID VARCHAR(50),
    IN pPatientID VARCHAR(50),
    IN pBillID VARCHAR(50),
    IN pClaimID VARCHAR(50),
    IN pAmount DECIMAL(10, 2),
    IN pPaymentDate DATE,
    IN pInsurancePaymentID VARCHAR(50)
)
BEGIN
    DECLARE vBalance DECIMAL(10, 2);
    DECLARE vNewBalance DECIMAL(10, 2);
    START TRANSACTION;

    -- Check if the patient exists
    IF NOT EXISTS (SELECT 1 FROM Patient WHERE PatientID = pPatientID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient not found';
    END IF;

    -- Check if the bill exists
    IF NOT EXISTS (SELECT 1 FROM Bill WHERE BillID = pBillID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bill not found';
    END IF;

    -- Get the current balance due for the bill
    SELECT BalanceDue INTO vBalance FROM Bill WHERE BillID = pBillID;

    -- Check if the payment amount exceeds the balance due
    IF pAmount > vBalance THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment exceeds outstanding balance';
    END IF;

    -- Calculate the new balance
    SET vNewBalance = vBalance - pAmount;

    -- Insert payment record
    INSERT INTO Payment (
        PaymentID, PatientID, BillID, 
        PaymentAmount, PaymentDate, Payer
    ) VALUES (
        pPaymentID, pPatientID, pBillID, 
        pAmount, pPaymentDate, 'Insurance'
    );

    -- Insert relationship record for the insurance payment
    INSERT INTO InsurancePaymentRelationship (
        InsurancePaymentID,
        InsurancePlanID,
        BillID,
        PaymentID,
        PaymentAmount
    ) VALUES (
        pInsurancePaymentID,
        pInsurancePlanID,
        pBillID,
        pPaymentID,
        pAmount
    );

    -- Update the bill status and balance due
    UPDATE Bill
    SET
        BalanceDue = vNewBalance,
        PaymentStatus = CASE
            WHEN vNewBalance <= 0 THEN 'PaID'
            ELSE 'Pending'
        END
    WHERE BillID = pBillID;
    COMMIT;

END //
DELIMITER ;

-- ASSIGN Bed TO Patient/ ADMIT Patient
DELIMITER //
CREATE PROCEDURE AssignBedToPatient(
	IN pBedID VARCHAR(50),
	IN pPatientID VARCHAR(50)
)
BEGIN
	DECLARE assignedPatient varchar(50);

	SELECT PatientID INTO assignedPatient
	FROM Bed
	WHERE BedID = pBedID;

	IF assignedPatient IS NOT NULL THEN
    		SIGNAL SQLSTATE  '45000' SET message_text  = 'Bed is already occupied.';
	ELSE
    	UPDATE Bed
    	SET PatientID = pPatientID
    	WHERE BedID = pBedID;
	END IF ; 
END //
DELIMITER ;

-- DISCHARGE A Patient
DELIMITER // 
CREATE PROCEDURE DischargePatient(
	IN pPatientID VARCHAR(255))
BEGIN
	UPDATE Bed
	SET PatientID = NULL
	WHERE PatientID = pPatientID; 
END // 
DELIMITER ; 


-- VIEW ALL PaymentS MADE BY A Patient
DELIMITER //
CREATE PROCEDURE ViewPatientPayments (
    IN pPatientID VARCHAR(50)
)
BEGIN
    SELECT
        p.BillID,
        b.InvoiceID,
        b.TotalCharge,
        p.PaymentAmount,  -- Ensure this is the correct column in the Payment table
        p.PaymentDate,
        p.PaymentID,
        p.Payer
    FROM Payment p
    JOIN Bill b ON b.BillID = p.BillID
    WHERE p.PatientID = pPatientID  -- Correctly filter by the PatientID in the Payment table
      AND p.Payer = 'Patient';
END //
DELIMITER ;

-- VIEW ALL PaymentS MADE BY INSURANCE PER Patient
DELIMITER //
CREATE PROCEDURE ViewInsurancePayments (
    IN pPatientID VARCHAR(50)
)
BEGIN
    SELECT
        p.BillID,
        b.InvoiceID,
        b.TotalCharge,
        ipr.PaymentAmount,
        p.PaymentDate,
        p.PaymentID,
        ipr.InsurancePlanID,
        ipr.InsurancePaymentID,
        p.Payer
    FROM Payment p
    JOIN Bill b ON b.BillID = p.BillID
    JOIN InsurancePaymentRelationship ipr ON ipr.PaymentID = p.PaymentID
    WHERE p.PatientID = pPatientID
      AND p.Payer = 'Insurance';
END //
DELIMITER ;

-- INSERT SOAP/AFTER-VISIT SUMMARY
DELIMITER //
CREATE PROCEDURE insertSOAPsummary(
	IN pSummaryID VARCHAR(255),
	IN pPhysicianID VARCHAR(255),
	IN pPatientID VARCHAR(255),
	IN pVisibleToPatient BOOLEAN
)
BEGIN
	INSERT INTO AfterVisitSummary (
    	SummaryID, PhysicianID, PatientID, VisibleToPatient, Created
	) VALUES (
    	pSummaryID, pPhysicianID, pPatientID, pVisibleToPatient, NOW()
	);
END //
DELIMITER ;

-- MAKE SOAP DOC VISIBLE TO Patient (AS AN AFTER-VISIT SUMMARY) AFTER THEY HAVE BEEN DISCHARGED
DELIMITER //
CREATE PROCEDURE MakeSOAPVisibleToPatient (
    IN summaryID VARCHAR(255),
    IN PatientID VARCHAR(255)
)
BEGIN
    UPDATE AfterVisitSummary
	SET VisibleToPatient = TRUE
	WHERE SummaryID = summaryID 
	AND PatientID = PatientID	AND VisibleToPatient = FALSE;
        
    SELECT 'SOAP Summary made visible to Patient.' AS MESSAGE;
END //
DELIMITER ;

-- PRESCRIBE MEDICATION
DELIMITER //
CREATE PROCEDURE PrescribeMedication (
	IN pPrescriptionID VARCHAR(50),
	IN pDrugName VARCHAR(100),
	IN pDosage NUMERIC(10,2),
	IN pQuantity NUMERIC(10,2),
	IN pStartDate DATETIME,
	IN pEndDate DATETIME,
	IN pRefill BOOLEAN,
	IN pPharmacyID VARCHAR(50),
	IN pPatientID VARCHAR(50),
	IN pPlanID VARCHAR(50),
	IN pPhysicianID VARCHAR(50),
	IN pFrequency VARCHAR(100)
)
BEGIN
    -- Insert prescription into the Prescription table
	INSERT INTO Prescription (
    	PrescriptionID, DateOfIssue, DeliveryMethod, Refill, PharmacyID, PatientID, PlanID, PhysicianID
	) VALUES (
    	pPrescriptionID, NOW(), 'Oral', pRefill, pPharmacyID, pPatientID, pPlanID, pPhysicianID
	);

    -- Insert medication into the Medication table
	INSERT INTO Medication (
    	PrescriptionMedID, PrescriptionID, MedicationName, MedicationStrength, Quantity, StartDate, EndDate, DirectionsForUse
	) VALUES (
    	uuid(), pPrescriptionID, pDrugName, CONCAT(pDosage, ' mg'), pQuantity, pStartDate, pEndDate, pFrequency
	);
END //

DELIMITER ;

-- ENTER Lab TEST RESULT
DELIMITER // 
CREATE PROCEDURE EnterLabResult(
	IN pLabResultID VARCHAR(50),
	IN pObjectiveDataID VARCHAR(50),
	IN pTestName VARCHAR(100),
	IN pResult NUMERIC(10,2),
	IN pUnit VARCHAR(20),
	IN pTestDate DATETIME,
	IN pOrderID VARCHAR(255),
	IN pStaffID VARCHAR(255)
)
BEGIN
	INSERT INTO Lab (
    	LabID, ObjectiveDataID, TestName, ResultValue, Units, ResultDate, OrderID, StaffID, LabStatus
	)
	VALUES (
    	pLabResultID, pObjectiveDataID, pTestName, pResult, pUnit, pTestDate, pOrderID, pStaffID, 'Pending'
        );
END //
DELIMITER ;

-- CREATE Lab ORDER
DELIMITER //

CREATE PROCEDURE CreateLabOrder(
	IN pOrderID VARCHAR(50),
	IN pPlanID VARCHAR(50),
	IN pOrderType VARCHAR(50),
	IN pDetails VARCHAR(255),
	IN pDateScheduled DATETIME,
	IN pOrderStatus ENUM('Pending', 'Completed', 'Cancelled') -- Ensuring valID ENUM status
)
BEGIN
	INSERT INTO Orders (
    	OrderID, PlanID, OrderType, Details, DateScheduled, DateDone, OrderStatus
	)
	VALUES (
    	pOrderID, pPlanID, pOrderType, pDetails, pDateScheduled, NULL, pOrderStatus
	);
END //

DELIMITER ;

-- ADD SUBJECTIVE DATA TO SOAP DOC
DELIMITER //

CREATE PROCEDURE AddSubjectiveData(
    IN pSubjectiveDataID VARCHAR(50),
    IN pSummaryID VARCHAR(50),
    IN pCC VARCHAR(255),
    IN pHPI VARCHAR(255)
)
BEGIN
    INSERT INTO SubjectiveData (SubjectiveDataID, SummaryID, CC, HPI)
    VALUES (pSubjectiveDataID, pSummaryID, pCC, pHPI);

END //

DELIMITER ;

-- ADD OBJECTIVE DATA TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddObjectiveData(
    IN pSummaryID VARCHAR(50),
    IN pObjectiveDataID VARCHAR(50)
)
BEGIN
    INSERT INTO ObjectiveData (ObjectiveDataID, SummaryID)
    VALUES (pObjectiveDataID, pSummaryID);
    
END //
DELIMITER ;

-- ADD Assessment TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddAssessment(
	IN pAssessmentID VARCHAR(255),
	IN pSummaryID VARCHAR(255),
	IN pAssessment VARCHAR(255)
)
BEGIN
	INSERT INTO Assessment (AssessmentID, SummaryID, Assessment)
	VALUES (pAssessmentID, pSummaryID, pAssessment);
END //
DELIMITER ;

-- ADD Plan TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddPlan(
	IN pPlanID VARCHAR(255),
	IN pSummaryID VARCHAR(255),
	IN pCreatedDate DATETIME,
	IN pFollowUp BOOLEAN,
	IN pPlanStatus ENUM("Active", "Completed"),
	IN pNotes VARCHAR(255)
)
BEGIN
	INSERT INTO Plan (
		PlanID, SummaryID, CreatedDate, FollowUp, PlanStatus, Notes
	)
	VALUES (
		pPlanID, pSummaryID, pCreatedDate, pFollowUp, pPlanStatus, pNotes
	);
END //
DELIMITER ;

-- ADD Vitals TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddVitals(
	IN pVitalsID VARCHAR(255),
	IN pObjectiveDataID VARCHAR(255),
	IN pVitalsDate DATETIME,
	IN pBloodPressure VARCHAR(20),
	IN pHeartRate NUMERIC,
	IN pTemp NUMERIC(5, 3)
)
BEGIN
	INSERT INTO Vitals (
		VitalsID, ObjectiveDataID, VitalsDate, BloodPressure, HeartRate, Temp
	)
	VALUES (
		pVitalsID, pObjectiveDataID, pVitalsDate, pBloodPressure, pHeartRate, pTemp
	);
END //
DELIMITER ;

-- CREATE Bed
DELIMITER //
CREATE PROCEDURE CreateBed (
	IN pBedID VARCHAR(50),
	IN pBedType VARCHAR(50),
	IN pDeptID VARCHAR(50)
)
BEGIN
	IF EXISTS (SELECT 1 FROM Bed WHERE BedID = pBedID) THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed ID already exists';
	END IF;

	IF pBedType NOT IN ('General', 'ICU', 'CCU', 'Pediatric', 'Maternity', 'Surgical',
                      	'Trauma', 'Birthing', 'Psychiatric', 'Geriatric', 'Transport',
                      	'Step-Down', 'Rehabilitation', 'Isolation', 'Burn Unit') THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'InvalID Bed Type';
	END IF;

	INSERT INTO Bed (BedID, BedType, DeptID, PatientID)
	VALUES (pBedID, pBedType, pDeptID, NULL);
END //
DELIMITER ;

-- DELETE Bed
DELIMITER //
CREATE PROCEDURE DeleteBed (
	IN pBedID VARCHAR(50)
)
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Bed WHERE BedID = pBedID) THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed ID does not exist';
	END IF;

	IF EXISTS (SELECT 1 FROM Bed WHERE BedID = pBedID AND PatientID IS NOT NULL) THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete Bed: It is currently assigned to a Patient.';
	END IF;

	DELETE FROM Bed WHERE BedID = pBedID;

END //
DELIMITER ;

-- MODIFY Bed
DELIMITER //
CREATE PROCEDURE ModifyBed (
	IN pBedID VARCHAR(50),
	IN pNewBedType VARCHAR(50),
	IN pNewDeptID VARCHAR(50)
)
BEGIN
    IF pNewBedType NOT IN ('General', 'ICU', 'CCU', 'Pediatric', 'Maternity', 'Surgical',
                           'Trauma', 'Birthing', 'Psychiatric', 'Geriatric', 'Transport',
                           'Step-Down', 'Rehabilitation', 'Isolation', 'Burn Unit') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'InvalID Bed Type';
    END IF;
	UPDATE Bed
	SET BedType = pNewBedType,
    	DeptID = pNewDeptID
	WHERE BedID = pBedID;
END //
DELIMITER ;






-- CREATE Physician SHIFT
DELIMITER //

CREATE PROCEDURE AddPhysicianShift (
    IN pShiftID VARCHAR(50),
    IN pPhysicianID VARCHAR(50),
    IN pStaffID VARCHAR(50),
    IN pDeptID VARCHAR(50),
    IN pShiftStart DATETIME,
    IN pShiftEnd DATETIME,
    IN pShiftType VARCHAR(50)
)
BEGIN
    DECLARE vPhysicianExists INT DEFAULT 0;
    DECLARE vShiftExists INT DEFAULT 0;
    DECLARE vStaffInDept INT DEFAULT 0;

    START TRANSACTION;

    -- Check if the shift already exists for the physician during the provIDed time
    SELECT COUNT(*)
    INTO vShiftExists
    FROM PhysicianShift
    WHERE PhysicianID = pPhysicianID
      AND ((pShiftStart BETWEEN ShiftStartTime AND ShiftEndTime)
      OR (pShiftEnd BETWEEN ShiftStartTime AND ShiftEndTime)
      OR (ShiftStartTime BETWEEN pShiftStart AND pShiftEnd));

    -- Error if shift already exists
    IF vShiftExists > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This Physician already has a shift scheduled during this time';
    END IF;

    -- Insert the new shift tuple
    INSERT INTO PhysicianShift (
        ShiftID,
        PhysicianID,
        StaffID,
        DeptID,
        ShiftStartTime,
        ShiftEndTime,
        ShiftType
    )
    VALUES (
        pShiftID,
        pPhysicianID,
        pStaffID,
        pDeptID,
        pShiftStart,
        pShiftEnd,
        pShiftType
    );
    COMMIT;
END //
DELIMITER ;


-- DELETE Physician SHIFT
DELIMITER //
CREATE PROCEDURE DeletePhysicianShift (
	IN pShiftID VARCHAR(50)
)
BEGIN
	DECLARE vshiftexists INT DEFAULT 0;

	SELECT COUNT(*)
	INTO vshiftexists
	FROM PhysicianShift
	WHERE ShiftID = pShiftID;

	IF vshiftexists = 0 THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'ShiftID does not exist';
	END IF;

	START TRANSACTION;
	DELETE FROM PhysicianShift
	WHERE ShiftID = pShiftID;
	COMMIT;
END //
DELIMITER ;


-- MODIFY Physician SHIFT
DELIMITER //
CREATE PROCEDURE ModifyPhysicianShift (
    IN pShiftID VARCHAR(50),
    IN pShiftStart DATETIME,
    IN pShiftEnd DATETIME,
    IN pShiftType VARCHAR(50)
)
BEGIN
    DECLARE vShiftExists INT DEFAULT 0;
    DECLARE vShiftOverlap INT DEFAULT 0;

    -- Check if the shift exists
    SELECT COUNT(*)
    INTO vShiftExists
    FROM PhysicianShift
    WHERE ShiftID = pShiftID;

    IF vShiftExists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ShiftID does not exist';
    END IF;

    -- Check if the new shift time overlaps with any existing shifts
    SELECT COUNT(*)
    INTO vShiftOverlap
    FROM PhysicianShift
    WHERE PhysicianID = (SELECT PhysicianID FROM PhysicianShift WHERE ShiftID = pShiftID)
      AND ((pShiftStart BETWEEN ShiftStartTime AND ShiftEndTime)
      OR (pShiftEnd BETWEEN ShiftStartTime AND ShiftEndTime)
      OR (ShiftStartTime BETWEEN pShiftStart AND pShiftEnd))
      AND ShiftID != pShiftID; -- Make sure not to check against itself

    IF vShiftOverlap > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The new shift time overlaps with an existing shift';
    END IF;

    START TRANSACTION;

    UPDATE PhysicianShift
    SET ShiftStartTime = pShiftStart,
        ShiftEndTime = pShiftEnd,
        ShiftType = pShiftType
    WHERE ShiftID = pShiftID;

    COMMIT;
END //
DELIMITER ;

-- VIEW Physician AVAILabILITY
DELIMITER //
CREATE PROCEDURE GetPhysicianAvailability (
    IN pPhysicianID VARCHAR(50)
)
BEGIN
    -- Retrieve available time slots for the physician
    SELECT SlotID, StartTime, EndTime
    FROM TimeSlot
    WHERE PhysicianID = pPhysicianID AND Available = TRUE
    ORDER BY StartTime;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No available slots for this physician';
    END IF;
END //

DELIMITER ;

-- VIEW ROSTER (who’s on duty/call)
DELIMITER //
CREATE PROCEDURE GetRoster()
BEGIN
    -- Query on Nurses
    SELECT 
        N.NurseID AS StaffID,
        U.FirstName,
        U.LastName,
        'Nurse' AS StaffType,
        NULL AS PhysicianType,
        NULL AS PhysicianRank,
        NULL AS Specialization,
        D.DeptName
    FROM Nurse N
    JOIN User U ON N.UserID = U.UserID  -- Join with User table to get first and last name
    JOIN NurseDepartment ND ON N.NurseID = ND.NurseID  -- Join NurseDepartment to get DeptID
    JOIN Department D ON ND.DeptID = D.DeptID  -- Get Department name

    UNION ALL

    -- Query on Physicians
    SELECT 
        P.PhysicianID AS StaffID,
        U.FirstName,
        U.LastName,
        'Physician' AS StaffType,
        P.PhysicianType,
        PR.RankName AS PhysicianRank, 
        S.Specialization,
        D.DeptName
    FROM Physician P
    JOIN User U ON P.UserID = U.UserID  -- Join with User table for names
    JOIN PhysicianDepartment PD ON P.PhysicianID = PD.PhysicianID  -- Join PhysicianDepartment to get Dept
    JOIN Department D ON PD.DeptID = D.DeptID  -- Get Department name
    LEFT JOIN PhysicianRanks PR ON P.PhysicianRankID = PR.RankID  -- Join PhysicianRanks for rank
    LEFT JOIN PhysicianSpecializations PS ON P.PhysicianID = PS.PhysicianID  -- Join PhysicianSpecializations for specialization
    LEFT JOIN Specializations S ON PS.SpecializationID = S.SpecializationID;  -- Join Specializations for specialization name
END //
DELIMITER ;


-- ADD/MODIFY Patient PROFILE
DELIMITER //
CREATE PROCEDURE AddOrUpdatePatientProfile (
    IN pPatientID VARCHAR(50),
    IN pUserID VARCHAR(50),   
    IN pInsurancePlanID VARCHAR(50)
)
BEGIN
    INSERT INTO Patient (PatientID, UserID, InsurancePlanID)
    VALUES (pPatientID, pUserID, pInsurancePlanID)
    ON DUPLICATE KEY UPDATE
        PatientID = pPatientID,  -- optional, only if you want to update the ID
        InsurancePlanID = pInsurancePlanID;
END //
DELIMITER ;

-- UPDATE Patient ADDRESS
DELIMITER //
CREATE PROCEDURE updatePatientAddress (
	IN pPatientID VARCHAR(50),
	IN pNewAddress VARCHAR(255)
)
BEGIN
	UPDATE Patient
	SET PatientAddress = pNewAddress
	WHERE PatientID = pPatientID;
END //
DELIMITER ;


-- MODIFY Patient INSURANCE
DELIMITER // 
CREATE PROCEDURE UpdatePatientInsurance(
	IN pPatientID VARCHAR(50), 
	IN pInsurancePlanID VARCHAR(50))
BEGIN
	UPDATE Patient
	SET InsurancePlanID = pInsurancePlanID
	WHERE PatientID = pPatientID; 
END // 
DELIMITER ; 



DELIMITER //

CREATE PROCEDURE AddPhysician (
    IN pUserID VARCHAR(50),
    IN pPhysicianID VARCHAR(50),
    IN pPhysicianType VARCHAR(50),
    IN pPhysicianRankID VARCHAR(50),
    IN pDeptID VARCHAR(50),
    IN pSpecializationID VARCHAR(50)
)
BEGIN
    DECLARE existingPhysicianID VARCHAR(50);
    
    -- Start a transaction
    START TRANSACTION;

    -- Check if the physician already exists with the provided UserID
    SELECT PhysicianID INTO existingPhysicianID
    FROM Physician
    WHERE UserID = pUserID
    LIMIT 1;

    -- If the physician exists, update the PhysicianID if necessary
    IF existingPhysicianID IS NOT NULL THEN
        -- Optionally update PhysicianID if it's different from the provided one
        IF existingPhysicianID != pPhysicianID THEN
            UPDATE Physician
            SET PhysicianID = pPhysicianID,
                PhysicianType = pPhysicianType,
                PhysicianRankID = pPhysicianRankID
            WHERE UserID = pUserID;
        END IF;
    ELSE
        -- If the physician doesn't exist, insert a new record
        INSERT INTO Physician (PhysicianID, UserID, PhysicianType, PhysicianRankID)
        VALUES (pPhysicianID, pUserID, pPhysicianType, pPhysicianRankID);
    END IF;

    -- Insert or update the PhysicianDepartment record
    INSERT INTO PhysicianDepartment (PhysicianID, DeptID)
    VALUES (pPhysicianID, pDeptID)
    ON DUPLICATE KEY UPDATE DeptID = pDeptID;

    -- Insert or update the PhysicianSpecializations record
    INSERT INTO PhysicianSpecializations (PhysicianID, SpecializationID)
    VALUES (pPhysicianID, pSpecializationID)
    ON DUPLICATE KEY UPDATE SpecializationID = pSpecializationID;

    -- Commit the transaction
    COMMIT;

END //
DELIMITER ;

-- ADD Nurse
DELIMITER //

CREATE PROCEDURE AddNurse (
    IN pUserID VARCHAR(50),
    IN pNurseID VARCHAR(50),
    IN pDeptID VARCHAR(50)
)
BEGIN
    DECLARE existingNurseID VARCHAR(50);
    
    -- Start a transaction
    START TRANSACTION;

    -- Check if the nurse already exists with the provided UserID
    SELECT NurseID INTO existingNurseID
    FROM Nurse
    WHERE UserID = pUserID
    LIMIT 1;

    -- If the nurse exists, update the NurseID if necessary
    IF existingNurseID IS NOT NULL THEN
        -- Optionally update NurseID if it's different from the provided one
        IF existingNurseID != pNurseID THEN
            UPDATE Nurse
            SET NurseID = pNurseID
            WHERE UserID = pUserID;
        END IF;
    ELSE
        -- If the nurse doesn't exist, insert a new record
        INSERT INTO Nurse (NurseID, UserID)
        VALUES (pNurseID, pUserID);
    END IF;

    -- Insert or update the NurseDepartment record
    INSERT INTO NurseDepartment (NurseDeptID, NurseID, DeptID)
    VALUES (CONCAT(pNurseID, '_', pDeptID), pNurseID, pDeptID)
    ON DUPLICATE KEY UPDATE NurseID = pNurseID;

    -- Commit the transaction
    COMMIT;

END //
DELIMITER ;

-- ADD Staff
DELIMITER //
CREATE PROCEDURE AddStaff (
    IN pUserID VARCHAR(50),
    IN pStaffID VARCHAR(50),
    IN pStaffRole VARCHAR(50),
    IN pDeptID VARCHAR(50)
)
BEGIN
    START TRANSACTION;
       INSERT INTO Staff (
        StaffID, UserID, StaffRole, DeptID
    )
    VALUES (
        pStaffID, pUserID, pStaffRole, pDeptID
    );

    COMMIT;
END //

DELIMITER ;


-- ADD Nurse SHIFT 
DELIMITER //
CREATE PROCEDURE AddNurseShift (
	IN pShiftID VARCHAR(50),
	IN pNurseID VARCHAR(50),
	IN pStaffID VARCHAR(50),
	IN pDeptID VARCHAR(50),
	IN pShiftStart DATETIME,
	IN pShiftEnd DATETIME,
	IN pShiftType VARCHAR(50)
)
BEGIN
	DECLARE vNurseexists INT DEFAULT 0;
	DECLARE vshiftexists INT DEFAULT 0;

	START TRANSACTION;

	IF vshiftexists > 0 THEN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'This Nurse already has a shift during this time';
	END IF;

	INSERT INTO NurseShift (
		ShiftID, NurseID, StaffID, DeptID, ShiftStartTime, ShiftEndTime, ShiftType
	)
	VALUES (
		pShiftID, pNurseID, pStaffID, pDeptID, pShiftStart, pShiftEnd, pShiftType
	);

	COMMIT;
END //
DELIMITER ;

-- DELETE Nurse SHIFT
DELIMITER //
CREATE PROCEDURE DeleteNurseShift (
	IN pShiftID VARCHAR(50)
)
BEGIN
	DECLARE vshiftexists INT DEFAULT 0;

	SELECT COUNT(*) INTO vshiftexists
	FROM NurseShift
	WHERE ShiftID = pShiftID;

	IF vshiftexists = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'ShiftID does not exist';
	END IF;

	START TRANSACTION;

	DELETE FROM NurseShift
	WHERE ShiftID = pShiftID;

	COMMIT;
END //
DELIMITER ;


-- MODIFY Nurse SHIFT
DELIMITER //
CREATE PROCEDURE ModifyNurseShift (
	IN pShiftID VARCHAR(50),
	IN pShiftStart DATETIME,
	IN pShiftEnd DATETIME,
	IN pShiftType VARCHAR(50)
)
BEGIN
	DECLARE vshiftexists INT DEFAULT 0;

	SELECT COUNT(*) INTO vshiftexists
	FROM NurseShift
	WHERE ShiftID = pShiftID;

	IF vshiftexists = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'ShiftID does not exist';
	END IF;

	START TRANSACTION;

	UPDATE NurseShift
	SET ShiftStartTime = pShiftStart,
		ShiftEndTime = pShiftEnd,
		ShiftType = pShiftType
	WHERE ShiftID = pShiftID;

	COMMIT;
END //
DELIMITER ;


-- VIEW OUTSTANDING BALANCES FOR A Patient 
DELIMITER //
CREATE PROCEDURE PatientOutstandingBills(
    IN pPatientID VARCHAR(50)
)
BEGIN
    -- Select all Bills (given a Patient) that aren't PaID
    SELECT 
        BillID, 
        BalanceDue, 
        PaymentStatus
    FROM 
        Bill
    WHERE 
        PatientID = pPatientID 
        AND PaymentStatus IN ('Pending', 'Overdue');
END //
DELIMITER ;





-- Muskan stored procedures

-- Get all Lab results for a Patient
DELIMITER //
CREATE PROCEDURE GetAllLabResults (
    IN in_PatientID VARCHAR(255)
)
BEGIN
    SELECT l.*
    FROM Lab l
    JOIN Orders o ON l.OrderID = o.OrderID
    WHERE o.PatientID = in_PatientID
    ORDER BY l.ResultDate DESC;
END //
DELIMITER ;


-- Get lab result details by LabID
DELIMITER //
CREATE PROCEDURE GetLabResultDetails (
    IN in_LabID VARCHAR(255)
)
BEGIN
    SELECT *
    FROM Lab
    WHERE LabID = in_LabID;
END //
DELIMITER ;


-- Get Lab results by Status
DELIMITER //
CREATE PROCEDURE GetLabResultsByStatus (
    IN in_PatientID VARCHAR(255),
    IN in_LabStatus VARCHAR(50)
)
BEGIN
    SELECT l.*
    FROM Lab l
    JOIN Orders o ON l.OrderID = o.OrderID
    WHERE o.PatientID = in_PatientID AND l.LabStatus = in_LabStatus
    ORDER BY l.ResultDate DESC;
END //
DELIMITER ;



-- Update Prescription Status
DELIMITER //
CREATE PROCEDURE UpdatePrescriptionStatus (
    IN in_PrescriptionID VARCHAR(255),
    IN in_Status VARCHAR(50)
)
BEGIN
    UPDATE Prescription
    SET PrescriptionStatus = in_Status
    WHERE PrescriptionID = in_PrescriptionID;
END //

DELIMITER ;

-- View All Prescription for a Patient (sorted by date)
DELIMITER //

CREATE PROCEDURE GetPrescriptionsByPatient (
    IN in_PatientID VARCHAR(255)
)
BEGIN
    SELECT 
        PrescriptionID,
        DateOfIssue,
        DeliveryMethod,
        Refill,
        PharmacyID,
        PatientID,
        PlanID,
        PhysicianID,
        PrescriptionStatus
    FROM Prescription
    WHERE PatientID = in_PatientID
    ORDER BY DateOfIssue DESC;
END //
DELIMITER ;


-- Change Delivery Method
DELIMITER //
CREATE PROCEDURE UpdateDeliveryMethod (
    IN in_PrescriptionID VARCHAR(255),
    IN in_Method VARCHAR(50)
)
BEGIN
    UPDATE Prescription
    SET DeliveryMethod = in_Method
    WHERE PrescriptionID = in_DeliveryID;
END //
DELIMITER ;

-- View all prescrptions for delivery
DELIMITER //

CREATE PROCEDURE GetPrescriptionsForDelivery ()
BEGIN
    SELECT 
        PrescriptionID,
        DateOfIssue,
        DeliveryMethod,
        Refill,
        PharmacyID,
        PatientID,
        PlanID,
        PhysicianID,
        PrescriptionStatus
    FROM Prescription 
    WHERE DeliveryMethod = 'Delivery';
END //

DELIMITER ;

-- Create a new notificaton for a user

DELIMITER //
CREATE PROCEDURE AddNotification (
    IN in_PatientID VARCHAR(255),    
    IN in_MessageContent TEXT,
    IN in_StatusID INT, 
    IN in_PriorityID INT 
)
BEGIN
    INSERT INTO Notification (
        NotificationID,
        UserID,
        MessageContent,
        DateCreated,
        StatusID,
        PriorityID
    )
    VALUES (
            UUID(),  -- auto-generate NotificationID
            in_UserID,
            in_MessageContent,
            NOW(),
            in_StatusID,
            in_PriorityID
        );
END //
DELIMITER ;



-- View All Notifications for a User (Newest First)
DELIMITER //
CREATE PROCEDURE GetNotificationsByUser (
    IN in_UserID VARCHAR(255)
)
BEGIN
    SELECT 
        n.NotificationID,
        n.MessageContent,
        n.DateCreated,
        ns.StatusName,
        np.PriorityName
    FROM Notification n
    JOIN NotificationStatus ns ON n.StatusID = ns.StatusID
    JOIN NotificationPriority np ON n.PriorityID = np.PriorityID
    WHERE n.UserID = in_UserID
    ORDER BY n.DateCreated DESC;
END //
DELIMITER ;

-- Get unread Notifications
DELIMITER //
CREATE PROCEDURE GetUnreadNotifications (
    IN in_UserID VARCHAR(255)
)
BEGIN
    SELECT 
        n.NotificationID,
        n.MessageContent,
        n.DateCreated,
        ns.StatusName,
        np.PriorityName
    FROM Notification n
    JOIN NotificationStatus ns ON n.StatusID = ns.StatusID
    JOIN NotificationPriority np ON n.PriorityID = np.PriorityID
    WHERE n.UserID = in_UserID AND ns.StatusName = 'Unread'
    ORDER BY n.DateCreated DESC;
END //
DELIMITER ;


-- Update Notification status
DELIMITER //
CREATE PROCEDURE UpdateNotificationStatus (
    IN in_NotificationID VARCHAR(255), 
    IN in_StatusID INT
)
BEGIN
    UPDATE Notification
    SET StatusID = in_StatusID
    WHERE NotificationID = in_NotificationID;
END //
DELIMITER ;


-- Mark all Notifications as Read
DELIMITER //
CREATE PROCEDURE MarkAllNotificationsRead (
    IN in_UserID VARCHAR(255)
)
BEGIN
    UPDATE Notification
    SET StatusID = (
        SELECT StatusID FROM NotificationStatus WHERE StatusName = 'Read'
    )
    WHERE UserID = in_UserID AND StatusID = (
        SELECT StatusID FROM NotificationStatus WHERE StatusName = 'Unread'
    );
END //
DELIMITER ;



-- Nick stored procedures



DELIMITER //

CREATE PROCEDURE AddUserProfile(
    IN p_UserID VARCHAR(50),
    IN p_Username VARCHAR(255),
    IN p_FirstName VARCHAR(255),
    IN p_LastName VARCHAR(255),
    IN p_Email VARCHAR(255),
    IN p_PasswordHash VARCHAR(255),
    IN p_RoleID VARCHAR(50),
    IN p_Phone VARCHAR(20),
    IN p_Gender VARCHAR(20),
    IN p_Sex VARCHAR(20),
    IN p_DOB DATE
)
BEGIN
    DECLARE v_PatientID VARCHAR(50);
    DECLARE v_PhysicianID VARCHAR(50);
    DECLARE v_NurseID VARCHAR(50);
    DECLARE v_AdminID VARCHAR(50);

    START TRANSACTION;

    -- Check for duplicate username
    IF EXISTS (SELECT 1 FROM User WHERE Username = p_Username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username is already taken.';
    END IF;

    -- Check for duplicate email
    IF EXISTS (SELECT 1 FROM User WHERE Email = p_Email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email is already registered.';
    END IF;

    -- ValIDate RoleID
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleID = p_RoleID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'InvalID role selected.';
    END IF;

    -- Insert into User table
    INSERT INTO User (
        UserID, Username, FirstName, LastName, Email, PasswordHash,
        RoleID, Phone, Gender, Sex, DOB
    )
    VALUES (
        p_UserID, p_Username, p_FirstName, p_LastName, p_Email, p_PasswordHash,
        p_RoleID, p_Phone, p_Gender, p_Sex, p_DOB
    );

    -- Role-specific inserts
    CASE p_RoleID
        WHEN 'R1' THEN
            SET v_PatientID = uuid();
            INSERT INTO Patient (PatientID, UserID) VALUES (v_PatientID, p_UserID);
        WHEN 'R2' THEN
            SET v_PhysicianID = uuid();
            INSERT INTO Physician (PhysicianID, UserID) VALUES (v_PhysicianID, p_UserID);
        WHEN 'R3' THEN
            SET v_NurseID = uuid();
            INSERT INTO Nurse (NurseID, UserID) VALUES (v_NurseID, p_UserID);
        WHEN 'R4' THEN
            SET v_AdminID = uuid();
            INSERT INTO Admin (AdminID, UserID) VALUES (v_AdminID, p_UserID);
    END CASE;
    COMMIT;
END //
DELIMITER ;




DELIMITER //

CREATE PROCEDURE VerifyUserLogin(
    IN p_Username VARCHAR(255)
)
BEGIN
    SELECT 
        u.UserID,
        u.Username,
        u.PasswordHash,
        r.RoleName,
        u.FirstName,
        u.LastName
    FROM User u
    JOIN Roles r ON u.RoleID = r.RoleID
    WHERE u.Username = p_Username;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE CheckUsernameExists(
    IN p_Username VARCHAR(255)
)
BEGIN
    SELECT COUNT(*) AS UserCount
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
-- DROP Procedure CompletePhysicianProfile;
DELIMITER //
CREATE PROCEDURE CompletePhysicianProfile(
    IN p_UserID VARCHAR(50),
    IN p_DeptIDs TEXT,
    IN p_PhysicianType VARCHAR(255),
    IN p_PhysicianRankID VARCHAR(50),
    IN p_SpecializationID VARCHAR(50)
)
BEGIN
    DECLARE physicianID VARCHAR(50);
    DECLARE DeptID VARCHAR(50);
    DECLARE done INT DEFAULT FALSE;

    DECLARE dept_cursor CURSOR FOR
        SELECT value FROM JSON_TABLE(p_DeptIDs, '$[*]' COLUMNS(value VARCHAR(50) PATH '$')) AS jt;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    START TRANSACTION;

    -- Debug: Check if UserID exists in Physician
    SELECT PhysicianID INTO physicianID
    FROM Physician
    WHERE UserID = p_UserID;

    IF physicianID IS NULL THEN
        -- Abort if no matching PhysicianID found
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No Physician record found for provided UserID';
    END IF;

    -- Debug print
    SELECT CONCAT('DEBUG: Found PhysicianID = ', physicianID);

    -- Update Physician profile fields
    UPDATE Physician
    SET PhysicianType = p_PhysicianType, PhysicianRankID = p_PhysicianRankID
    WHERE PhysicianID = physicianID;

    -- Delete existing department links
    DELETE FROM PhysicianDepartment WHERE PhysicianID = physicianID;

    -- Insert new department links
    OPEN dept_cursor;
    dept_loop: LOOP
        FETCH dept_cursor INTO DeptID;
        IF done THEN LEAVE dept_loop; END IF;
        INSERT INTO PhysicianDepartment (PhysicianID, DeptID)
        VALUES (physicianID, DeptID);
    END LOOP;
    CLOSE dept_cursor;

    -- Update specialization
    DELETE FROM PhysicianSpecializations WHERE PhysicianID = physicianID;
    INSERT INTO PhysicianSpecializations (PhysicianID, SpecializationID)
    VALUES (physicianID, p_SpecializationID);

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
    IN p_PhysicianID VARCHAR(50),
    IN p_Mode VARCHAR(20)
)
BEGIN
    SELECT 
        a.ApptID, 
        p.FirstName AS PatientFirstName, 
        p.LastName AS PatientLastName, 
        d.DeptName, 
        a.ApptDate, 
        at.TypeName, 
        a.ApptStatus
    FROM Appointment a
    JOIN Patient pt ON a.PatientID = pt.PatientID
    JOIN User p ON pt.UserID = p.UserID
    JOIN Department d ON a.DeptID = d.DeptID
    JOIN AppointmentTypes at ON a.TypeID = at.TypeID
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
    IN p_SlotID VARCHAR(50), 
    IN p_DeptID VARCHAR(50), 
    IN p_PhysicianID VARCHAR(50), 
    IN p_StartTime DATETIME, 
    IN p_EndTime DATETIME
)
BEGIN
    -- Insert a new time slot into the TimeSlot table
    INSERT INTO TimeSlot (SlotID, DeptID, PhysicianID, StartTime, EndTime, Available) 
    VALUES (p_SlotID, p_DeptID, p_PhysicianID, p_StartTime, p_EndTime, TRUE);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetPatientAppointments(
    IN p_PatientID VARCHAR(50),
    IN p_Mode VARCHAR(20)
)
BEGIN
    IF p_Mode = 'upcoming' THEN
        SELECT 
            a.ApptID,
            d.DeptName AS DeptName,
            CONCAT(doc.FirstName, ' ', doc.LastName) AS PhysicianName,
            a.ApptDate,
            at.TypeName AS TypeName,
            a.ApptStatus
        FROM Appointment a
        JOIN Department d ON a.DeptID = d.DeptID
        JOIN Physician p ON a.PhysicianID = p.PhysicianID
        JOIN User doc ON p.UserID = doc.UserID
        JOIN AppointmentTypes at ON a.TypeID = at.TypeID
        WHERE a.PatientID = p_PatientID
          AND a.ApptDate >= NOW()
        ORDER BY a.ApptDate ASC;

    ELSEIF p_Mode = 'past' THEN
        SELECT 
            a.ApptID,
            d.DeptName AS DeptName,
            CONCAT(doc.FirstName, ' ', doc.LastName) AS PhysicianName,
            a.ApptDate,
            at.TypeName AS TypeName,
            a.ApptStatus
        FROM Appointment a
        JOIN Department d ON a.DeptID = d.DeptID
        JOIN Physician p ON a.PhysicianID = p.PhysicianID
        JOIN User doc ON p.UserID = doc.UserID
        JOIN AppointmentTypes at ON a.TypeID = at.TypeID
        WHERE a.PatientID = p_PatientID
          AND a.ApptDate < NOW()
        ORDER BY a.ApptDate DESC;
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetAppointmentDetails(
    IN p_ApptID VARCHAR(50))
BEGIN
    SELECT 
        a.ApptID, CONCAT(u.FirstName, ' ', u.LastName) AS PhysicianName, d.DeptName,
        d.DeptID, at.TypeName, a.ApptDate, a.ApptStatus
    FROM Appointment a JOIN Physician p ON a.PhysicianID = p.PhysicianID
    JOIN User u ON p.UserID = u.UserID JOIN Department d ON a.DeptID = d.DeptID
    JOIN AppointmentTypes at ON a.TypeID = at.TypeID
    WHERE a.ApptID = p_ApptID;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE InsertNurseDepartment(
    IN p_NurseID VARCHAR(50), IN p_DeptID VARCHAR(50))
BEGIN
    INSERT INTO NurseDepartment (NurseDeptID, NurseID, DeptID) VALUES (uuid(), p_NurseID, p_DeptID);
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE GetAllClinics()
BEGIN
    SELECT ClinicID, ClinicName 
    FROM Clinic
    ORDER BY 
        CASE 
            WHEN ClinicName REGEXP '^[a-zA-Z]' THEN 0
            ELSE 1
        END,
        ClinicName ASC;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE AddClinic(
    IN p_ClinicID VARCHAR(50), IN p_ClinicName VARCHAR(255))
BEGIN
    INSERT INTO Clinic (ClinicID, ClinicName) VALUES (p_ClinicID, p_ClinicName);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE EditDepartment(
    IN p_DeptID VARCHAR(255), IN p_NewName VARCHAR(255))
BEGIN
    UPDATE Department SET DeptName = p_NewName
    WHERE DeptID = p_DeptID;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE EditClinic(
    IN p_ClinicID VARCHAR(255), IN p_NewName VARCHAR(255))
BEGIN
    UPDATE Clinic SET ClinicName = p_NewName
    WHERE ClinicID = p_ClinicID;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetAllDepartments()
BEGIN
    SELECT 
        d.DeptID, d.DeptName, 
        GROUP_CONCAT(c.ClinicName ORDER BY c.ClinicName SEPARATOR ', ') AS ClinicNames
    FROM Department d 
    LEFT JOIN ClinicDepartment cd ON d.DeptID = cd.DeptID
    LEFT JOIN Clinic c ON cd.ClinicID = c.ClinicID 
    GROUP BY d.DeptID, d.DeptName
    ORDER BY 
        CASE 
            WHEN d.DeptName REGEXP '^[a-zA-Z]' THEN 0
            ELSE 1
        END,
        d.DeptName ASC;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE AddDepartment(
    IN p_DeptID VARCHAR(50), IN p_DeptName VARCHAR(255), IN p_ClinicID VARCHAR(255))
BEGIN
    START TRANSACTION;
    INSERT INTO Department (DeptID, DeptName) VALUES (p_DeptID, p_DeptName);
    INSERT INTO ClinicDepartment (DeptID, ClinicID) VALUES (p_DeptID, p_ClinicID);
    -- Commit the transaction if both inserts are successful
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
    INSERT INTO Specializations (SpecializationID, Specialization) VALUES (p_SpecID, p_Name);
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE EditSpecialization(
    IN p_SpecID VARCHAR(50), IN p_NewName VARCHAR(255))
BEGIN
    UPDATE Specializations
    SET Specialization = p_NewName WHERE SpecializationID = p_SpecID;
END //
DELIMITER ;


DELIMITER //

CREATE PROCEDURE GetUsersWithSpecializations()
BEGIN
    SELECT * FROM (
        SELECT 
            u.Username, u.FirstName, u.LastName, 'Physician' AS Role,
            GROUP_CONCAT(s.Specialization ORDER BY s.Specialization SEPARATOR ', ') AS Specializations
        FROM Physician p 
        JOIN User u ON p.UserID = u.UserID 
        LEFT JOIN PhysicianSpecializations ps ON p.PhysicianID = ps.PhysicianID
        LEFT JOIN Specializations s ON ps.SpecializationID = s.SpecializationID 
        GROUP BY u.UserID, u.Username, u.FirstName, u.LastName

        UNION

        SELECT 
            u.Username, u.FirstName, u.LastName, 'Nurse' AS Role,
            GROUP_CONCAT(s.Specialization ORDER BY s.Specialization SEPARATOR ', ') AS Specializations
        FROM Nurse n 
        JOIN User u ON n.UserID = u.UserID 
        LEFT JOIN NurseSpecializations ns ON n.NurseID = ns.NurseID
        LEFT JOIN Specializations s ON ns.SpecializationID = s.SpecializationID 
        GROUP BY u.UserID, u.Username, u.FirstName, u.LastName
    ) AS combined_User
    ORDER BY Role, LastName, FirstName;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE AssignSpecializationByRole(
    IN p_Username VARCHAR(255), IN p_SpecID VARCHAR(50))
BEGIN
    DECLARE userID_local VARCHAR(50);
    DECLARE roleID_local VARCHAR(50);
    DECLARE entityID VARCHAR(50);

    -- Get the UserID and RoleID for the given Username
    SELECT UserID, RoleID INTO userID_local, roleID_local
    FROM User WHERE Username = p_Username;

    -- Check if the user exists
    IF userID_local IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found.';
    END IF;

    -- Assign specialization based on the role
    IF roleID_local = 'R2' THEN -- Physician
        SELECT PhysicianID INTO entityID FROM Physician WHERE UserID = userID_local;
        IF entityID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Physician not found for the given user.';
        END IF;
        INSERT IGNORE INTO PhysicianSpecializations (PhysicianID, SpecializationID)
        VALUES (entityID, p_SpecID);

    ELSEIF roleID_local = 'R3' THEN -- Nurse
        SELECT NurseID INTO entityID FROM Nurse WHERE UserID = userID_local;
        IF entityID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nurse not found for the given user.';
        END IF;
        INSERT IGNORE INTO NurseSpecializations (NurseID, SpecializationID)
        VALUES (entityID, p_SpecID);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only Physicians or Nurses can be assigned specializations.';
    END IF;
END //
DELIMITER ;






DELIMITER //
CREATE PROCEDURE RemoveSpecializationFromUser(
    IN p_Username VARCHAR(255), IN p_SpecID VARCHAR(50))
BEGIN
    DECLARE userID_local VARCHAR(50);
    DECLARE roleID_local VARCHAR(50);
    DECLARE targetID VARCHAR(50);

    -- Get the UserID and RoleID for the given Username
    SELECT UserID, RoleID INTO userID_local, roleID_local
    FROM User WHERE Username = p_Username;

    -- Check if the user exists
    IF userID_local IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found.';
    END IF;

    -- Remove specialization
    IF roleID_local = 'R2' THEN -- Physician
        SELECT PhysicianID INTO targetID FROM Physician WHERE UserID = userID_local;
        IF targetID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Physician not found for the given user.';
        END IF;
        DELETE FROM PhysicianSpecializations WHERE PhysicianID = targetID AND SpecializationID = p_SpecID;

    ELSEIF roleID_local = 'R3' THEN -- Nurse
        SELECT NurseID INTO targetID FROM Nurse WHERE UserID = userID_local;
        IF targetID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nurse not found for the given user.';
        END IF;
        DELETE FROM NurseSpecializations WHERE NurseID = targetID AND SpecializationID = p_SpecID;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only Physicians or Nurses can have specializations.';
    END IF;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE GetUsersSpecializationRows()
BEGIN
    SELECT * FROM (
        -- Physician Specializations
        SELECT 
            u.Username, u.FirstName, u.LastName,
            'Physician' AS Role, s.Specialization, s.SpecializationID
        FROM Physician p 
        JOIN User u ON p.UserID = u.UserID
        JOIN PhysicianSpecializations ps ON p.PhysicianID = ps.PhysicianID
        JOIN Specializations s ON ps.SpecializationID = s.SpecializationID

        UNION ALL

        -- Nurse Specializations
        SELECT 
            u.Username, u.FirstName, u.LastName,
            'Nurse' AS Role, s.Specialization, s.SpecializationID
        FROM Nurse n 
        JOIN User u ON n.UserID = u.UserID
        JOIN NurseSpecializations ns ON n.NurseID = ns.NurseID
        JOIN Specializations s ON ns.SpecializationID = s.SpecializationID
    ) AS all_specializations
    ORDER BY Role, LastName, FirstName, Specialization;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetClinicDepartmentLinks()
BEGIN
    SELECT 
        c.ClinicID, c.ClinicName, d.DeptID, d.DeptName
    FROM ClinicDepartment cd
    JOIN Clinic c ON cd.ClinicID = c.ClinicID
    JOIN Department d ON cd.DeptID = d.DeptID
    ORDER BY c.ClinicName, d.DeptName;
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
    SELECT d.DeptID, d.DeptName 
    FROM Physician p
    JOIN PhysicianDepartment pd ON p.PhysicianID = pd.PhysicianID
    JOIN Department d ON pd.DeptID = d.DeptID 
    WHERE p.UserID = p_UserID;
END //
DELIMITER ;



DELIMITER //
CREATE PROCEDURE GetNurseIDByUserID(IN p_UserID VARCHAR(50))
BEGIN
    SELECT NurseID FROM Nurse WHERE UserID = p_UserID;
END//
DELIMITER ;

DELIMITER //

CREATE PROCEDURE GetDepartmentsByNurseID(
    IN p_NurseID VARCHAR(50))
BEGIN
    SELECT d.DeptID, d.DeptName 
    FROM NurseDepartment nd
    JOIN Department d ON nd.DeptID = d.DeptID 
    WHERE nd.NurseID = p_NurseID;
END //
DELIMITER ;
DROP PROCEDURE IF EXISTS GetAllUsers;

DELIMITER //

CREATE PROCEDURE GetAllUsers()
BEGIN
    SELECT 
        u.UserID, 
        u.Username, 
        CONCAT(u.FirstName, ' ', u.LastName) AS FullName, 
        r.RoleName, 
        u.Email
    FROM User u
    JOIN Roles r ON u.RoleID = r.RoleID
    ORDER BY r.RoleName, u.Username;
END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE RemoveDepartmentFromClinic(
    IN p_ClinicID VARCHAR(50), IN p_DeptID VARCHAR(50))
BEGIN
    DELETE FROM ClinicDepartment WHERE ClinicID = p_ClinicID AND DeptID = p_DeptID;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE CompletePhysicianProfileByID(
    IN p_PhysicianID VARCHAR(50),
    IN p_DeptIDs TEXT,
    IN p_PhysicianType VARCHAR(255),
    IN p_PhysicianRankID VARCHAR(50),
    IN p_SpecializationID VARCHAR(50)
)
BEGIN
    DECLARE DeptID VARCHAR(50);
    DECLARE done INT DEFAULT FALSE;

    DECLARE dept_cursor CURSOR FOR
        SELECT value FROM JSON_TABLE(p_DeptIDs, '$[*]' COLUMNS(value VARCHAR(50) PATH '$')) AS jt;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    START TRANSACTION;

    -- Update Physician's profile
    UPDATE Physician
    SET PhysicianType = p_PhysicianType, PhysicianRankID = p_PhysicianRankID
    WHERE PhysicianID = p_PhysicianID;

    -- Delete existing department associations and reinsert with the new ones
    DELETE FROM PhysicianDepartment WHERE PhysicianID = p_PhysicianID;

    OPEN dept_cursor;
    dept_loop: LOOP
        FETCH dept_cursor INTO DeptID;
        IF done THEN LEAVE dept_loop; END IF;
        INSERT INTO PhysicianDepartment (PhysicianID, DeptID)
        VALUES (p_PhysicianID, DeptID);
    END LOOP;
    CLOSE dept_cursor;

    -- Delete existing specialization and reinsert with the new one
    DELETE FROM PhysicianSpecializations WHERE PhysicianID = p_PhysicianID;
    INSERT INTO PhysicianSpecializations (PhysicianID, SpecializationID)
    VALUES (p_PhysicianID, p_SpecializationID);

    COMMIT;
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE ScheduleAppointmentForPatient(
    IN p_UserID VARCHAR(50),
    IN p_SlotID VARCHAR(50),
    IN p_PhysicianID VARCHAR(50),
    IN p_TypeID VARCHAR(50),
    IN p_DeptID VARCHAR(50)  
)
BEGIN
    DECLARE appt_id VARCHAR(50);
    DECLARE patient_id VARCHAR(50);
    DECLARE slot_available BOOLEAN;
    DECLARE appt_date DATETIME;

    SET appt_id = UUID();

    SELECT PatientID INTO patient_id FROM Patient WHERE UserID = p_UserID;

    SELECT Available, StartTime INTO slot_available, appt_date
    FROM TimeSlot WHERE SlotID = p_SlotID FOR UPDATE;

    IF slot_available = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slot already booked.';
    END IF;

    INSERT INTO Appointment (
        ApptID, PatientID, PhysicianID, SlotID, TypeID, DeptID, ApptDate, ApptStatus, CheckinStatus, SurveyCompleted)
    VALUES (
        appt_id, patient_id, p_PhysicianID, p_SlotID, p_TypeID, p_DeptID, appt_date, 'Scheduled', FALSE, FALSE
    );

    UPDATE TimeSlot SET Available = FALSE WHERE SlotID = p_SlotID;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetAllAppointments()
BEGIN
    SELECT 
        a.ApptID, 
        CONCAT(p_user.FirstName, ' ', p_user.LastName) AS PatientName, 
        CONCAT(doc_user.FirstName, ' ', doc_user.LastName) AS PhysicianName,
        d.DeptName,  
        at.TypeName, 
        a.ApptDate, 
        a.ApptStatus
    FROM Appointment a
    JOIN Patient pt ON a.PatientID = pt.PatientID 
    JOIN User p_user ON pt.UserID = p_user.UserID
    JOIN Physician ph ON a.PhysicianID = ph.PhysicianID 
    JOIN User doc_user ON ph.UserID = doc_user.UserID
    JOIN Department d ON a.DeptID = d.DeptID  
    JOIN AppointmentTypes at ON a.TypeID = at.TypeID
    ORDER BY a.ApptDate DESC;
END //

DELIMITER ;
DELIMITER //

CREATE PROCEDURE SetUserSecurityAnswer(
    IN p_UserID VARCHAR(50),
    IN p_QuestionID VARCHAR(50),
    IN p_AnswerHash VARCHAR(255)
)
BEGIN
    DECLARE existing_count INT;

    -- Check if the user already has an entry
    SELECT COUNT(*) INTO existing_count
    FROM UserSecurityAnswers
    WHERE UserID = p_UserID;

    IF existing_count > 0 THEN
        -- Update existing entry
        UPDATE UserSecurityAnswers
        SET QuestionID = p_QuestionID,
            AnswerHash = p_AnswerHash
        WHERE UserID = p_UserID;
    ELSE
        -- Insert new entry
        INSERT INTO UserSecurityAnswers (UserID, QuestionID, AnswerHash)
        VALUES (p_UserID, p_QuestionID, p_AnswerHash);
    END IF;
END //

DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAvailableBeds()
BEGIN
    SELECT b.BedID, b.BedType, b.DeptID, d.DeptName
    FROM Bed b
    JOIN Department d ON b.DeptID = d.DeptID
    WHERE b.PatientID IS NULL;
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE GetPatientsWithoutBeds()
BEGIN
    SELECT p.PatientID, u.FirstName, u.LastName
    FROM Patient p
    JOIN User u ON p.UserID = u.UserID
    WHERE p.PatientID NOT IN (
        SELECT PatientID FROM Bed WHERE PatientID IS NOT NULL
    );
END //
DELIMITER ;
DELIMITER //
CREATE PROCEDURE GetAssignedBeds()
BEGIN
    SELECT b.BedID, b.BedType, b.DeptID, d.DeptName, p.PatientID, u.FirstName, u.LastName
    FROM Bed b
    JOIN Department d ON b.DeptID = d.DeptID
    JOIN Patient p ON b.PatientID = p.PatientID
    JOIN User u ON p.UserID = u.UserID
    WHERE b.PatientID IS NOT NULL;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetAllBeds()
BEGIN
    SELECT b.BedID, b.BedType, b.DeptID, d.DeptName, b.PatientID
    FROM Bed b
    JOIN Department d ON b.DeptID = d.DeptID;
END //
DELIMITER ;


