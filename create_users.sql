/* ============================================================
   FILE: create_users.sql
   PHASE 2 Users and Privileges
   SKS National Bank - Group D
   ============================================================ */

USE BankDatabase;
GO


--1) Create LOGINS
   
-- Customer user
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'customer_group_D')
    CREATE LOGIN customer_group_D WITH PASSWORD = 'customer';
GO

-- Accountant user
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'accountant_group_D')
    CREATE LOGIN accountant_group_D WITH PASSWORD = 'accountant';
GO


--2) Create DATABASE USERS
   
CREATE USER customer_group_D FOR LOGIN customer_group_D;
CREATE USER accountant_group_D FOR LOGIN accountant_group_D;
GO


--3) CUSTOMER USER PRIVILEGES

GRANT SELECT ON dbo.Customer       TO customer_group_D;
GRANT SELECT ON dbo.Account        TO customer_group_D;
GRANT SELECT ON dbo.AccountHolder  TO customer_group_D;
GRANT SELECT ON dbo.Overdraft      TO customer_group_D;
GRANT SELECT ON dbo.Loan           TO customer_group_D;
GRANT SELECT ON dbo.LoanCustomer   TO customer_group_D;
GRANT SELECT ON dbo.LoanPayment    TO customer_group_D;

-- Deny write operations everywhere
DENY INSERT, UPDATE, DELETE ON DATABASE::BankDatabase TO customer_group_D;
GO

--4) ACCOUNTANT USER PRIVILEGES
   
-- Allow SELECT on entire database
EXEC sp_msforeachtable 'GRANT SELECT ON ? TO accountant_group_D';
GO

-- Explicit DENY write on financial tables
DENY INSERT, UPDATE, DELETE ON dbo.Account        TO accountant_group_D;
DENY INSERT, UPDATE, DELETE ON dbo.Loan           TO accountant_group_D;
DENY INSERT, UPDATE, DELETE ON dbo.LoanPayment    TO accountant_group_D;
DENY INSERT, UPDATE, DELETE ON dbo.LoanCustomer   TO accountant_group_D;
DENY INSERT, UPDATE, DELETE ON dbo.Overdraft      TO accountant_group_D;
GO

