--Trigger
--Vor INSERT/UPDATE/DELETE etwas machen
--Können auch die Abfrage verändern

USE Demo;

CREATE TABLE TriggerTest
(
	ID int identity primary key,
	Name varchar(10)
);

--CREATE TRIGGER <Name> ON <Tabelle> FOR/AFTER/INSTEAD OF   INSERT/UPDATE/DELETE AS <SQL-Statement>
GO
CREATE TRIGGER Test
ON TriggerTest
FOR INSERT
AS
PRINT 'Transaktion gestartet'
BEGIN TRAN;
GO

INSERT INTO TriggerTest VALUES('ABCDE')

ROLLBACK;