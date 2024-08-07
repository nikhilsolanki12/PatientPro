CREATE DATABASE hospital_management;
USE hospital_management;


--Patient Table
---------------
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Age INT,
    Gender CHAR(1),
    ContactInfo NVARCHAR(100),
    MedicalHistory NVARCHAR(MAX)
);


--Doctors Table
---------------
CREATE TABLE Doctors (
    DoctorID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Specialization NVARCHAR(100),
    ContactInfo NVARCHAR(100),
    Availability NVARCHAR(100)
);


-- Appointments Table
---------------------
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT FOREIGN KEY REFERENCES Patients(PatientID),
    DoctorID INT FOREIGN KEY REFERENCES Doctors(DoctorID),
    AppointmentDateTime DATETIME NOT NULL,
    Status NVARCHAR(50)
);


--MedialRecords Table
--------------------
CREATE TABLE MedicalRecords (
    RecordID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT FOREIGN KEY REFERENCES Patients(PatientID),
    DoctorID INT FOREIGN KEY REFERENCES Doctors(DoctorID),
    Diagnosis NVARCHAR(255),
    Treatment NVARCHAR(MAX),
    Prescription NVARCHAR(MAX),
    RecordDate DATETIME
);






CREATE VIEW UpcomingAppointments AS
SELECT d.DoctorID, d.FirstName AS DoctorFirstName, d.LastName AS DoctorLastName, a.AppointmentID, a.AppointmentDateTime, p.FirstName AS PatientFirstName, p.LastName AS PatientLastName, a.Status
FROM Appointments a
JOIN Doctors d ON a.DoctorID = d.DoctorID
JOIN Patients p ON a.PatientID = p.PatientID
WHERE a.AppointmentDateTime >= GETDATE();


CREATE TRIGGER trg_UpdateAppointmentStatus
ON Appointments
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Appointments
    SET Status = 'Completed'
    WHERE AppointmentDateTime < GETDATE() AND Status = 'Scheduled';
END;


CREATE TRIGGER trg_DeletePatient
ON Patients
AFTER DELETE
AS
BEGIN
    DELETE FROM Appointments WHERE PatientID IN (SELECT PatientID FROM DELETED);
    DELETE FROM MedicalRecords WHERE PatientID IN (SELECT PatientID FROM DELETED);
END;

CREATE TRIGGER trg_AppointmentNotification
ON Appointments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Placeholder for notification logic (email/system alerts)
    PRINT 'Notification: Appointment scheduled, updated, or canceled.';
END;

SELECT * FROM UpcomingAppointments
WHERE DoctorID = 1;




-- Input data to tables
--------

INSERT INTO Patients (FirstName, LastName, Age, Gender, ContactInfo, MedicalHistory)
VALUES ('John', 'Doe', 30, 'M', '1234567890', 'No significant medical history');
INSERT INTO Doctors (FirstName, LastName, Specialization, ContactInfo, Availability)
VALUES ('Jane', 'Smith', 'Cardiology', '0987654321', 'TRUE');

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDateTime)
VALUES (1, 1, '2024-08-10 10:00:00');

INSERT INTO Patients (FirstName, LastName, Age, Gender, ContactInfo, MedicalHistory)
VALUES 
('Jane', 'Smith', 25, 'F', 'jane.smith@example.com', 'Allergic to penicillin.'),
('Alice', 'Brown', 40, 'F', 'alice.brown@example.com', 'History of hypertension.');


INSERT INTO Doctors (FirstName, LastName, Specialization, ContactInfo, Availability)
VALUES 
('Dr. James', 'Wilson', 'Cardiologist', 'dr.james.wilson@example.com', 'Mon-Fri 9am-5pm'),
('Dr. Emily', 'Clark', 'Dermatologist', 'dr.emily.clark@example.com', 'Tue-Thu 10am-4pm'),
('Dr. Michael', 'Jones', 'General Practitioner', 'dr.michael.jones@example.com', 'Mon-Wed 8am-3pm, Fri 8am-12pm');

INSERT INTO Appointments (PatientID, DoctorID, AppointmentDateTime, Status)
VALUES 
(1, 1, '2024-08-10 10:00:00', 'Scheduled'),
(2, 2, '2024-08-11 11:00:00', 'Scheduled'),
(3, 3, '2024-08-12 09:00:00', 'Scheduled');

INSERT INTO MedicalRecords (PatientID, DoctorID, Diagnosis, Treatment, Prescription, RecordDate)
VALUES 
(1, 1, 'Hypertension', 'Lifestyle changes, prescribed medication.', 'Lisinopril 10mg daily', '2024-08-01'),
(2, 2, 'Eczema', 'Topical corticosteroids.', 'Hydrocortisone cream', '2024-08-02'),
(3, 3, 'General checkup', 'Routine checkup, all vitals normal.', 'None', '2024-08-03');


CREATE PROCEDURE GetPatientHistories
    @PatientID INT
AS
BEGIN
    -- Retrieve patient medical histories along with patient and doctor details
    SELECT 
        p.FirstName AS PatientFirstName,
        p.LastName AS PatientLastName,
        m.Diagnosis,
        m.Treatment,
        m.Prescription,
        m.RecordDate,
        d.FirstName AS DoctorFirstName,
        d.LastName AS DoctorLastName
    FROM 
        MedicalRecords m
    JOIN 
        Patients p ON m.PatientID = p.PatientID
    JOIN 
        Doctors d ON m.DoctorID = d.DoctorID
    WHERE 
        p.PatientID = @PatientID
    ORDER BY 
        m.RecordDate DESC;
END;

Exec GetPatientHistories @PatientID=1


CREATE PROCEDURE ScheduleAppointment
    @PatientID INT,
    @DoctorID INT,
    @AppointmentDateTime DATETIME,
    @Status NVARCHAR(50)
AS
BEGIN
    -- Check if the doctor is available at the requested time
    IF EXISTS (
        SELECT 1
        FROM Appointments
        WHERE DoctorID = @DoctorID
        AND AppointmentDateTime = @AppointmentDateTime
    )
    BEGIN
        -- If there is a conflict, return an error message
        RAISERROR('The doctor is not available at the requested time.', 16, 1);
        RETURN;
    END

    -- Insert the new appointment into the table
    INSERT INTO Appointments (PatientID, DoctorID, AppointmentDateTime, Status)
    VALUES (@PatientID, @DoctorID, @AppointmentDateTime, @Status);

    -- Return a success message
    PRINT 'Appointment scheduled successfully.';
END;

CREATE PROCEDURE GetDoctorAppointments
    @DoctorID INT
AS
BEGIN
    -- Select appointments for the given doctor
    SELECT 
        a.AppointmentID, 
        a.PatientID, 
        p.FirstName AS PatientFirstName, 
        p.LastName AS PatientLastName, 
        a.AppointmentDateTime, 
        a.Status
    FROM Appointments a
    JOIN Patients p ON a.PatientID = p.PatientID
    WHERE a.DoctorID = @DoctorID
    ORDER BY a.AppointmentDateTime;
END;


EXEC GetDoctorAppointments @DoctorID = 1;
