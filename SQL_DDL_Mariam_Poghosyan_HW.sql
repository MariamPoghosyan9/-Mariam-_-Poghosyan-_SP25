-- Create schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS auction_house;

-- Create Location table
CREATE TABLE IF NOT EXISTS auction_house.Location (
    location_id SERIAL PRIMARY KEY,
    address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Employee table
CREATE TABLE IF NOT EXISTS auction_house.Employee (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    contact_info VARCHAR(100),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Category table
CREATE TABLE IF NOT EXISTS auction_house.Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Seller table
CREATE TABLE IF NOT EXISTS auction_house.Seller (
    seller_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(100),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Buyer table
CREATE TABLE IF NOT EXISTS auction_house.Buyer (
    buyer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(100),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Auction table
CREATE TABLE IF NOT EXISTS auction_house.Auction (
    auction_id SERIAL PRIMARY KEY,
    date DATE NOT NULL CHECK (date > '2000-01-01'),
    time TIME NOT NULL,
    location_id INT REFERENCES auction_house.Location(location_id),
    managed_by INT REFERENCES auction_house.Employee(employee_id),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Auction_Seller table
CREATE TABLE IF NOT EXISTS auction_house.Auction_Seller (
    auction_seller_id SERIAL PRIMARY KEY,
    auction_id INT REFERENCES auction_house.Auction(auction_id),
    seller_id INT REFERENCES auction_house.Seller(seller_id),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Item table
CREATE TABLE IF NOT EXISTS auction_house.Item (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category_id INT REFERENCES auction_house.Category(category_id),
    seller_id INT REFERENCES auction_house.Seller(seller_id),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Auction_Lot table
CREATE TABLE IF NOT EXISTS auction_house.Auction_Lot (
    lot_id SERIAL PRIMARY KEY,
    auction_id INT REFERENCES auction_house.Auction(auction_id),
    item_id INT REFERENCES auction_house.Item(item_id),
    starting_price DECIMAL(10,2) CHECK (starting_price >= 0),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Transaction table
CREATE TABLE IF NOT EXISTS auction_house.Transaction (
    transaction_id SERIAL PRIMARY KEY,
    item_id INT REFERENCES auction_house.Item(item_id),
    buyer_id INT REFERENCES auction_house.Buyer(buyer_id),
    auction_id INT REFERENCES auction_house.Auction(auction_id),
    final_price DECIMAL(10,2) CHECK (final_price >= 0),
    transaction_date DATE CHECK (transaction_date > '2000-01-01'),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Bid table
CREATE TABLE IF NOT EXISTS auction_house.Bid (
    bid_id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES auction_house.Transaction(transaction_id),
    item_id INT REFERENCES auction_house.Item(item_id),
    bid_amount DECIMAL(10,2) CHECK (bid_amount >= 0),
    bid_time TIMESTAMP NOT NULL,
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Create Payment table
CREATE TABLE IF NOT EXISTS auction_house.Payment (
    payment_id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES auction_house.Transaction(transaction_id),
    buyer_id INT REFERENCES auction_house.Buyer(buyer_id),
    payment_method VARCHAR(50) CHECK (payment_method IN ('Card', 'Cash', 'PayPal')),
    payment_status VARCHAR(20),
    record_ts DATE DEFAULT CURRENT_DATE NOT NULL
);


-- Insert into Location
INSERT INTO auction_house.Location (address, city)
SELECT '23 Main St', 'New York'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Location WHERE address = '23 Main St' AND city = 'New York'
);

INSERT INTO auction_house.Location (address, city)
SELECT '45 Art St', 'Los Angeles'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Location WHERE address = '45 Art St' AND city = 'Los Angeles'
);

-- Insert into Employee
INSERT INTO auction_house.Employee (name, role, contact_info)
SELECT 'Alice Gray', 'Manager', 'alice@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Employee WHERE name = 'Alice Gray' AND role = 'Manager'
);

INSERT INTO auction_house.Employee (name, role, contact_info)
SELECT 'Bob Smith', 'Clerk', 'bob@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Employee WHERE name = 'Bob Smith' AND role = 'Clerk'
);

-- Insert into Category
INSERT INTO auction_house.Category (category_name)
SELECT 'Painting'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Category WHERE category_name = 'Painting'
);

INSERT INTO auction_house.Category (category_name)
SELECT 'Sculpture'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Category WHERE category_name = 'Sculpture'
);

-- Insert into Seller
INSERT INTO auction_house.Seller (name, contact_info)
SELECT 'Old Town Antiques', 'contact@oldtown.com'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Seller WHERE name = 'Old Town Antiques'
);

INSERT INTO auction_house.Seller (name, contact_info)
SELECT 'Historic Arts Ltd', 'info@historicarts.com'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Seller WHERE name = 'Historic Arts Ltd'
);

-- Insert into Buyer
INSERT INTO auction_house.Buyer (name, contact_info)
SELECT 'John Doe', 'john@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Buyer WHERE name = 'John Doe'
);

INSERT INTO auction_house.Buyer (name, contact_info)
SELECT 'Jane Roe', 'jane@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM auction_house.Buyer WHERE name = 'Jane Roe'
);

INSERT INTO auction_house.Auction (date, time, location_id, managed_by)
SELECT '2024-03-10', '15:00',
       l.location_id,
       e.employee_id
FROM auction_house.Location l
JOIN auction_house.Employee e ON e.name = 'Alice Gray'
WHERE l.address = '23 Main St' AND l.city = 'New York'
  AND NOT EXISTS (
      SELECT 1
      FROM auction_house.Auction a
      WHERE a.date = '2024-03-10'
        AND a.time = '15:00'
        AND a.location_id = l.location_id
        AND a.managed_by = e.employee_id
  );
 
