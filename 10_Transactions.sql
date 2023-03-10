--Transaction
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--Wenn ein Fehler in der Transaktion auftritt, wird ein Rollback gemacht
BEGIN TRAN;
INSERT INTO Customers (CustomerID) VALUES ('ABCEDF')

USE Demo;
ALTER TABLE T1 ALTER COLUMN test varchar(5);
BEGIN TRY
	BEGIN TRAN;
	UPDATE T1 SET test = '123456789';
	COMMIT;
	PRINT 'Erfolg';
END TRY
BEGIN CATCH
	ROLLBACK;
	PRINT 'Fehler';
END CATCH