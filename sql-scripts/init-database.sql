-- =====================================================
-- ShopAzure E-Commerce Database Schema
-- Azure SQL Database
-- =====================================================

-- Create Orders Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
BEGIN
    CREATE TABLE Orders (
        OrderId NVARCHAR(50) PRIMARY KEY,
        CustomerName NVARCHAR(100) NOT NULL,
        CustomerEmail NVARCHAR(255) NOT NULL,
        OrderDate DATETIME2 DEFAULT GETUTCDATE(),
        Subtotal DECIMAL(18, 2) NOT NULL,
        Tax DECIMAL(18, 2) NOT NULL,
        Shipping DECIMAL(18, 2) NOT NULL,
        Discount DECIMAL(18, 2) DEFAULT 0,
        Total DECIMAL(18, 2) NOT NULL,
        Status NVARCHAR(50) DEFAULT 'Confirmed',
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
    PRINT 'Orders table created successfully';
END
GO

-- Create OrderItems Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrderItems')
BEGIN
    CREATE TABLE OrderItems (
        ItemId INT IDENTITY(1,1) PRIMARY KEY,
        OrderId NVARCHAR(50) NOT NULL,
        ProductId INT NOT NULL,
        ProductName NVARCHAR(200) NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(18, 2) NOT NULL,
        Subtotal DECIMAL(18, 2) NOT NULL,
        CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) 
            REFERENCES Orders(OrderId) ON DELETE CASCADE
    );
    PRINT 'OrderItems table created successfully';
END
GO

-- Create Products Table (optional - for future use)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
    CREATE TABLE Products (
        ProductId INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500),
        Price DECIMAL(18, 2) NOT NULL,
        ImageUrl NVARCHAR(500),
        Category NVARCHAR(100),
        IsActive BIT DEFAULT 1,
        CreatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
    PRINT 'Products table created successfully';
    
    -- Insert sample products
    INSERT INTO Products (Name, Description, Price, Category) VALUES
    ('Pro Laptop 15"', 'Intel i7, 16GB RAM, 512GB SSD', 65999.00, 'Electronics'),
    ('Wireless Headphones', 'Active Noise Cancellation, 30hr Battery', 8499.00, 'Electronics'),
    ('Smart Watch Pro', 'Health tracking, GPS, Water resistant', 15999.00, 'Electronics'),
    ('Smartphone X12', '6.5" AMOLED, 128GB, 5G enabled', 42999.00, 'Electronics'),
    ('DSLR Camera', '24MP, 4K Video, Dual lens kit', 54999.00, 'Electronics'),
    ('Gaming Console', '4K Gaming, 1TB Storage, 2 Controllers', 38999.00, 'Electronics');
    PRINT 'Sample products inserted';
END
GO

-- Create index for faster order lookups
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_CustomerEmail')
BEGIN
    CREATE INDEX IX_Orders_CustomerEmail ON Orders(CustomerEmail);
    PRINT 'Index IX_Orders_CustomerEmail created';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_OrderDate')
BEGIN
    CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate DESC);
    PRINT 'Index IX_Orders_OrderDate created';
END
GO

-- Stored Procedure: Insert Order
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_InsertOrder')
    DROP PROCEDURE sp_InsertOrder;
GO

CREATE PROCEDURE sp_InsertOrder
    @OrderId NVARCHAR(50),
    @CustomerName NVARCHAR(100),
    @CustomerEmail NVARCHAR(255),
    @Subtotal DECIMAL(18, 2),
    @Tax DECIMAL(18, 2),
    @Shipping DECIMAL(18, 2),
    @Discount DECIMAL(18, 2),
    @Total DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Orders (OrderId, CustomerName, CustomerEmail, Subtotal, Tax, Shipping, Discount, Total)
    VALUES (@OrderId, @CustomerName, @CustomerEmail, @Subtotal, @Tax, @Shipping, @Discount, @Total);
    
    SELECT * FROM Orders WHERE OrderId = @OrderId;
END
GO

PRINT 'Database schema setup completed successfully!';
