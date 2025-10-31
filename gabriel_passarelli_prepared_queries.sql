/*================================================================================================
  DATA2201 – Phase 1
  File: gabriel_passarelli_prepared_queries.sql
  Group D: Wesley Lomazzi, Lorenzo Ronzani, Gabriel Passarelli
  Description: Bank Database queries by Gabriel Passarelli
  SKS National Bank
================================================================================================
  ERD
  https://dbdiagram.io/d/BankDatabase-Diagram-68e56472d2b621e422b9b2cc
  https://dbdocs.io/wlomazzi/Bank-Database?view=relationships
  https://github.com/Lorenzo-Ronzani/Relational_Database_Project

  Prepared Queries 
  Prepare relevant queries for your populated database. Create an SQL file named 
  “[your name]_prepared_queries.sql”. 
  This file should contain at least 3 queries that meet the following requirements: 
  # Each query is in a stored procedure or user-defined function format. 
  # Each query performs a meaningful action based on the case study. 
  # Each query includes a comment that describes the purpose of the query. 
  # Each query has a separate SQL statement that tests the query.
*/

USE BankDatabase;
GO

-- 1) Purpose: Show all accounts that belong to a customer.
CREATE OR ALTER PROCEDURE GetAccountsByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT 
        a.AccountID,
        a.Balance,
        a.AccountTypeID
    FROM dbo.AccountHolder AS ah
    INNER JOIN dbo.Account AS a ON ah.AccountID = a.AccountID
    WHERE ah.CustomerID = @CustomerID;
END;
GO
-- Test
EXEC GetAccountsByCustomer @CustomerID = 3;
GO

-- 2) Purpose: Show all loans of a customer and how many payments each one has.
CREATE OR ALTER PROCEDURE GetLoansAndPayments
    @CustomerID INT
AS
BEGIN
    SELECT 
        lc.LoanID,
        COUNT(lp.LoanID) AS TotalPayments
    FROM dbo.LoanCustomer AS lc
    LEFT JOIN dbo.LoanPayment AS lp ON lc.LoanID = lp.LoanID
    WHERE lc.CustomerID = @CustomerID
    GROUP BY lc.LoanID
    ORDER BY lc.LoanID;
END;
GO
-- Test
EXEC GetLoansAndPayments @CustomerID = 3;
GO

-- 3) Purpose: Show all overdraft records for a customer.
CREATE OR ALTER PROCEDURE GetCustomerOverdrafts
    @CustomerID INT
AS
BEGIN
    SELECT 
        o.OverdraftID,
        o.AccountID,
        o.Amount,
        o.OccurredOn
    FROM dbo.Overdraft AS o
    INNER JOIN dbo.AccountHolder AS ah ON ah.AccountID = o.AccountID
    WHERE ah.CustomerID = @CustomerID
    ORDER BY o.OccurredOn DESC;
END;
GO
-- Test
EXEC GetCustomerOverdrafts @CustomerID = 3;
GO
