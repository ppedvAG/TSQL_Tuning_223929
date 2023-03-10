--Funktionen

--CREATE FUNCTION <Name> (@<Parameter> <Typ>, ...) RETURNS <Typ> AS BEGIN <Code> END
GO
CREATE FUNCTION f_CreateFullName(@FirstName varchar(25), @LastName varchar(25)) RETURNS varchar(50)
AS
	BEGIN
		RETURN @FirstName + ' ' + @LastName;
	END
GO

SELECT dbo.f_CreateFullName(FirstName, LastName) FROM Employees;


--Tabelle in Teile aufteilen mit Partitionsfunktion
CREATE PARTITION FUNCTION groupEmp(int)
AS
RANGE LEFT FOR VALUES (3, 6, 9);

SELECT $partition.groupEmp(10);

SELECT COUNT(*)
FROM Suppliers
GROUP BY $partition.groupEmp(SupplierID);