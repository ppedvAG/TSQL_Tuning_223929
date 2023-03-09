--Datumspartitionierung
CREATE PARTITION FUNCTION pfDatum(date) AS
RANGE LEFT FOR VALUES ('20181231', '20191231', '20201231', '20211231');
--Grenzen sind inklusiv '20190101' -> Partition 1, würde dieses Datum in die unterste Partition legen

CREATE PARTITION SCHEME schDatum AS
PARTITION pfDatum TO (Datum2018, Datum2019, Datum2020, Datum2021, Datum2022);

CREATE TABLE Rechnungsdaten (ID int identity, Rechnungsdatum date, Betrag float) ON schDatum(Rechnungsdatum);

DECLARE @i int = 0;
WHILE @i < 20000
BEGIN
	INSERT INTO Rechnungsdaten VALUES
	(DATEADD(DAY, FLOOR(RAND() * 1826), '20180101'), RAND() * 1000);
	SET @i += 1;
END

SELECT * FROM Rechnungsdaten ORDER BY Rechnungsdatum;

SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_partition_stats;

--Gibt eine Übersicht über die Partitionen einer Tabelle
SELECT
$partition.pfDatum(Rechnungsdatum) AS Partition,
COUNT(*) AS AnzDatensätze,
MIN(Rechnungsdatum) AS Untergrenze,
MAX(Rechnungsdatum) AS Obergrenze
FROM Rechnungsdaten
GROUP BY $partition.pfDatum(Rechnungsdatum);