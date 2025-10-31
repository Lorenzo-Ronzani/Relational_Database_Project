/*================================================================================================
  DATA2201 – Phase 1
  File: prepared_queries.sql

  Group D: 
  Wesley Lomazzi.....: 461407
  Lorenzo Ronzani....: 460676
  Gabriel Passarelli.: 460625

  Description: Bank Database Prepared Queries
  SKS National Bank
 =================================================================================================
  Prepared Queries: Prepare relevant queries for your populated database. Create an SQL file named 
  “prepared_queries.sql”. 
  This file should contain 10 queries that meet the following requirements: 
  # Each query is in a stored procedure or user-defined function format. 
  # Each query performs a meaningful action based on the case study. 
  # Each query includes a comment that describes the purpose of the query. 
  # Each query has a separate SQL statement that tests the query.
*/

/* ================================================================
   Author: Wesley Lomazzi
   Purpose: Advanced analytical queries using stored procedures
   ================================================================ */

USE BankDatabase;
GO

/* ================================================================
   1) Procedure: GetBranchProfitabilityReport
   Purpose:
       Calculates profitability per branch, considering:
       - Total deposits (sum of balances)
       - Total loans (sum of principal)
       - Total overdrafts (sum of overdraft amounts)
       - Net Financial Position = Deposits - (Loans + Overdrafts)
   ================================================================ */
CREATE OR ALTER PROCEDURE GetBranchProfitabilityReport
AS
BEGIN
    SELECT 
        b.BranchID,
        b.Name AS BranchName,
        COUNT(DISTINCT a.AccountID) AS TotalAccounts,
        ROUND(SUM(a.Balance), 2) AS TotalDeposits,
        ROUND(ISNULL(SUM(DISTINCT l.PrincipalAmount), 0), 2) AS TotalLoans,
        ROUND(ISNULL(SUM(DISTINCT o.Amount), 0), 2) AS TotalOverdrafts,
        ROUND(SUM(a.Balance) - (ISNULL(SUM(DISTINCT l.PrincipalAmount), 0) + ISNULL(SUM(DISTINCT o.Amount), 0)), 2) AS NetFinancialPosition
    FROM Branch b
    LEFT JOIN Account a ON b.BranchID = a.BranchID
    LEFT JOIN Loan l ON l.BranchID = b.BranchID
    LEFT JOIN Overdraft o ON o.AccountID = a.AccountID
    GROUP BY b.BranchID, b.Name
    ORDER BY NetFinancialPosition DESC;
END;
GO
-- Test
EXEC GetBranchProfitabilityReport;
GO

/* ================================================================
   2) Procedure: GetCustomerLifetimeValue
   Purpose:
       Calculates a “Customer Lifetime Value” score estimating 
       the long-term value of each customer based on:
       - Total deposits (sum of balances)
       - Total loans taken
       - Loan repayment ratio
       - Number of overdrafts
       - Weighted scoring model for ranking valuable customers
   ================================================================ */
CREATE OR ALTER PROCEDURE GetCustomerLifetimeValue
AS
BEGIN
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS Customer,
        COUNT(DISTINCT a.AccountID) AS Accounts,
        ISNULL(SUM(a.Balance), 0) AS TotalDeposits,
        ISNULL(SUM(l.PrincipalAmount), 0) AS TotalLoaned,
        ISNULL(SUM(lp.Amount), 0) AS TotalPaid,
        COUNT(DISTINCT o.OverdraftID) AS Overdrafts,
        ROUND(
            (ISNULL(SUM(a.Balance), 0) * 0.5) +
            (ISNULL(SUM(lp.Amount), 0) * 0.3) -
            (COUNT(DISTINCT o.OverdraftID) * 200),
            2
        ) AS LifetimeValueScore
    FROM Customer c
    LEFT JOIN AccountHolder ah ON ah.CustomerID = c.CustomerID
    LEFT JOIN Account a ON a.AccountID = ah.AccountID
    LEFT JOIN LoanCustomer lc ON lc.CustomerID = c.CustomerID
    LEFT JOIN Loan l ON l.LoanID = lc.LoanID
    LEFT JOIN LoanPayment lp ON lp.LoanID = l.LoanID
    LEFT JOIN Overdraft o ON o.AccountID = a.AccountID
    GROUP BY c.CustomerID, c.FirstName, c.LastName
    ORDER BY LifetimeValueScore DESC;
END;
GO
-- Test
EXEC GetCustomerLifetimeValue;
GO

/* ================================================================
   3) Procedure: GetEmployeePerformanceAnalytics
   Purpose:
       Evaluates each employee's performance by aggregating:
       - Number of customers managed as banker
       - Total deposits under management
       - Total loan volume handled as loan officer
       - Average account balance per customer
   ================================================================ */
CREATE OR ALTER PROCEDURE GetEmployeePerformanceAnalytics
AS
BEGIN
    SELECT 
        e.EmployeeID,
        e.FirstName + ' ' + e.LastName AS Employee,
        COUNT(DISTINCT c.CustomerID) AS TotalCustomersManaged,
        ISNULL(SUM(a.Balance), 0) AS TotalDepositsManaged,
        ISNULL(SUM(l.PrincipalAmount), 0) AS TotalLoansApproved,
        ROUND(AVG(a.Balance), 2) AS AvgBalancePerCustomer
    FROM Employee e
    LEFT JOIN Customer c ON c.BankerID = e.EmployeeID OR c.LoanOfficerID = e.EmployeeID
    LEFT JOIN AccountHolder ah ON ah.CustomerID = c.CustomerID
    LEFT JOIN Account a ON a.AccountID = ah.AccountID
    LEFT JOIN LoanCustomer lc ON lc.CustomerID = c.CustomerID
    LEFT JOIN Loan l ON l.LoanID = lc.LoanID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
    ORDER BY TotalDepositsManaged DESC;
END;
GO
-- Test
EXEC GetEmployeePerformanceAnalytics;
GO


/* ================================================================
   4) Procedure: GetLoanDelinquencyRateByBranch
   Purpose:
       Calculates each branch’s loan repayment efficiency, showing:
       - Total principal issued
       - Total payments made
       - Remaining balance
       - Delinquency rate (%) = (Remaining / Principal) * 100
   ================================================================ */
CREATE OR ALTER PROCEDURE GetLoanDelinquencyRateByBranch
AS
BEGIN
    SELECT 
        b.BranchID,
        b.Name AS Branch,
        COUNT(DISTINCT l.LoanID) AS TotalLoans,
        ROUND(SUM(l.PrincipalAmount), 2) AS TotalPrincipal,
        ROUND(ISNULL(SUM(lp.Amount), 0), 2) AS TotalPaid,
        ROUND(SUM(l.PrincipalAmount) - ISNULL(SUM(lp.Amount), 0), 2) AS RemainingBalance,
        CASE 
            WHEN SUM(l.PrincipalAmount) = 0 THEN 0
            ELSE ROUND(((SUM(l.PrincipalAmount) - ISNULL(SUM(lp.Amount), 0)) / SUM(l.PrincipalAmount)) * 100, 2)
        END AS DelinquencyRatePercent
    FROM Branch b
    JOIN Loan l ON l.BranchID = b.BranchID
    LEFT JOIN LoanPayment lp ON lp.LoanID = l.LoanID
    GROUP BY b.BranchID, b.Name
    ORDER BY DelinquencyRatePercent DESC;
END;
GO
-- Test
EXEC GetLoanDelinquencyRateByBranch;
GO

/*----------------------------------------------------------------
   End of prepeared queries wlomazzi
-----------------------------------------------------------------*/


/* ================================================================
   Author: Lorenzo Ronzani
   Purpose: Prepeared Queries for Bank Database
=================================================================*/

-- 5) Get all customers from a specific city. Purpose: Returns all customers located in a given city.

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

--6) Get loan payments for a given customer
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


--7) Get customers with overdrafts
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

/*----------------------------------------------------------------
   End of prepeared queries Lorenzo Ronzani
-----------------------------------------------------------------*/


/* ================================================================
   Author: Gabriel Passarelli
   Purpose: Prepeared Queries for Bank Database
=================================================================*/
GO
-- 8) Purpose: Show all accounts that belong to a customer.
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

-- 9) Purpose: Show all loans of a customer and how many payments each one has.
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

-- 10) Purpose: Show all overdraft records for a customer.
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

/*----------------------------------------------------------------
   End of prepeared queries Gabriel Passarelli
-----------------------------------------------------------------*/

