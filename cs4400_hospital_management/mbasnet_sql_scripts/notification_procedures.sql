-- Insert a New Notification for a Patient
DELIMITER //
CREATE PROCEDURE AddNotification (
    IN in_PatientID INT,
    IN in_MessageContent TEXT,
    IN in_Status VARCHAR(50),
    IN in_Priority VARCHAR(50)
)
BEGIN
    INSERT INTO Notification (PatientID, MessageContent, DateCreated, Status, Priority)
    Values (in_PatientID, in_MessageContent, NOW(), in_Status, in_Priority);
END //
DELIMITER ;

-- View All Notifications for a Patient (Newest First)
DELIMITER //
CREATE PROCEDURE GetNotificationsByPatient (
    IN in_PatientID INT
)
BEGIN
    SELECT *
    FROM Notification
    WHERE PatientID = in_PatientID
    ORDER BY DateCreated DESC;
END //
DELIMITER ;

-- View Only Unread Notifications for a Patient
DELIMITER //
CREATE PROCEDURE GetUnreadNotifications (
    IN in_PatientID INT
)
BEGIN
    SELECT *
    FROM Notification
    WHERE PatientID = in_PatientID AND Status = 'Unread'
    ORDER BY DateCreated DESC;
END //
DELIMITER ;

-- Mark a Notification as Read or Archived
DELIMITER //
CREATE PROCEDURE UpdateNotificationStatus (
    IN in_NotificationID INT,
    IN in_Status VARCHAR(50)
)
BEGIN
    UPDATE Notification
    SET Status = in_Status
    WHERE NotificationID = in_NotificationID;
END //
DELIMITER ;

