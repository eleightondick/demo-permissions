USE [master];

IF EXISTS (SELECT 'x' FROM sys.databases WHERE name = 'AdventureWorks2014_snapshot')
	BEGIN
		ALTER DATABASE [AdventureWorks2014] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		RESTORE DATABASE [AdventureWorks2014]
			FROM DATABASE_SNAPSHOT = 'AdventureWorks2014_snapshot';
	END
ELSE
	CREATE DATABASE [AdventureWorks2014_snapshot]
		ON (NAME = AdventureWorks2014_Data, FILENAME = 'C:\SqlData\MSSQL15.MSSQLSERVER\MSSQL\DATA\AdventureWorks2014.ss')
		AS SNAPSHOT OF [AdventureWorks2014];
GO

IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE name = 'ADeveloper')
	DROP LOGIN ADeveloper;

IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE name = 'NAdmin')
	DROP LOGIN NAdmin;

IF EXISTS (SELECT 'x' FROM sys.databases WHERE name = 'Test')
	DROP DATABASE Test;
GO

IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE name = 'AdministratorRole')
	DROP SERVER ROLE AdministratorRole;
GO
