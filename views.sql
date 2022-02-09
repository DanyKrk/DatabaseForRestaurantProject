-- 1. Widok łączący zamówienie i status zamówienia
CREATE VIEW OrdersWithStatus
AS
SELECT OrderID,
       CustomerID,
       OS.Status,
       InvoiceID,
       OrderTime,
       RequiredTime,
       ReservationDuration
FROM Orders O
         INNER JOIN OrderStatuses OS ON O.StatusID = OS.StatusID


-- 2. Widok łączący zamówienie z nazwą klienta (niezależnie czy jest to klient indywidualny czy przedsiębiorca)
CREATE VIEW OrderWithClient
AS
SELECT OrderID,
       ISNULL(CB.CompanyName, CP.FirstName + ' ' + CP.LastName) CustomerName,
       O.CustomerID,
       StatusID,
       InvoiceID,
       OrderTime,
       RequiredTime,
       ReservationDuration,
       IdOfDiscountUsedDuringPayment
FROM Orders O
         INNER JOIN Customers C ON O.CustomerID = C.CustomerID
         LEFT JOIN CustomersBusiness CB ON C.CustomerID = CB.CustomerID
         LEFT JOIN CustomersPerson CP ON C.CustomerID = CP.CustomerID


-- 3. Widok łączący łączący produkty z nazwami kategorii
CREATE VIEW ProductsWithCategory
AS
SELECT ProductID,
       ProductName,
       C.CategoryName,
       UnitPrice,
       UnitsInStock,
       Discontinued
FROM Products
         JOIN Categories C ON Products.CategoryID = C.CategoryID


-- 4. Widok z obliczoną wartością dla każdego szczegółu zamówienia’
CREATE VIEW OrderDetailsWithValue
AS
SELECT OD.OrderID,
       OD.ProductID,
       (OD.Quantity * MD.UnitPrice) AS OrderDetailValue,
       OD.Quantity,
       MD.UnitPrice
FROM Orders O
         JOIN OrderDetails OD ON O.OrderID = OD.OrderID
         JOIN Products P ON OD.ProductID = P.ProductID
         JOIN MenuDetails MD ON P.ProductID = MD.ProductID
         JOIN Customers C ON C.CustomerID = O.CustomerID


-- 5. Widok z menu które nie są jeszcze zatwierdzone i trwa nad nimi praca
CREATE VIEW MenusInProgressWithProducts
AS
SELECT M.MenuID,
       M.MenuName,
       M.MenuDescription,
       StartDate,
       EndDate,
       P.ProductID,
       ProductName,
       MD.UnitPrice
FROM Menu M
         INNER JOIN MenuDetails MD ON M.MenuID = MD.MenuID
         INNER JOIN Products P ON P.ProductID = MD.ProductID
WHERE IsReadyForDisplay = 0


-- 6. Widok wszystkich menu z ich produktami

CREATE VIEW MenusWithProducts
AS
SELECT M.MenuID,
       M.MenuName,
       M.MenuDescription,
       StartDate,
       EndDate,
       P.ProductID,
       ProductName,
       MD.UnitPrice
FROM Menu M
         INNER JOIN MenuDetails MD ON M.MenuID = MD.MenuID
         INNER JOIN Products P ON P.ProductID = MD.ProductID


-- 7. Widok wszystkich zamówień które mają rezerwacje na stoliki z informacjami o tychże rezerwacjach
CREATE VIEW OrdersWithTables
AS
SELECT O.OrderID,
       CustomerID,
       OS.Status,
       OrderTime,
       RequiredTime,
       ReservationDuration,
       ReservationID,
       RT.TableID,
       T.TableName,
       T.IsUsable
FROM Orders O
         INNER JOIN OrderStatuses OS ON O.StatusID = OS.StatusID
         INNER JOIN ReservationTable RT ON O.OrderID = RT.OrderID
         INNER JOIN Tables T ON RT.TableID = T.TableID

