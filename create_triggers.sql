/*=========================================================================================================================================================
--  DATA2201 – Phase 1
--  File: create_triggers.sql
--  Group D: 
--  Wesley Lomazzi.....: 461407
--  Lorenzo Ronzani....: 460676
--  Gabriel Passarelli.: 460625

--  Description: Triggers to track INSERT / UPDATE / DELETE 
--  SKS National Bank
===========================================================================================================================================================
    Create a new table called “Audit” to track changes made in the database. At minimum, this table should contain the following 3 pieces of information:
    -> Primary key.
    -> An explanation of exactly what happened in the database.
    -> Timestamp.
    Create 3 triggers of your choice that meet the following minimum requirements:
    -> Each trigger should log an entry into the Audit table.
    -> Each trigger should provide meaningful information to the database administrator at SKS National Bank.
    -> Provide SQL statements that test each of the 3 triggers.
===========================================================================================================================================================
*/
use BankDatabase
GO

/*=================================================================================================================
  Script: CREATE Audit Table
===================================================================================================================*/
CREATE TABLE Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,          -- Primary Key
    EventDescription NVARCHAR(500) NOT NULL,        -- Event Description: what type of execution
    EventDate DATETIME NOT NULL DEFAULT(GETDATE())  -- A timestamp field that automatically captures the date and time when a record is created
);


GO
/*=================================================================================================================
  Trigger 1 Script: CREATE trigger trg_Audit_Customer_Insert in Customer table
===================================================================================================================*/
CREATE TRIGGER trg_Audit_Customer_Insert
ON Customer
AFTER INSERT
AS
BEGIN
    INSERT INTO Audit (EventDescription)
    SELECT CONCAT('NEW CUSTOMER ADDED: CustomerID=', i.CustomerID,
                  ', Name=', i.FirstName, ' ', i.LastName)
    FROM inserted i;
END;

GO
/*=================================================================================================================
  Trigger 2 Script: CREATE trigger trg_Audit_Account_Update in Account table
  Executed: When the account balance is updated
===================================================================================================================*/
CREATE TRIGGER trg_Audit_Account_Update
ON Account
AFTER UPDATE
AS
BEGIN
    INSERT INTO Audit (EventDescription)
    SELECT CONCAT('ACCOUNT UPDATED: AccountID=', i.AccountID,
                  ' OldBalance=', d.Balance,
                  ' NewBalance=', i.Balance)
    FROM inserted i
    INNER JOIN deleted d ON i.AccountID = d.AccountID
    WHERE i.Balance <> d.Balance;
END;

GO
/*=================================================================================================================
  Trigger 3 Script: CREATE Trigger trg_Audit_Loan_Delete in Loan table
  Executed: When a Loan is deleted
===================================================================================================================*/
CREATE TRIGGER trg_Audit_Loan_Delete
ON LoanCustomer
AFTER DELETE
AS
BEGIN
    INSERT INTO Audit (EventDescription)
    SELECT CONCAT('LOAN DELETED: LoanID=', d.LoanID,
                  ', CustomerID=', d.CustomerID)
    FROM deleted d;
END;


GO
/*=================================================================================================================
  Test Trigger 1 — Insert into Customer
===================================================================================================================*/
INSERT INTO Customer (FirstName, LastName, Street, City, Province, PostalCode, Email)
VALUES ('John', 'Doe', 'Default Street', 'Calgary', 'AB', 'T3L0X3', 'john.doe@test.com');

GO
/*=================================================================================================================
  Testing Trigger 2 — Update in Account (changing balance)
===================================================================================================================*/
UPDATE Account
SET Balance = Balance + 500
WHERE AccountID = 1;

GO
/*=================================================================================================================
  Test Trigger 3 — Delete in Loan
===================================================================================================================*/
DELETE FROM LoanCustomer
WHERE CustomerID = 44;

GO
/*=================================================================================================================
  Check results in Audit Log
===================================================================================================================*/
SELECT * FROM Audit ORDER BY AuditID DESC;


