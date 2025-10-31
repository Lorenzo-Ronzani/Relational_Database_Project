/* ================================================================
--  DATA2201 – Phase 1
--  File: create_database.sql
--  Group D: 
	Wesley Lomazzi: 461407
	Lorenzo Ronzani: 460676
	Gabriel Passarelli: 460625
--  Description: Bank Database creation script (updated to new ERD)
--  SKS National Bank
-- ================================================================
-- ERD
-- https://dbdiagram.io/d/BankDatabase-Diagram-68e56472d2b621e422b9b2cc
-- https://dbdocs.io/wlomazzi/Bank-Database?view=relationships
-- https://github.com/Lorenzo-Ronzani/Relational_Database_Project
*/

-- Make sure it's in master
USE master;
GO

-- Kill all active connections (except yours)
DECLARE @db_id int = DB_ID(N'BankDatabase');
IF @db_id IS NOT NULL
BEGIN
    DECLARE @sql nvarchar(max) = N'';
    SELECT @sql = STRING_AGG(N'KILL ' + CAST(session_id AS nvarchar(10)), N'; ')
    FROM sys.dm_exec_sessions
    WHERE database_id = @db_id
      AND session_id <> @@SPID;

    IF (@sql IS NOT NULL AND LEN(@sql) > 0)
        EXEC (@sql);
END
GO

-- Drop database if it already exists
IF DB_ID(N'BankDatabase') IS NOT NULL
BEGIN
    ALTER DATABASE [BankDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [BankDatabase];
END
GO


/* ================================================================
   1) Create database
   ================================================================ */
CREATE DATABASE [BankDatabase];
GO
ALTER DATABASE [BankDatabase] SET MULTI_USER;
GO
USE [BankDatabase];
GO


/* ================================================================
   2) Creating Tables (dbo schema)
   ================================================================ */

-- Table: LocationType
CREATE TABLE dbo.LocationType (
    LocationTypeID  int IDENTITY(1,1) NOT NULL,
    Name            varchar(50) NOT NULL,
    Description     varchar(40) NULL,
    CONSTRAINT PK_LocationType PRIMARY KEY (LocationTypeID),
    CONSTRAINT UQ_LocationType_Name UNIQUE (Name)
);
GO

-- Table: Branch
CREATE TABLE dbo.Branch (
    BranchID    int IDENTITY(1,1) NOT NULL,
    Name        varchar(100) NOT NULL,
    City        varchar(100) NOT NULL,
    CreatedAt   datetime2(3) NOT NULL CONSTRAINT DF_Branch_CreatedAt DEFAULT (sysutcdatetime()),
    CONSTRAINT PK_Branch PRIMARY KEY (BranchID),
    CONSTRAINT UQ_Branch_Name UNIQUE (Name)
);
GO

-- Table: Location
CREATE TABLE dbo.Location (
    LocationID      int IDENTITY(1,1) NOT NULL,
    Name            varchar(100) NOT NULL,
    LocationTypeID  int NOT NULL,
    BranchID        int NOT NULL,
    CreatedAt       datetime2(3) NOT NULL CONSTRAINT DF_Location_CreatedAt DEFAULT (sysutcdatetime()),
    CONSTRAINT PK_Location PRIMARY KEY (LocationID)
);
GO

-- Table: Employee
CREATE TABLE dbo.Employee (
    EmployeeID  int IDENTITY(1,1) NOT NULL,
    FirstName   varchar(20) NOT NULL,
    LastName    varchar(60) NOT NULL,
    PostalCode  varchar(6) NOT NULL,
    Street      varchar(40) NOT NULL,
    SuiteNumber varchar(10) NULL,
    City        varchar(40) NOT NULL,
    Province    varchar(2) NOT NULL,
    StartDate   date NOT NULL,
    ManagerID   int NULL,
    CONSTRAINT PK_Employee PRIMARY KEY (EmployeeID)
);
GO

-- Table: EmployeeLocation (junction)
CREATE TABLE dbo.EmployeeLocation (
    EmployeeID  int NOT NULL,
    LocationID  int NOT NULL,
    PrimarySite bit NOT NULL CONSTRAINT DF_EmployeeLocation_PrimarySite DEFAULT (0),
    CONSTRAINT PK_EmployeeLocation PRIMARY KEY (EmployeeID, LocationID)
);
GO

-- Table: Customer
CREATE TABLE dbo.Customer (
    CustomerID    int IDENTITY(1,1) NOT NULL,
    FirstName     varchar(20) NOT NULL,
    LastName      varchar(60) NOT NULL,
    PostalCode    varchar(6) NOT NULL,
    Street        varchar(40) NOT NULL,
    SuiteNumber   varchar(10) NULL,
    City          varchar(40) NOT NULL,
    Province      varchar(2) NOT NULL,
    Email         varchar(255) NULL,
    BankerID      int NULL,
    LoanOfficerID int NULL,
    CreatedAt     datetime2(3) NOT NULL CONSTRAINT DF_Customer_CreatedAt DEFAULT (sysutcdatetime()),
    CONSTRAINT PK_Customer PRIMARY KEY (CustomerID),
    CONSTRAINT UQ_Customer_Email UNIQUE (Email),
    CONSTRAINT CK_Customer_Email CHECK (Email IS NULL OR Email LIKE '%_@_%._%')
);
GO

-- Table: AccountType
CREATE TABLE dbo.AccountType (
    AccountTypeID int IDENTITY(1,1) NOT NULL,
    Name          varchar(50) NOT NULL,
    Description   varchar(200) NULL,
    CONSTRAINT PK_AccountType PRIMARY KEY (AccountTypeID),
    CONSTRAINT UQ_AccountType_Name UNIQUE (Name)
);
GO

-- Table: Account
CREATE TABLE dbo.Account (
    AccountID      bigint IDENTITY(1,1) NOT NULL,
    AccountTypeID  int NOT NULL,
    BranchID       int NOT NULL,
    Balance        decimal(18,2) NOT NULL CONSTRAINT DF_Account_Balance DEFAULT (0),
    InterestRate   decimal(5,2) NULL,
    LastAccessed   datetime2(3) NOT NULL CONSTRAINT DF_Account_LastAccessed DEFAULT (sysutcdatetime()),
    CONSTRAINT PK_Account PRIMARY KEY (AccountID),
    CONSTRAINT CK_Account_IRange CHECK (InterestRate IS NULL OR (InterestRate >= 0 AND InterestRate <= 100))
);
GO

-- Table: AccountHolder (junction)
CREATE TABLE dbo.AccountHolder (
    AccountID   bigint NOT NULL,
    CustomerID  int NOT NULL,
    CONSTRAINT PK_AccountHolder PRIMARY KEY (AccountID, CustomerID)
);
GO

-- Table: Overdraft
CREATE TABLE dbo.Overdraft (
    OverdraftID bigint IDENTITY(1,1) NOT NULL,
    AccountID   bigint NOT NULL,
    OccurredOn  date NOT NULL,
    Amount      decimal(18,2) NOT NULL,
    CheckNumber varchar(30) NULL,
    CONSTRAINT PK_Overdraft PRIMARY KEY (OverdraftID)
);
GO

-- Table: Loan
CREATE TABLE dbo.Loan (
    LoanID          bigint IDENTITY(1,1) NOT NULL,
    BranchID        int NOT NULL,
    PrincipalAmount decimal(18,2) NOT NULL,
    StartDate       date NOT NULL,
    CONSTRAINT PK_Loan PRIMARY KEY (LoanID)
);
GO

-- Table: LoanCustomer (junction)
CREATE TABLE dbo.LoanCustomer (
    LoanID     bigint NOT NULL,
    CustomerID int NOT NULL,
    CONSTRAINT PK_LoanCustomer PRIMARY KEY (LoanID, CustomerID)
);
GO

-- Table: LoanPayment
CREATE TABLE dbo.LoanPayment (
    LoanID        bigint NOT NULL,
    PaymentNumber int NOT NULL,
    PaidOn        date NOT NULL,
    Amount        decimal(18,2) NOT NULL,
    CONSTRAINT PK_LoanPayment PRIMARY KEY (LoanID, PaymentNumber)
);
GO


/* ================================================================
   3) Foreign Keys (relationships)
   ================================================================ */

ALTER TABLE dbo.Location
  ADD CONSTRAINT FK_Location_Branch
  FOREIGN KEY (BranchID) REFERENCES dbo.Branch(BranchID),
  CONSTRAINT FK_Location_LocationType
  FOREIGN KEY (LocationTypeID) REFERENCES dbo.LocationType(LocationTypeID);
GO

ALTER TABLE dbo.Employee
  ADD CONSTRAINT FK_Employee_Manager
  FOREIGN KEY (ManagerID) REFERENCES dbo.Employee(EmployeeID);
GO

ALTER TABLE dbo.EmployeeLocation
  ADD CONSTRAINT FK_EmployeeLocation_Employee
  FOREIGN KEY (EmployeeID) REFERENCES dbo.Employee(EmployeeID),
  CONSTRAINT FK_EmployeeLocation_Location
  FOREIGN KEY (LocationID) REFERENCES dbo.Location(LocationID);
GO

ALTER TABLE dbo.Customer
  ADD CONSTRAINT FK_Customer_Banker
  FOREIGN KEY (BankerID) REFERENCES dbo.Employee(EmployeeID),
  CONSTRAINT FK_Customer_LoanOfficer
  FOREIGN KEY (LoanOfficerID) REFERENCES dbo.Employee(EmployeeID);
GO

ALTER TABLE dbo.Account
  ADD CONSTRAINT FK_Account_AccountType
  FOREIGN KEY (AccountTypeID) REFERENCES dbo.AccountType(AccountTypeID),
  CONSTRAINT FK_Account_Branch
  FOREIGN KEY (BranchID) REFERENCES dbo.Branch(BranchID);
GO

ALTER TABLE dbo.AccountHolder
  ADD CONSTRAINT FK_AccountHolder_Account
  FOREIGN KEY (AccountID) REFERENCES dbo.Account(AccountID),
  CONSTRAINT FK_AccountHolder_Customer
  FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID);
GO

ALTER TABLE dbo.Overdraft
  ADD CONSTRAINT FK_Overdraft_Account
  FOREIGN KEY (AccountID) REFERENCES dbo.Account(AccountID);
GO

ALTER TABLE dbo.Loan
  ADD CONSTRAINT FK_Loan_Branch
  FOREIGN KEY (BranchID) REFERENCES dbo.Branch(BranchID);
GO

ALTER TABLE dbo.LoanCustomer
  ADD CONSTRAINT FK_LoanCustomer_Loan
  FOREIGN KEY (LoanID) REFERENCES dbo.Loan(LoanID),
  CONSTRAINT FK_LoanCustomer_Customer
  FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID);
GO

ALTER TABLE dbo.LoanPayment
  ADD CONSTRAINT FK_LoanPayment_Loan
  FOREIGN KEY (LoanID) REFERENCES dbo.Loan(LoanID);
GO


/* ================================================================
   4) Extended Properties (metadata and documentation)
   ================================================================ */

EXEC sys.sp_addextendedproperty
@name = N'Table_Description',
@value = 'Lookup for types of locations (Head Office, Branch, ATM, etc.)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'LocationType';
GO

EXEC sys.sp_addextendedproperty
@name = N'Table_Description',
@value = 'Lookup for account types (Chequing, Savings, RRSP, etc.)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'AccountType';
GO

EXEC sys.sp_addextendedproperty
@name = N'Table_Description',
@value = 'Composite PK (EmployeeID, LocationID)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'EmployeeLocation';
GO

EXEC sys.sp_addextendedproperty
@name = N'Table_Description',
@value = 'Composite PK (AccountID, CustomerID)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'AccountHolder';
GO

EXEC sys.sp_addextendedproperty
@name = N'Table_Description',
@value = 'Composite PK (LoanID, CustomerID)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'LoanCustomer';
GO

EXEC sys.sp_addextendedproperty
@name = N'Table_Description',
@value = 'Composite PK (LoanID, PaymentNumber)',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'LoanPayment';
GO

/* ================================================================
   END OF SCRIPT
   ================================================================ */
