
CREATE DATABASE ExaminationSystem
ON PRIMARY (
    NAME = 'Exam_Primary',
    FILENAME = 'C:\Users\modern\ITI\ProjectSql\Data\Exam_Primary.mdf'
),
FILEGROUP FG_StaticData (
    NAME = 'StaticData',
    FILENAME = 'C:\Users\modern\ITI\ProjectSql\Data\StaticData.ndf'
),
FILEGROUP FG_Transactional (
    NAME = 'TransactionalData',
    FILENAME = 'C:\Users\modern\ITI\ProjectSql\Data\TransactionalData.ndf'
),
FILEGROUP FG_Indexes (
    NAME = 'Exam_Indexes',
    FILENAME = 'C:\Users\modern\ITI\ProjectSql\Data\Exam_Indexes.ndf'
);
GO

USE ExaminationSystem;
GO



CREATE TABLE Roles (
    ID   INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(50) UNIQUE
) ON FG_StaticData;
GO

CREATE TABLE Branches (
    ID   INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) UNIQUE
) ON FG_StaticData;
GO

CREATE TABLE Departments (
    ID   INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) UNIQUE
) ON FG_StaticData;
GO

CREATE TABLE Intake (
    ID       INT PRIMARY KEY IDENTITY(1,1),
    Name     NVARCHAR(50),
    BranchID INT,
    CONSTRAINT FK_Intake_Branch FOREIGN KEY (BranchID) REFERENCES Branches(ID)
) ON FG_StaticData;
GO

CREATE TABLE Track (
    ID     INT PRIMARY KEY IDENTITY(1,1),
    Name   NVARCHAR(100) UNIQUE,
    DeptID INT,
    CONSTRAINT FK_Track_Department FOREIGN KEY (DeptID) REFERENCES Departments(ID)
) ON FG_StaticData;
GO

CREATE TABLE Track_Intake (
    TrackID  INT FOREIGN KEY REFERENCES Track(ID),
    IntakeID INT FOREIGN KEY REFERENCES Intake(ID),
    PRIMARY KEY (TrackID, IntakeID)
);
GO

CREATE TABLE Branch_Track (
    BranchID INT FOREIGN KEY REFERENCES Branches(ID),
    TrackID  INT FOREIGN KEY REFERENCES Track(ID),
    PRIMARY KEY (BranchID, TrackID)
);
GO

CREATE TABLE Users (
    ID       INT PRIMARY KEY IDENTITY(1,1),
    Name     NVARCHAR(50),
    Password NVARCHAR(255),
    Email    NVARCHAR(100) UNIQUE,
    RoleID   INT,
    CONSTRAINT FK_Role_User FOREIGN KEY (RoleID) REFERENCES Roles(ID)
) ON FG_Transactional;
GO

CREATE TABLE Instructor (
    ID     INT PRIMARY KEY IDENTITY(1,1),
    Name   NVARCHAR(100),
    Phone  NVARCHAR(20),
    Email  NVARCHAR(100),
    UserID INT,
    CONSTRAINT Email_const    UNIQUE (Email),
    CONSTRAINT FK_Ins_User    FOREIGN KEY (UserID) REFERENCES Users(ID)
) ON FG_Transactional;
GO

CREATE TABLE Student (
    ID       INT PRIMARY KEY IDENTITY(1,1),
    Name     NVARCHAR(100),
    Phone    NVARCHAR(20),
    Email    NVARCHAR(100),
    UserID   INT,
    TrackID  INT,
    BranchID INT,
    IntakeID INT,
    CONSTRAINT StEmail_const      UNIQUE (Email),
    CONSTRAINT FK_Student_User    FOREIGN KEY (UserID)   REFERENCES Users(ID),
    CONSTRAINT FK_Student_Track   FOREIGN KEY (TrackID)  REFERENCES Track(ID),
    CONSTRAINT FK_Student_Branch  FOREIGN KEY (BranchID) REFERENCES Branches(ID),
    CONSTRAINT FK_Student_Intake  FOREIGN KEY (IntakeID) REFERENCES Intake(ID)
) ON FG_Transactional;
GO

CREATE TABLE Course (
    ID          INT PRIMARY KEY IDENTITY(1,1),
    Name        NVARCHAR(100) UNIQUE,
    Description NVARCHAR(MAX),
    MaxDegree   INT,
    MinDegree   INT
) ON FG_StaticData;
GO

CREATE TABLE Question (
    ID         INT PRIMARY KEY IDENTITY(1,1),
    Text       NVARCHAR(MAX),
    Type       NVARCHAR(50),   -- MCQ, T/F, Text
    BestAnswer NVARCHAR(MAX),
    CourseID   INT,
    CONSTRAINT CHK_QuestionType    CHECK (Type IN ('MCQ', 'T/F', 'Text')),
    CONSTRAINT FK_Question_Course  FOREIGN KEY (CourseID) REFERENCES Course(ID)
) ON FG_Transactional;
GO

CREATE TABLE Choice (
    ChoiceID   INT PRIMARY KEY IDENTITY(1,1),
    ChoiceText NVARCHAR(MAX),
    IsCorrect  BIT,
    QuestionID INT,
    CONSTRAINT FK_Choice_Question FOREIGN KEY (QuestionID)
        REFERENCES Question(ID) ON DELETE CASCADE
) ON FG_Transactional;
GO

CREATE TABLE Exam (
    ID               INT PRIMARY KEY IDENTITY(1,1),
    StartTime        DATETIME NOT NULL,
    EndTime          DATETIME NOT NULL,
    Type             NVARCHAR(50),
    Year             INT,
    AllowanceOptions NVARCHAR(MAX),
    TrackID          INT,
    IntakeID         INT,
    InsID            INT,
    CourseID         INT,
    CONSTRAINT FK_Exam_Track       FOREIGN KEY (TrackID)  REFERENCES Track(ID),
    CONSTRAINT FK_Exam_Intake      FOREIGN KEY (IntakeID) REFERENCES Intake(ID),
    CONSTRAINT FK_Exam_Instructor  FOREIGN KEY (InsID)    REFERENCES Instructor(ID),
    CONSTRAINT FK_Exam_Course      FOREIGN KEY (CourseID) REFERENCES Course(ID),
    CONSTRAINT CHK_ExamTime        CHECK (EndTime > StartTime)
) ON FG_Transactional;
GO

CREATE TABLE Question_Exam (
    QuestionID INT,
    ExamID     INT,
    Degree     INT,
    CONSTRAINT PK_Question_Exam PRIMARY KEY (QuestionID, ExamID),
    CONSTRAINT FK_QE_Question   FOREIGN KEY (QuestionID) REFERENCES Question(ID),
    CONSTRAINT FK_QE_Exam       FOREIGN KEY (ExamID)     REFERENCES Exam(ID)
);
GO

-- Add Exam_Result, Attendance_Degree, Project_Degree,
--          Total_Result, Course_Grade so TR_AutoCalculateResults works.
CREATE TABLE Student_Ans (
    AnsID      INT PRIMARY KEY IDENTITY(1,1),
    StudentAns NVARCHAR(MAX),
    IsCorrect  BIT DEFAULT 0,
    Degree     INT DEFAULT 0,
    StdID      INT,
    ExamID     INT,
    QuestionID INT,
    CONSTRAINT Stans_un         UNIQUE (StdID, ExamID, QuestionID),
    CONSTRAINT FK_Ans_Student   FOREIGN KEY (StdID)      REFERENCES Student(ID),
    CONSTRAINT FK_Ans_Exam      FOREIGN KEY (ExamID)     REFERENCES Exam(ID),
    CONSTRAINT FK_Ans_Question  FOREIGN KEY (QuestionID) REFERENCES Question(ID)
) ON FG_Transactional;
GO

CREATE TABLE Student_Course (
    StdID             INT,
    CourseID          INT,
    IntakeID          INT,
    Exam_Result       INT DEFAULT 0,
    Attendance_Degree INT DEFAULT 0,
    Project_Degree    INT DEFAULT 0,
    Total_Result      INT DEFAULT 0,
    Course_Grade      CHAR(1),
    CONSTRAINT PK_Student_Course  PRIMARY KEY (StdID, CourseID),
    CONSTRAINT FK_SC_Student      FOREIGN KEY (StdID)    REFERENCES Student(ID),
    CONSTRAINT FK_SC_Course       FOREIGN KEY (CourseID) REFERENCES Course(ID),
    CONSTRAINT FK_SC_Intake       FOREIGN KEY (IntakeID) REFERENCES Intake(ID)
);
GO

CREATE TABLE Student_Exam (
    StdID  INT NOT NULL,
    ExamID INT NOT NULL,
    CONSTRAINT FK_StdExam_Student FOREIGN KEY (StdID)  REFERENCES Student(ID),
    CONSTRAINT FK_StdExam_Exam    FOREIGN KEY (ExamID) REFERENCES Exam(ID),
    PRIMARY KEY (StdID, ExamID)
) ON FG_Transactional;
GO

CREATE TABLE Branch_Exam (
    ExamID   INT NOT NULL,
    BranchID INT NOT NULL,
    CONSTRAINT FK_BranchExam_Exam   FOREIGN KEY (ExamID)   REFERENCES Exam(ID),
    CONSTRAINT FK_BranchExam_Branch FOREIGN KEY (BranchID) REFERENCES Branches(ID),
    PRIMARY KEY (ExamID, BranchID)
) ON FG_Transactional;
GO

CREATE TABLE Instructor_Course (
    InsID    INT NOT NULL,
    CourseID INT NOT NULL,
    Year     INT NOT NULL,
    IntakeID INT NOT NULL,
    BranchID INT NOT NULL,
    TrackID  INT NOT NULL,
    CONSTRAINT FK_InsCourse_Instructor FOREIGN KEY (InsID)    REFERENCES Instructor(ID),
    CONSTRAINT FK_InsCourse_Course     FOREIGN KEY (CourseID) REFERENCES Course(ID),
    CONSTRAINT FK_InsCourse_Intake     FOREIGN KEY (IntakeID) REFERENCES Intake(ID),
    CONSTRAINT FK_InsCourse_Branch     FOREIGN KEY (BranchID) REFERENCES Branches(ID),
    CONSTRAINT FK_InsCourse_Track      FOREIGN KEY (TrackID)  REFERENCES Track(ID),
    PRIMARY KEY (InsID, CourseID, Year, IntakeID, BranchID, TrackID)
) ON FG_Transactional;
GO

-- Omar Monir
CREATE INDEX IDX_Student_Email    ON Student(Email)     ON FG_Indexes;
GO
CREATE INDEX IDX_Users_Email      ON Users(Email)       ON FG_Indexes;
GO
CREATE INDEX IDX_Question_CourseID ON Question(CourseID) ON FG_Indexes;
GO

-- text questions (suggested score 0-100)
CREATE FUNCTION FN_CheckTextAnswer (
    @StudentAns NVARCHAR(MAX),
    @BestAns    NVARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
    DECLARE @Score INT = 0;
    IF @StudentAns = @BestAns                          SET @Score = 100;
    ELSE IF @StudentAns LIKE '%' + @BestAns + '%'      SET @Score = 80;
    ELSE IF @BestAns    LIKE '%' + @StudentAns + '%'   SET @Score = 50;
    RETURN @Score;
END;
GO

-- Pass / Fail based on MinDegree
CREATE FUNCTION FN_GetStudentStatus (@TotalResult INT, @MinDegree INT)
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN CASE WHEN @TotalResult >= @MinDegree THEN 'Passed' ELSE 'Failed' END;
END;
GO

-- Submit an answer; TR_CheckAnswer sets IsCorrect and Degree automatically
CREATE PROC SubmitAnswer
    @StdID      INT,
    @ExamID     INT,
    @QuestionID INT,
    @Answer     NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO Student_Ans (StudentAns, StdID, ExamID, QuestionID)
    VALUES (@Answer, @StdID, @ExamID, @QuestionID);
END;
GO

CREATE PROC CalculateExamResult @StdID INT, @ExamID INT
AS
BEGIN
    SELECT SUM(Degree) AS TotalDegree
    FROM Student_Ans
    WHERE StdID = @StdID AND ExamID = @ExamID;
END;
GO

CREATE PROC SP_StartExam @StdID INT, @ExamID INT
AS
BEGIN
    DECLARE @StartTime DATETIME, @EndTime DATETIME, @CourseID INT;

    SELECT @StartTime = StartTime, @EndTime = EndTime, @CourseID = CourseID
    FROM Exam WHERE ID = @ExamID;

    IF @CourseID IS NULL
    BEGIN PRINT 'Exam does not exist.'; RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Student_Course WHERE StdID = @StdID AND CourseID = @CourseID)
    BEGIN PRINT 'Student is not enrolled in this course.'; RETURN; END

    IF GETDATE() BETWEEN @StartTime AND @EndTime
    BEGIN
        PRINT 'You can start the exam.';
        IF NOT EXISTS (SELECT 1 FROM Student_Exam WHERE StdID = @StdID AND ExamID = @ExamID)
            INSERT INTO Student_Exam (StdID, ExamID) VALUES (@StdID, @ExamID);
    END
    ELSE
        PRINT 'Exam is not active at this time.';
END;
GO

CREATE PROC SP_AddBranch @Name NVARCHAR(100)
AS
BEGIN
    INSERT INTO Branches (Name) VALUES (@Name);
END;
GO

CREATE PROC SP_AddTrack @Name NVARCHAR(100), @DeptID INT
AS
BEGIN
    INSERT INTO Track (Name, DeptID) VALUES (@Name, @DeptID);
END;
GO

CREATE PROC SP_AddIntake @Name NVARCHAR(50), @BranchID INT
AS
BEGIN
    INSERT INTO Intake (Name, BranchID) VALUES (@Name, @BranchID);
END;
GO

CREATE PROC SP_AssignInstructorToCourse
    @InsID    INT, @CourseID INT, @Year INT,
    @IntakeID INT, @BranchID INT, @TrackID INT
AS
BEGIN
    INSERT INTO Instructor_Course (InsID, CourseID, Year, IntakeID, BranchID, TrackID)
    VALUES (@InsID, @CourseID, @Year, @IntakeID, @BranchID, @TrackID);
END;
GO

CREATE TRIGGER TR_CheckDegree
ON Question_Exam
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM (
            SELECT qe.ExamID, SUM(qe.Degree) AS ExistingTotal
            FROM Question_Exam qe
            GROUP BY qe.ExamID
        ) existing
        JOIN (
            SELECT i.ExamID, SUM(i.Degree) AS NewTotal
            FROM inserted i
            GROUP BY i.ExamID
        ) incoming ON existing.ExamID = incoming.ExamID
        JOIN Exam e   ON e.ID = existing.ExamID
        JOIN Course c ON c.ID = e.CourseID
        WHERE (existing.ExistingTotal + incoming.NewTotal) > c.MaxDegree
    )
    BEGIN
        RAISERROR('Total exam degree would exceed the course MaxDegree.', 16, 1);
        RETURN;
    END;

    -- Also check exams that have no existing rows yet (first insert)
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT i.ExamID, SUM(i.Degree) AS NewTotal
            FROM inserted i
            GROUP BY i.ExamID
        ) incoming
        JOIN Exam e   ON e.ID = incoming.ExamID
        JOIN Course c ON c.ID = e.CourseID
        WHERE incoming.NewTotal > c.MaxDegree
        AND NOT EXISTS (SELECT 1 FROM Question_Exam qe WHERE qe.ExamID = incoming.ExamID)
    )
    BEGIN
        RAISERROR('Total exam degree would exceed the course MaxDegree.', 16, 1);
        RETURN;
    END;

    INSERT INTO Question_Exam (QuestionID, ExamID, Degree)
    SELECT QuestionID, ExamID, Degree FROM inserted;
END;
GO

--  TR_CheckAnswer now awards the actual per-question Degree
--          from Question_Exam, not a hardcoded 1/0.
--          Text questions are NOT auto-graded here; they stay at
--          Degree=0 and IsCorrect=0 until the instructor reviews them
--          using FN_CheckTextAnswer.
CREATE TRIGGER TR_CheckAnswer
ON Student_Ans
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sa
    SET
        IsCorrect = CASE
                        WHEN q.Type IN ('MCQ', 'T/F') AND sa.StudentAns = q.BestAnswer THEN 1
                        ELSE 0
                    END,
        Degree    = CASE
                        WHEN q.Type IN ('MCQ', 'T/F') AND sa.StudentAns = q.BestAnswer
                             THEN ISNULL(qe.Degree, 0)
                        ELSE 0
                    END
    FROM Student_Ans sa
    JOIN inserted    i  ON sa.AnsID     = i.AnsID
    JOIN Question    q  ON q.ID         = sa.QuestionID
    LEFT JOIN Question_Exam qe
                         ON qe.QuestionID = sa.QuestionID
                        AND qe.ExamID     = sa.ExamID;
END;
GO

CREATE VIEW V_StudentResults
AS
SELECT
    s.ID  AS StudentID,
    s.Name,
    e.ID  AS ExamID,
    dbo.FN_GetStudentExamDegree(s.ID, e.ID) AS TotalDegree
FROM Student s
JOIN Student_Exam se ON s.ID  = se.StdID
JOIN Exam e          ON e.ID  = se.ExamID;
GO

CREATE VIEW V_ExamDetails
AS
SELECT
    e.ID         AS ExamID,
    c.Name       AS CourseName,
    q.Text       AS Question,
    q.Type       AS QuestionType,
    qe.Degree
FROM Exam e
JOIN Course c        ON e.CourseID  = c.ID
JOIN Question_Exam qe ON e.ID        = qe.ExamID
JOIN Question q      ON q.ID        = qe.QuestionID;
GO

-- Encrypted so grading logic is hidden from students
CREATE VIEW VW_StudentAnswer WITH ENCRYPTION
AS
SELECT
    Std.[Name]      AS [Student Name],
    Crs.[Name]      AS [Course Name],
    Ques.[Text]     AS Question,
    Ques.[Type]     AS QuestionType,
    StdAns.StudentAns AS [Student Answer],
    StdAns.IsCorrect  AS [Is Correct],
    StdAns.Degree     AS [Score Awarded]
FROM Student Std
JOIN Student_Ans StdAns ON Std.ID       = StdAns.StdID
JOIN Exam                ON Exam.ID      = StdAns.ExamID
JOIN Question Ques       ON Ques.ID      = StdAns.QuestionID
JOIN Course Crs          ON Crs.ID       = Exam.CourseID;
GO

-- Instructor: manage questions, create exams, review answers
CREATE USER InstructorUser FOR LOGIN InstructorLogin;
GRANT SELECT, INSERT, UPDATE ON Question         TO InstructorUser;
GRANT SELECT, INSERT, UPDATE ON Choice           TO InstructorUser;
GRANT SELECT, INSERT, UPDATE ON Question_Exam    TO InstructorUser;
GRANT SELECT                 ON Student          TO InstructorUser;
GRANT SELECT                 ON Student_Ans      TO InstructorUser;
GRANT SELECT                 ON Student_Exam     TO InstructorUser;
GRANT SELECT                 ON Exam             TO InstructorUser;
GRANT INSERT                 ON Exam             TO InstructorUser;
GRANT SELECT                 ON V_ExamDetails    TO InstructorUser;
GRANT EXECUTE ON SP_AddQuestion         TO InstructorUser;
GRANT EXECUTE ON SP_AddQuestionToExam   TO InstructorUser;
GRANT EXECUTE ON CreateExam             TO InstructorUser;
GRANT EXECUTE ON GenerateExamQuestions  TO InstructorUser;
GRANT EXECUTE ON AssignExamToStudents   TO InstructorUser;
GO

-- Training Manager now has access to infrastructure tables
CREATE USER TrainingManagerUser FOR LOGIN TrainingManagerLogin;
GRANT SELECT, INSERT, UPDATE ON Branches    TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Departments TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Track       TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Intake      TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Track_Intake  TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Branch_Track  TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Course      TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Instructor  TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Student     TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Exam        TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Instructor_Course TO TrainingManagerUser;
GRANT SELECT, INSERT, UPDATE ON Student_Course    TO TrainingManagerUser;
GRANT EXECUTE ON SP_AddBranch               TO TrainingManagerUser;
GRANT EXECUTE ON SP_AddTrack                TO TrainingManagerUser;
GRANT EXECUTE ON SP_AddIntake               TO TrainingManagerUser;
GRANT EXECUTE ON SP_AddStudent              TO TrainingManagerUser;
GRANT EXECUTE ON SP_AddInstructor           TO TrainingManagerUser;
GRANT EXECUTE ON SP_AddCourse               TO TrainingManagerUser;
GRANT EXECUTE ON SP_AssignInstructorToCourse TO TrainingManagerUser;
GRANT EXECUTE ON CreateExam                 TO TrainingManagerUser;
GRANT EXECUTE ON GenerateExamQuestions      TO TrainingManagerUser;
GRANT EXECUTE ON AssignExamToStudents       TO TrainingManagerUser;
GO

CREATE LOGIN InstructorLogin      WITH PASSWORD = 'Instructor@123';
CREATE LOGIN TrainingManagerLogin WITH PASSWORD = 'TrainingManager@123';

--mohamed mostafa

CREATE NONCLUSTERED INDEX IX_StdAns ON Student_Ans(StdID);
GO
CREATE NONCLUSTERED INDEX IX_CrsId  ON Exam(CourseID);
GO



-- Total score a student earned in a specific exam
CREATE FUNCTION FN_GetStudentExamDegree (@StdID INT, @ExamID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Total INT;
    SELECT @Total = ISNULL(SUM(Degree), 0)
    FROM Student_Ans
    WHERE StdID = @StdID AND ExamID = @ExamID;
    RETURN @Total;
END;
GO

-- Convert raw exam score to a percentage of MaxDegree
CREATE FUNCTION FN_CalcTotalCourseDegree (@MaxDegree INT, @ExamRes INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalResultCourse INT;
    SET @ExamRes = ISNULL(@ExamRes, 0);
    IF (@MaxDegree > 0)
        SET @TotalResultCourse = (@ExamRes * 100) / @MaxDegree;
    ELSE
        SET @TotalResultCourse = 0;
    RETURN @TotalResultCourse;
END;
GO



--  SP_AddStudent now accepts full profile and links to Users
CREATE PROC SP_AddStudent
    @Name     NVARCHAR(100),
    @Phone    NVARCHAR(20),
    @Email    NVARCHAR(100),
    @Password NVARCHAR(255),
    @TrackID  INT,
    @BranchID INT,
    @IntakeID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @UserID INT;
    DECLARE @RoleID INT;

    SELECT @RoleID = ID FROM Roles WHERE Name = 'Student';

    -- Create login record in Users
    INSERT INTO Users (Name, Password, Email, RoleID)
    VALUES (@Name, @Password, @Email, @RoleID);

    SET @UserID = SCOPE_IDENTITY();

    -- Create student profile
    INSERT INTO Student (Name, Phone, Email, UserID, TrackID, BranchID, IntakeID)
    VALUES (@Name, @Phone, @Email, @UserID, @TrackID, @BranchID, @IntakeID);
END;
GO

--  SP_AddInstructor now links to Users
CREATE PROC SP_AddInstructor
    @Name     NVARCHAR(200),
    @Phone    NVARCHAR(20),
    @Email    NVARCHAR(200),
    @Password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @UserID INT;
    DECLARE @RoleID INT;

    SELECT @RoleID = ID FROM Roles WHERE Name = 'Instructor';

    INSERT INTO Users (Name, Password, Email, RoleID)
    VALUES (@Name, @Password, @Email, @RoleID);

    SET @UserID = SCOPE_IDENTITY();

    INSERT INTO Instructor (Name, Phone, Email, UserID)
    VALUES (@Name, @Phone, @Email, @UserID);
END;
GO

CREATE PROC SP_AddCourse
    @Name        NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @MaxDegree   INT,
    @MinDegree   INT
AS
BEGIN
    INSERT INTO Course (Name, Description, MaxDegree, MinDegree)
    VALUES (@Name, @Description, @MaxDegree, @MinDegree);
END;
GO

CREATE PROC SP_AddQuestion
    @QuesText   NVARCHAR(MAX),
    @Type       NVARCHAR(50),
    @BestAnswer NVARCHAR(MAX),
    @CourseID   INT
AS
BEGIN
    INSERT INTO Question ([Text], [Type], BestAnswer, CourseID)
    VALUES (@QuesText, @Type, @BestAnswer, @CourseID);
END;
GO

--  Manual question selection for an exam
CREATE PROC SP_AddQuestionToExam
    @QuestionID INT,
    @ExamID     INT,
    @Degree     INT
AS
BEGIN
    -- Verify the question belongs to the same course as the exam
    IF NOT EXISTS (
        SELECT 1
        FROM Question q
        JOIN Exam e ON e.CourseID = q.CourseID
        WHERE q.ID = @QuestionID AND e.ID = @ExamID
    )
    BEGIN
        RAISERROR('Question does not belong to the course of this exam.', 16, 1);
        RETURN;
    END

    -- TR_CheckDegree will enforce the MaxDegree constraint on insert
    INSERT INTO Question_Exam (QuestionID, ExamID, Degree)
    VALUES (@QuestionID, @ExamID, @Degree);
END;
GO

CREATE PROC CreateExam
    @StartTime        DATETIME,
    @EndTime          DATETIME,
    @Type             NVARCHAR(50),
    @Year             INT,
    @TrackID          INT,
    @IntakeID         INT,
    @InsID            INT,
    @CourseID         INT,
    @AllowanceOptions NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO Exam (StartTime, EndTime, Type, Year, TrackID, IntakeID, InsID, CourseID, AllowanceOptions)
    VALUES (@StartTime, @EndTime, @Type, @Year, @TrackID, @IntakeID, @InsID, @CourseID, @AllowanceOptions);
END;
GO

--- GenerateExamQuestions now accepts per-type counts.
--          @Degree is the point value assigned to every question added.
CREATE PROC GenerateExamQuestions
    @ExamID    INT,
    @CourseID  INT,
    @NumMCQ    INT = 0,
    @NumTF     INT = 0,
    @NumText   INT = 0,
    @Degree    INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @NumMCQ > 0
        INSERT INTO Question_Exam (QuestionID, ExamID, Degree)
        SELECT TOP (@NumMCQ) ID, @ExamID, @Degree
        FROM Question
        WHERE CourseID = @CourseID AND Type = 'MCQ'
        ORDER BY NEWID();

    IF @NumTF > 0
        INSERT INTO Question_Exam (QuestionID, ExamID, Degree)
        SELECT TOP (@NumTF) ID, @ExamID, @Degree
        FROM Question
        WHERE CourseID = @CourseID AND Type = 'T/F'
        ORDER BY NEWID();

    IF @NumText > 0
        INSERT INTO Question_Exam (QuestionID, ExamID, Degree)
        SELECT TOP (@NumText) ID, @ExamID, @Degree
        FROM Question
        WHERE CourseID = @CourseID AND Type = 'Text'
        ORDER BY NEWID();
END;
GO

CREATE OR ALTER PROC AssignExamToStudents @ExamID INT
AS
BEGIN
    INSERT INTO Student_Exam (StdID, ExamID)
    SELECT s.ID, @ExamID
    FROM Student s
    JOIN Exam e ON e.ID = @ExamID
    WHERE
        s.TrackID  = e.TrackID
        AND s.IntakeID = e.IntakeID
        AND s.BranchID IN (
            SELECT BranchID FROM Branch_Exam WHERE ExamID = @ExamID
        )
        AND NOT EXISTS (
            SELECT 1 FROM Student_Exam se
            WHERE se.StdID = s.ID AND se.ExamID = @ExamID
        );
END;
GO




-- : Single correct definition of TR_CheckDegree.
--   Checks the running total INCLUDING the newly inserted rows.

-- TR_AutoCalculateResults now uses the real columns that
--          exist in Student_Course.
CREATE TRIGGER TR_AutoCalculateResults
ON Student_Course
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sc
    SET
        Total_Result = (
            (ISNULL(i.Exam_Result, 0)
             + ISNULL(i.Attendance_Degree, 0)
             + ISNULL(i.Project_Degree, 0)
            ) * 100
        ) / NULLIF(c.MaxDegree, 0),

        Course_Grade = CASE
            WHEN ((ISNULL(i.Exam_Result, 0) + ISNULL(i.Attendance_Degree, 0) + ISNULL(i.Project_Degree, 0)) * 100)
                 / NULLIF(c.MaxDegree, 0) >= 85 THEN 'A'
            WHEN ((ISNULL(i.Exam_Result, 0) + ISNULL(i.Attendance_Degree, 0) + ISNULL(i.Project_Degree, 0)) * 100)
                 / NULLIF(c.MaxDegree, 0) >= 75 THEN 'B'
            WHEN ((ISNULL(i.Exam_Result, 0) + ISNULL(i.Attendance_Degree, 0) + ISNULL(i.Project_Degree, 0)) * 100)
                 / NULLIF(c.MaxDegree, 0) >= 65 THEN 'C'
            WHEN ((ISNULL(i.Exam_Result, 0) + ISNULL(i.Attendance_Degree, 0) + ISNULL(i.Project_Degree, 0)) * 100)
                 / NULLIF(c.MaxDegree, 0) >= 50 THEN 'D'
            ELSE 'F'
        END
    FROM Student_Course sc
    JOIN inserted i ON sc.StdID = i.StdID AND sc.CourseID = i.CourseID
    JOIN Course c   ON c.ID     = sc.CourseID;
END;
GO



CREATE VIEW V_InstructorPerformance
AS
SELECT
    Ins.Name   AS InstructorName,
    Crs.Name   AS CourseName,
    COUNT(StdCrs.StdID) AS NumberOfStudents
FROM Instructor Ins
JOIN Instructor_Course InsCrs ON Ins.ID       = InsCrs.InsID
JOIN Course Crs               ON InsCrs.CourseID = Crs.ID
LEFT JOIN Student_Course StdCrs ON Crs.ID = StdCrs.CourseID
GROUP BY Ins.Name, Crs.Name;
GO

-- Pass/Fail now based on each student's TOTAL exam score,
--           not on individual answer degrees.
CREATE VIEW V_ExamAnalytics
AS
SELECT
    e.ID        AS ExamID,
    c.Name      AS CourseName,
    COUNT(DISTINCT per_student.StdID)                                                    AS TotalStudents,
    SUM(CASE WHEN per_student.TotalScore >= c.MinDegree THEN 1 ELSE 0 END)              AS PassedCount,
    SUM(CASE WHEN per_student.TotalScore <  c.MinDegree THEN 1 ELSE 0 END)              AS FailedCount
FROM Exam e
JOIN Course c ON e.CourseID = c.ID
JOIN (
    SELECT ExamID, StdID, SUM(Degree) AS TotalScore
    FROM Student_Ans
    GROUP BY ExamID, StdID
) per_student ON per_student.ExamID = e.ID
GROUP BY e.ID, c.Name;
GO

CREATE VIEW VW_StudentScheduleExams
AS
SELECT
    Std.Name        AS StudentName,
    Crs.Name        AS CourseName,
    Exam.StartTime,
    Exam.EndTime,
    Exam.Type       AS ExamType
FROM Student Std
JOIN Student_Exam StdExam ON Std.ID        = StdExam.StdID
JOIN Exam                  ON StdExam.ExamID = Exam.ID
JOIN Course Crs            ON Exam.CourseID  = Crs.ID
WHERE Exam.EndTime > GETDATE();
GO

USE master;
GO

CREATE LOGIN AdminLogin           WITH PASSWORD = 'Admin@123';
CREATE LOGIN StudentLogin         WITH PASSWORD = 'Student@123';

GO

USE ExaminationSystem;
GO

-- Admin: full ownership
CREATE USER AdminUser FOR LOGIN AdminLogin;
ALTER ROLE db_owner ADD MEMBER AdminUser;
GO

-- Student: read exams, submit answers, see own results
CREATE USER StudentUser FOR LOGIN StudentLogin;
GRANT SELECT         ON Exam              TO StudentUser;
GRANT SELECT         ON Question          TO StudentUser;
GRANT SELECT         ON Choice            TO StudentUser;
GRANT INSERT         ON Student_Ans       TO StudentUser;
GRANT SELECT         ON V_StudentResults  TO StudentUser;
GRANT SELECT         ON VW_StudentScheduleExams TO StudentUser;
GRANT EXECUTE        ON SP_StartExam      TO StudentUser;
GRANT EXECUTE        ON SubmitAnswer      TO StudentUser;
GRANT EXECUTE        ON CalculateExamResult TO StudentUser;
GO




USE msdb;
GO

EXEC sp_add_job
    @job_name = N'ExaminationSystem_DailyBackup';
GO

EXEC sp_add_jobstep
    @job_name   = N'ExaminationSystem_DailyBackup',
    @step_name  = N'Backup ExaminationSystem DB',
    @subsystem  = N'TSQL',
    @command    = N'
DECLARE @Path NVARCHAR(500);
SET @Path = N''C:\Users\modern\ITI\ProjectSql\Data\ExaminationSystem_''
            + CONVERT(NVARCHAR, GETDATE(), 112)
            + N''.bak'';
BACKUP DATABASE ExaminationSystem
TO DISK = @Path
WITH COMPRESSION, STATS = 10, CHECKSUM;',
    @on_success_action = 1;
GO

EXEC sp_add_schedule
    @schedule_name     = N'DailyAt0200',
    @freq_type         = 4,          -- Daily
    @freq_interval     = 1,
    @active_start_time = 020000;     -- 02:00 AM
GO

EXEC sp_attach_schedule
    @job_name      = N'ExaminationSystem_DailyBackup',
    @schedule_name = N'DailyAt0200';
GO

EXEC sp_add_jobserver
    @job_name = N'ExaminationSystem_DailyBackup';
GO

