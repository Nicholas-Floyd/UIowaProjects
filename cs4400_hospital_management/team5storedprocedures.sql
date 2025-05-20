use team5project; 

-- dropping all of these stored procedures: updated versions in team5storedproceduresNEW
drop procedure if exists ScheduleAppointment; 
drop procedure if exists RescheduleAppointment;
drop procedure if exists CancelAppointment;
drop procedure if exists CheckInAndSurvey;
drop procedure if exists GetAllAvailableTimeSlots;
drop procedure if exists createBill;
drop procedure if exists InsertServiceBreakdown;
drop procedure if exists CreateClaim;
drop procedure if exists createInvoice;
drop procedure if exists UpdateInvoiceTotals; 
drop procedure if exists MakePatientPayment;
drop procedure if exists MakeInsurancePayment;
drop procedure if exists AssignBedToPatient;
drop procedure if exists DischargePatient;
drop procedure if exists ViewPatientPayments;
drop procedure if exists ViewInsurancePayments;
drop procedure if exists insertSOAPsummary;
drop procedure if exists MakeSOAPVisibleToPatient;
drop procedure if exists PrescribeMedication;
drop procedure if exists EnterLabResult;
drop procedure if exists CreateLabOrder;
drop procedure if exists AddSubjectiveData;
drop procedure if exists AddObjectiveData;
drop procedure if exists AddAssessment;
drop procedure if exists AddPlan;
drop procedure if exists AddVitals;
drop procedure if exists CreateBed;
drop procedure if exists DeleteBed;
drop procedure if exists ModifyBed;
drop procedure if exists AddPhysicianShift;
drop procedure if exists DeletePhysicianShift;
drop procedure if exists ModifyPhysicianShift;
drop procedure if exists GetPhysicianAvailability;
drop procedure if exists GetRoster;
drop procedure if exists AddOrUpdatePatientProfile;
drop procedure if exists updatePatientAddress;
drop procedure if exists UpdatePatientInsurance;
drop procedure if exists AddPhysician;
drop procedure if exists AddNurse;
drop procedure if exists AddStaff;
drop procedure if exists AddNurseShift;
drop procedure if exists DeleteNurseShift;
drop procedure if exists ModifyNurseShift;
drop procedure if exists PatientOutstandingBills;

-- SCHEDULE APPOINTMENT
DELIMITER // 
CREATE PROCEDURE ScheduleAppointment (
	IN p_Appt_ID VARCHAR(50),
	IN p_Patient_ID VARCHAR(50),
	IN p_Slot_ID VARCHAR(50),
	IN p_Type_ID VARCHAR(50),
	IN p_Dept_ID VARCHAR(50),
	IN p_Physician_ID VARCHAR(50)
)
BEGIN
	DECLARE Is_Slot_Available BOOLEAN;
	START TRANSACTION;
    
	SELECT Available INTO Is_Slot_Available
	FROM TIME_SLOT
	WHERE Slot_ID = p_Slot_ID
	FOR UPDATE;

	IF Is_Slot_Available = FALSE THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Time slot is not available';
    	ROLLBACK;
	ELSE
    	INSERT INTO APPOINTMENT (
        	Appt_ID, Patient_ID, Slot_ID, Type_ID, Dept_ID, Appt_Date, Physician_ID, Check_in_Status, Survey_Completed, Appt_Status
    	)
    	SELECT
        	p_Appt_ID, p_Patient_ID, p_Slot_ID, p_Type_ID, p_Dept_ID, Start_Time, p_Physician_ID, FALSE, FALSE, 'Scheduled'
    	FROM TIME_SLOT
    	WHERE Slot_ID = p_Slot_ID;

    	-- mark the appointment time as unavailable
    	UPDATE TIME_SLOT
    	SET Available = FALSE
    	WHERE Slot_ID = p_Slot_ID;

    	COMMIT;
	END IF;
END // 
DELIMITER ;





-- RESCHEDULE APPOINTMENT
DELIMITER //
CREATE PROCEDURE RescheduleAppointment (
    IN p_Appt_ID VARCHAR(50),
    IN p_New_Slot_ID VARCHAR(50)
)
BEGIN
    DECLARE old_Slot_ID VARCHAR(50);
    DECLARE new_Slot_Available BOOLEAN;

    DECLARE exit handler for sqlexception
    BEGIN
        ROLLBACK;
    END;

    SELECT Available INTO new_Slot_Available
    FROM TIME_SLOT
    WHERE Slot_ID = p_New_Slot_ID;

    IF new_Slot_Available = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New slot is unavailable.';
    END IF;

    SELECT Slot_ID INTO old_Slot_ID
    FROM APPOINTMENT
    WHERE Appt_ID = p_Appt_ID;

    START TRANSACTION;

    UPDATE APPOINTMENT
    SET Slot_ID = p_New_Slot_ID,
        Appt_Date = (SELECT Start_Time FROM TIME_SLOT WHERE Slot_ID = p_New_Slot_ID),
        Appt_Status = 'Rescheduled'
    WHERE Appt_ID = p_Appt_ID;

    -- set "new" slot time as unavailable
    UPDATE TIME_SLOT
    SET Available = FALSE
    WHERE Slot_ID = p_New_Slot_ID;

    -- set "old" slot time as available
    UPDATE TIME_SLOT
    SET Available = TRUE
    WHERE Slot_ID = old_Slot_ID;

    -- Commit the changes
    COMMIT;
END //
DELIMITER ;











-- CANCEL APPOINTMENT
DELIMITER //
CREATE PROCEDURE CancelAppointment (
    IN p_Appt_ID VARCHAR(50)
)
BEGIN
    DECLARE current_Appt_Status VARCHAR(50);
    DECLARE v_Slot_ID VARCHAR(50);

    -- Check if the appointment exists and fetch the current status and time slot
    SELECT Appt_Status, Slot_ID INTO current_Appt_Status, v_Slot_ID
    FROM APPOINTMENT
    WHERE Appt_ID = p_Appt_ID;

    IF current_Appt_Status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment not found.';
    END IF;

    IF current_Appt_Status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment is already canceled.';
    END IF;

    START TRANSACTION;
    
	-- set appointment status as cancelled
    UPDATE APPOINTMENT
    SET Appt_Status = 'Cancelled'
    WHERE Appt_ID = p_Appt_ID;
    
	-- set timeslot as available
    UPDATE TIME_SLOT
    SET available = 1
    WHERE Slot_ID = v_Slot_ID;
    
    COMMIT;
END //
DELIMITER ;










-- CHECK IN FOR APPOINTMENT AND COMPLETE SURVEY
DELIMITER //
CREATE PROCEDURE CheckInAndSurvey(
    IN p_Appt_ID VARCHAR(50),
    IN p_Survey_Completed BOOLEAN
)
BEGIN
    DECLARE current_Check_In_Status BOOLEAN;

    SELECT Check_in_Status INTO current_Check_In_Status
    FROM APPOINTMENT
    WHERE Appt_ID = p_Appt_ID;

    IF current_Check_In_Status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment not found.';
    END IF;

    IF current_Check_In_Status = TRUE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment has already been checked in.';
    END IF;

    START TRANSACTION;

    UPDATE APPOINTMENT
    SET Check_in_Status = TRUE,
        Survey_Completed = p_Survey_Completed
    WHERE Appt_ID = p_Appt_ID;

    COMMIT;
END //
DELIMITER ;










-- VIEW AVAILABLE APPOINTMENT TIME SLOTS
DELIMITER //
CREATE PROCEDURE GetAllAvailableTimeSlots()
BEGIN
	SELECT Slot_ID, Start_Time, End_Time, Physician_ID
	FROM TIME_SLOT
	WHERE Available = TRUE
	ORDER BY Start_Time;
END //
DELIMITER ;










-- CREATE A BILL
DELIMITER //
CREATE PROCEDURE createBill(
    IN p_Bill_ID VARCHAR(50),
    IN p_Patient_ID VARCHAR(50),
    IN p_Service_Breakdown_ID VARCHAR(50),  
    IN p_Invoice_ID VARCHAR(50),
    IN p_Due_Date DATE
)
BEGIN
    DECLARE total_charge DECIMAL(10, 2);
    DECLARE copay DECIMAL(10, 2);
    DECLARE deductible DECIMAL(10, 2);
    DECLARE coinsurance DECIMAL(5, 2); -- stored as decimal (e.g. 0.2 for 20%)
    DECLARE oop_max DECIMAL(10, 2);
    DECLARE remaining_bill DECIMAL(10, 2);
    DECLARE insurance_payment DECIMAL(10, 2);
    DECLARE patient_payment DECIMAL(10, 2);
    DECLARE insurance_plan_id VARCHAR(50);
    DECLARE payment_status VARCHAR(20);
    DECLARE balance_due DECIMAL(10, 2);

    -- 1. Get service cost and insurance plan details
    SELECT
        sb.Service_Cost,
        p.insurance_Plan_ID,
        ip.Copay,
        ip.Deductible,
        ip.Coinsurance,
        ip.OOPmax
    INTO
        total_charge,
        insurance_plan_id,
        copay,
        deductible,
        coinsurance,
        oop_max
    FROM SERVICE_BREAKDOWN sb
    JOIN PATIENT p ON p.Patient_ID = p_Patient_ID
    JOIN INSURANCE_PLAN ip ON ip.Insurance_Plan_ID = p.insurance_Plan_ID
    WHERE sb.Service_Breakdown_ID = p_Service_Breakdown_ID AND p.Patient_ID = p_Patient_ID;

    -- 2. Payment calculations
    IF total_charge <= deductible THEN
        -- Patient pays full amount if charge is under deductible
        SET patient_payment = total_charge;
        SET insurance_payment = 0;
    ELSE
        SET remaining_bill = total_charge - deductible;
        SET insurance_payment = remaining_bill * (1 - coinsurance);
        SET patient_payment = copay + deductible + (remaining_bill * coinsurance);

        -- Enforce out-of-pocket max
        IF patient_payment > oop_max THEN
            SET patient_payment = oop_max;
            SET insurance_payment = total_charge - oop_max;
        END IF;
    END IF;

    -- 3. Balance due is what the patient and insurance owe
    SET balance_due = total_charge;

    -- 4. Determine payment status
    IF balance_due <= 0 THEN
        SET payment_status = 'Paid';
    ELSE
        SET payment_status = 'Pending';
    END IF;

    -- 5. Insert the bill record
    INSERT INTO BILL (
        Bill_ID, Patient_ID, Invoice_ID,
        Total_Charge, Due_Date, Patient_Responsibility,
        Insurance_Payment, Balance_Due, Payment_Status)
    VALUES (
        p_Bill_ID, p_Patient_ID, p_invoice_ID,
        total_charge, p_Due_Date, patient_payment,
        insurance_payment, balance_due, payment_status);

    -- 6. Link the bill with service breakdown details
    INSERT INTO BILL_SERVICE_DETAIL (Bill_ID, Service_Breakdown_ID)
    VALUES (p_Bill_ID, p_Service_Breakdown_ID);

    -- 7. Update invoice totals (if this exists)
    CALL UpdateInvoiceTotals(p_Bill_ID);
END //
DELIMITER ;







-- ADD SERVICE BREAKDOWN
DELIMITER //
CREATE PROCEDURE InsertServiceBreakdown (
    IN p_Service_Breakdown_ID VARCHAR(255),
    IN p_Staff_ID VARCHAR(255),
    IN p_Dept_ID VARCHAR(255),
    IN p_Service_Description VARCHAR(255),
    IN p_Service_Date DATETIME,
    IN p_Service_Cost NUMERIC,
    IN p_Notes VARCHAR(255)
)
BEGIN
    DECLARE StaffExists INT;
    DECLARE DeptExists INT;

    START TRANSACTION;

    SELECT COUNT(*) INTO StaffExists
    FROM STAFF
    WHERE Staff_ID = p_Staff_ID
    FOR UPDATE;

    IF StaffExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Staff ID does not exist';
        ROLLBACK;
    END IF;

    SELECT COUNT(*) INTO DeptExists
    FROM DEPARTMENT
    WHERE Dept_ID = p_Dept_ID
    FOR UPDATE;

    IF DeptExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Department ID does not exist';
        ROLLBACK;
    END IF;

    INSERT INTO SERVICE_BREAKDOWN (
        Service_Breakdown_ID, 
        Staff_ID, 
        Dept_ID, 
        Service_Description, 
        Service_Date, 
        Service_Cost, 
        Notes
    )
    VALUES (
        p_Service_Breakdown_ID, 
        p_Staff_ID, 
        p_Dept_ID, 
        p_Service_Description, 
        p_Service_Date, 
        p_Service_Cost, 
        p_Notes
    );

    COMMIT;
END //
DELIMITER ;











-- MAKE A CLAIM
DELIMITER //
CREATE PROCEDURE CreateClaim (
    IN p_Claim_ID VARCHAR(255),
    IN p_Patient_ID VARCHAR(255),
    IN p_Insurance_Coverage_ID VARCHAR(255),
    IN p_Claim_Creation_Date DATETIME
)
BEGIN
    DECLARE PatientExists INT;
    DECLARE CoverageExists INT;

    START TRANSACTION;

    SELECT COUNT(*) INTO PatientExists
    FROM PATIENT
    WHERE Patient_ID = p_Patient_ID
    FOR UPDATE;

    IF PatientExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient does not exist';
        ROLLBACK;
    END IF;
    
    SELECT COUNT(*) INTO CoverageExists
    FROM INSURANCE_COVERAGE
    WHERE Coverage_ID = p_Insurance_Coverage_ID
    FOR UPDATE;

    IF CoverageExists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insurance coverage does not exist';
        ROLLBACK;
    END IF;

    INSERT INTO CLAIM (
        Claim_ID, 
        Patient_ID, 
        Insurance_Coverage_ID, 
        Claim_Creation_Date
    )
    VALUES (
        p_Claim_ID, 
        p_Patient_ID, 
        p_Insurance_Coverage_ID, 
        p_Claim_Creation_Date
    );

    COMMIT;
END //
DELIMITER ;












-- GENERATE INVOICE
DELIMITER //
CREATE PROCEDURE createInvoice(
	IN p_Invoice_ID VARCHAR(50),
	IN p_Patient_ID VARCHAR(50),
	IN p_Staff_ID VARCHAR(50),
	IN p_Due_Date DATE
)
BEGIN
	DECLARE gross_charge DECIMAL(10, 2) DEFAULT 0;
	DECLARE total_payments DECIMAL(10, 2) DEFAULT 0;
	DECLARE balance_due DECIMAL(10, 2) DEFAULT 0;

	-- 1. Calculate gross charge (sum of all bill charges connected to this invoice)
	SELECT COALESCE(SUM(b.Total_Charge), 0)
	INTO gross_charge
	FROM BILL b
	WHERE b.Invoice_ID = p_Invoice_ID;

	-- 2. Calculate total payments made (from both patient & insurance) toward any bill in the invoice
	SELECT COALESCE(SUM(p.Payment_Amount), 0)
	INTO total_payments
	FROM PAYMENT p
	JOIN BILL b ON b.Bill_ID = p.Bill_ID
	WHERE b.Invoice_ID = p_Invoice_ID;

	-- 3. Calculate remaining balance due
	SET balance_due = gross_charge - total_payments;

	-- 4. Insert the invoice record
	INSERT INTO INVOICE (
    	Invoice_ID, Patient_ID, Staff_ID, Gross_Charge, Total_Payments, Balance_Due, Due_Date
	)
	VALUES (
    	p_Invoice_ID, p_Patient_ID, p_Staff_ID, gross_charge, total_payments, balance_due, p_Due_Date
	);
END //
DELIMITER ;











-- update invoice after a payment is made
DELIMITER //
CREATE PROCEDURE UpdateInvoiceTotals(
	IN p_Bill_ID VARCHAR(50)
)
BEGIN
	DECLARE v_Invoice_ID VARCHAR(50);
	DECLARE v_Gross_Charge DECIMAL(10,2);
	DECLARE v_Total_Payments DECIMAL(10,2);
	DECLARE v_Balance_Due DECIMAL(10,2);

	-- 1. Get the invoice ID from the bill
	SELECT Invoice_ID INTO v_Invoice_ID
	FROM BILL
	WHERE Bill_ID = p_Bill_ID;

	-- 2. Calculate total charge for the invoice
	SELECT COALESCE(SUM(Total_Charge), 0)
	INTO v_Gross_Charge
	FROM BILL
	WHERE Invoice_ID = v_Invoice_ID;

	-- 3. Calculate total payments across all bills in that invoice
	SELECT COALESCE(SUM(p.Payment_Amount), 0)
	INTO v_Total_Payments
	FROM PAYMENT p
	JOIN BILL b ON b.Bill_ID = p.Bill_ID
	WHERE b.Invoice_ID = v_Invoice_ID;

	-- 4. Calculate balance due
	SET v_Balance_Due = v_Gross_Charge - v_Total_Payments;

	-- 5. Update the invoice record
	UPDATE INVOICE
	SET Gross_Charge = v_Gross_Charge,
		Total_Payments = v_Total_Payments,
		Balance_Due = v_Balance_Due
	WHERE Invoice_ID = v_Invoice_ID;
END //
DELIMITER ;















-- PATIENT PAYS BILL
DELIMITER //
CREATE PROCEDURE MakePatientPayment(
    IN p_Payment_ID VARCHAR(50),
    IN p_Patient_ID VARCHAR(50),
    IN p_Bill_ID VARCHAR(50),
    IN p_Claim_ID VARCHAR(50),
    IN p_Amount DECIMAL(10, 2),
    IN p_Payment_Date DATE
)
BEGIN
    DECLARE v_Balance DECIMAL(10, 2);
    DECLARE v_NewBalance DECIMAL(10, 2);

    IF NOT EXISTS (SELECT 1 FROM PATIENT WHERE Patient_ID = p_Patient_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient not found';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM BILL WHERE Bill_ID = p_Bill_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bill not found';
    END IF;

    SELECT Balance_Due INTO v_Balance FROM BILL WHERE Bill_ID = p_Bill_ID;

    IF p_Amount > v_Balance THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment exceeds outstanding balance';
    END IF;

    SET v_NewBalance = v_Balance - p_Amount;

    INSERT INTO PAYMENT (
        Payment_ID, Patient_ID, Bill_ID, 
        Payment_Amount, Payment_Date, Payer
    ) VALUES (
        p_Payment_ID, p_Patient_ID, p_Bill_ID, 
        p_Amount, p_Payment_Date, 'Patient'
    );

    UPDATE BILL
    SET
        Balance_Due = v_NewBalance,
        Payment_Status = CASE
            WHEN v_NewBalance <= 0 THEN 'Paid'
            ELSE 'Pending'
        END
    WHERE Bill_ID = p_Bill_ID;

    
    CALL UpdateInvoiceTotals(p_Bill_ID);
END //
DELIMITER ;










-- INSURANCE PAYMENT
DELIMITER //
CREATE PROCEDURE MakeInsurancePayment(
    IN p_Payment_ID VARCHAR(50),
    IN p_Insurance_Plan_ID VARCHAR(50),
    IN p_Patient_ID VARCHAR(50),
    IN p_Bill_ID VARCHAR(50),
    IN p_Claim_ID VARCHAR(50),
    IN p_Amount DECIMAL(10, 2),
    IN p_Payment_Date DATE,
    IN p_Insurance_Payment_ID VARCHAR(50)
)
BEGIN
    DECLARE v_Balance DECIMAL(10, 2);
    DECLARE v_NewBalance DECIMAL(10, 2);

    IF NOT EXISTS (SELECT 1 FROM PATIENT WHERE Patient_ID = p_Patient_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient not found';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM BILL WHERE Bill_ID = p_Bill_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bill not found';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM INSURANCE_PLAN WHERE Insurance_Plan_ID = p_Insurance_Plan_ID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insurance plan not found';
    END IF;

    SELECT Balance_Due INTO v_Balance FROM BILL WHERE Bill_ID = p_Bill_ID;

    IF p_Amount > v_Balance THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment exceeds outstanding balance';
    END IF;

    SET v_NewBalance = v_Balance - p_Amount;


    INSERT INTO PAYMENT (
        Payment_ID, Patient_ID, Bill_ID,
        Payment_Amount, Payment_Date, Payer
    ) VALUES (
        p_Payment_ID, p_Patient_ID, p_Bill_ID,
        p_Amount, p_Payment_Date, 'Insurance'
    );

   
    INSERT INTO INSURANCE_PAYMENT_RELATIONSHIP (
        Insurance_Payment_ID,
        Insurance_Plan_ID,
        Bill_ID,
        Payment_ID,
        Payment_Amount
    ) VALUES (
        p_Insurance_Payment_ID,
        p_Insurance_Plan_ID,
        p_Bill_ID,
        p_Payment_ID,
        p_Amount
    );

    -- Update bill
    UPDATE BILL
    SET
        Balance_Due = v_NewBalance,
        Payment_Status = CASE
            WHEN v_NewBalance <= 0 THEN 'Paid'
            ELSE 'Pending'
        END
    WHERE Bill_ID = p_Bill_ID;

    CALL UpdateInvoiceTotals(p_Bill_ID);
END //
DELIMITER ;











-- ASSIGN BED TO PATIENT/ ADMIT PATIENT
DELIMITER //
CREATE PROCEDURE AssignBedToPatient(
	IN p_Bed_ID VARCHAR(50),
	IN p_Patient_ID VARCHAR(50)
)
BEGIN
	DECLARE assigned_patient varchar(50);

	SELECT Patient_ID INTO assigned_patient
	FROM BED
	WHERE Bed_ID = p_Bed_ID;

	IF assigned_patient IS NOT NULL THEN
    		SIGNAL SQLSTATE  '45000' SET message_text  = 'Bed is already occupied.';
	ELSE
    	UPDATE BED
    	SET Patient_ID = p_Patient_ID
    	WHERE Bed_ID = p_Bed_ID;
	END IF ; 
END //
DELIMITER ;









-- DISCHARGE A PATIENT
DELIMITER // 
CREATE PROCEDURE DischargePatient(
	IN p_Patient_ID VARCHAR(255))
BEGIN
	UPDATE BED
	SET Patient_ID = NULL
	WHERE Patient_ID = p_Patient_ID; 
END // 
DELIMITER ; 






-- VIEW ALL PAYMENTS MADE BY A PATIENT
DELIMITER //
CREATE PROCEDURE ViewPatientPayments (
    IN p_Patient_ID VARCHAR(50)
)
BEGIN
    SELECT
        p.Bill_ID,
        b.Invoice_ID,
        b.Total_Charge,
        p.Payment_Amount,
        p.Payment_Date,
        p.Payment_ID,
        p.Payer
    FROM PAYMENT p
    JOIN BILL b ON b.Bill_ID = p.Bill_ID
    WHERE p.Patient_ID = p_Patient_ID
      AND p.Payer = 'Patient';
END //
DELIMITER ;









-- VIEW ALL PAYMENTS MADE BY INSURANCE PER PATIENT
DELIMITER //
CREATE PROCEDURE ViewInsurancePayments (
    IN p_Patient_ID VARCHAR(50)
)
BEGIN
    SELECT
        p.Bill_ID,
        b.Invoice_ID,
        b.Total_Charge,
        ipr.Payment_Amount,
        p.Payment_Date,
        p.Payment_ID,
        ipr.Insurance_Plan_ID,
        ipr.Insurance_Payment_ID,
        p.Payer
    FROM PAYMENT p
    JOIN BILL b ON b.Bill_ID = p.Bill_ID
    JOIN INSURANCE_PAYMENT_RELATIONSHIP ipr ON ipr.Payment_ID = p.Payment_ID
    WHERE p.Patient_ID = p_Patient_ID
      AND p.Payer = 'Insurance';
END //
DELIMITER ;




















-- INSERT SOAP/AFTER-VISIT SUMMARY
DELIMITER //
CREATE PROCEDURE insertSOAPsummary(
	IN p_Summary_ID VARCHAR(255),
	IN p_Physician_ID VARCHAR(255),
	IN p_Patient_ID VARCHAR(255),
	IN p_Visible_To_Patient BOOLEAN
)
BEGIN
	INSERT INTO AFTER_VISIT_SUMMARY (
    	Summary_ID, Physician_ID, Patient_ID, Visible_To_Patient, Created
	) VALUES (
    	p_Summary_ID, p_Physician_ID, p_Patient_ID, p_Visible_To_Patient, NOW()
	);
END //
DELIMITER ;











-- MAKE SOAP DOC VISIBLE TO PATIENT (AS AN AFTER-VISIT SUMMARY) AFTER THEY HAVE BEEN DISCHARGED
DELIMITER //
CREATE PROCEDURE MakeSOAPVisibleToPatient (
    IN summary_id VARCHAR(255),
    IN patient_id VARCHAR(255)
)
BEGIN
    DECLARE summary_exists INT;
    DECLARE patient_exists INT;
    
    SET SQL_SAFE_UPDATES = 0;
    -- Check if the summary exists
    SELECT COUNT(*) INTO summary_exists
    FROM AFTER_VISIT_SUMMARY
    WHERE Summary_ID = summary_id;
    
    -- Check if the patient exists
    SELECT COUNT(*) INTO patient_exists
    FROM PATIENT
    WHERE Patient_ID = patient_id;
    
    -- If both the summary and the patient exist, update the summary
    IF summary_exists > 0 AND patient_exists > 0 THEN
        UPDATE AFTER_VISIT_SUMMARY
		SET Visible_To_Patient = TRUE
		WHERE Summary_ID = summary_id 
		AND Patient_ID = patient_id
		AND Visible_To_Patient = FALSE;
        
        SELECT 'SOAP Summary made visible to patient.' AS Message;
    ELSE
        SELECT 'Summary or Patient does not exist.' AS Message;
    END IF;
END //
DELIMITER ;











-- PRESCRIBE MEDICATION
DELIMITER //
CREATE PROCEDURE PrescribeMedication (
	IN p_Prescription_ID VARCHAR(50),
	IN p_Drug_Name VARCHAR(100),
	IN p_Dosage NUMERIC(10,2),
	IN p_Quantity NUMERIC(10,2),
	IN p_StartDate DATETIME,
	IN p_EndDate DATETIME,
	IN p_Refill BOOLEAN,
	IN p_Pharmacy_ID VARCHAR(50),
	IN p_Patient_ID VARCHAR(50),
	IN p_Plan_ID VARCHAR(50),
	IN p_Physician_ID VARCHAR(50),
	IN p_Frequency VARCHAR(100)
)
BEGIN
	INSERT INTO PRESCRIPTION (
    	Prescription_ID, Drug_Name, Dosage, Quantity, StartDate, EndDate,
    	Refill, Pharmacy_ID, Patient_ID, Plan_ID, Physician_ID, Frequency
	) VALUES (
    	p_Prescription_ID, p_Drug_Name, p_Dosage, p_Quantity, p_StartDate, p_EndDate,
    	p_Refill, p_Pharmacy_ID, p_Patient_ID, p_Plan_ID, p_Physician_ID, p_Frequency
	);
END //
DELIMITER ;










-- ENTER LAB TEST RESULT
DELIMITER //
CREATE PROCEDURE EnterLabResult(
	IN p_Lab_Result_ID VARCHAR(50),
	IN p_Objective_Data_ID VARCHAR(50),
	IN p_Test_Name VARCHAR(100),
	IN p_Result NUMERIC(10,2),
	IN p_Unit VARCHAR(20),
	IN p_Test_Date DATETIME
)
BEGIN
	INSERT INTO LAB_RESULT (
    	Lab_Result_ID, Objective_Data_ID, Test_Name, Result, Unit, Test_Date
	)
	VALUES (
    	p_Lab_Result_ID, p_Objective_Data_ID, p_Test_Name, p_Result, p_Unit, p_Test_Date
	);
END //
DELIMITER ;











-- CREATE LAB ORDER
DELIMITER //
CREATE PROCEDURE CreateLabOrder(
	IN p_Order_ID VARCHAR(50),
	IN p_Plan_ID VARCHAR(50),
	IN p_Order_Type VARCHAR(50),
	IN p_Details VARCHAR(255),
	IN p_Date_Scheduled DATETIME,
	IN p_Order_Status VARCHAR(50)
)
BEGIN
	INSERT INTO ORDERS (
    	Order_ID, Plan_ID, Order_Type, Details,
    	Date_Scheduled, Date_Done, Order_Status
	)
	VALUES (
    	p_Order_ID, p_Plan_ID, p_Order_Type, p_Details,
    	p_Date_Scheduled, NULL, p_Order_Status
	);
END //
DELIMITER ;













-- ADD SUBJECTIVE DATA TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddSubjectiveData(
    IN p_Subjective_Data_ID VARCHAR(50),
    IN p_summary_ID VARCHAR(50),
    IN p_CC VARCHAR(255),
    IN p_HPI VARCHAR(255)
)
BEGIN
    DECLARE summary_exists INT;

    SELECT COUNT(*) INTO summary_exists
    FROM AFTER_VISIT_SUMMARY
    WHERE Summary_ID = p_summary_ID;

    IF summary_exists > 0 THEN
        INSERT INTO SUBJECTIVE_DATA (
            Subjective_Data_ID, summary_ID, CC, HPI
        )
        VALUES (
            p_Subjective_Data_ID, p_summary_ID, p_CC, p_HPI
        );
    ELSE
        SELECT 'Error: The provided Summary_ID does not exist.' AS ErrorMessage;
    END IF;
END //
DELIMITER ;









-- ADD OBJECTIVE DATA TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddObjectiveData(
    IN p_Summary_ID VARCHAR(50),
    IN p_Objective_Data_ID VARCHAR(50)
)
BEGIN
    DECLARE summary_exists INT;

    SELECT COUNT(*) INTO summary_exists
    FROM AFTER_VISIT_SUMMARY
    WHERE Summary_ID = p_Summary_ID;

    IF summary_exists > 0 THEN
        INSERT INTO OBJECTIVE_DATA (
            Objective_Data_ID, Summary_ID
        )
        VALUES (
            p_Objective_Data_ID, p_Summary_ID
        );
    ELSE
        SELECT 'Error: The provided Summary_ID does not exist.' AS ErrorMessage;
    END IF;
END //
DELIMITER ;










-- ADD ASSESSMENT TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddAssessment(
	IN p_Assessment_ID VARCHAR(255),
	IN p_Summary_ID VARCHAR(255),
	IN p_Assessment VARCHAR(255)
)
BEGIN
	INSERT INTO ASSESSMENT (Assessment_ID, Summary_ID, Assessment)
	VALUES (p_Assessment_ID, p_Summary_ID, p_Assessment);
END //
DELIMITER ;









-- ADD PLAN TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddPlan(
	IN p_Plan_ID VARCHAR(255),
	IN p_Summary_ID VARCHAR(255),
	IN p_Created_Date DATETIME,
	IN p_Follow_Up BOOLEAN,
	IN p_Plan_Status ENUM("Active", "Completed"),
	IN p_Notes VARCHAR(255)
)
BEGIN
	INSERT INTO PLAN (
		Plan_ID, Summary_ID, Created_Date, Follow_Up, Plan_Status, Notes
	)
	VALUES (
		p_Plan_ID, p_Summary_ID, p_Created_Date, p_Follow_Up, p_Plan_Status, p_Notes
	);
END //
DELIMITER ;














-- ADD VITALS TO SOAP DOC
DELIMITER //
CREATE PROCEDURE AddVitals(
	IN p_Vitals_ID VARCHAR(255),
	IN p_Objective_Data_ID VARCHAR(255),
	IN p_Vitals_Date DATETIME,
	IN p_Blood_Pressure VARCHAR(20),
	IN p_Heart_Rate NUMERIC,
	IN p_Temp NUMERIC(5, 3)
)
BEGIN
	INSERT INTO VITALS (
		Vitals_ID, Objective_Data_ID, Vitals_Date, Blood_Pressure, Heart_Rate, Temp
	)
	VALUES (
		p_Vitals_ID, p_Objective_Data_ID, p_Vitals_Date, p_Blood_Pressure, p_Heart_Rate, p_Temp
	);
END //
DELIMITER ;











-- CREATE BED
DELIMITER //
CREATE PROCEDURE CreateBed (
	IN p_Bed_ID VARCHAR(50),
	IN p_Bed_Type VARCHAR(50),
	IN p_Dept_ID VARCHAR(50)
)
BEGIN
	IF EXISTS (SELECT 1 FROM BED WHERE Bed_ID = p_Bed_ID) THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed ID already exists';
	END IF;

	IF p_Bed_Type NOT IN ('General', 'ICU', 'CCU', 'Pediatric', 'Maternity', 'Surgical',
                      	'Trauma', 'Birthing', 'Psychiatric', 'Geriatric', 'Transport',
                      	'Step-Down', 'Rehabilitation', 'Isolation', 'Burn Unit') THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Bed Type';
	END IF;

	INSERT INTO BED (Bed_ID, Bed_Type, Dept_ID, Patient_ID)
	VALUES (p_Bed_ID, p_Bed_Type, p_Dept_ID, NULL);
END //
DELIMITER ;








-- DELETE BED
DELIMITER //
CREATE PROCEDURE DeleteBed (
	IN p_Bed_ID VARCHAR(50)
)
BEGIN
	IF NOT EXISTS (SELECT 1 FROM BED WHERE Bed_ID = p_Bed_ID) THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed ID does not exist';
	END IF;

	IF EXISTS (SELECT 1 FROM BED WHERE Bed_ID = p_Bed_ID AND Patient_ID IS NOT NULL) THEN
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete bed: It is currently assigned to a patient.';
	END IF;

	DELETE FROM BED WHERE Bed_ID = p_Bed_ID;

END //
DELIMITER ;









-- MODIFY BED
DELIMITER //
CREATE PROCEDURE ModifyBed (
	IN p_Bed_ID VARCHAR(50),
	IN p_New_Bed_Type VARCHAR(50),
	IN p_New_Dept_ID VARCHAR(50)
)
BEGIN
	UPDATE BED
	SET Bed_Type = p_New_Bed_Type,
    	Dept_ID = p_New_Dept_ID
	WHERE Bed_ID = p_Bed_ID;
END //
DELIMITER ;






-- CREATE PHYSICIAN SHIFT
DELIMITER //
CREATE PROCEDURE AddPhysicianShift (
	IN p_Shift_ID VARCHAR(50),
	IN p_Physician_ID VARCHAR(50),
	IN p_Staff_ID VARCHAR(50),
	IN p_Dept_ID VARCHAR(50),
	IN p_Shift_Start DATETIME,
	IN p_Shift_end DATETIME,
	IN p_Shift_Type VARCHAR(50)
)
BEGIN
	DECLARE v_physician_exists INT DEFAULT 0;
	DECLARE v_shift_exists INT DEFAULT 0;

	START TRANSACTION;

	SELECT COUNT(*)
	INTO v_physician_exists
	FROM PHYSICIAN
	WHERE Physician_ID = p_Physician_ID;

	SELECT COUNT(*)
	INTO v_shift_exists
	FROM PHYSICIAN_SHIFT
	WHERE Physician_ID = p_Physician_ID
  	AND ((p_Shift_Start BETWEEN Shift_Start_Time AND Shift_End_Time)
       	OR (p_Shift_end BETWEEN Shift_Start_Time AND Shift_End_Time)
       	OR (Shift_Start_Time BETWEEN p_Shift_Start AND p_Shift_end));

	-- Raise an error if the shift already exists
	IF v_shift_exists > 0 THEN
    	ROLLBACK; 
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'This physician already has a shift scheduled during this time';
	END IF;
 
	INSERT INTO PHYSICIAN_SHIFT (
    	Shift_ID,
    	Physician_ID,
    	Staff_ID,
    	Dept_ID,
    	Shift_Start_Time,
    	Shift_End_Time,
    	Shift_Type
	)
	VALUES (
    	p_Shift_ID,
    	p_Physician_ID,
    	p_Staff_ID,
    	p_Dept_ID,
    	p_Shift_Start,
    	p_Shift_end,
    	p_Shift_Type
	);
	COMMIT;
END //
DELIMITER ;











-- DELETE PHYSICIAN SHIFT
DELIMITER //
CREATE PROCEDURE DeletePhysicianShift (
	IN p_Shift_ID VARCHAR(50)
)
BEGIN
	DECLARE v_shift_exists INT DEFAULT 0;

	SELECT COUNT(*)
	INTO v_shift_exists
	FROM PHYSICIAN_SHIFT
	WHERE Shift_ID = p_Shift_ID;

	IF v_shift_exists = 0 THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Shift_ID does not exist';
	END IF;

	START TRANSACTION;

	DELETE FROM PHYSICIAN_SHIFT
	WHERE Shift_ID = p_Shift_ID;

	COMMIT;
END //
DELIMITER ;






-- MODIFY PHYSICIAN SHIFT
DELIMITER //
CREATE PROCEDURE ModifyPhysicianShift (
	IN p_Shift_ID VARCHAR(50),
	IN p_Shift_Start DATETIME,
	IN p_Shift_end DATETIME,
	IN p_Shift_Type VARCHAR(50)
)
BEGIN
	DECLARE v_shift_exists INT DEFAULT 0;

	SELECT COUNT(*)
	INTO v_shift_exists
	FROM PHYSICIAN_SHIFT
	WHERE Shift_ID = p_Shift_ID;

	IF v_shift_exists = 0 THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Shift_ID does not exist';
	END IF;

	START TRANSACTION;

	UPDATE PHYSICIAN_SHIFT
	SET Shift_Start_Time = p_Shift_Start,
    	Shift_end_Time = p_Shift_end,
    	Shift_Type = p_Shift_Type
	WHERE Shift_ID = p_Shift_ID;

	COMMIT;
END //
DELIMITER ;








-- VIEW PHYSICIAN AVAILABILITY
DELIMITER //
CREATE PROCEDURE GetPhysicianAvailability (
	IN p_Physician_ID VARCHAR(50)
)
BEGIN
	SELECT Slot_ID, Start_Time, End_Time
	FROM TIME_SLOT
	WHERE Physician_ID = p_Physician_ID AND Available = TRUE
	ORDER BY Start_Time;
END //
DELIMITER ;







-- VIEW ROSTER (who’s on duty/call)
DELIMITER //
CREATE PROCEDURE GetRoster()
BEGIN
    SELECT 
        Nurse_ID AS Staff_ID,
        First_Name,
        Last_Name,
        'Nurse' AS Staff_Type,
        NULL AS Physician_Type,
        NULL AS Physician_Rank,
        NULL AS Specialization,
        D.Dept_Name
    FROM NURSE N
    JOIN DEPARTMENT D ON N.Dept_ID = D.Dept_ID

    UNION ALL

    SELECT 
        Physician_ID AS Staff_ID,
        First_Name,
        Last_Name,
        'Physician' AS Staff_Type,
        Physician_Type,
        Physician_Rank,
        S.Specialization,
        D.Dept_Name
    FROM PHYSICIAN P
    JOIN DEPARTMENT D ON P.Dept_ID = D.Dept_ID
    LEFT JOIN SPECIALIZATIONS S ON P.Specialization_ID = S.Specialization_ID;
END//
DELIMITER ;






-- ADD/MODIFY PATIENT PROFILE
DELIMITER //
CREATE PROCEDURE AddOrUpdatePatientProfile (
	IN p_Patient_ID VARCHAR(50),
	IN p_First_Name VARCHAR(100),
	IN p_Last_Name VARCHAR(100),
	IN p_DOB DATE,
	IN p_Insurance_Plan_ID VARCHAR(50),
	IN p_Address VARCHAR(255),
	IN p_Phone VARCHAR(20),
	IN p_Email VARCHAR(100),
	IN p_Gender VARCHAR(20),
	IN p_Sex VARCHAR(20)
)
BEGIN
	INSERT INTO PATIENT (
    	Patient_ID, First_Name, Last_Name, DOB,
    	Insurance_Plan_ID, Address, Phone, Email, Gender, Sex
	)
	VALUES (
    	p_Patient_ID, p_First_Name, p_Last_Name, p_DOB,
    	p_Insurance_Plan_ID, p_Address, p_Phone, p_Email, p_Gender, p_Sex
	)
	ON DUPLICATE KEY UPDATE
    	First_Name = VALUES(First_Name),
    	Last_Name = VALUES(Last_Name),
    	DOB = VALUES(DOB),
    	Insurance_Plan_ID = VALUES(Insurance_Plan_ID),
    	Address = VALUES(Address),
    	Phone = VALUES(Phone),
    	Email = VALUES(Email),
    	Gender = VALUES(Gender),
    	Sex = VALUES(Sex);
END //
DELIMITER ;





-- UPDATE PATIENT ADDRESS
DELIMITER //
CREATE PROCEDURE updatePatientAddress (
	IN p_Patient_ID VARCHAR(50),
	IN p_New_Address VARCHAR(255)
)
BEGIN
	UPDATE PATIENT
	SET Address = p_New_Address
	WHERE Patient_ID = p_Patient_ID;
END //
DELIMITER ;














-- MODIFY PATIENT INSURANCE
DELIMITER // 
CREATE PROCEDURE UpdatePatientInsurance(
	IN p_Patient_ID VARCHAR(50), 
	IN p_Insurance_Plan_ID VARCHAR(50))
BEGIN
	UPDATE PATIENT
	SET Insurance_Plan_ID = p_Insurance_Plan_ID
	WHERE Patient_ID = p_Patient_ID; 
END // 
DELIMITER ; 









-- ADD PHYSICIAN
DELIMITER //
CREATE PROCEDURE AddPhysician (
	IN p_Physician_ID VARCHAR(50),
	IN p_First_Name VARCHAR(50),
	IN p_Last_Name VARCHAR(50),
	IN p_Physician_Type VARCHAR(50),
	IN p_Physician_Rank VARCHAR(50),
	IN p_Dept_ID VARCHAR(50),
	IN p_Specialization_ID VARCHAR(50)
)
BEGIN
	START TRANSACTION;
			INSERT INTO PHYSICIAN (
				Physician_ID, First_Name, Last_Name, Physician_Type, Physician_Rank, Dept_ID, Specialization_ID
			)
			VALUES (
				p_Physician_ID, p_First_Name, p_Last_Name, p_Physician_Type, p_Physician_Rank, p_Dept_ID, p_Specialization_ID
			);

			COMMIT;
END //
DELIMITER ;









-- ADD NURSE
DELIMITER //
CREATE PROCEDURE AddNurse (
	IN p_Nurse_ID VARCHAR(50),
	IN p_First_Name VARCHAR(50),
	IN p_Last_Name VARCHAR(50),
	IN p_Dept_ID VARCHAR(50)
)
BEGIN
	START TRANSACTION;
			INSERT INTO NURSE (
				Nurse_ID, First_Name, Last_Name, Dept_ID
			)
			VALUES (
				p_Nurse_ID, p_First_Name, p_Last_Name, p_Dept_ID
			);

			COMMIT;
END //
DELIMITER ;









-- ADD STAFF
DELIMITER //
CREATE PROCEDURE AddStaff (
	IN p_Staff_ID VARCHAR(50),
	IN p_First_Name VARCHAR(50),
	IN p_Last_Name VARCHAR(50),
	IN p_Staff_Role VARCHAR(50),
	IN p_Dept_ID VARCHAR(50)
)
BEGIN
	START TRANSACTION;
			INSERT INTO STAFF (
				Staff_ID, First_Name, Last_Name, Staff_Role, Dept_ID
			)
			VALUES (
				p_Staff_ID, p_First_Name, p_Last_Name, p_Staff_Role, p_Dept_ID
			);

			COMMIT;
END //
DELIMITER ;










-- ADD NURSE SHIFT 
DELIMITER //
CREATE PROCEDURE AddNurseShift (
	IN p_Shift_ID VARCHAR(50),
	IN p_Nurse_ID VARCHAR(50),
	IN p_Staff_ID VARCHAR(50),
	IN p_Dept_ID VARCHAR(50),
	IN p_Shift_Start DATETIME,
	IN p_Shift_End DATETIME,
	IN p_Shift_Type VARCHAR(50)
)
BEGIN
	DECLARE v_nurse_exists INT DEFAULT 0;
	DECLARE v_shift_exists INT DEFAULT 0;

	START TRANSACTION;

	SELECT COUNT(*) INTO v_nurse_exists
	FROM NURSE
	WHERE Nurse_ID = p_Nurse_ID;

	SELECT COUNT(*) INTO v_shift_exists
	FROM NURSE_SHIFT
	WHERE Nurse_ID = p_Nurse_ID
	  AND (
			p_Shift_Start BETWEEN Shift_Start_Time AND Shift_End_Time
			OR p_Shift_End BETWEEN Shift_Start_Time AND Shift_End_Time
			OR Shift_Start_Time BETWEEN p_Shift_Start AND p_Shift_End
		);

	IF v_shift_exists > 0 THEN
		ROLLBACK;
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'This nurse already has a shift scheduled during this time';
	END IF;

	INSERT INTO NURSE_SHIFT (
		Shift_ID, Nurse_ID, Staff_ID, Dept_ID, Shift_Start_Time, Shift_End_Time, Shift_Type
	)
	VALUES (
		p_Shift_ID, p_Nurse_ID, p_Staff_ID, p_Dept_ID, p_Shift_Start, p_Shift_End, p_Shift_Type
	);

	COMMIT;
END //
DELIMITER ;









-- DELETE NURSE SHIFT
DELIMITER //
CREATE PROCEDURE DeleteNurseShift (
	IN p_Shift_ID VARCHAR(50)
)
BEGIN
	DECLARE v_shift_exists INT DEFAULT 0;

	SELECT COUNT(*) INTO v_shift_exists
	FROM NURSE_SHIFT
	WHERE Shift_ID = p_Shift_ID;

	IF v_shift_exists = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Shift_ID does not exist';
	END IF;

	START TRANSACTION;

	DELETE FROM NURSE_SHIFT
	WHERE Shift_ID = p_Shift_ID;

	COMMIT;
END //
DELIMITER ;







-- MODIFY NURSE SHIFT
DELIMITER //
CREATE PROCEDURE ModifyNurseShift (
	IN p_Shift_ID VARCHAR(50),
	IN p_Shift_Start DATETIME,
	IN p_Shift_End DATETIME,
	IN p_Shift_Type VARCHAR(50)
)
BEGIN
	DECLARE v_shift_exists INT DEFAULT 0;

	SELECT COUNT(*) INTO v_shift_exists
	FROM NURSE_SHIFT
	WHERE Shift_ID = p_Shift_ID;

	IF v_shift_exists = 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Shift_ID does not exist';
	END IF;

	START TRANSACTION;

	UPDATE NURSE_SHIFT
	SET Shift_Start_Time = p_Shift_Start,
		Shift_End_Time = p_Shift_End,
		Shift_Type = p_Shift_Type
	WHERE Shift_ID = p_Shift_ID;

	COMMIT;
END //
DELIMITER ;




-- VIEW OUTSTANDING BALANCES FOR A PATIENT 
DELIMITER //
CREATE PROCEDURE PatientOutstandingBills(
    IN p_Patient_ID VARCHAR(50)
)
BEGIN
    -- Select all bills (given a patient) that aren't Paid
    SELECT 
        Bill_ID, 
        Balance_Due, 
        Payment_Status
    FROM 
        BILL
    WHERE 
        Patient_ID = p_Patient_ID 
        AND Payment_Status IN ('Pending', 'Overdue');
END //
DELIMITER ;








