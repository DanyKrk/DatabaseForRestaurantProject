-- 1. Wartość danego zamówienia
CREATE PROCEDURE usp_valueOfOrder @VarOrderID INT
AS
BEGIN
   IF EXISTS(SELECT * FROM Orders O WHERE O.OrderID = @VarOrderID)
       BEGIN
           SELECT SUM(ODValue.OrderDetailValue)
           FROM Customers C
                    JOIN Orders O ON C.CustomerID = O.CustomerID
                    JOIN OrderDetailsWithValue ODValue
                         ON O.OrderID = ODValue.OrderID
           WHERE O.OrderID = @VarOrderID
       END
   ELSE
       BEGIN
           ;THROW 60000, 'Specified @order_id does not exist!!!', 1;
       END
END

-- 2. Menu ważne danego dnia
CREATE PROCEDURE usp_menuValidInDate @VarDate DATE
AS
BEGIN
   SELECT ProductName, C2.CategoryName, M.UnitPrice
   FROM Products
            JOIN MenuDetails M ON Products.ProductID = M.ProductID
            JOIN Menu M2 ON M2.MenuID = M.MenuID
            JOIN Categories C2 ON C2.CategoryID = Products.CategoryID
   WHERE @VarDate >= M2.StartDate
     AND @VarDate <= M2.EndDate
     AND M2.IsReadyForDisplay = 1
END

-- 3. Rezerwacje w danym przedziale czasowym
CREATE PROCEDURE usp_reservationsInTimePeriod @VarStartDate DATE, @VarEndDate DATE
AS
BEGIN
   SELECT ReservationID,
          O.OrderID,
          ISNULL(CB.CompanyName, CP.FirstName + ' ' +
                                 CP.LastName) CustomerName,
          T.TableID,
          T.TableName,
          O.OrderTime
   FROM ReservationTable RT
            INNER JOIN Orders O ON RT.OrderID = O.OrderID
            INNER JOIN Tables T ON RT.TableID = T.TableID
            INNER JOIN Customers C ON O.CustomerID = C.CustomerID
            LEFT JOIN CustomersBusiness CB
                      ON C.CustomerID = CB.CustomerID
            LEFT JOIN CustomersPerson CP
                      ON C.CustomerID = CP.CustomerID

   WHERE
            O.OrderTime >= @VarStartDate and O.OrderTime <= @VarEndDate
   ORDER BY ReservationID;
END

-- 4. Faktury danego klienta
CREATE PROCEDURE usp_invoicesOfRequester @VarCustomerID INT
AS
BEGIN
    IF ((@VarCustomerID) NOT IN (SELECT CustomerID
                                 FROM Customers))
        BEGIN
            ;THROW 60000, 'There is no such order!!!', 1;
        END

    SELECT *
    FROM Invoices

    WHERE InvoiceID IN
          (SELECT Orders.InvoiceID FROM Orders WHERE CustomerID = @VarCustomerID)
END

-- 5. Informacje na temat zniżek typu 1. danego klienta
CREATE PROCEDURE usp_discount1Progress @VarCustomerID INT
AS
BEGIN
    IF NOT EXISTS(SELECT *
                  FROM Customers
                  WHERE CustomerID = @VarCustomerID)
        BEGIN
            ;THROW 60000, 'Specified Customer does not exist!!!', 1;
        END
    ELSE
        IF IIF(@VarCustomerID IN (SELECT CustomerID
                               FROM Discounts
                               WHERE DiscountType = 1),
               1,
               NULL) IS NULL
            BEGIN
                SELECT COUNT(*) AS HowManyOrders,
                       IIF(COUNT(*) > (SELECT Z1
                                       FROM DiscountParameters
                                       WHERE StartTime =
                                             (SELECT MAX(StartTime)
                                              FROM DiscountParameters)),
                           1, 0)   HasDiscountR1
                FROM (SELECT SUM(MD.UnitPrice) price
                      FROM OrderDetails OD
                               INNER JOIN Orders O ON O.OrderID = OD.OrderID
                               INNER JOIN Products P ON P.ProductID = OD.ProductID
                               INNER JOIN MenuDetails MD ON P.ProductID = MD.ProductID
                      WHERE CustomerID = @VarCustomerID
                      GROUP BY O.OrderID
                      HAVING SUM(MD.UnitPrice) > (SELECT K1
                                                  FROM DiscountParameters
                                                  WHERE StartTime =
                                                        (SELECT MAX(StartTime)
                                                         FROM DiscountParameters))) AS orders

            END
        ELSE
            BEGIN
                SELECT COUNT(*) AS HowManyOrders,
                       1           HasDiscountR1
                FROM (SELECT SUM(MD.UnitPrice) price, O.OrderTime
                      FROM OrderDetails OD
                               INNER JOIN Orders O ON O.OrderID = OD.OrderID
                               INNER JOIN Products P ON P.ProductID = OD.ProductID
                               INNER JOIN MenuDetails MD ON P.ProductID = MD.ProductID
                      WHERE CustomerID = @VarCustomerID
                      GROUP BY O.OrderID, O.OrderTime
                      HAVING SUM(MD.UnitPrice) *
                             ISNULL(1 - (SELECT R1
                                         FROM DiscountParameters
                                         WHERE StartTime < O.OrderTime
                                           AND EndTime > O.OrderTime),
                                    1) > (SELECT K1
                                          FROM DiscountParameters
                                          WHERE StartTime =
                                                (SELECT MAX(StartTime)
                                                 FROM DiscountParameters))) AS orders
            END
END

-- 6. Informacje na temat zniżek typu 2. danego klienta
CREATE PROCEDURE usp_discount2Progress @VarCustomerID INT
AS
BEGIN
    IF NOT EXISTS(SELECT *
                  FROM Customers
                  WHERE CustomerID = @VarCustomerID)
        BEGIN
            ;THROW 60000, 'Specified Customer does not exist!!!', 1;
        END
    ELSE
        BEGIN
            IF IIF(@VarCustomerID IN (SELECT CustomerID
                                   FROM Discounts
                                   WHERE DiscountType = 2),
                   1, NULL) IS NULL
                BEGIN
                    SELECT SUM(MD.UnitPrice) MoneySpent,
                           IIF(SUM(MD.UnitPrice) >
                               (SELECT K2
                                FROM DiscountParameters
                                WHERE StartTime =
                                      (SELECT MAX(StartTime)
                                       FROM DiscountParameters)),
                               1, 0) AS      HasDiscountR2
                    FROM OrderDetails OD
                             INNER JOIN Orders O ON O.OrderID = OD.OrderID
                             INNER JOIN Products P ON P.ProductID = OD.ProductID
                             INNER JOIN MenuDetails MD ON P.ProductID = MD.ProductID
                    WHERE CustomerID = @VarCustomerID
                    GROUP BY CustomerID
                END
            ELSE
                BEGIN
                    SELECT SUM(MD.UnitPrice) MoneySpent,
                           1 AS              HasDiscountR2
                    FROM OrderDetails OD
                             INNER JOIN Orders O ON O.OrderID = OD.OrderID
                             INNER JOIN Products P ON P.ProductID = OD.ProductID
                             INNER JOIN MenuDetails MD ON P.ProductID = MD.ProductID
                    WHERE CustomerID = @VarCustomerID
                      AND O.OrderTime >
                          (SELECT MAX(DiscountAcquisitionDate)
                           FROM Discounts
                           WHERE CustomerID = @VarCustomerID
                             AND DiscountType = 2)
                    GROUP BY CustomerID
                END
        END
END

-- 7. Informacje na temat zniżek obu typów dla danego klienta
CREATE PROCEDURE usp_discountProgress @VarCustomerID INT
AS
BEGIN
    IF NOT EXISTS(SELECT *
                  FROM Customers
                  WHERE CustomerID = @VarCustomerID)
        BEGIN
            ;THROW 60000, 'Specified Customer does not exist!!!', 1;
        END
    ELSE
        BEGIN
            DECLARE @t TABLE
                       (
                           [OrdersDone/MoneySpent] INT,
                           HasDiscount             INT
                       )
            INSERT INTO @t EXEC usp_discount1Progress @VarCustomerID
            INSERT INTO @t EXEC usp_discount2Progress @VarCustomerID
            SELECT * FROM @t
        END
END

-- 8. Stoliki danej rezerwacji
CREATE PROCEDURE usp_tablesOfOrderReservation @VarOrderID INT
AS
BEGIN
    IF NOT EXISTS(SELECT * FROM Orders WHERE OrderID = @VarOrderID)
        BEGIN
            ;THROW 60000, 'Specified OrderID does not exist!!!', 1;
        END
    ELSE
        BEGIN
            SELECT O.OrderID, T.TableID, T.TableName
            FROM Orders O
                     INNER JOIN ReservationTable RT ON O.OrderID = RT.OrderID
                     INNER JOIN Tables T ON RT.TableID = T.TableID
            WHERE O.OrderID = @VarOrderID
            ORDER BY TableID;
        END
END

-- 9. Ustawienie stanu gotowości do wystawienia danego menu
CREATE PROCEDURE usp_setMenuReadyForDisplayState @VarMenuID INT, @VarMenuState BIT
AS
BEGIN
    IF NOT EXISTS(SELECT * FROM Menu WHERE MenuID = @VarMenuID)
        BEGIN
            ;THROW 60000, 'Specified MenuID does not  exist!!!', 1;
        END

    ELSE
        BEGIN
            UPDATE Menu
            SET IsReadyForDisplay = @VarMenuState
            WHERE MenuID = @VarMenuID;
        END
END

-- 10. Wystawianie faktury (zmiana isCompleted w tabeli Invoices)
CREATE PROCEDURE usp_completeInvoice @VarInvoiceID INT
AS
BEGIN
    IF IIF(@VarInvoiceID IN (SELECT InvoiceID
                               FROM Invoices),
               1,
               NULL) IS NULL
        BEGIN
            ;THROW 60000, 'Specified InvoiceID does not  exist!!!', 1;
        END

    ELSE IF IIF(@VarInvoiceID IN (SELECT InvoiceID
                                FROM Invoices
                                WHERE IsCompleted = 0),
               1,
               NULL) IS NULL
        BEGIN
            ;THROW 60000, 'Specified invoice was already completed!!!', 1;
        END
    ELSE
        BEGIN
            UPDATE Invoices
            SET IsCompleted = 1
            WHERE InvoiceID = @VarInvoiceID;
        END
END

-- 11. Stworzenie faktury z jednym zamówieniem
CREATE PROCEDURE usp_createInvoiceAndAddFirstOrder @VarOrderID INT,
                                                  @VarInvoiceNumber INT,
                                                  @VarIssuedDate DATE
AS
BEGIN
   BEGIN TRANSACTION
       IF ((@VarOrderID) NOT IN (SELECT OrderID
                                 FROM Orders))
           BEGIN
               ;THROW 60000, 'Specified OrderID does not  exist!!!', 1;
           END

       ELSE
           BEGIN
               IF (1 IN (SELECT IsCompleted
                         FROM Invoices
                         WHERE InvoiceID = (SELECT InvoiceID
                                            FROM Orders
                                            WHERE OrderID = @VarOrderID)))
                   BEGIN
                       ;THROW 60000, 'That order is already included in completed invoice', 1;
                   END


               INSERT INTO Invoices (InvoiceNumber, IssuedDate,
                                     InvoiceRequester,
                                     Country,
                                     City, Address, IsCompleted)

               SELECT @VarInvoiceNumber,
                      @VarIssuedDate,
                      CompanyName,
                      Country,
                      City,
                      Address,
                      0
               FROM CustomersBusiness
               WHERE CustomerID =
                     (SELECT CustomerID
                      FROM Orders
                      WHERE OrderID = @VarOrderID)

               DECLARE @LastID INT;
               SET @LastID = @@IDENTITY

               UPDATE Orders
               SET InvoiceID = @LastID
               WHERE OrderID = @VarOrderID
           END
   COMMIT
END

-- 12. Dodanie pojedynczego zamówienia do faktury
CREATE PROCEDURE usp_addSingleOrderToInvoice @VarInvoiceID INT, @VarOrderID INT
AS
BEGIN
       BEGIN TRANSACTION
           IF (1 IN (SELECT IsCompleted
                     FROM Invoices
                     WHERE InvoiceID = @VarInvoiceID))
               BEGIN
                   ;THROW 60000, 'That invoice is already completed!!!', 1;
               END

           IF ((@VarInvoiceID) NOT IN (SELECT InvoiceID
                                       FROM Invoices))
               BEGIN
                   ;THROW 60000, 'Specified InvoiceID does not  exist!!!', 1;
               END

           IF ((@VarOrderID) NOT IN (SELECT OrderID
                                     FROM Orders))
               BEGIN
                   ;THROW 60000, 'Specified OrderID does not  exist!!!', 1;
               END

           IF (1 IN (SELECT IsCompleted
                     FROM Invoices
                     WHERE InvoiceID = (SELECT InvoiceID
                                        FROM Orders
                                        WHERE OrderID = @VarOrderID)))
               BEGIN
                   ;THROW 60000, 'That order is already included in completed invoice', 1;
               END

           DECLARE @InvoiceOwnerID INT;
           SET @InvoiceOwnerID =
                   (SELECT CustomerID FROM Orders WHERE OrderID = @VarOrderID)

           IF ((SELECT COUNT(DISTINCT CustomerID)
                FROM Orders
                WHERE InvoiceID = @VarInvoiceID
                  AND CustomerID != @InvoiceOwnerID) >= 1)
               BEGIN
                   ;THROW 60000, 'That invoice already contains orders from other customer!!!', 1;
               END

           UPDATE Orders
           SET InvoiceID = @VarInvoiceID
           WHERE OrderID = @VarOrderID;
       COMMIT
END

-- 13. Utworzenie faktury miesięcznej dla danego klienta
CREATE PROCEDURE usp_createMonthlyInvoice @VarCustomerID INT,
                                         @VarYear INT,
                                         @VarMonth INT,
                                         @VarInvoiceNumber INT,
                                         @VarIssuedDate DATE
AS
BEGIN

   IF ((@VarCustomerID) NOT IN (SELECT CustomerID
                                FROM CustomersBusiness))
       BEGIN
           ;THROW 60000, 'There is no such Business Client!!!', 1;
       END


   INSERT INTO Invoices (InvoiceNumber, IssuedDate,
                         InvoiceRequester,
                         Country,
                         City, Address, IsCompleted)

   SELECT @VarInvoiceNumber,
          @VarIssuedDate,
          CompanyName,
          Country,
          City,
          Address,
          0
   FROM CustomersBusiness
   WHERE CustomerID = @VarCustomerID

   DECLARE @LastID INT;
   SET @LastID = @@IDENTITY;

   UPDATE Orders
   SET InvoiceID = @LastID
   WHERE CustomerID = @VarCustomerID
     AND YEAR(OrderTime) = @VarYear
     AND MONTH(OrderTime) = @VarMonth
     AND InvoiceID IS NULL

END

-- 14. Uzyskanie danych na temat danej faktury
CREATE PROCEDURE usp_getInvoiceInfo @VarInvoiceID INT
AS
BEGIN
    IF IIF(@VarInvoiceID IN (SELECT InvoiceID
                               FROM Invoices),
               1,
               NULL) IS NULL
        BEGIN
            ;THROW 60000, 'Specified InvoiceID does not  exist!!!', 1;
        END

    ELSE
        BEGIN
		SELECT I.InvoiceID, I.InvoiceNumber,
                     I.IsCompleted, I.IssuedDate, I.InvoiceRequester,
		       I.Country, I.City, I.Address,
                     O.OrderID, P.ProductName, OD.Quantity,
                     P.UnitPrice, P.UnitPrice * OD.Quantity as 'Sum'
		FROM Invoices I
			INNER JOIN Orders O ON O.InvoiceID = I.InvoiceID
			INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
			INNER JOIN Products P ON OD.ProductID = P.ProductID
        END
END

-- 15. Stworzenie nowego zamówienia
CREATE PROCEDURE usp_createOrder @VarCustomerID INT, @VarRequiredTime DATETIME, @VarReservatonDuration TIME = NULL
AS
BEGIN
    IF IIF(@VarCustomerID IN (SELECT CustomerID
                               FROM Customers),
               1,
               NULL) IS NULL
        BEGIN
            ;THROW 60000, 'Specified CustomerID does not  exist!!!', 1;
        END
    ELSE IF @VarRequiredTime < GETDATE()
		THROW 60000, 'Required time cannot be set before current time!!!', 1;
	ELSE IF @VarReservatonDuration IS NOT NULL AND @VarReservatonDuration <= '00:00:00'
		THROW 60000, 'Reservation duration cannot be negative!!!', 1;
	ELSE
        BEGIN
		INSERT INTO Orders(CustomerID, StatusID, InvoiceID, OrderTime, RequiredTime, ReservationDuration)
		VALUES(@VarCustomerID, 6, NULL, GETDATE(), @VarRequiredTime, @VarReservatonDuration)
        END
END

-- 16 Anulowanie zamówienia
CREATE PROCEDURE usp_orderCancelling @OrderID INT
AS
BEGIN
    UPDATE Orders
    SET StatusID = 9
    WHERE OrderID = @OrderID
END

-- 17. Ustawienie statusu zamówienia na zrelizowane
CREATE PROCEDURE usp_orderCompleted @OrderID INT
AS
BEGIN
    IF ((SELECT StatusID FROM Orders WHERE OrderID = @OrderID) != 2)
        BEGIN
            ;THROW 60000, 'Order have to be payed first!!!', 1;
        END
    ELSE
        BEGIN
            UPDATE Orders
            SET StatusID = 4
            WHERE OrderID = @OrderID
        END
END

-- 18. Dodawanie produktów do zamówienia
CREATE PROCEDURE usp_addProductToOrder @VarProductID INT, @VarOrderID INT,
                                       @VarQuantity INT
AS
BEGIN
    IF @VarOrderID NOT IN (SELECT OrderID FROM Orders)
        THROW 60000, 'Specified order does not exist!!!', 1;
    ELSE
        IF (SELECT Status
            FROM OrdersWithStatus
            WHERE OrderID = @VarOrderID) != 'W trakcie składania'
            THROW 60000, 'Specified order has been closed!!!', 1;
        ELSE
            BEGIN
                DECLARE @VarRequiredTime AS DATETIME,
                    @VarValidMenuID AS INT;
                SET @VarRequiredTime = (SELECT RequiredTime
                                        FROM Orders
                                        WHERE OrderID = @VarOrderID);
                SET @VarValidMenuID = (SELECT MenuID
                                       FROM Menu
                                       WHERE @VarRequiredTime >= StartDate
                                         AND @VarRequiredTime <= EndDate
                                         AND IsReadyForDisplay = 1);

                IF @VarValidMenuID IS NULL
                    THROW 60000, 'There is no valid menu in order required time!!!', 1;
                IF @VarProductID NOT IN (SELECT ProductID
                                         FROM MenusWithProducts
                                         WHERE MenuID = @VarValidMenuID)
                    THROW 60000, 'Specified product does not appear in valid menu!!!', 1;
                IF (SELECT CategoryName
                    FROM ProductsWithCategory
                    WHERE ProductID = @VarProductID) = 'Owoce morza'
                    BEGIN
                        IF (DATENAME(WEEKDAY, @VarRequiredTime) !=
                            'Thursday' AND
                            DATENAME(WEEKDAY, @VarRequiredTime) !=
                            'Friday' AND
                            DATENAME(WEEKDAY, @VarRequiredTime) !=
                            'Saturday')
                            THROW 60000, 'RequiredTime for Seafood can be only Thursday/Friday/Saturday!!!', 1;
                        ELSE
                            DECLARE @VarTuesdayBeforeRequiredTime AS DATETIME;
                        SET @VarTuesdayBeforeRequiredTime =
                                (SELECT DATEADD(DD, -1 *
                                                    (DATEPART(DW, @VarRequiredTime) - 2),
                                                @VarRequiredTime));
                        IF GETDATE() >= @VarTuesdayBeforeRequiredTime
                            THROW 60000, 'Seafood cannot be order later than monday before RequiredTime!!!', 1;
                    END
                INSERT INTO OrderDetails
                VALUES (@VarOrderID, @VarProductID, @VarQuantity)
                UPDATE Orders
                SET OrderTime = GETDATE()
                WHERE OrderID = @VarOrderID
            END
END

-- 19. Sprawdzenie czy klient ma aktualnie obowiązujące zniżki
CREATE PROCEDURE usp_discountToUse @Date DATE, @CustomerID INT
AS
BEGIN
    SELECT TOP 1 DiscountID
    FROM Discounts
    WHERE ((DiscountType = 1 AND DiscountAcquisitionDate <= @Date)
        OR
           ((DiscountType = 2 AND DiscountAcquisitionDate <= @Date AND
             @Date <= DATEADD(DAY, (SELECT TOP 1 D1
                                    FROM DiscountParameters
                                    WHERE StartTime <= @Date
                                      AND @Date <= EndTime
                                    ORDER BY StartTime DESC), @Date)))
        )
      AND CustomerID = @CustomerID
    ORDER BY IIF(DiscountType = 1, (SELECT TOP 1 R1
                                    FROM DiscountParameters
                                    WHERE StartTime <= @Date
                                      AND @Date <= EndTime
                                    ORDER BY StartTime DESC),
                 (SELECT TOP 1 R2
                  FROM DiscountParameters
                  WHERE StartTime <= @Date
                    AND @Date <= EndTime
                  ORDER BY StartTime DESC)) DESC
END

-- 20. Ile klient ma zapłacić, uwzględniając ew. Zniżkę
CREATE PROCEDURE usp_showPrice @OrderID INT
AS
BEGIN
    DECLARE @CustomerID INT = (SELECT CustomerID
                               FROM Orders
                               WHERE OrderID = @OrderID)
    DECLARE @Date DATE = GETDATE()
    DECLARE @d INT EXEC usp_discountToUse @Date, @CustomerID

    SELECT SUM(OrderDetailValue) * ISNULL(1 - @d, 1)
    FROM OrderDetailsWithValue
    WHERE OrderID = @OrderID
END

-- 21. Płacenie - zmiana Order Status i DiscountUsedDuringPayment
CREATE PROCEDURE usp_payment @OrderID INT, @CustomerID INT
AS
BEGIN
    DECLARE @Date DATE = GETDATE()
    DECLARE @p INT EXEC usp_showPrice @OrderID, @CustomerID
    DECLARE @d INT EXEC usp_discountToUse @Date, @CustomerID

    UPDATE Orders
    SET StatusID = 2
    WHERE OrderID = @OrderID

    IF (@d IS NOT NULL)
        BEGIN
            UPDATE Orders
            SET IdOfDiscountUsedDuringPayment = @d
            WHERE OrderID = @OrderID
        END
END


-- 22. Sprawdzenie czy po transakcji klientowi będzie przysługiwać jakaś nowa zniżka
CREATE PROCEDURE usp_addNewDiscountIfGranted @CustomerID INT, @Date DATE
AS
BEGIN
    DECLARE @t1 TABLE
                (
                    [OrdersDone/MoneySpent] INT,
                    HasDiscount             INT,
                    type                    INT
                )
    DECLARE @t2 TABLE
                (
                    [OrdersDone/MoneySpent] INT,
                    HasDiscount             INT,
                    type                    INT
                )
    INSERT INTO @t1 EXEC usp_discount1Progress @CustomerID
    INSERT INTO @t2 EXEC usp_discount2Progress @CustomerID

    IF ((SELECT HasDiscount FROM @t1) = 0 AND
        (SELECT [OrdersDone/MoneySpent] FROM @t1) > (SELECT TOP 1 Z1
                                                     FROM DiscountParameters
                                                     WHERE StartTime <= @Date
                                                       AND @Date <= EndTime
                                                     ORDER BY StartTime DESC))
        BEGIN
            INSERT INTO Discounts(CustomerID, DiscountType,
                                  DiscountAcquisitionDate)
            VALUES (@CustomerID, 1, @Date)
        END

    IF ((SELECT HasDiscount FROM @t2) = 0 AND
        (SELECT [OrdersDone/MoneySpent] FROM @t2) > (SELECT TOP 1 K1
                                                     FROM DiscountParameters
                                                     WHERE StartTime <= @Date
                                                       AND @Date <= EndTime
                                                     ORDER BY StartTime DESC))
        BEGIN
            INSERT INTO Discounts(CustomerID, DiscountType,
                                  DiscountAcquisitionDate)
            VALUES (@CustomerID, 2, @Date)
        END

END

-- 23. Dodawanie nowego produktu
CREATE PROCEDURE usp_addProduct @ProductName VARCHAR(100), @CategoryID INT,
                                @UnitPrice DECIMAL(10, 2), @UnitsInStock INT
AS
BEGIN
    IF (@CategoryID > (SELECT MAX(CategoryID) FROM Categories))
        BEGIN
            ;THROW 60000, 'No such category! Consider adding one first', 1;
        END
    ELSE
        BEGIN
            INSERT INTO Products(ProductName, CategoryID, UnitPrice,
                                 UnitsInStock, Discontinued)
            VALUES (@ProductName, @CategoryID, @UnitPrice, @UnitsInStock, 0)
        END

END

-- 24. Dodawanie stworzonego produktu do menu
CREATE PROCEDURE usp_addProductToMenu @ProductID INT, @MenuID INT,
                                      @UnitPrice DECIMAL(10, 2)
AS
BEGIN
    IF ((SELECT ProductID
         FROM MenuDetails
         WHERE ProductID = @ProductID AND MenuID = @MenuID) IS NOT NULL)
        BEGIN
            ;THROW 60000, 'Product has already been added ', 1;
        END
    ELSE
        BEGIN
            INSERT INTO MenuDetails(ProductID, MenuID, UnitPrice)
            VALUES (@ProductID, @MenuID, @UnitPrice)
        END
END

-- 25. Zatwierdzenie menu gdy jest gotowe
CREATE PROCEDURE usp_confirmMenu @StartDate DATE, @EndDate DATE
AS
BEGIN
    DECLARE @NumOfNewProducts INT = (
        SELECT COUNT(CurrMenu.ProductID)
        FROM (SELECT ProductID
              FROM MenusInProgressWithProducts
              WHERE StartDate <= GETDATE()
                AND GETDATE() <= EndDate) CurrMenu
                 LEFT JOIN
             (SELECT ProductID
              FROM MenuDetails MD
                       INNER JOIN Menu M ON M.MenuID = MD.MenuID
              WHERE StartDate <= DATEADD(DAY, -14, GETDATE())
                AND DATEADD(DAY, -14, GETDATE()) <= EndDate
                AND IsReadyForDisplay = 'true') PrevMenu
             ON PrevMenu.ProductID = CurrMenu.ProductID
        WHERE PrevMenu.ProductID IS NULL
    )

    IF ((SELECT TOP 1 EndDate
         FROM Menu
         WHERE IsReadyForDisplay = 'true'
         ORDER BY EndDate DESC) > @StartDate)
        BEGIN
            ;THROW 60000, 'Menus are overlapping!!!', 1;
        END
    ELSE
        IF (@NumOfNewProducts < (SELECT COUNT(ProductID)
                                 FROM MenuDetails MD
                                          INNER JOIN Menu M ON M.MenuID = MD.MenuID
                                 WHERE StartDate <= DATEADD(DAY, -14, GETDATE())
                                   AND DATEADD(DAY, -14, GETDATE()) <= EndDate
                                   AND IsReadyForDisplay = 'true') / 2)
            BEGIN
                ;
                THROW 60000, 'Not enough products products are different that two weeks ago!!!', 1;
            END
        ELSE
            BEGIN
                UPDATE Menu
                SET IsReadyForDisplay = 'true'
                WHERE Menu.StartDate = @StartDate
                  AND Menu.EndDate = @EndDate
            END

END

-- 26. Dodawanie klienta indywidualnego
CREATE PROCEDURE usp_addCustomerPerson @VarFirstName VARCHAR(50),
                                      @VarLastName VARCHAR(50),
                                      @VarEmailAddress VARCHAR(50),
                                      @VarPhoneNumber VARCHAR(50)
AS
BEGIN

   IF ((@VarEmailAddress) NOT IN (SELECT EmailAddress
                                  FROM CustomersPerson
                                  UNION
                                  SELECT EmailAddress
                                  FROM CustomersBusiness))
       BEGIN
           ;THROW 60000, 'That email is already used!!!', 1;
       END

   INSERT INTO Customers DEFAULT VALUES;

   DECLARE @LastID INT;
   SET @LastID = @@IDENTITY;

   INSERT INTO CustomersPerson (CustomerID, FirstName, LastName,
                                EmailAddress, PhoneNumber)

   VALUES (@LastID,
           @VarFirstName,
           @VarLastName,
           @VarEmailAddress,
           @VarPhoneNumber)

END

-- 27. Dodawanie klienta biznesowego
CREATE PROCEDURE usp_addCustomerBusiness @VarCompanyName VARCHAR(50),
                                        @VarCountry VARCHAR(50),
                                        @VarCity VARCHAR(50),
                                        @VarAddress VARCHAR(50),
                                        @VarEmailAddress VARCHAR(50),
                                        @VarPhoneNumber VARCHAR(50),
                                        @VarNIP VARCHAR(50)
AS
BEGIN

   IF ((@VarEmailAddress) NOT IN (SELECT EmailAddress
                                  FROM CustomersPerson
                                  UNION
                                  SELECT EmailAddress
                                  FROM CustomersBusiness))
       BEGIN
           ;THROW 60000, 'That email is already used!!!', 1;
       END

   INSERT INTO Customers DEFAULT VALUES;

   DECLARE @LastID INT;
   SET @LastID = @@IDENTITY;

   INSERT INTO CustomersBusiness (CustomerID, CompanyName, Country, City,
                                  Address, EmailAddress, PhoneNumber, NIP)

   VALUES (@LastID,
           @VarCompanyName,
           @VarCountry,
           @VarCity,
           @VarAddress,
           @VarEmailAddress,
           @VarPhoneNumber,
           @VarNIP)

END

-- 28. Stoliki danego zamówienia
CREATE PROCEDURE usp_TablesOfOrder @VarOrderID INT
AS
BEGIN
    IF ((@VarOrderID) NOT IN (SELECT OrderID
                                FROM Orders))
       BEGIN
           ;THROW 60000, 'There is no such order!!!', 1;
       END


   SELECT TableName, IsUsable, TableCapacity FROM Tables
   JOIN ReservationTable RT ON Tables.TableID = RT.TableID
   JOIN Orders O ON O.OrderID = RT.OrderID
   WHERE O.OrderID = @VarOrderID;

END

-- 29. Raport zniżek
CREATE PROCEDURE usp_ReportOfDiscounts @VarStartDate DATE, @VarEndDate DATE
AS
BEGIN
    IF (@VarStartDate > @VarEndDate)
       BEGIN
           ;THROW 60000, 'Starting Date has to be less than EndDate', 1;
       END


   SELECT * FROM Discounts
   WHERE DiscountAcquisitionDate BETWEEN @VarStartDate AND @VarEndDate
END

-- 30. Raport menu
CREATE PROCEDURE usp_ReportOfMenu @VarStartDate DATE, @VarEndDate DATE
AS
BEGIN
   IF (@VarStartDate > @VarEndDate)
       BEGIN
           ;THROW 60000, 'Starting Date has to be less than EndDate', 1;
       END


   SELECT *
   FROM Menu
   WHERE ((StartDate BETWEEN @VarStartDate AND @VarEndDate) OR
          (EndDate BETWEEN @VarStartDate AND @VarEndDate))
     AND IsReadyForDisplay = 1
END

-- 31. Zamówienia danego klienta
CREATE PROCEDURE usp_ordersOfCustomer @VarCustomerID INT
AS
BEGIN
    IF ((@VarCustomerID) NOT IN (SELECT CustomerID
                                FROM Customers))
       BEGIN
           ;THROW 60000, 'There is no such customer!!!', 1;
       END

   SELECT * FROM Orders
   WHERE CustomerID = @VarCustomerID
END

-- 32. Zniżki danego klienta
CREATE PROCEDURE usp_discountsOfCustomer @VarCustomerID INT
AS
BEGIN
    IF ((@VarCustomerID) NOT IN (SELECT CustomerID
                                FROM Customers))
       BEGIN
           ;THROW 60000, 'There is no such customer!!!', 1;
       END

   SELECT * FROM Discounts
   WHERE CustomerID = @VarCustomerID
END

-- 33. Średnia wartość zamówienia danego klienta
CREATE PROCEDURE usp_meanOrderValueOfCustomer @VarCustomerID INT
AS
BEGIN
   IF ((@VarCustomerID) NOT IN (SELECT CustomerID
                                FROM Customers))
       BEGIN
           ;THROW 60000, 'There is no such customer!!!', 1;
       END

   SELECT AVG(sum)
   FROM (
            SELECT O.OrderID, SUM(ODValue.OrderDetailValue) AS sum
            FROM Customers C
                     JOIN Orders O ON C.CustomerID = O.CustomerID
                     JOIN OrderDetailsWithValue ODValue
                          ON O.OrderID = ODValue.OrderID
            WHERE C.CustomerID = @VarCustomerID
            GROUP BY O.OrderID
        ) OrdersValue
END

-- 34. Dodanie stolika do zamóienia
CREATE PROCEDURE usp_addTableToReservation @OrderID INT, @NumOfPeople INT,
                                           @DateTime DATETIME,
                                           @ReservationDuration INT
AS
BEGIN
    DECLARE @CustomerID INT = (SELECT CustomerID
                               FROM Orders
                               WHERE OrderID = @OrderID)
    IF ((SELECT OrderID FROM Orders WHERE OrderID = @OrderID) IS NULL)
        BEGIN
            ;THROW 60000, 'There no such order!!!', 1;
        END
    ELSE
        BEGIN
            DECLARE @val DECIMAL(10, 2) EXEC usp_showPrice @OrderID
            IF (@val < (SELECT TOP 1 WZ
                        FROM ReservationRequirements
                        ORDER BY StartTime DESC))
                BEGIN
                    ;THROW 60000, 'Value of order is too low!!!', 1;
                END
            ELSE
                IF ((SELECT COUNT(OrderID)
                     FROM Orders
                     WHERE CustomerID = @CustomerID) <= (SELECT TOP 1 WK
                                                         FROM ReservationRequirements
                                                         ORDER BY StartTime DESC))
                    BEGIN
                        ;THROW 60000, 'Not enough orders done!!!', 1;
                    END
                ELSE
                    BEGIN
                        DECLARE @TableProposition INT
                        SELECT TOP 1 TA.TableID
                        FROM Tables TA
                        WHERE TableCapacity >= @NumOfPeople
                          AND (
                            SELECT O.OrderID
                            FROM Orders O
                                     INNER JOIN ReservationTable RT ON O.OrderID = RT.OrderID
                                     INNER JOIN Tables T ON RT.TableID = T.TableID
                            WHERE ((RequiredTime > @DateTime AND
                                    Requiredtime <
                                    DATEADD(HOUR, @ReservationDuration, @DateTime))
                                OR (DATEADD(HOUR, ReservationDuration,
                                            RequiredTime) > @DateTime AND
                                    DATEADD(HOUR, ReservationDuration,
                                            Requiredtime) <
                                    DATEADD(HOUR, @ReservationDuration, @DateTime))
                                OR (RequiredTime < @DateTime AND
                                    DATEADD(HOUR, ReservationDuration,
                                            RequiredTime) >
                                    DATEADD(HOUR, @ReservationDuration, @DateTime)))
                              AND T.TableID = TA.TableID
                        ) IS NULL
                        IF (@TableProposition IS NULL)
                            BEGIN
                                ;THROW 60000, 'No free tables left', 1;
                            END
                        ELSE
                            BEGIN
                                INSERT INTO ReservationTable(OrderID, TableID)
                                VALUES (@OrderID, @TableProposition)
                            END
                    END
        END
END


-- 35. Potwierdzenie złożonego zamówienia
CREATE PROCEDURE usp_orderPlaced @OrderID INT
AS
BEGIN
    IF ((SELECT OrderID FROM Orders WHERE OrderID = @OrderID) IS NULL)
        BEGIN
            ;THROW 60000, 'There no such order!!!', 1;
        END
    ELSE
        IF ((SELECT StatusID FROM Orders WHERE OrderID = @OrderID) != 6)
            BEGIN
                ;THROW 60000, 'Order has already been placed!!!', 1;
            END
        ELSE
            BEGIN
                UPDATE Orders
                SET StatusID = 1
                WHERE OrderID = @OrderID
            END
END

-- 36.Dodanie osoby do rezerwacji
CREATE PROCEDURE usp_addReservationPerson @VarOrderID INT,
                                          @VarFirstName VARCHAR(50),
                                          @VarLastName VARCHAR(50)
AS
BEGIN
    IF ((@VarOrderID) NOT IN (SELECT OrderID
                              FROM Orders))
        BEGIN
            ;THROW 60000, 'That email is already used!!!', 1;
        END

    DECLARE @NumberOfPeopleOnOrder INT
    SET @NumberOfPeopleOnOrder = (SELECT COUNT(*)
                                  FROM ReservationPerson
                                  WHERE OrderID = @VarOrderID)

    DECLARE @PossibleSlots INT
    SET @PossibleSlots = (
        SELECT SUM(TableCapacity)
        FROM Tables
                 JOIN ReservationTable RT2
                      ON Tables.TableID = RT2.TableID
        WHERE RT2.OrderID = @VarOrderID
    )

    IF (@PossibleSlots IS NOT NULL AND
        @PossibleSlots >= (@NumberOfPeopleOnOrder + 1))
        BEGIN

            INSERT INTO ReservationPerson (OrderID, FirstName, LastName)
            VALUES (@VarOrderID, @VarFirstName, @VarLastName)
        END
    ELSE
        BEGIN
            ;THROW 60000, 'There is no place on that reservation', 1;
        END
END














