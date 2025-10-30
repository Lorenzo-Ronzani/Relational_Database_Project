/* ================================================================
   DATA2201 – Phase 1
   File:       populate_database.sql
   Project:    SKS_National_Bank
   Target DB:  BankDatabase
   Purpose:    Populate the database with realistic sample data 
               (reseed-safe and dependency-order aware)

   Note:       This script was initially generated with the assistance 
               of ChatGPT (AI-based SQL generation). 
               Additional details about its use and manual adjustments 
               can be found at the end of this file.

   ================================================================ */

USE BankDatabase;
GO
SET NOCOUNT ON;
GO

/* -------------------------------------------------
   0) CLEANUP + RESEED IDENTITY TABLES
   ------------------------------------------------- */
PRINT ' Purging old data and reseeding identity columns...';

-- ======== Script to Clear All data before the inserts ================================================================================================================
PRINT '===============================================================';
PRINT ' Cleaning BankDatabase tables in dependency order...';

--------------------------------------------------
-- 1. Tables that depend on others (deepest children)
--------------------------------------------------
DELETE FROM LoanPayment;
DELETE FROM LoanCustomer;
DELETE FROM Overdraft;
DELETE FROM AccountHolder;
DELETE FROM EmployeeLocation;

--------------------------------------------------
-- 2. Tables that depend on Branch, Employee, or Customer
--------------------------------------------------
DELETE FROM Loan;
DELETE FROM Account;
DELETE FROM Customer;
DELETE FROM Employee;
DELETE FROM EmployeeLocation;
DELETE FROM Location;

--------------------------------------------------
-- 3. Independent lookup tables
--------------------------------------------------
DELETE FROM AccountType;
DELETE FROM LocationType;

--------------------------------------------------
-- 4. Finally, delete top-level master tables
--------------------------------------------------
DELETE FROM Branch;
PRINT '---------------------------------------------------------------';
PRINT '  All tables cleaned successfully (dependency order respected).';
PRINT '===============================================================';

-----------------------------------------------------------------------
-- 5. Optional: Reseed identity values for a clean start
-----------------------------------------------------------------------
DBCC CHECKIDENT ('Branch', RESEED, 0);
DBCC CHECKIDENT ('LocationType', RESEED, 0);
DBCC CHECKIDENT ('Location', RESEED, 0);
DBCC CHECKIDENT ('Employee', RESEED, 0);
DBCC CHECKIDENT ('Customer', RESEED, 0);
DBCC CHECKIDENT ('AccountType', RESEED, 0);
DBCC CHECKIDENT ('Account', RESEED, 0);
DBCC CHECKIDENT ('Overdraft', RESEED, 0);
DBCC CHECKIDENT ('Loan', RESEED, 0);

PRINT 'Identity reseed completed.';
PRINT '===============================================================';
PRINT ' Database ready for data population scripts.';
PRINT '===============================================================';

-- ======== END Script to Clear All data before the inserts ============================================================================================================

GO
PRINT 'Populating Branch...';

-- Remove old records if needed
DELETE FROM Branch;


-- Insert 10 sample branches in major Canadian cities
INSERT INTO Branch (Name, City, CreatedAt)
VALUES 
 ('Calgary Central Branch', 'Calgary', sysutcdatetime()),
 ('Toronto Downtown Branch', 'Toronto', sysutcdatetime()),
 ('Vancouver West Branch', 'Vancouver', sysutcdatetime()),
 ('Edmonton River Valley Branch', 'Edmonton', sysutcdatetime()),
 ('Montreal Centre-Ville Branch', 'Montreal', sysutcdatetime()),
 ('Ottawa Parliament Branch', 'Ottawa', sysutcdatetime()),
 ('Winnipeg Forks Branch', 'Winnipeg', sysutcdatetime()),
 ('Halifax Harbour Branch', 'Halifax', sysutcdatetime()),
 ('Victoria Inner Harbour Br.', 'Victoria', sysutcdatetime()),
 ('Saskatoon Prairie Branch', 'Saskatoon', sysutcdatetime());

--PRINT 'Branch table populated successfully!';
--SELECT * FROM Branch;






--==================== Populating Location ======================================================================================
GO
PRINT 'Populating LocationType...';

-- Clean old records (if any)
DELETE FROM LocationType;

-- Insert location types
INSERT INTO LocationType (Name, Description)
VALUES
 ('Head Office', 'Corporate HQ and admin centre'),
 ('Branch', 'Full-service branch location'),
 ('ATM', 'Automated Teller Machine');

--PRINT 'LocationType table populated successfully!';

-- Verify inserted data
--SELECT * FROM LocationType;







--==================== Populating Location ======================================================================================
GO
PRINT 'Populating Location...';

-- Clean old data
DELETE FROM Location;

-- Get LocationType IDs dynamically (to respect FKs)
DECLARE @HeadOfficeID INT = (SELECT LocationTypeID FROM LocationType WHERE Name = 'Head Office');
DECLARE @BranchTypeID INT = (SELECT LocationTypeID FROM LocationType WHERE Name = 'Branch');
DECLARE @ATMTypeID    INT = (SELECT LocationTypeID FROM LocationType WHERE Name = 'ATM');

-- Insert multiple locations per branch using correct FK IDs
INSERT INTO Location (Name, LocationTypeID, BranchID, CreatedAt)
SELECT CONCAT(City, ' Head Office'), @HeadOfficeID, BranchID, sysutcdatetime() FROM Branch
UNION ALL
SELECT CONCAT(City, ' Main Branch'), @BranchTypeID, BranchID, sysutcdatetime() FROM Branch
UNION ALL
SELECT CONCAT(City, ' ATM #1'), @ATMTypeID, BranchID, sysutcdatetime() FROM Branch
UNION ALL
SELECT CONCAT(City, ' ATM #2'), @ATMTypeID, BranchID, sysutcdatetime() FROM Branch;

--PRINT 'Location table populated successfully!';
-- Verify inserted data
--SELECT TOP 40 LocationID, Name, LocationTypeID, BranchID FROM Location;






--==================== Populating Employee ======================================================================================
GO
PRINT 'Populating Employee...';

--------------------------------------------------
-- 1. Initial cleaning
--------------------------------------------------
DELETE FROM Employee;

--------------------------------------------------
-- 2. Local parameters
--------------------------------------------------
DECLARE @TotalEmployees INT = 50;

--------------------------------------------------
-- 3. Name Pools (First Name/Last Name)
--------------------------------------------------
DECLARE @FirstNames TABLE (FirstName varchar(30), RowNum int IDENTITY(1,1));
INSERT INTO @FirstNames (FirstName) VALUES 
('Alex'), ('Taylor'), ('Jordan'), ('Riley'), ('Morgan'),
('Casey'), ('Drew'), ('Quinn'), ('Jamie'), ('Avery'),
('Logan'), ('Parker'), ('Skyler'), ('Emerson'), ('Cameron');

DECLARE @LastNames TABLE (LastName varchar(40), RowNum int IDENTITY(1,1));
INSERT INTO @LastNames (LastName) VALUES
('Smith'), ('Johnson'), ('Brown'), ('Wilson'), ('Martin'),
('Clark'), ('Lopez'), ('Young'), ('King'), ('Wright'),
('Green'), ('Hall'), ('Baker'), ('Adams'), ('Turner');

DECLARE @FirstCount int = (SELECT COUNT(*) FROM @FirstNames);
DECLARE @LastCount  int = (SELECT COUNT(*) FROM @LastNames);
DECLARE @BranchCount int = (SELECT COUNT(*) FROM Branch);

--------------------------------------------------
-- 4. Generate Employees
-- Strategy:
-- * We generate a list of numbers 1..50 (Num)
-- * We "match" each number with a first and last name in a cyclical fashion
-- * We assign the city/branch in a cyclical fashion
--------------------------------------------------
;WITH Num AS (
    SELECT TOP (@TotalEmployees)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
),
PickFirst AS (
    SELECT n.rn,
           f.FirstName
    FROM Num n
    JOIN @FirstNames f
      ON ((n.rn - 1) % @FirstCount) + 1 = f.RowNum
),
PickLast AS (
    SELECT n.rn,
           l.LastName
    FROM Num n
    JOIN @LastNames l
      ON ((n.rn - 1) % @LastCount) + 1 = l.RowNum
),
PickBranch AS (
    SELECT n.rn,
           b.BranchID,
           b.City
    FROM Num n
    JOIN Branch b
      ON ((n.rn - 1) % @BranchCount) + 1 = b.BranchID
)
INSERT INTO Employee (FirstName, LastName, PostalCode, Street, City, Province, StartDate)
SELECT 
    pf.FirstName,
    pl.LastName,
    RIGHT(CONVERT(varchar(10), 10000 + ABS(CHECKSUM(NEWID())) % 99999), 6) AS PostalCode,
    CONCAT(100 + n.rn, ' ', pb.City, ' St NW') AS Street,
    pb.City AS City,
    CASE 
        WHEN n.rn % 4 = 0 THEN 'AB'
        WHEN n.rn % 4 = 1 THEN 'ON'
        WHEN n.rn % 4 = 2 THEN 'BC'
        ELSE 'QC'
    END AS Province,
    DATEADD(DAY, -1 * (n.rn * 5) % 2000, CAST(GETDATE() AS date)) AS StartDate
FROM Num n
JOIN PickFirst pf ON pf.rn = n.rn
JOIN PickLast  pl ON pl.rn = n.rn
JOIN PickBranch pb ON pb.rn = n.rn;

PRINT 'Populating Employee: Step 1/2: Employees added. Now Ill assign ManagerID...';

------------------------------------------------------------------------------------
-- 5. Assign Manager by Branch
-- Rule: The employee with the lowest Employee ID in that city becomes the manager.
-- All others in that same city point to that employee's Manager ID.
------------------------------------------------------------------------------------
;WITH MinManagerPerCity AS (
    SELECT City, MIN(EmployeeID) AS ManagerID
    FROM Employee
    GROUP BY City
)
UPDATE e
SET e.ManagerID = m.ManagerID
FROM Employee e
JOIN MinManagerPerCity m
  ON m.City = e.City
WHERE e.EmployeeID <> m.ManagerID;

PRINT 'Populating Employee: Step 2/2: ManagerID assigned.';

--------------------------------------------------
-- 6. Quick check
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalEmployees FROM Employee;

SELECT TOP 100 
    EmployeeID,
    FirstName,
    LastName,
    City,
    ManagerID
FROM Employee
ORDER BY EmployeeID;
*/




--==================== Populating EmployeeLocation ==============================================================================
GO
PRINT 'Populating EmployeeLocation...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM EmployeeLocation;

--------------------------------------------------
-- 2. Assign each employee to a physical location
--    Rules:
--      • Each employee is linked to the "Main Branch" of their city.
--      • PrimarySite = 1 for all.
--      • Matching is done by City (Employee.City = Branch.City).
--------------------------------------------------
;WITH LocMain AS (
    SELECT 
        l.LocationID,
        b.City
    FROM Location l
    INNER JOIN Branch b ON l.BranchID = b.BranchID
    WHERE l.Name LIKE '%Main Branch%'   -- only main branches
)
INSERT INTO EmployeeLocation (EmployeeID, LocationID, PrimarySite)
SELECT 
    e.EmployeeID,
    lm.LocationID,
    1 AS PrimarySite
FROM Employee e
INNER JOIN LocMain lm ON e.City = lm.City;

--PRINT 'EmployeeLocation table populated successfully!';
--------------------------------------------------
-- 3. Validation: check total and sample rows
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalAssignments FROM EmployeeLocation;

SELECT TOP 100
    el.EmployeeID,
    e.FirstName,
    e.LastName,
    e.City,
    el.LocationID,
    l.Name AS LocationName,
    el.PrimarySite
FROM EmployeeLocation el
JOIN Employee e ON el.EmployeeID = e.EmployeeID
JOIN Location l ON el.LocationID = l.LocationID
ORDER BY e.EmployeeID;
*/





--==================== Populating Customer ======================================================================================
GO
PRINT 'Populating Customer...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM Customer;

--------------------------------------------------
-- 2. Configuration
--------------------------------------------------
DECLARE @TotalCustomers INT = 500;

--------------------------------------------------
-- 3. Build first- and last-name pools (use #temp tables for safe re-runs)
--------------------------------------------------
IF OBJECT_ID('tempdb..#tmpFirstNames') IS NOT NULL DROP TABLE #tmpFirstNames;
IF OBJECT_ID('tempdb..#tmpLastNames')  IS NOT NULL DROP TABLE #tmpLastNames;

-- First names
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum, v.FirstName
INTO #tmpFirstNames
FROM (VALUES
 ('Alex'), ('Taylor'), ('Jordan'), ('Riley'), ('Morgan'),
 ('Casey'), ('Drew'), ('Quinn'), ('Jamie'), ('Avery'),
 ('Logan'), ('Parker'), ('Skyler'), ('Emerson'), ('Cameron')
) v(FirstName);

-- Last names
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum, v.LastName
INTO #tmpLastNames
FROM (VALUES
 ('Smith'), ('Johnson'), ('Brown'), ('Wilson'), ('Martin'),
 ('Clark'), ('Lopez'), ('Young'), ('King'), ('Wright'),
 ('Green'), ('Hall'), ('Baker'), ('Adams'), ('Turner')
) v(LastName);

DECLARE @FirstCount  INT = (SELECT COUNT(*) FROM #tmpFirstNames);
DECLARE @LastCount   INT = (SELECT COUNT(*) FROM #tmpLastNames);
DECLARE @BranchCount INT = (SELECT COUNT(*) FROM Branch);

--------------------------------------------------
-- 4. Generate and insert 500 customers
--------------------------------------------------
;WITH Num AS (
    SELECT TOP (@TotalCustomers)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
),
PickBranch AS (
    SELECT ROW_NUMBER() OVER (ORDER BY BranchID) AS RowNum, *
    FROM Branch
)
INSERT INTO Customer
(
    FirstName, LastName, PostalCode, Street, SuiteNumber,
    City, Province, Email, BankerID, LoanOfficerID, CreatedAt
)
SELECT 
    f.FirstName,
    l.LastName,
    RIGHT(CONVERT(varchar(10), 10000 + ABS(CHECKSUM(NEWID())) % 99999), 6) AS PostalCode,
    CONCAT(100 + n.rn, ' ', b.City, ' Ave SW') AS Street,
    NULL AS SuiteNumber, -- optional field
    b.City,
    CASE 
        WHEN n.rn % 4 = 0 THEN 'AB'
        WHEN n.rn % 4 = 1 THEN 'ON'
        WHEN n.rn % 4 = 2 THEN 'BC'
        ELSE 'QC'
    END AS Province,
    LOWER(CONCAT(f.FirstName, '.', l.LastName, '.', n.rn, '@example.com')) AS Email,
    (SELECT TOP 1 EmployeeID FROM Employee ORDER BY NEWID()) AS BankerID,
    (SELECT TOP 1 EmployeeID FROM Employee ORDER BY NEWID()) AS LoanOfficerID,
    SYSUTCDATETIME() AS CreatedAt
FROM Num n
JOIN #tmpFirstNames f ON ((n.rn - 1) % @FirstCount) + 1 = f.RowNum
JOIN #tmpLastNames  l ON ((n.rn - 1) % @LastCount)  + 1 = l.RowNum
JOIN PickBranch     b ON ((n.rn - 1) % @BranchCount) + 1 = b.RowNum;

--PRINT 'Customer table populated successfully!';
--------------------------------------------------
-- 5. Validation
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalCustomers FROM Customer;

SELECT TOP 20 
    CustomerID,
    FirstName,
    LastName,
    City,
    Province,
    Email,
    BankerID,
    LoanOfficerID,
    CreatedAt
FROM Customer
ORDER BY CustomerID;
*/





--==================== Populating AccountType ===================================================================================
GO
PRINT 'Populating AccountType...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM AccountType;

--------------------------------------------------
-- 2. Insert standard account types
--    These types will be used by the Account table.
--------------------------------------------------
INSERT INTO AccountType (Name, Description)
VALUES
('Chequing', 'Standard daily-use account for payments and deposits'),
('Savings',  'Interest-bearing account for long-term saving'),
('RRSP',     'Registered Retirement Savings Plan (Canada)');

--PRINT 'AccountType table populated successfully!';

--------------------------------------------------
-- 3. Validation
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalAccountTypes FROM AccountType;
SELECT * FROM AccountType;
*/





--==================== Populating Account  ======================================================================================
GO
SET NOCOUNT ON;

PRINT 'Populating Account...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM Account;

--------------------------------------------------
-- 2. Configuration
--------------------------------------------------
DECLARE @ChequingCount INT = 600;   -- number of chequing accounts
DECLARE @SavingsCount  INT = 300;   -- number of savings accounts
DECLARE @RRSPCount     INT = 100;   -- number of RRSP accounts

--------------------------------------------------
-- 3. Build a valid Branch reference list
--    (ensures all BranchIDs used actually exist)
--------------------------------------------------
;WITH BranchList AS (
    SELECT ROW_NUMBER() OVER (ORDER BY BranchID) AS RowNum, BranchID
    FROM Branch
),
Num AS (
    SELECT TOP (@ChequingCount + @SavingsCount + @RRSPCount)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
)
--------------------------------------------------
-- 4. Generate and insert accounts
--    Each account will be assigned to an existing BranchID
--    and a valid AccountType (Chequing, Savings, RRSP).
--------------------------------------------------
INSERT INTO Account (AccountTypeID, BranchID, Balance, InterestRate, LastAccessed)
SELECT 
    CASE 
        WHEN rn <= @ChequingCount THEN (SELECT AccountTypeID FROM AccountType WHERE Name = 'Chequing')
        WHEN rn <= @ChequingCount + @SavingsCount THEN (SELECT AccountTypeID FROM AccountType WHERE Name = 'Savings')
        ELSE (SELECT AccountTypeID FROM AccountType WHERE Name = 'RRSP')
    END AS AccountTypeID,

    -- Corrected: use existing BranchIDs instead of assuming sequential 1..N
    b.BranchID,

    -- Random realistic balance between $100 and $10,000
    CAST(ROUND((RAND(CHECKSUM(NEWID())) * 10000 + 100), 2) AS decimal(18,2)) AS Balance,

    -- Only non-chequing accounts get interest rates
    CASE 
        WHEN rn <= @ChequingCount THEN NULL 
        ELSE CAST(ROUND((RAND(CHECKSUM(NEWID())) * 3.5 + 0.5), 2) AS decimal(5,2)) 
    END AS InterestRate,

    SYSUTCDATETIME() AS LastAccessed
FROM Num n
JOIN BranchList b 
    ON ((n.rn - 1) % (SELECT COUNT(*) FROM BranchList)) + 1 = b.RowNum;

--PRINT 'Account table populated successfully!';
--------------------------------------------------
-- 5. Validation
--    Check total count and distribution by account type
--------------------------------------------------
/*
DECLARE @ChequingID INT, @SavingsID INT, @RRSPID INT;
SELECT @ChequingID = AccountTypeID FROM AccountType WHERE Name = 'Chequing';
SELECT @SavingsID  = AccountTypeID FROM AccountType WHERE Name = 'Savings';
SELECT @RRSPID     = AccountTypeID FROM AccountType WHERE Name = 'RRSP';

SELECT 
    COUNT(*) AS TotalAccounts,
    SUM(CASE WHEN AccountTypeID = @ChequingID THEN 1 ELSE 0 END) AS Chequing,
    SUM(CASE WHEN AccountTypeID = @SavingsID  THEN 1 ELSE 0 END) AS Savings,
    SUM(CASE WHEN AccountTypeID = @RRSPID     THEN 1 ELSE 0 END) AS RRSP
FROM Account;


--------------------------------------------------
-- 6. Preview first accounts
--------------------------------------------------

SELECT TOP 20 
    AccountID, 
    AccountTypeID, 
    BranchID, 
    Balance, 
    InterestRate, 
    LastAccessed
FROM Account
ORDER BY AccountID;
*/
--PRINT 'Account population and validation completed.';







--==================== Populating Overdraft =====================================================================================
GO
PRINT 'Populating Overdraft...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM Overdraft;

--------------------------------------------------
-- 2. Configuration
--------------------------------------------------
DECLARE @OverdraftCount INT = 150;  -- approximate number of records
DECLARE @ChequingID INT = (SELECT AccountTypeID FROM AccountType WHERE Name = 'Chequing');

--------------------------------------------------
-- 3. Generate 150 random overdrafts for chequing accounts
--------------------------------------------------
;WITH Pick AS (
    SELECT TOP (@OverdraftCount)
      ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
      a.AccountID
    FROM Account a
    WHERE a.AccountTypeID = @ChequingID
    ORDER BY NEWID()
)
INSERT INTO Overdraft (AccountID, OccurredOn, Amount, CheckNumber)
SELECT 
  p.AccountID,
  DATEADD(DAY, -((p.rn * 7) % 400), CAST(GETDATE() AS date)) AS OccurredOn,
  CAST(50 + ((p.rn * 17) % 450) AS decimal(18,2)) AS Amount,
  CONCAT('CHK', RIGHT('00000' + CAST(((p.rn * 29) % 100000) AS varchar(5)), 5)) AS CheckNumber
FROM Pick p;

--PRINT 'Overdraft table populated successfully!';
--------------------------------------------------
-- 4. Validation
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalOverdrafts FROM Overdraft;

SELECT TOP 1000 
  o.OverdraftID,
  o.AccountID,
  a.BranchID,
  o.OccurredOn,
  o.Amount,
  o.CheckNumber
FROM Overdraft o
JOIN Account a ON o.AccountID = a.AccountID
ORDER BY o.OverdraftID;
*/


--==================== Populating AccountHolder =================================================================================
GO
PRINT 'Populating AccountHolder...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM AccountHolder;

--------------------------------------------------
-- 2. Configuration
--------------------------------------------------
DECLARE @AccountCount INT = (SELECT COUNT(*) FROM Account);
DECLARE @CustomerCount INT = (SELECT COUNT(*) FROM Customer);
DECLARE @JointPct INT = 25; -- Around 25% of accounts will have a joint holder

--------------------------------------------------
-- 3. Assign one primary customer per account
--------------------------------------------------
;WITH AccountSeq AS (
    SELECT 
        a.AccountID,
        ROW_NUMBER() OVER (ORDER BY a.AccountID) AS rn
    FROM Account a
)
INSERT INTO AccountHolder (AccountID, CustomerID)
SELECT 
    a.AccountID,
    ((a.rn - 1) % @CustomerCount) + 1 AS CustomerID
FROM AccountSeq a;

PRINT 'Populating AccountHolder: Step 1/2 – Primary account holders assigned.';

--------------------------------------------------
-- 4. Add joint holders (~25% of accounts)
--------------------------------------------------
;WITH AccountSeq AS (
    SELECT 
        a.AccountID,
        ROW_NUMBER() OVER (ORDER BY a.AccountID) AS rn
    FROM Account a
)
INSERT INTO AccountHolder (AccountID, CustomerID)
SELECT 
    a.AccountID,
    ((a.rn + 45) % @CustomerCount) + 1 AS JointHolderID
FROM AccountSeq a
WHERE (a.AccountID % 100) < @JointPct
  AND NOT EXISTS (
        SELECT 1 
        FROM AccountHolder ah
        WHERE ah.AccountID = a.AccountID
          AND ah.CustomerID = ((a.rn + 45) % @CustomerCount) + 1
    );

PRINT 'Populating AccountHolder: Step 2/2 – Joint holders assigned.';

--------------------------------------------------
-- 5. Validation
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalLinks FROM AccountHolder;

-- Preview a sample of linked records
SELECT TOP 20 
    ah.AccountID,
    c.FirstName,
    c.LastName,
    c.Email
FROM AccountHolder ah
JOIN Customer c ON ah.CustomerID = c.CustomerID
ORDER BY ah.AccountID;
*/

--PRINT 'AccountHolder table populated successfully!';


--==================== Populating Loan ==========================================================================================
GO
PRINT 'Populating Loan...';

--------------------------------------------------
-- 1. Ensure Branch data exists (safety check)
--    If Branch table is empty, repopulate with default data.
--------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Branch)
BEGIN
    PRINT 'Branch table empty — rebuilding default branch data...';

    DBCC CHECKIDENT ('Branch', RESEED, 0);

    INSERT INTO Branch (Name, City, CreatedAt)
    VALUES 
        ('Calgary Central Branch',       'Calgary',   sysutcdatetime()),
        ('Toronto Downtown Branch',      'Toronto',   sysutcdatetime()),
        ('Vancouver West Branch',        'Vancouver', sysutcdatetime()),
        ('Edmonton River Valley Branch', 'Edmonton',  sysutcdatetime()),
        ('Montreal Centre-Ville Branch', 'Montreal',  sysutcdatetime()),
        ('Ottawa Parliament Branch',     'Ottawa',    sysutcdatetime()),
        ('Winnipeg Forks Branch',        'Winnipeg',  sysutcdatetime()),
        ('Halifax Harbour Branch',       'Halifax',   sysutcdatetime()),
        ('Victoria Inner Harbour Br.',   'Victoria',  sysutcdatetime()),
        ('Saskatoon Prairie Branch',     'Saskatoon', sysutcdatetime());

    PRINT 'Branch table rebuilt successfully.';
END
ELSE
BEGIN
    PRINT 'Branch table already populated.';
END

--------------------------------------------------
-- 2. Clean existing Loan data
--------------------------------------------------
DELETE FROM Loan;

--------------------------------------------------
-- 3. Configuration
--------------------------------------------------
DECLARE @TotalLoans INT = 200;

--------------------------------------------------
-- 4. Build valid Branch reference list
--    Ensures only existing BranchIDs are used
--------------------------------------------------
;WITH BranchList AS (
    SELECT ROW_NUMBER() OVER (ORDER BY BranchID) AS RowNum, BranchID
    FROM Branch
),
Num AS (
    SELECT TOP (@TotalLoans)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects
)
--------------------------------------------------
-- 5. Generate random loans distributed across branches
--------------------------------------------------
INSERT INTO Loan (BranchID, PrincipalAmount, StartDate)
SELECT 
    b.BranchID,  -- ✅ guaranteed valid BranchID
    CAST(ROUND((RAND(CHECKSUM(NEWID())) * 95000 + 5000), 2) AS decimal(18,2)) AS PrincipalAmount,
    DATEADD(DAY, -((n.rn * 12) % 900), CAST(GETDATE() AS date)) AS StartDate
FROM Num n
JOIN BranchList b 
    ON ((n.rn - 1) % (SELECT COUNT(*) FROM BranchList)) + 1 = b.RowNum;

--PRINT 'Loan table populated successfully!';

--------------------------------------------------
-- 6. Validation
--------------------------------------------------
/*
SELECT COUNT(*) AS TotalLoans FROM Loan;

SELECT TOP 20 
    LoanID,
    BranchID,
    PrincipalAmount,
    StartDate
FROM Loan
ORDER BY LoanID;
*/





--==================== Populating LoanCustomer ==================================================================================
GO
PRINT 'Populating LoanCustomer...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM LoanCustomer;

--------------------------------------------------
-- 2. Configuration
--------------------------------------------------
DECLARE @CustomerCount INT = (SELECT COUNT(*) FROM Customer);
DECLARE @JointLoanPct INT = 25;   -- 25% of loans will have 2 customers

--------------------------------------------------
-- 3. Assign one main customer per loan
--------------------------------------------------
;WITH LoanSeq AS (
    SELECT 
        l.LoanID,
        ROW_NUMBER() OVER (ORDER BY l.LoanID) AS rn
    FROM Loan l
)
INSERT INTO LoanCustomer (LoanID, CustomerID)
SELECT 
    ls.LoanID,
    ((ls.rn - 1) % @CustomerCount) + 1 AS CustomerID
FROM LoanSeq ls;

PRINT 'Populating LoanCustomer: Step 1/2: Primary loan customers assigned.';

--------------------------------------------------
-- 4. Add joint customers (~25%)
--------------------------------------------------
;WITH LoanSeq AS (
    SELECT 
        l.LoanID,
        ROW_NUMBER() OVER (ORDER BY l.LoanID) AS rn
    FROM Loan l
)
INSERT INTO LoanCustomer (LoanID, CustomerID)
SELECT 
    ls.LoanID,
    ((ls.rn + 42) % @CustomerCount) + 1 AS JointCustomerID
FROM LoanSeq ls
WHERE (ls.LoanID % 100) < @JointLoanPct
  AND NOT EXISTS (
        SELECT 1 
        FROM LoanCustomer lc
        WHERE lc.LoanID = ls.LoanID
          AND lc.CustomerID = ((ls.rn + 42) % @CustomerCount) + 1
    );

PRINT 'Populating LoanCustomer: Step 2/2: Joint loan customers assigned.';

--------------------------------------------------
-- 5. Validation
--------------------------------------------------
/*
SELECT 
    COUNT(*) AS TotalLinks,
    COUNT(DISTINCT LoanID) AS TotalLoansLinked,
    COUNT(DISTINCT CustomerID) AS TotalUniqueCustomers
FROM LoanCustomer;

-- Sample of linked records
SELECT TOP 20 
    lc.LoanID,
    c.FirstName,
    c.LastName,
    c.Email
FROM LoanCustomer lc
JOIN Customer c ON lc.CustomerID = c.CustomerID
ORDER BY lc.LoanID;
*/





--==================== Populating LoanPayment ===================================================================================
GO
PRINT 'Populating LoanPayment...';

--------------------------------------------------
-- 1. Clean existing data
--------------------------------------------------
DELETE FROM LoanPayment;

--------------------------------------------------
-- 2. Configuration
--------------------------------------------------
DECLARE @PaymentsPerLoan INT = 12;

--------------------------------------------------
-- 3. Generate 12 payments per loan
--------------------------------------------------
;WITH LoanSeq AS (
    SELECT 
        LoanID,
        StartDate,
        ROW_NUMBER() OVER (ORDER BY LoanID) AS rn
    FROM Loan
),
PaymentNum AS (
    SELECT TOP (@PaymentsPerLoan)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS PaymentNumber
    FROM sys.all_objects
)
INSERT INTO LoanPayment (LoanID, PaymentNumber, PaidOn, Amount)
SELECT 
    l.LoanID,
    p.PaymentNumber,
    DATEADD(MONTH, p.PaymentNumber, DATEFROMPARTS(YEAR(l.StartDate), MONTH(l.StartDate), 15)) AS PaidOn,
    CAST(ROUND((RAND(CHECKSUM(NEWID())) * 800 + 100), 2) AS decimal(18,2)) AS Amount
FROM LoanSeq l
CROSS JOIN PaymentNum p;

--PRINT 'LoanPayment table populated successfully!';
--------------------------------------------------
-- 4. Validation
--------------------------------------------------
/*
SELECT 
    COUNT(*) AS TotalPayments,
    COUNT(DISTINCT LoanID) AS TotalLoansWithPayments,
    AVG(Amount) AS AvgPaymentAmount
FROM LoanPayment;

-- Preview some payments
SELECT TOP 20 
    LoanID,
    PaymentNumber,
    PaidOn,
    Amount
FROM LoanPayment
ORDER BY LoanID, PaymentNumber;
*/


/* ==================== 13) Summary ==================== */
GO
DECLARE 
    @Branches INT,
    @Locations INT,
	@LocationType INT,
    @Employees INT,
	@EmployeeLocation INT,
    @Customers INT,
    @Accounts INT,
	@AccountHolder INT,
	@AccountType INT,
    @Overdrafts INT,
    @Loans INT,
	@LoanCustomer INT,
    @LoanPayments INT;

SELECT @Branches = COUNT(*) FROM Branch;
SELECT @Locations = COUNT(*) FROM Location;
SELECT @LocationType = COUNT(*) FROM LocationType;
SELECT @Employees = COUNT(*) FROM Employee;
SELECT @EmployeeLocation = COUNT(*) FROM EmployeeLocation;
SELECT @Customers = COUNT(*) FROM Customer;
SELECT @Accounts = COUNT(*) FROM Account;
SELECT @AccountHolder = COUNT(*) FROM AccountHolder;
SELECT @AccountType = COUNT(*) FROM AccountType;
SELECT @Overdrafts = COUNT(*) FROM Overdraft;
SELECT @Loans = COUNT(*) FROM Loan;
SELECT @LoanCustomer = COUNT(*) FROM LoanCustomer;
SELECT @LoanPayments = COUNT(*) FROM LoanPayment;

PRINT '--------------------------------------------------------';
PRINT 'Accounts........: ' + CAST(@Accounts AS varchar(20));
PRINT 'AccountHolder...: ' + CAST(@AccountHolder AS varchar(20));
PRINT 'AccountType.....: ' + CAST(@AccountType AS varchar(20));
PRINT 'Branch..........: ' + CAST(@Branches AS varchar(20));
PRINT 'Customer........: ' + CAST(@Customers AS varchar(20));
PRINT 'Employee........: ' + CAST(@Employees AS varchar(20));
PRINT 'EmployeeLocation: ' + CAST(@EmployeeLocation AS varchar(20));
PRINT 'Loan............: ' + CAST(@Loans AS varchar(20));
PRINT 'LoanCustomer....: ' + CAST(@LoanCustomer AS varchar(20));
PRINT 'LoanPayments....: ' + CAST(@LoanPayments AS varchar(20));
PRINT 'Location........: ' + CAST(@Locations AS varchar(20));
PRINT 'LocationType....: ' + CAST(@LocationType AS varchar(20));
PRINT 'Overdrafts......: ' + CAST(@Overdrafts AS varchar(20));
PRINT '--------------------------------------------------------';
PRINT 'Data population completed successfully!';
PRINT '==================== End of Script ====================';

--==================== End of Script ============================================================================================


/* ============================================================================================================
   Project: SKS_National_Bank
   File:    populate_database.sql
   Author:  Generated initially by ChatGPT (AI-assisted development)
   Date:    2025-10-15
   ------------------------------------------------------------------------------------------------------------
   ------------------------------------------------------------------------------------------------------------
   Description:
   This script populates the SKS_National_Bank database with realistic sample data in dependency order.
   It inserts data into all tables — including Branch, LocationType, Location, Employee, Customer,
   Account, Loan, and related association tables — ensuring referential integrity and adherence
   to all foreign key and unique constraints.

   The dataset includes:
     • Branches across major Canadian cities (e.g., Calgary, Toronto, Vancouver, etc.)
     • Location types (Head Office, Branch, ATM)
     • Employees with hierarchical ManagerID structure
     • Customers distributed across branches with valid postal codes and emails
     • Account types (Chequing, Savings, RRSP) and associated accounts
     • Loans, payments, overdrafts, and many-to-many relationships

   ------------------------------------------------------------------------------------------------------------
   Note:
   Although the initial version of this script was generated using ChatGPT for automation and efficiency,
   several manual adjustments and refinements were subsequently applied to ensure full compatibility
   and successful execution within Microsoft SQL Server. These modifications included:
     • Correcting variable scope and batch separation using GO statements
     • Adjusting dependency order between related tables
     • Resolving foreign key and constraint-related conflicts
     • Enhancing data validation and summary output for quality assurance

   The final version of this script is now stable, executable end-to-end, and suitable for academic,
   demonstration, or testing purposes.
   ------------------------------------------------------------------------------------------------------------
   Execution:
     1. Ensure the database "BankDatabase" already exists.
     2. Run the script in Microsoft SQL Server Management Studio (SSMS).
     3. The script will:
        - Purge existing data in the correct dependency order
        - Reseed identity values
        - Populate all tables with consistent, realistic data
        - Output a summary report of inserted records at the end

   ------------------------------------------------------------------------------------------------------------
   Version History:
     v1.0 - Initial AI-generated draft
     v1.1 - Manual corrections for constraints and dependency order
     v1.2 - Final validated version (full automation confirmed)

   ------------------------------------------------------------------------------------------------------------

   <<<<<<  PROMPT  >>>>>>>

	You are an expert in SQL Server database seeding and data generation.  
	Use the following database structure (from `database-diagram.txt`) to create a full **data population script** for the project **SKS_National_Bank**.

	The database includes these tables (with relationships and notes):

	database-diagram.txt  (file attached to the prompt)

	Your task:
	Create a SQL Server script named **populate_database.sql** that inserts realistic sample data for each table, in dependency order.  
	The data must respect all primary keys, foreign keys, and unique constraints.

	### Requirements:
	1. **Start the script with:**
	   ```sql
	   USE BankDatabase;
	   GO
	   SET NOCOUNT ON;
	2. Insert realistic data:
	•	Branch: ~10 branches (major Canadian cities like Calgary, Toronto, Vancouver, etc.).
	•	LocationType: Head Office, Branch, ATM.
	•	Location: Each branch has at least one main location and several ATMs.
	•	Employee: 50–100 employees total, with hierarchical ManagerID assignments (1 top-level per branch).
	•	EmployeeLocation: Link each employee to one primary site.
	•	Customer: ~500 customers distributed across branches, with valid postal codes, provinces, and emails.
	•	AccountType: Chequing, Savings, RRSP.
	•	Account: ~1000 accounts spread across customers and branches, with realistic balances and interest rates.
	•	AccountHolder: Each account must have 1–2 holders.
	•	Overdraft: Only for Chequing accounts, random occurrences.
	•	Loan: ~200 loans assigned to branches.
	•	LoanCustomer: Link one or two customers to each loan.
	•	LoanPayment: 12 payments per loan (monthly, sequential PaymentNumber).
	3. Data rules:
	•	Use sysutcdatetime() for timestamps where defaults apply.
	•	Generate random but consistent postal codes, cities, and provinces (e.g., AB, BC, ON, QC).
	•	Respect constraints like unique Email, valid FKs, and self-reference on ManagerID.
	•	Ensure InterestRate applies only to non-Chequing accounts.
	4. Formatting:
	•	Separate sections clearly with comments, e.g.:
				   /* ===== Populate Branch ===== */
	•	Use multi-row INSERT statements for brevity.
	•	End with summary PRINTs like:
				   PRINT 'Data population completed successfully!';

	No schema creation needed — assume the database already exists.

	Goal: produce a single ready-to-run T-SQL script that fills the BankDatabase database with realistic, relationally valid data for testing and learning purposes.

   ------------------------------------------------------------------------------------------------------------
   © 2025 SKS_National_Bank | Academic Project - Bow Valley College
   ============================================================================================================ */


