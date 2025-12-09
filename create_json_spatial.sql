USE BankDatabase;
GO

/* ====================================================
   1) ADD JSON COLUMN TO CUSTOMER TABLE
   ==================================================== */

ALTER TABLE dbo.Customer
ADD ExtraInfoJSON NVARCHAR(MAX) NULL;
GO

/* Insert sample JSON into all Customer rows */

UPDATE dbo.Customer
SET ExtraInfoJSON =
    '{
        "PreferredLanguage": "English",
        "MarketingOptIn": true,
        "EmergencyContacts": [
            {
                "Name": "John Doe",
                "Phone": "403-111-2222"
            }
        ]
     }';
GO


/* ====================================================
   2) ADD SPATIAL COLUMN TO EMPLOYEE TABLE
   ==================================================== */

ALTER TABLE dbo.Employee
ADD EmployeeGeoLocation GEOGRAPHY NULL;
GO

/* Insert sample geographic coordinates
   (example employees assigned to real-world coordinates)
*/

UPDATE dbo.Employee
SET EmployeeGeoLocation = GEOGRAPHY::STPointFromText('POINT(-114.0719 51.0447)', 4326)
WHERE EmployeeID = 1;  -- Employee 1 -> Calgary Downtown

UPDATE dbo.Employee
SET EmployeeGeoLocation = GEOGRAPHY::STPointFromText('POINT(-113.4938 53.5461)', 4326)
WHERE EmployeeID = 2;  -- Employee 2 -> Edmonton

UPDATE dbo.Employee
SET EmployeeGeoLocation = GEOGRAPHY::STPointFromText('POINT(-114.0853 51.0501)', 4326)
WHERE EmployeeID = 3;  -- Employee 3 -> Calgary University District



/* ====================================================
   3) VALIDATION QUERIES
   ==================================================== */

-- Ver spatial em formato WKT
SELECT EmployeeID, FirstName, LastName,
       EmployeeGeoLocation.ToString() AS WKTPresentation
FROM dbo.Employee;

-- Ver JSON
SELECT CustomerID, FirstName, LastName, ExtraInfoJSON
FROM dbo.Customer;
