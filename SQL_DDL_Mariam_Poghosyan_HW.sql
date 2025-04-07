CREATE TABLE Location (
    location_id SERIAL PRIMARY KEY,
    address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Employee
CREATE TABLE Employee (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    contact_info VARCHAR(100),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Auction
CREATE TABLE Auction (
    auction_id SERIAL PRIMARY KEY,
    date DATE NOT NULL CHECK (date > '2000-01-01'), -- CHECK #1
    time TIME NOT NULL,
    location_id INT REFERENCES Location(location_id),
    managed_by INT REFERENCES Employee(employee_id),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Seller
CREATE TABLE Seller (
    seller_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(100),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Buyer
CREATE TABLE Buyer (
    buyer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(100),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Category
CREATE TABLE Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL, -- CHECK #2: Unique value
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Item
CREATE TABLE Item (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category_id INT REFERENCES Category(category_id),
    seller_id INT REFERENCES Seller(seller_id),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Auction_Lot
CREATE TABLE Auction_Lot (
    lot_id SERIAL PRIMARY KEY,
    auction_id INT REFERENCES Auction(auction_id),
    item_id INT REFERENCES Item(item_id),
    starting_price DECIMAL(10,2) CHECK (starting_price >= 0), -- CHECK #3: Not negative
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Transaction
CREATE TABLE Transaction (
    transaction_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES Item(item_id),
    buyer_id INT REFERENCES Buyer(buyer_id),
    auction_id INT REFERENCES Auction(auction_id),
    final_price DECIMAL(10,2) CHECK (final_price >= 0), -- CHECK #4: Not negative
    transaction_date DATE CHECK (transaction_date > '2000-01-01'),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Bid
CREATE TABLE Bid (
    bid_id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES Transaction(transaction_id),
    item_id INT REFERENCES Item(item_id),
    bid_amount DECIMAL(10,2) CHECK (bid_amount >= 0),
    bid_time TIMESTAMP NOT NULL,
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Payment
CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES Transaction(transaction_id),
    buyer_id INT REFERENCES Buyer(buyer_id),
    payment_method VARCHAR(50) CHECK (payment_method IN ('Card', 'Cash', 'PayPal')), -- CHECK #5
    payment_status VARCHAR(20),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Table: Auction_Seller (many-to-many)
CREATE TABLE Auction_Seller (
    auction_seller_id SERIAL PRIMARY KEY,
    auction_id INT REFERENCES Auction(auction_id),
    seller_id INT REFERENCES Seller(seller_id),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- LOCATION
INSERT INTO Location (location_id, address, city, record_ts)
VALUES 
(1, '23 Main St', 'New York', CURRENT_DATE),
(2, '45 Art St', 'Los Angeles', CURRENT_DATE);

-- EMPLOYEE
INSERT INTO Employee (employee_id, name, role, contact_info, record_ts)
VALUES 
(1, 'Alice Gray', 'Manager', 'alice@example.com', CURRENT_DATE),
(2, 'Bob Smith', 'Clerk', 'bob@example.com', CURRENT_DATE);

-- CATEGORY
INSERT INTO Category (category_id, category_name, record_ts)
VALUES 
(1, 'Painting', CURRENT_DATE),
(2, 'Sculpture', CURRENT_DATE);

-- SELLER
INSERT INTO Seller (seller_id, name, contact_info, record_ts)
VALUES 
(1, 'Old Town Antiques', 'contact@oldtown.com', CURRENT_DATE),
(2, 'Historic Arts Ltd', 'info@historicarts.com', CURRENT_DATE);

-- BUYER
INSERT INTO Buyer (buyer_id, name, contact_info, record_ts)
VALUES 
(1, 'John Doe', 'john@example.com', CURRENT_DATE),
(2, 'Jane Roe', 'jane@example.com', CURRENT_DATE);

-- AUCTION
INSERT INTO Auction (auction_id, date, time, location_id, managed_by, record_ts)
VALUES 
(1, '2024-03-10', '15:00', 1, 1, CURRENT_DATE),
(2, '2024-04-05', '16:00', 2, 2, CURRENT_DATE);

-- AUCTION_SELLER
INSERT INTO Auction_Seller (auction_seller_id, auction_id, seller_id, record_ts)
VALUES 
(1, 1, 1, CURRENT_DATE),
(2, 2, 2, CURRENT_DATE);

-- ITEM
INSERT INTO Item (item_id, name, description, category_id, seller_id, record_ts)
VALUES 
(1, 'Vintage Vase', '18th century porcelain', 2, 1, CURRENT_DATE),
(2, 'Impressionist Painting', 'Oil painting from 1875', 1, 2, CURRENT_DATE);

-- AUCTION_LOT
INSERT INTO Auction_Lot (lot_id, auction_id, item_id, starting_price, record_ts)
VALUES 
(1, 1, 1, 150.00, CURRENT_DATE),
(2, 2, 2, 500.00, CURRENT_DATE);

-- TRANSACTION
INSERT INTO Transaction (transaction_id, item_id, buyer_id, auction_id, final_price, transaction_date, record_ts)
VALUES 
(1, 1, 1, 1, 180.00, '2024-03-10', CURRENT_DATE),
(2, 2, 2, 2, 650.00, '2024-04-05', CURRENT_DATE);

-- BID
INSERT INTO Bid (bid_id, transaction_id, item_id, bid_amount, bid_time, record_ts)
VALUES 
(1, 1, 1, 170.00, '2024-03-10 14:50', CURRENT_DATE),
(2, 2, 2, 620.00, '2024-04-05 15:45', CURRENT_DATE);

-- PAYMENT
INSERT INTO Payment (payment_id, transaction_id, buyer_id, payment_method, payment_status, record_ts)
VALUES 
(1, 1, 1, 'Card', 'Completed', CURRENT_DATE),
(2, 2, 2, 'PayPal', 'Completed', CURRENT_DATE);


-- 

UPDATE Location SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Location ALTER COLUMN record_ts SET NOT NULL;

-- Employee table
UPDATE Employee SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Employee ALTER COLUMN record_ts SET NOT NULL;

-- Category table
UPDATE Category SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Category ALTER COLUMN record_ts SET NOT NULL;

-- Seller table
UPDATE Seller SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Seller ALTER COLUMN record_ts SET NOT NULL;

-- Buyer table
UPDATE Buyer SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Buyer ALTER COLUMN record_ts SET NOT NULL;

-- Auction table
UPDATE Auction SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Auction ALTER COLUMN record_ts SET NOT NULL;

-- Auction_Seller table
UPDATE Auction_Seller SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Auction_Seller ALTER COLUMN record_ts SET NOT NULL;

-- Item table
UPDATE Item SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Item ALTER COLUMN record_ts SET NOT NULL;

-- Auction_Lot table
UPDATE Auction_Lot SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Auction_Lot ALTER COLUMN record_ts SET NOT NULL;

-- Transaction table
UPDATE Transaction SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Transaction ALTER COLUMN record_ts SET NOT NULL;

-- Bid table
UPDATE Bid SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Bid ALTER COLUMN record_ts SET NOT NULL;

-- Payment table
UPDATE Payment SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE Payment ALTER COLUMN record_ts SET NOT NULL;