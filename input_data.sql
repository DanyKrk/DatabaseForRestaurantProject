-- Discount Parameters

INSERT INTO DiscountParameters (Z1, K1, R1, K2, R2, D1, StartTime, EndTime)
VALUES (10, 30, 0.03, 1000, 0.05, 7, '20100102', '20301231')

-- Customers
INSERT Customers DEFAULT
VALUES;

INSERT Customers DEFAULT
VALUES;

INSERT Customers DEFAULT
VALUES;

INSERT Customers DEFAULT
VALUES;

INSERT INTO CustomersBusiness (CustomerID, CompanyName, Country, City, Address,
                               EmailAddress, PhoneNumber, NIP)
VALUES (1, 'Stalbud', 'Polska', 'Kraków', 'Floriańska 1', 'stalbud@gmail.com',
        '123456789', '1234567899')

INSERT INTO CustomersBusiness (CustomerID, CompanyName, Country, City, Address,
                               EmailAddress, PhoneNumber, NIP)
VALUES (2, 'Januszex', 'Polska', 'Kraków', 'Morska 3', 'januszex@o2.pl', NULL,
        '6546546541')

INSERT INTO CustomersPerson (CustomerID, FirstName, LastName, EmailAddress,
                             PhoneNumber)
VALUES (3, 'Jan', 'Kowalski', 'jkjk@o2.pl', NULL)

INSERT INTO CustomersPerson (CustomerID, FirstName, LastName, EmailAddress,
                             PhoneNumber)
VALUES (4, 'Ania', 'Z Zielonego Wzgórza', 'ania_kmwtwk@gmail.pl', '123987987')

-- Discounts

INSERT INTO Discounts (CustomerID, DiscountType, DiscountAcquisitionDate)
VALUES (3, 1, '20210101')

INSERT INTO Discounts (CustomerID, DiscountType, DiscountAcquisitionDate)
VALUES (3, 2, '20210103')

-- Categories
INSERT INTO Categories (categoryname, description, pictureurl)
VALUES ('Kanapki', 'fajne kanapki', 'kanapka-url')

INSERT INTO Categories (categoryname, description, pictureurl)
VALUES ('Owoce morza', 'fajne rybki i inne owocki', 'ryba-url')

INSERT INTO Categories (categoryname, description, pictureurl)
VALUES ('Słodycze', 'mało zdrowe ale fajne', 'cukierek-url')

-- Products

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Krótka kanapka', 1, 10, 15, 0)

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Długa kanapka', 1, 20, 5, 0)

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Karp', 2, 40, 10, 0)

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Ryba ptak', 2, 100, 3, 0)

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Cukierek', 3, 2, 100, 0)

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Lizak', 3, 3, 200, 0)

INSERT INTO Products (ProductName, CategoryID, UnitPrice, UnitsInStock,
                      Discontinued)
VALUES ('Ciasto beza', 3, 40, 50, 0)

-- Menu

INSERT INTO Menu (MenuName, MenuDescription, StartDate, EndDate,
                  IsReadyForDisplay)
VALUES ('Smaczne menu codzienne', 'Super opis super menu', '20220101',
        '20220114', 0)

INSERT INTO Menu (MenuName, MenuDescription, StartDate, EndDate,
                  IsReadyForDisplay)
VALUES ('Super menu przed sesją', 'takie na pocieszenie dla studentów',
        '20220115', '20220131', 0)

-- Menu Details

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (1, 1, 10)

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (2, 1, 25)

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (5, 1, 2)

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (6, 1, 2.5)

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (3, 2, 50)

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (4, 2, 75)

INSERT INTO MenuDetails (ProductID, MenuID, UnitPrice)
VALUES (7, 2, 40)

-- Statuses

INSERT INTO OrderStatuses (Status)
VALUES ('Zamówione')

INSERT INTO OrderStatuses (Status)
VALUES ('Zamówione i zapłacone')

INSERT INTO OrderStatuses (Status)
VALUES ('Przygotowywane')

INSERT INTO OrderStatuses (Status)
VALUES ('Zrealizowane')

INSERT INTO OrderStatuses (Status)
VALUES ('Porzucone')

-- Invoices

INSERT INTO Invoices (InvoiceNumber, IssuedDate, InvoiceRequester, Country,
                      City, Address)
VALUES (20210112, '20220101', 'Jan Kowalski', 'Polska', 'Kraków', 'Nawojki 5')

--Orders

INSERT INTO Orders (CustomerID, StatusID, InvoiceID, OrderTime, RequiredTime)
VALUES (3, 4, 1, '20220101 10:34:09 AM', '20220101 11:15:00 AM')

INSERT INTO Orders (CustomerID, StatusID, InvoiceID, OrderTime, RequiredTime)
VALUES (3, 4, 1, '20220101 10:45:09 AM', '20220101 11:15:00 AM')

INSERT INTO Orders (CustomerID, StatusID, InvoiceID, OrderTime, RequiredTime)
VALUES (1, 4, NULL, '20220101 10:45:09 AM', '20220101 11:15:00 AM')

INSERT INTO Orders (CustomerID, StatusID, InvoiceID, OrderTime, RequiredTime)
VALUES (2, 5, NULL, '20220101 08:45:09 AM', '20220101 11:15:00 AM')

INSERT INTO Orders (CustomerID, StatusID, InvoiceID, OrderTime, RequiredTime)
VALUES (1, 2, NULL, '20220103 08:45:09 AM', '20220104 04:00:00 PM')

-- Order Details

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (1, 1, 20)

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (1, 2, 10)

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (1, 7, 15)

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (2, 5, 50)

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (3, 1, 3)

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (4, 1, 4)

INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES (7, 3, 5)

-- Tables

INSERT INTO Tables (TableName, IsUsable)
VALUES (NULL, 1)

INSERT INTO Tables (TableName, IsUsable)
VALUES (NULL, 1)

INSERT INTO Tables (TableName, IsUsable)
VALUES ('Duży stół', 1)

-- ReservationTable

INSERT INTO ReservationTable (OrderID, TableID)
VALUES (1, 3)

INSERT INTO ReservationTable (OrderID, TableID)
VALUES (7, 1)

-- ReservationPerson

INSERT INTO ReservationPerson (OrderID, FirstName, LastName)
VALUES (3, 'Piotr', 'Kowalski')

INSERT INTO ReservationPerson (OrderID, FirstName, LastName)
VALUES (3, 'Anna', 'Kowalska')
