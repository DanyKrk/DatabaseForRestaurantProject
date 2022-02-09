-- tables
-- Table: Categories
CREATE TABLE Categories
(
    CategoryID   INT          NOT NULL IDENTITY (1,1),
    CategoryName VARCHAR(100) NOT NULL DEFAULT 'Category',
    Description  TEXT         NULL,
    PictureURL   VARCHAR(300) NOT NULL,
    CONSTRAINT Categories_pk PRIMARY KEY (CategoryID)
);

-- Table: Customers
CREATE TABLE Customers
(
    CustomerID INT NOT NULL IDENTITY (1,1),
    CONSTRAINT Customers_pk PRIMARY KEY (CustomerID)
);

-- Table: CustomersBusiness
CREATE TABLE CustomersBusiness
(
    CustomerID   INT          NOT NULL,
    CompanyName  VARCHAR(100) NOT NULL,
    Country      VARCHAR(100) NOT NULL,
    City         VARCHAR(100) NOT NULL,
    Address      VARCHAR(100) NOT NULL,
    EmailAddress VARCHAR(80)  NOT NULL,
    PhoneNumber  VARCHAR(20)  NULL,
    NIP          VARCHAR(10)  NULL,
    CONSTRAINT CustomersBusiness_ak_1 UNIQUE (EmailAddress),
    CONSTRAINT CustomersBusiness_ak_2 UNIQUE (PhoneNumber),
    CONSTRAINT CustomersBusiness_pk PRIMARY KEY (CustomerID)
);

-- Table: CustomersPerson
CREATE TABLE CustomersPerson
(
    CustomerID   INT         NOT NULL,
    FirstName    VARCHAR(30) NOT NULL,
    LastName     VARCHAR(30) NOT NULL,
    EmailAddress VARCHAR(80) NOT NULL,
    PhoneNumber  VARCHAR(20) NULL,
    CONSTRAINT CustomersPerson_ak_1 UNIQUE (EmailAddress),
    CONSTRAINT CustomersPerson_ak_2 UNIQUE (PhoneNumber),
    CONSTRAINT CustomersPerson_pk PRIMARY KEY (CustomerID)
);

-- Table: DiscountParameters
CREATE TABLE DiscountParameters
(
    ParametersID INT            NOT NULL IDENTITY (1,1),
    Z1           INT            NOT NULL,
    K1           DECIMAL(10, 2) NOT NULL,
    R1           DECIMAL(10, 2) NOT NULL,
    K2           DECIMAL(10, 2) NOT NULL,
    R2           DECIMAL(10, 2) NOT NULL,
    D1           INT            NOT NULL,
    StartTime    DATETIME       NOT NULL,
    EndTime      DATETIME       NOT NULL,
    CONSTRAINT ParametersCheck CHECK (Z1 > 0 AND K1 > 0 AND R1 > 0 AND
                                      K2 > 0 AND R2 > 0 AND D1 > 0),
    CONSTRAINT TimeCheck CHECK (EndTime > StartTime AND StartTime > '2010-01-01'),
    CONSTRAINT DiscountParameters_pk PRIMARY KEY (ParametersID)
);

-- Table: Discounts
CREATE TABLE Discounts
(
    DiscountID              INT     NOT NULL IDENTITY (1,1),
    CustomerID              INT     NOT NULL,
    DiscountType            TINYINT NOT NULL,
    DiscountAcquisitionDate DATE    NOT NULL,
    CONSTRAINT DiscountTypeCheck CHECK (DiscountType IN (1, 2)),
    CONSTRAINT CheckDate CHECK (DiscountAcquisitionDate > '2010-01-01'),
    CONSTRAINT Discounts_pk PRIMARY KEY (DiscountID)
);

-- Table: Invoices
CREATE TABLE Invoices
(
    InvoiceID        INT          NOT NULL IDENTITY (1,1),
    InvoiceNumber    INT          NOT NULL,
    IssuedDate       DATE         NOT NULL,
    InvoiceRequester VARCHAR(100) NOT NULL,
    Country          VARCHAR(100) NOT NULL,
    City             VARCHAR(100) NOT NULL,
    Address          VARCHAR(100) NOT NULL,
    IsCompleted      BIT          NOT NULL DEFAULT 0,
    CONSTRAINT Invoices_ak_1 UNIQUE (InvoiceNumber),
    CONSTRAINT Invoices_pk PRIMARY KEY (InvoiceID)
);

-- Table: Menu
CREATE TABLE Menu
(
    MenuID            INT          NOT NULL IDENTITY (1,1),
    MenuName          VARCHAR(100) NOT NULL DEFAULT 'Menu',
    MenuDescription   TEXT         NULL,
    StartDate         DATE         NOT NULL,
    EndDate           DATE         NOT NULL,
    IsReadyForDisplay BIT          NOT NULL,
    CONSTRAINT DatesCheck CHECK (EndDate > StartDate AND StartDate > '2010-01-01' ),
    CONSTRAINT Menu_pk PRIMARY KEY (MenuID)
);

-- Table: MenuDetails
CREATE TABLE MenuDetails
(
    ProductID INT            NOT NULL,
    MenuID    INT            NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    CONSTRAINT UnitPricePositive CHECK (UnitPrice > 0),
    CONSTRAINT MenuDetails_pk PRIMARY KEY (ProductID, MenuID)
);

-- Table: OrderDetails
CREATE TABLE OrderDetails
(
    OrderID   INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity  INT NOT NULL,
    CONSTRAINT QuantityPositive CHECK (Quantity > 0),
    CONSTRAINT OrderDetails_pk PRIMARY KEY (OrderID, ProductID)
);

-- Table: OrderStatuses
CREATE TABLE OrderStatuses
(
    StatusID INT         NOT NULL IDENTITY (1,1),
    Status   VARCHAR(50) NOT NULL DEFAULT 'Status',
    CONSTRAINT OrderStatuses_pk PRIMARY KEY (StatusID)
);

-- Table: Orders
CREATE TABLE Orders
(
    OrderID             INT      NOT NULL IDENTITY (1,1),
    CustomerID          INT      NOT NULL,
    StatusID            INT      NOT NULL,
    InvoiceID           INT      NULL,
    OrderTime           DATETIME NOT NULL,
    RequiredTime        DATETIME NOT NULL,
    ReservationDuration TIME(0)  NULL,
    CONSTRAINT TimesCheck CHECK (RequiredTime >= OrderTime AND
                                 OrderTime > '2010-01-01'),
    CONSTRAINT Orders_pk PRIMARY KEY (OrderID)
);

-- Table: Products
CREATE TABLE Products
(
    ProductID    INT            NOT NULL IDENTITY (1,1),
    ProductName  VARCHAR(100)   NOT NULL DEFAULT 'Product',
    CategoryID   INT            NOT NULL,
    UnitPrice    DECIMAL(10, 2) NOT NULL,
    UnitsInStock INT            NOT NULL DEFAULT 0,
    Discontinued BIT            NOT NULL DEFAULT 0,
    CONSTRAINT UnitPricePositiveProducts CHECK (UnitPrice > 0),
    CONSTRAINT UnitsInStockNotNegative CHECK (UnitsInStock >= 0),
    CONSTRAINT Products_pk PRIMARY KEY (ProductID)
);

-- Table: ReservationPerson
CREATE TABLE ReservationPerson
(
    PersonID  INT         NOT NULL IDENTITY (1,1),
    OrderID   INT         NOT NULL,
    FirstName VARCHAR(30) NOT NULL,
    LastName  VARCHAR(30) NOT NULL,
    CONSTRAINT ReservationPerson_pk PRIMARY KEY (PersonID)
);

-- Table: ReservationTable
CREATE TABLE ReservationTable
(
    ReservationID INT NOT NULL IDENTITY (1,1),
    OrderID       INT NOT NULL,
    TableID       INT NOT NULL,
    CONSTRAINT ReservationTable_pk PRIMARY KEY (ReservationID)
);

-- Table: Tables
CREATE TABLE Tables
(
    TableID   INT          NOT NULL IDENTITY (1,1),
    TableName VARCHAR(100) NULL,
    IsUsable  BIT          NOT NULL DEFAULT 1,
    CONSTRAINT Tables_pk PRIMARY KEY (TableID)
);

-- foreign keys
-- Reference: Categories_Products (table: Products)
ALTER TABLE Products
    ADD CONSTRAINT Categories_Products
        FOREIGN KEY (CategoryID)
            REFERENCES Categories (CategoryID);

-- Reference: CustomersPerson_Customers (table: CustomersPerson)
ALTER TABLE CustomersPerson
    ADD CONSTRAINT CustomersPerson_Customers
        FOREIGN KEY (CustomerID)
            REFERENCES Customers (CustomerID);

-- Reference: CustomerBusiness_Customers (table: CustomersBusiness)
ALTER TABLE CustomersBusiness
    ADD CONSTRAINT CustomerBusiness_Customers
        FOREIGN KEY (CustomerID)
            REFERENCES Customers (CustomerID);


-- Reference: Customers_Discounts (table: Discounts)
ALTER TABLE Discounts
    ADD CONSTRAINT Customers_Discounts
        FOREIGN KEY (CustomerID)
            REFERENCES Customers (CustomerID);

-- Reference: Invoices_Orders (table: Orders)
ALTER TABLE Orders
    ADD CONSTRAINT Invoices_Orders
        FOREIGN KEY (InvoiceID)
            REFERENCES Invoices (InvoiceID);

-- Reference: MenuDetails_Products (table: MenuDetails)
ALTER TABLE MenuDetails
    ADD CONSTRAINT MenuDetails_Products
        FOREIGN KEY (ProductID)
            REFERENCES Products (ProductID);

-- Reference: Menu_MenuDetails (table: MenuDetails)
ALTER TABLE MenuDetails
    ADD CONSTRAINT Menu_MenuDetails
        FOREIGN KEY (MenuID)
            REFERENCES Menu (MenuID);

-- Reference: OrderDetails_Order (table: OrderDetails)
ALTER TABLE OrderDetails
    ADD CONSTRAINT OrderDetails_Order
        FOREIGN KEY (OrderID)
            REFERENCES Orders (OrderID);

-- Reference: OrderDetails_Products (table: OrderDetails)
ALTER TABLE OrderDetails
    ADD CONSTRAINT OrderDetails_Products
        FOREIGN KEY (ProductID)
            REFERENCES Products (ProductID);

-- Reference: OrderStatuses_Orders (table: Orders)
ALTER TABLE Orders
    ADD CONSTRAINT OrderStatuses_Orders
        FOREIGN KEY (StatusID)
            REFERENCES OrderStatuses (StatusID);

-- Reference: Order_Customers (table: Orders)
ALTER TABLE Orders
    ADD CONSTRAINT Order_Customers
        FOREIGN KEY (CustomerID)
            REFERENCES Customers (CustomerID);

-- Reference: PersonOnReservation_Orders (table: ReservationPerson)
ALTER TABLE ReservationPerson
    ADD CONSTRAINT PersonOnReservation_Orders
        FOREIGN KEY (OrderID)
            REFERENCES Orders (OrderID);

-- Reference: ReservationDetails_Orders (table: ReservationTable)
ALTER TABLE ReservationTable
    ADD CONSTRAINT ReservationDetails_Orders
        FOREIGN KEY (OrderID)
            REFERENCES Orders (OrderID);

-- Reference: Tables_ReservationDetails (table: ReservationTable)
ALTER TABLE ReservationTable
    ADD CONSTRAINT Tables_ReservationDetails
        FOREIGN KEY (TableID)
            REFERENCES Tables (TableID);

