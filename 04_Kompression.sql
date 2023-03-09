--Kompression
--für Client komplett transparent (bei SELECT wird dekomprimiert, User sieht nix)
--Tabellen -> Zeilen- und Seitenkompression
--40%-60%, 70%-80%

--Große Tabelle erzeugen
SELECT  c.CustomerID
		, c.CompanyName
		, c.ContactName
		, c.ContactTitle
		, c.City
		, c.Country
		, o.EmployeeID
		, o.OrderDate
		, o.freight
		, o.shipcity
		, o.shipcountry
		, o.OrderID
		, od.ProductID
		, od.UnitPrice
		, od.Quantity
		, p.ProductName
		, e.LastName
		, e.FirstName
		, e.birthdate
INTO dbo.KundenUmsatz
FROM	Northwind.dbo.Customers c
		INNER JOIN Northwind.dbo.Orders o ON c.CustomerID = o.CustomerID
		INNER JOIN Northwind.dbo.Employees e ON o.EmployeeID = e.EmployeeID
		INNER JOIN Northwind.dbo.[Order Details] od ON o.orderid = od.orderid
		INNER JOIN Northwind.dbo.Products p ON od.productid = p.productid

INSERT INTO KundenUmsatz
SELECT * FROM KundenUmsatz
GO 9 --Viele Daten erzeugen

SELECT COUNT(*) FROM KundenUmsatz;

SET STATISTICS time, io ON;

SELECT * FROM KundenUmsatz;
--Logische Lesevorgänge: 41304, CPU-Zeit = 2109 ms, verstrichene Zeit = 15385 ms

DBCC showcontig('KundenUmsatz')
--Seiten 41304, Dichte: 98.19%

--Rechtsklick auf Tabelle -> Storage -> Manage Compression -> Row oder Page Compression auswählen und Next

--Nach Row Compression: 322MB -> 179MB (~45%)
SELECT * FROM KundenUmsatz;
--Logische Lesevorgänge: 22861, CPU-Zeit = 2188 ms, verstrichene Zeit = 13817 ms (CPU hat mehr Aufwand aber Daten brauchen weniger Platz)

DBCC showcontig('KundenUmsatz')
--Seiten: 22861, Dichte: 98.96%

--Nach Page Compression: 322MB -> 84MB (~75%)
SELECT * FROM KundenUmsatz;
--Logische Lesevorgänge: 10686, CPU-Zeit = 2704 ms, verstrichene Zeit = 13319 ms

DBCC showcontig('KundenUmsatz')
--Seiten: 10686, Dichte: 99.27%