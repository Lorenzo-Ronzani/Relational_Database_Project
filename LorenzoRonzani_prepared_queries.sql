//*================================================================================================
  DATA2201 � Phase 1
  File: LorenzoRonzani_prepared_queries.sql
  Group D: Wesley Lomazzi, Lorenzo Ronzani, Gabriel Passarelli
  Description: Bank Database queries by Lorenzo Ronzani
  SKS National Bank
 =================================================================================================
  ERD
  https://dbdiagram.io/d/BankDatabase-Diagram-68e56472d2b621e422b9b2cc
  https://dbdocs.io/wlomazzi/Bank-Database?view=relationships
  https://github.com/Lorenzo-Ronzani/Relational_Database_Project

  Prepared Queries 
  Prepare relevant queries for your populated database. Create an SQL file named 
  �[your name]_prepared_queries.sql�. 
  This file should contain at least 3 queries that meet the following requirements: 
  # Each query is in a stored procedure or user-defined function format. 
  # Each query performs a meaningful action based on the case study. 
  # Each query includes a comment that describes the purpose of the query. 
  # Each query has a separate SQL statement that tests the query.

*/
USE BankDatabase;
GO

-- 1) Get all customers from a specific city. Purpose: Returns all customers located in a given city.

CREATE OR ALTER PROCEDURE GetCustomersByCity
    @City VARCHAR(40)
AS
BEGIN
    SELECT CustomerID, FirstName, LastName, Email, City, Province
    FROM Customer
    WHERE City = @City;
END;
-- Test
EXEC GetCustomersByCity @City = 'Calgary';
GO

--2) Get loan payments for a given customer
    -- Purpose: Shows all payments made for loans belonging to a customer.
   
CREATE OR ALTER PROCEDURE GetLoanPaymentsByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT 
        lp.LoanID,
        lp.PaymentNumber,
        lp.PaidOn,
        lp.Amount
    FROM LoanPayment lp
    INNER JOIN LoanCustomer lc ON lp.LoanID = lc.LoanID
    WHERE lc.CustomerID = @CustomerID
    ORDER BY lp.LoanID, lp.PaymentNumber;
END;
GO
-- Test
EXEC GetLoanPaymentsByCustomer @CustomerID = 3;
GO


--3) Get customers with overdrafts
   --Purpose: Lists distinct customers who have at least one overdraft.

CREATE OR ALTER PROCEDURE GetCustomersWithOverdraft
AS
BEGIN
    SELECT 
        c.CustomerID,
        c.FirstName,
        c.LastName,
        c.Email,
        a.AccountID,
        o.Amount AS OverdraftAmount,
        o.OccurredOn AS OverdraftDate
    FROM Overdraft o
    INNER JOIN Account a ON o.AccountID = a.AccountID
    INNER JOIN AccountHolder ah ON a.AccountID = ah.AccountID
    INNER JOIN Customer c ON ah.CustomerID = c.CustomerID
    ORDER BY o.OccurredOn DESC;
END;
GO

--Test

EXEC GetCustomersWithOverdraft;




