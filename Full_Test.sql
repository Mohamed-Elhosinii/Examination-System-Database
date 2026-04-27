-- ============================================================
-- FULL EXAMINATION SYSTEM TEST SUITE
-- Covers: Schema, Functions, SPs, Triggers, Views, Security
-- ============================================================

USE ExaminationSystem;
GO

PRINT '====================================================';
PRINT ' EXAMINATION SYSTEM - COMPLETE TEST SUITE';
PRINT '====================================================';
PRINT '';

-- ============================================================
-- PHASE 0: PREREQUISITE SEED DATA
-- ============================================================
PRINT '--- PHASE 0: Seeding prerequisite lookup data ---';

-- Roles (required by SP_AddStudent and SP_AddInstructor)
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'Student')
    INSERT INTO Roles (Name) VALUES ('Student');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'Instructor')
    INSERT INTO Roles (Name) VALUES ('Instructor');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'TrainingManager')
    INSERT INTO Roles (Name) VALUES ('TrainingManager');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'Admin')
    INSERT INTO Roles (Name) VALUES ('Admin');

-- Department (required by SP_AddTrack @DeptID = 1)
IF NOT EXISTS (SELECT 1 FROM Departments WHERE ID = 1)
    INSERT INTO Departments (Name) VALUES ('Information Technology');

PRINT 'Phase 0 Complete.';
GO


-- ============================================================
-- PHASE 1: INFRASTRUCTURE STORED PROCEDURES
-- ============================================================
PRINT '';
PRINT '--- PHASE 1: Infrastructure & User Entry SPs ---';

-- 1A. SP_AddBranch
EXEC SP_AddBranch @Name = 'Fayoum Branch';
PRINT 'SP_AddBranch: OK';

-- 1B. SP_AddTrack
EXEC SP_AddTrack @Name = 'Full Stack .NET', @DeptID = 1;
PRINT 'SP_AddTrack: OK';

-- 1C. SP_AddIntake
EXEC SP_AddIntake @Name = 'Intake 46', @BranchID = 1;
PRINT 'SP_AddIntake: OK';

-- 1D. SP_AddStudent
EXEC SP_AddStudent
    @Name     = 'Mohamed Elhosinii',
    @Phone    = '01001242109',
    @Email    = 'mohamed@test.com',
    @Password = 'Mohamed@Passw0rd',
    @TrackID  = 1,
    @BranchID = 1,
    @IntakeID = 1;
PRINT 'SP_AddStudent: OK';

-- 1E. SP_AddStudent – second student (used for multi-student tests)
EXEC SP_AddStudent
    @Name     = 'Sara Hassan',
    @Phone    = '01112223333',
    @Email    = 'sara@test.com',
    @Password = 'Sara@Passw0rd',
    @TrackID  = 1,
    @BranchID = 1,
    @IntakeID = 1;
PRINT 'SP_AddStudent (2nd student): OK';

-- 1F. SP_AddInstructor
EXEC SP_AddInstructor
    @Name     = 'Dr. Aliaa',
    @Phone    = '0111222333',
    @Email    = 'aliaa@test.com',
    @Password = 'Aliaa@Passw0rd';
PRINT 'SP_AddInstructor: OK';

-- 1G. SP_AddCourse
EXEC SP_AddCourse
    @Name        = 'SQL Server',
    @Description = 'Database Design & Development',
    @MaxDegree   = 100,
    @MinDegree   = 50;
PRINT 'SP_AddCourse: OK';

-- 1H. SP_AddQuestion – Text type
EXEC SP_AddQuestion
    @QuesText   = 'What is DBMS?',
    @Type       = 'Text',
    @BestAnswer = 'Database Management System',
    @CourseID   = 1;
PRINT 'SP_AddQuestion (Text): OK';

-- 1I. SP_AddQuestion – T/F type
EXEC SP_AddQuestion
    @QuesText   = 'SQL is a programming language',
    @Type       = 'T/F',
    @BestAnswer = 'False',
    @CourseID   = 1;
PRINT 'SP_AddQuestion (T/F): OK';

-- 1J. SP_AddQuestion – MCQ type
EXEC SP_AddQuestion
    @QuesText   = 'Which command is used to retrieve data?',
    @Type       = 'MCQ',
    @BestAnswer = 'SELECT',
    @CourseID   = 1;
PRINT 'SP_AddQuestion (MCQ): OK';

-- Insert MCQ choices for question 3
INSERT INTO Choice (ChoiceText, IsCorrect, QuestionID)
VALUES ('INSERT', 0, 3), ('SELECT', 1, 3), ('UPDATE', 0, 3), ('DELETE', 0, 3);
PRINT 'MCQ choices inserted: OK';

-- Add a 4th question (MCQ) for question-bank variety tests
EXEC SP_AddQuestion
    @QuesText   = 'Which clause filters rows in SQL?',
    @Type       = 'MCQ',
    @BestAnswer = 'WHERE',
    @CourseID   = 1;
INSERT INTO Choice (ChoiceText, IsCorrect, QuestionID)
VALUES ('FROM', 0, 4), ('WHERE', 1, 4), ('HAVING', 0, 4), ('ORDER BY', 0, 4);
PRINT 'SP_AddQuestion (MCQ #2) + choices: OK';

-- 1K. SP_AssignInstructorToCourse
EXEC SP_AssignInstructorToCourse
    @InsID    = 1,
    @CourseID = 1,
    @Year     = 2026,
    @IntakeID = 1,
    @BranchID = 1,
    @TrackID  = 1;
PRINT 'SP_AssignInstructorToCourse: OK';

PRINT 'Phase 1 Complete.';
GO


-- ============================================================
-- PHASE 2: EXAM LIFECYCLE
-- ============================================================
PRINT '';
PRINT '--- PHASE 2: Exam Creation & Validation ---';

-- 2A. CreateExam
DECLARE @Start DATETIME = GETDATE();
DECLARE @End   DATETIME = DATEADD(HOUR, 2, GETDATE());

EXEC CreateExam
    @StartTime = @Start,
    @EndTime   = @End,
    @Type      = 'Final',
    @Year      = 2026,
    @TrackID   = 1,
    @IntakeID  = 1,
    @InsID     = 1,
    @CourseID  = 1;
PRINT 'CreateExam: OK';
GO

-- 2B. CHK_ExamTime constraint – end before start must fail
PRINT 'Testing CHK_ExamTime (EndTime <= StartTime should fail)...';
BEGIN TRY
    INSERT INTO Exam (StartTime, EndTime, Type, Year, TrackID, IntakeID, InsID, CourseID)
    VALUES (GETDATE(), DATEADD(HOUR, -1, GETDATE()), 'Final', 2026, 1, 1, 1, 1);
    PRINT 'CHK_ExamTime: FAILED – constraint did NOT fire';
END TRY
BEGIN CATCH
    PRINT 'CHK_ExamTime: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 2C. Link exam to branch (required by AssignExamToStudents)
INSERT INTO Branch_Exam (ExamID, BranchID) VALUES (1, 1);
PRINT 'Branch_Exam link: OK';
GO

-- 2D. GenerateExamQuestions
EXEC GenerateExamQuestions
    @ExamID   = 1,
    @CourseID = 1,
    @NumMCQ   = 1,
    @NumTF    = 1,
    @NumText  = 0,
    @Degree   = 10;
PRINT 'GenerateExamQuestions (MCQ+TF, 10pts each): OK';
GO

-- 2E. SP_AddQuestionToExam – manual addition
EXEC SP_AddQuestionToExam
    @QuestionID = 1,   -- Text question
    @ExamID     = 1,
    @Degree     = 20;
PRINT 'SP_AddQuestionToExam (manual, Degree=20): OK';
GO

-- 2F. TR_CheckDegree – current total = 10+10+20 = 40; adding 150 must fail
PRINT 'Testing TR_CheckDegree (Degree=150, expected FAIL)...';
BEGIN TRY
    INSERT INTO Question_Exam (QuestionID, ExamID, Degree) VALUES (1, 1, 150);
    PRINT 'TR_CheckDegree: FAILED – trigger did NOT fire';
END TRY
BEGIN CATCH
    PRINT 'TR_CheckDegree: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 2G. SP_AddQuestionToExam – wrong course question must fail
PRINT 'Testing SP_AddQuestionToExam cross-course guard (expected FAIL)...';
BEGIN TRY
    -- Add a question for a different course, then try to attach to exam 1
    INSERT INTO Course (Name, Description, MaxDegree, MinDegree)
    VALUES ('C# Basics', 'OOP with C#', 100, 50);

    INSERT INTO Question ([Text], [Type], BestAnswer, CourseID)
    VALUES ('What is a class?', 'Text', 'A blueprint for objects', 2);

    EXEC SP_AddQuestionToExam @QuestionID = 5, @ExamID = 1, @Degree = 10;
    PRINT 'Cross-course guard: FAILED – SP did NOT raise error';
END TRY
BEGIN CATCH
    PRINT 'Cross-course guard: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 2H. Enroll both students in the course
INSERT INTO Student_Course (StdID, CourseID, IntakeID) VALUES (1, 1, 1);
INSERT INTO Student_Course (StdID, CourseID, IntakeID) VALUES (2, 1, 1);
PRINT 'Student_Course enrolment (both students): OK';
GO

-- 2I. SP_StartExam – valid student
EXEC SP_StartExam @StdID = 1, @ExamID = 1;
PRINT 'SP_StartExam (StdID=1): OK (see PRINT output above)';
GO

-- 2J. SP_StartExam – unenrolled student (StdID=2 not in Student_Course for wrong course)
--     We'll test with a non-existent student to verify guard
PRINT 'Testing SP_StartExam with non-existent student (should warn)...';
EXEC SP_StartExam @StdID = 999, @ExamID = 1;
GO

-- 2K. AssignExamToStudents
EXEC AssignExamToStudents @ExamID = 1;
PRINT 'AssignExamToStudents: OK';
GO

-- 2L. Verify Student_Exam rows assigned
SELECT StdID, ExamID FROM Student_Exam WHERE ExamID = 1;
GO


-- ============================================================
-- PHASE 3: ANSWER SUBMISSION & AUTO-GRADING
-- ============================================================
PRINT '';
PRINT '--- PHASE 3: Answer Submission & Auto-Grading ---';

-- 3A. Correct T/F answer
EXEC SubmitAnswer @StdID = 1, @ExamID = 1, @QuestionID = 2, @Answer = 'False';
PRINT 'SubmitAnswer T/F (correct): OK';
GO

-- 3B. Correct MCQ answer
EXEC SubmitAnswer @StdID = 1, @ExamID = 1, @QuestionID = 3, @Answer = 'SELECT';
PRINT 'SubmitAnswer MCQ (correct): OK';
GO

-- 3C. Incorrect MCQ answer (StdID 2)
EXEC SubmitAnswer @StdID = 2, @ExamID = 1, @QuestionID = 3, @Answer = 'INSERT';
PRINT 'SubmitAnswer MCQ (incorrect, StdID=2): OK';
GO

-- 3D. Text answer – not auto-graded
EXEC SubmitAnswer @StdID = 1, @ExamID = 1, @QuestionID = 1, @Answer = 'Database Management System';
PRINT 'SubmitAnswer Text: OK (will not be auto-graded)';
GO

-- 3E. Duplicate answer – UNIQUE constraint (Stans_un) must fail
PRINT 'Testing duplicate answer UNIQUE constraint (expected FAIL)...';
BEGIN TRY
    EXEC SubmitAnswer @StdID = 1, @ExamID = 1, @QuestionID = 2, @Answer = 'False';
    PRINT 'Duplicate answer guard: FAILED – no error raised';
END TRY
BEGIN CATCH
    PRINT 'Duplicate answer guard: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 3F. Verify TR_CheckAnswer awarded degrees correctly
PRINT 'Verifying TR_CheckAnswer results for StdID=1:';
SELECT
    QuestionID,
    StudentAns,
    IsCorrect,
    Degree
FROM Student_Ans
WHERE StdID = 1 AND ExamID = 1;
GO

PRINT 'Verifying TR_CheckAnswer results for StdID=2 (wrong answer, Degree should be 0):';
SELECT QuestionID, StudentAns, IsCorrect, Degree
FROM Student_Ans
WHERE StdID = 2 AND ExamID = 1;
GO


-- ============================================================
-- PHASE 4: SCALAR FUNCTIONS
-- ============================================================
PRINT '';
PRINT '--- PHASE 4: Scalar Functions ---';

-- 4A. FN_GetStudentExamDegree (also aliased as GetStudentExamDegree in views)
PRINT 'FN_GetStudentExamDegree (StdID=1, ExamID=1):';
SELECT dbo.FN_GetStudentExamDegree(1, 1) AS [Student_Total_Exam_Score];
GO

-- 4B. FN_CalcTotalCourseDegree – percentage calculation
PRINT 'FN_CalcTotalCourseDegree (MaxDegree=100, ExamRes=85 → expected 85):';
SELECT dbo.FN_CalcTotalCourseDegree(100, 85) AS [Calculated_Percentage];

PRINT 'FN_CalcTotalCourseDegree (MaxDegree=0, ExamRes=50 → expected 0, no divide-by-zero):';
SELECT dbo.FN_CalcTotalCourseDegree(0, 50) AS [Zero_MaxDegree_Safe];
GO

-- 4C. FN_CheckTextAnswer – text similarity
PRINT 'FN_CheckTextAnswer tests:';
SELECT dbo.FN_CheckTextAnswer('Database Management System', 'Database Management System') AS [Exact_Match_100];
SELECT dbo.FN_CheckTextAnswer('Database System', 'Database Management System') AS [Partial_50];
SELECT dbo.FN_CheckTextAnswer('Totally unrelated answer', 'Database Management System') AS [No_Match_0];
GO

-- 4D. FN_GetStudentStatus – pass/fail
PRINT 'FN_GetStudentStatus tests:';
SELECT dbo.FN_GetStudentStatus(85, 50) AS [Pass_Fail_Status];   -- Expected: Passed
SELECT dbo.FN_GetStudentStatus(30, 50) AS [Pass_Fail_Status];   -- Expected: Failed
SELECT dbo.FN_GetStudentStatus(50, 50) AS [Pass_Fail_Status];   -- Expected: Passed (boundary)
GO

-- 4E. CalculateExamResult SP (separate result SP)
PRINT 'CalculateExamResult (StdID=1, ExamID=1):';
EXEC CalculateExamResult @StdID = 1, @ExamID = 1;
GO


-- ============================================================
-- PHASE 5: TRIGGERS – TR_AutoCalculateResults
-- ============================================================
PRINT '';
PRINT '--- PHASE 5: TR_AutoCalculateResults Trigger ---';

-- 5A. Update Exam_Result and verify Total_Result + Course_Grade computed
UPDATE Student_Course
SET Exam_Result = 20
WHERE StdID = 1 AND CourseID = 1;
PRINT 'Updated Exam_Result = 20 for StdID=1. Verifying trigger output:';

SELECT StdID, CourseID, Exam_Result, Attendance_Degree, Project_Degree, Total_Result, Course_Grade
FROM Student_Course
WHERE StdID = 1 AND CourseID = 1;
GO

-- 5B. Update all three degree columns to verify grading boundary (A = >=85%)
UPDATE Student_Course
SET Exam_Result = 60, Attendance_Degree = 20, Project_Degree = 5
WHERE StdID = 1 AND CourseID = 1;
PRINT 'Updated to 60+20+5=85 (85% of 100 → Grade A expected):';
SELECT StdID, Exam_Result, Attendance_Degree, Project_Degree, Total_Result, Course_Grade
FROM Student_Course WHERE StdID = 1 AND CourseID = 1;
GO

-- 5C. Grade D boundary (50–64%)
UPDATE Student_Course
SET Exam_Result = 50, Attendance_Degree = 0, Project_Degree = 0
WHERE StdID = 1 AND CourseID = 1;
PRINT '50% → Grade D expected:';
SELECT StdID, Total_Result, Course_Grade FROM Student_Course WHERE StdID = 1 AND CourseID = 1;
GO

-- 5D. Grade F (<50%)
UPDATE Student_Course
SET Exam_Result = 30, Attendance_Degree = 0, Project_Degree = 0
WHERE StdID = 1 AND CourseID = 1;
PRINT '30% → Grade F expected:';
SELECT StdID, Total_Result, Course_Grade FROM Student_Course WHERE StdID = 1 AND CourseID = 1;
GO


-- ============================================================
-- PHASE 6: VIEWS
-- ============================================================
PRINT '';
PRINT '--- PHASE 6: System Views ---';

PRINT 'V_StudentResults (student total scores per exam):';
SELECT * FROM V_StudentResults;
GO

PRINT 'V_ExamDetails (questions and degrees per exam):';
SELECT * FROM V_ExamDetails;
GO

PRINT 'VW_StudentAnswer (encrypted: student answers vs correctness):';
SELECT * FROM VW_StudentAnswer;
GO

PRINT 'V_InstructorPerformance (instructor student counts):';
SELECT * FROM V_InstructorPerformance;
GO

PRINT 'V_ExamAnalytics (per-exam Pass/Fail counts):';
SELECT * FROM V_ExamAnalytics;
GO

PRINT 'VW_StudentScheduleExams (upcoming exams for students):';
SELECT * FROM VW_StudentScheduleExams;
GO


-- ============================================================
-- PHASE 7: SECURITY PRINCIPALS & PERMISSIONS
-- ============================================================
PRINT '';
PRINT '--- PHASE 7: Security Principals ---';

-- 7A. Verify all four DB users exist
SELECT name, type_desc
FROM sys.database_principals
WHERE name IN ('AdminUser', 'StudentUser', 'InstructorUser', 'TrainingManagerUser');
GO

-- 7B. Verify Training Manager can INSERT into Branches
SELECT HAS_PERMS_BY_NAME('Branches',    'OBJECT', 'INSERT') AS TM_CanInsertBranches;
SELECT HAS_PERMS_BY_NAME('Track',       'OBJECT', 'INSERT') AS TM_CanInsertTrack;
SELECT HAS_PERMS_BY_NAME('Intake',      'OBJECT', 'INSERT') AS TM_CanInsertIntake;
SELECT HAS_PERMS_BY_NAME('Departments', 'OBJECT', 'INSERT') AS TM_CanInsertDepts;
GO

-- 7C. Verify Student user has correct grants
EXECUTE AS USER = 'StudentUser';
    SELECT HAS_PERMS_BY_NAME('Student_Ans',         'OBJECT', 'INSERT') AS Std_CanSubmitAns;
    SELECT HAS_PERMS_BY_NAME('V_StudentResults',    'OBJECT', 'SELECT') AS Std_CanViewResults;
    SELECT HAS_PERMS_BY_NAME('VW_StudentScheduleExams','OBJECT','SELECT') AS Std_CanViewSchedule;
    SELECT HAS_PERMS_BY_NAME('Exam',                'OBJECT', 'INSERT') AS Std_CANNOT_InsertExam;
REVERT;
GO

-- 7D. Verify Instructor permissions
EXECUTE AS USER = 'InstructorUser';
    SELECT HAS_PERMS_BY_NAME('Question',      'OBJECT', 'INSERT') AS Ins_CanAddQuestion;
    SELECT HAS_PERMS_BY_NAME('Exam',          'OBJECT', 'INSERT') AS Ins_CanCreateExam;
    SELECT HAS_PERMS_BY_NAME('Student_Ans',   'OBJECT', 'INSERT') AS Ins_CANNOT_SubmitAns;
REVERT;
GO


-- ============================================================
-- PHASE 8: EDGE CASES & DATA INTEGRITY
-- ============================================================
PRINT '';
PRINT '--- PHASE 8: Edge Cases & Constraint Tests ---';

-- 8A. CHK_QuestionType – invalid type must fail
PRINT 'Testing CHK_QuestionType (invalid type, expected FAIL)...';
BEGIN TRY
    INSERT INTO Question ([Text], [Type], BestAnswer, CourseID)
    VALUES ('Bad type question', 'Essay', 'N/A', 1);
    PRINT 'CHK_QuestionType: FAILED – constraint did NOT fire';
END TRY
BEGIN CATCH
    PRINT 'CHK_QuestionType: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 8B. Duplicate email in Users (UNIQUE constraint)
PRINT 'Testing duplicate email in Users (expected FAIL)...';
BEGIN TRY
    INSERT INTO Users (Name, Password, Email, RoleID)
    VALUES ('Duplicate', 'pass', 'mohamed@test.com', 1);
    PRINT 'Duplicate email: FAILED – constraint did NOT fire';
END TRY
BEGIN CATCH
    PRINT 'Duplicate email: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 8C. FK integrity – branch that doesn't exist for intake
PRINT 'Testing FK_Intake_Branch (BranchID=999, expected FAIL)...';
BEGIN TRY
    INSERT INTO Intake (Name, BranchID) VALUES ('Bad Intake', 999);
    PRINT 'FK_Intake_Branch: FAILED – FK did NOT fire';
END TRY
BEGIN CATCH
    PRINT 'FK_Intake_Branch: OK – Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- 8D. Choice cascade delete – deleting a question should cascade to its choices
PRINT 'Testing CASCADE DELETE on Choice (via Question delete)...';
DECLARE @ChoicesBefore INT = (SELECT COUNT(*) FROM Choice WHERE QuestionID = 3);
PRINT 'Choices before delete: ' + CAST(@ChoicesBefore AS VARCHAR);

-- We do NOT actually delete question 3 (it's in active exam), just verify constraint is configured
SELECT c.constraint_name, c.delete_referential_action_desc
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS c
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON c.constraint_name = kcu.constraint_name
WHERE kcu.table_name = 'Choice' AND kcu.column_name = 'QuestionID';
GO

-- 8E. FN_GetStudentExamDegree for student with no answers
PRINT 'FN_GetStudentExamDegree for StdID with no answers (expected 0):';
SELECT dbo.FN_GetStudentExamDegree(999, 1) AS [No_Answers_Score];
GO

-- 8F. GenerateExamQuestions with 0 for all types (should silently do nothing)
PRINT 'GenerateExamQuestions (all zeros – should not error):';
BEGIN TRY
    EXEC GenerateExamQuestions @ExamID = 1, @CourseID = 1, @NumMCQ = 0, @NumTF = 0, @NumText = 0, @Degree = 10;
    PRINT 'GenerateExamQuestions (all-zero): OK';
END TRY
BEGIN CATCH
    PRINT 'GenerateExamQuestions (all-zero): ERROR – ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- PHASE 9: INDEXES EXIST
-- ============================================================
PRINT '';
PRINT '--- PHASE 9: Index Verification ---';

SELECT
    i.name      AS IndexName,
    t.name      AS TableName,
    i.type_desc AS IndexType
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IN (
    'IDX_Student_Email',
    'IDX_Users_Email',
    'IDX_Question_CourseID',
    'IX_StdAns',
    'IX_CrsId'
)
ORDER BY t.name;
GO


-- ============================================================
-- PHASE 10: SUMMARY REPORT
-- ============================================================
PRINT '';
PRINT '====================================================';
PRINT ' SUMMARY REPORT';
PRINT '====================================================';

SELECT 'Roles'           AS [Table], COUNT(*) AS [Rows] FROM Roles
UNION ALL
SELECT 'Departments',    COUNT(*) FROM Departments
UNION ALL
SELECT 'Branches',       COUNT(*) FROM Branches
UNION ALL
SELECT 'Track',          COUNT(*) FROM Track
UNION ALL
SELECT 'Intake',         COUNT(*) FROM Intake
UNION ALL
SELECT 'Users',          COUNT(*) FROM Users
UNION ALL
SELECT 'Student',        COUNT(*) FROM Student
UNION ALL
SELECT 'Instructor',     COUNT(*) FROM Instructor
UNION ALL
SELECT 'Course',         COUNT(*) FROM Course
UNION ALL
SELECT 'Question',       COUNT(*) FROM Question
UNION ALL
SELECT 'Choice',         COUNT(*) FROM Choice
UNION ALL
SELECT 'Exam',           COUNT(*) FROM Exam
UNION ALL
SELECT 'Question_Exam',  COUNT(*) FROM Question_Exam
UNION ALL
SELECT 'Student_Exam',   COUNT(*) FROM Student_Exam
UNION ALL
SELECT 'Student_Ans',    COUNT(*) FROM Student_Ans
UNION ALL
SELECT 'Student_Course', COUNT(*) FROM Student_Course
UNION ALL
SELECT 'Instructor_Course', COUNT(*) FROM Instructor_Course
UNION ALL
SELECT 'Branch_Exam',    COUNT(*) FROM Branch_Exam;

PRINT '';
PRINT '--- All Phases Complete ---';
GO
