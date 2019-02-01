USE [AdventureWorks2014];
GO

-- DEMO 1

-- Create a user and add them to db_datareader
CREATE USER User1 WITHOUT LOGIN;
ALTER ROLE db_datareader
	ADD MEMBER User1;
GO

EXECUTE AS USER='User1'
	SELECT TOP 10 * FROM HumanResources.EmployeePayHistory;
REVERT;
GO

EXECUTE AS USER='User1'
	SELECT *
		FROM sys.fn_my_permissions('HumanResources.EmployeePayHistory', 'OBJECT');
REVERT;
GO

-- So far, so good...
-- Let's deny them access to a table
DENY SELECT ON HumanResources.EmployeePayHistory TO User1;
GO

EXECUTE AS USER='User1'
	SELECT TOP 10 * FROM HumanResources.EmployeePayHistory;
REVERT;
GO

EXECUTE AS USER='User1'
	SELECT *
		FROM sys.fn_my_permissions('HumanResources.EmployeePayHistory', 'OBJECT');
REVERT;
GO

-- Looks good!
-- Now, let's say that someone added a new table...
SELECT BusinessEntityID, Rate as OldRate, CAST((CASE WHEN BusinessEntityID % 2 = 0 THEN Rate * 1.25 ELSE Rate END) AS money) AS NewRate 
	INTO HumanResources.EmployeeRaises
	FROM HumanResources.EmployeePayHistory;
GO

EXECUTE AS USER='User1'
	SELECT TOP 10 * FROM HumanResources.EmployeeRaises;
REVERT;
GO

-- DEMO 2

-- Let's create a developer login and a new database
USE [master];

CREATE LOGIN ADeveloper WITH PASSWORD = 'str0ngPa$$w0rd';
CREATE DATABASE [Test];
GO

-- Make the developer a member of db_owner
USE [Test];

CREATE USER ADeveloper;
ALTER ROLE db_owner
	ADD MEMBER ADeveloper;
GO

-- Should a developer be able to do this?
USE [master];

EXECUTE AS LOGIN='ADeveloper'
	DROP DATABASE [Test];
REVERT;

USE [AdventureWorks2014];

EXECUTE AS LOGIN='ADeveloper'
	CREATE USER NewUser WITHOUT LOGIN;
REVERT;
GO

-- DEMO 3
-- The better way to start
USE [AdventureWorks2014];

CREATE ROLE ApplicationRole;

GRANT SELECT ON HumanResources.Department TO ApplicationRole;
GRANT SELECT ON SCHEMA::Person TO ApplicationRole;
GRANT SELECT ON HumanResources.Employee (BusinessEntityID, JobTitle, HireDate, CurrentFlag) TO ApplicationRole;

CREATE USER User2 WITHOUT LOGIN;
ALTER ROLE ApplicationRole
	ADD MEMBER User2;
GO

EXECUTE AS USER='User2'
	SELECT TOP 10 * FROM HumanResources.Department;

	SELECT TOP 10 * FROM Person.Person;

	SELECT TOP 10 * FROM HumanResources.Employee;

	SELECT TOP 10 e.BusinessEntityID, p.FirstName + ' ' + p.LastName AS FullName, e.JobTitle, e.HireDate, e.CurrentFlag
		FROM HumanResources.Employee e
			LEFT OUTER JOIN Person.Person p ON p.BusinessEntityID = e.BusinessEntityID;
REVERT;
GO

-- DEMO 4
-- How do we handle administrators?
USE [master];

CREATE LOGIN NAdmin WITH PASSWORD = 'str0ngPa$$w0rd';
ALTER SERVER ROLE sysadmin
	ADD MEMBER NAdmin;
GO

EXECUTE AS LOGIN='NAdmin'
	SELECT HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'CREATE DATABASE');
REVERT;
GO

DENY CREATE ANY DATABASE TO NAdmin;
GO

EXECUTE AS LOGIN='NAdmin'
	SELECT HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'CREATE DATABASE');
REVERT;
GO

EXECUTE AS LOGIN='NAdmin'
	CREATE DATABASE [Test];
REVERT;
GO

SELECT *
	FROM sys.databases
	WHERE [name] = 'Test';
GO

DENY SELECT ALL USER SECURABLES TO NAdmin;
GO

EXECUTE AS LOGIN='NAdmin'
	SELECT TOP 10 * FROM AdventureWorks2014.HumanResources.Employee;
REVERT;
GO

USE [AdventureWorks2014];
CREATE USER NAdmin FOR LOGIN NAdmin;
DENY SELECT ON SCHEMA::HumanResources TO NAdmin;
GO

EXECUTE AS USER='NAdmin'
	SELECT TOP 10 * FROM HumanResources.Employee;
REVERT;
GO

-- That wasn't ideal...
-- Drop the login so we can try a different method
USE [AdventureWorks2014];
DROP USER NAdmin;
GO

USE [master];
DROP LOGIN NAdmin;
DROP DATABASE Test;
GO

-- Create a custom role for administrators
CREATE SERVER ROLE AdministratorRole;
GO

-- Method 1: Grant broad, "almost sysadmin" permissions
GRANT CONTROL SERVER TO AdministratorRole;
GO

-- Method 2: Grant more granular permissions
--GRANT VIEW ANY DATABASE TO AdministratorRole;
--GRANT CONNECT ANY DATABASE TO AdministratorRole;
--GRANT SELECT ALL USER SECURABLES TO AdministratorRole;
--GO

-- Now, recreate the same test login as before, but assign it to the custom role
CREATE LOGIN NAdmin WITH PASSWORD = 'str0ngPa$$w0rd';
ALTER SERVER ROLE AdministratorRole
	ADD MEMBER NAdmin;
GO

EXECUTE AS LOGIN='NAdmin'
	SELECT HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'CREATE DATABASE');
REVERT;
GO

-- DENYs now work as expected
DENY CREATE ANY DATABASE TO NAdmin;
GO

EXECUTE AS LOGIN='NAdmin'
	SELECT HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'CREATE DATABASE');
REVERT;
GO

EXECUTE AS LOGIN='NAdmin'
	CREATE DATABASE Test;
REVERT;

USE [AdventureWorks2014];
CREATE USER NAdmin FOR LOGIN NAdmin;

DENY SELECT ON SCHEMA::HumanResources TO NAdmin;
GO

EXECUTE AS USER='NAdmin'
	SELECT TOP 10 * FROM HumanResources.Employee;
REVERT;
GO

-- Similarly, dbo cannot be denied permissions within the database