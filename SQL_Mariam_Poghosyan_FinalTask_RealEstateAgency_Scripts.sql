-- 1. DROP and CREATE NEW DATABASE

DROP DATABASE IF EXISTS real_estate_agency_sample_db;
CREATE DATABASE real_estate_agency_sample_db;
-- Connect to the new database
\c real_estate_agency_sample_db


-- 2. DROP and CREATE NEW SCHEMA
DROP SCHEMA IF EXISTS real_estate_sample CASCADE;
CREATE SCHEMA real_estate_sample;

-- 3. CREATE TABLES


-- 3.1 Property Table
CREATE TABLE real_estate_sample.property (
    property_id SERIAL PRIMARY KEY,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    price NUMERIC(12,2) NOT NULL
        CONSTRAINT chk_property_price CHECK (price >= 0),
    status VARCHAR(20) DEFAULT 'available'
        CONSTRAINT chk_property_status CHECK (status IN ('available', 'sold', 'rented')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3.2 Agent Table
CREATE TABLE real_estate_sample.agent (
    agent_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    hire_date DATE NOT NULL
        CONSTRAINT chk_agent_hire_date CHECK (hire_date >= DATE '2020-01-01')
);

-- 3.3 Client Table
CREATE TABLE real_estate_sample.client (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    client_type VARCHAR(10) NOT NULL
        CONSTRAINT chk_client_type CHECK (client_type IN ('buyer', 'seller', 'landlord', 'tenant'))
);

-- 3.4 Feature Table
CREATE TABLE real_estate_sample.feature (
    feature_id SERIAL PRIMARY KEY,
    feature_name VARCHAR(50) UNIQUE NOT NULL
);

-- 3.5 Property_Feature Table (Many-to-Many)
CREATE TABLE real_estate_sample.property_feature (
    property_id INT NOT NULL,
    feature_id INT NOT NULL,
    PRIMARY KEY (property_id, feature_id),
    FOREIGN KEY (property_id) REFERENCES real_estate_sample.property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (feature_id) REFERENCES real_estate_sample.feature(feature_id) ON DELETE CASCADE
);

-- 3.6 Listing Table
CREATE TABLE real_estate_sample.listing (
    listing_id SERIAL PRIMARY KEY,
    property_id INT NOT NULL,
    agent_id INT NOT NULL,
    listing_date DATE NOT NULL
        CONSTRAINT chk_listing_date CHECK (listing_date >= DATE '2024-01-01'),
    listing_price NUMERIC(12,2) NOT NULL
        CONSTRAINT chk_listing_price CHECK (listing_price > 0),
    FOREIGN KEY (property_id) REFERENCES real_estate_sample.property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (agent_id) REFERENCES real_estate_sample.agent(agent_id) ON DELETE CASCADE
);

-- 3.7 Transaction Table
CREATE TABLE real_estate_sample.transaction (
    transaction_id SERIAL PRIMARY KEY,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    transaction_date DATE NOT NULL
        CONSTRAINT chk_transaction_date CHECK (transaction_date >= DATE '2024-01-01'),
    transaction_amount NUMERIC(12,2) NOT NULL
        CONSTRAINT chk_transaction_amount CHECK (transaction_amount > 0),
    transaction_type VARCHAR(10) NOT NULL
        CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('sale', 'rent')),
    FOREIGN KEY (property_id) REFERENCES real_estate_sample.property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES real_estate_sample.client(client_id) ON DELETE CASCADE
);

-- 3.8 Commission Table
CREATE TABLE real_estate_sample.commission (
    commission_id SERIAL PRIMARY KEY,
    agent_id INT NOT NULL,
    transaction_id INT NOT NULL,
    commission_amount NUMERIC(12,2) NOT NULL
        CONSTRAINT chk_commission_amount CHECK (commission_amount >= 0),
    commission_date DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (agent_id) REFERENCES real_estate_sample.agent(agent_id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES real_estate_sample.transaction(transaction_id) ON DELETE CASCADE
);


-- 4. INSERT SAMPLE DATA (DML Scripts)


-- 4.1 Insert Agents
INSERT INTO real_estate_sample.agent (first_name, last_name, email, phone_number, hire_date) VALUES
('Alice', 'Johnson', 'alice.johnson@example.com', '555-1234', '2022-05-10'),
('Bob', 'Smith', 'bob.smith@example.com', '555-2345', '2021-03-15'),
('Carol', 'Davis', 'carol.davis@example.com', '555-3456', '2023-08-20'),
('David', 'Wilson', 'david.wilson@example.com', '555-4567', '2020-12-01'),
('Eva', 'Taylor', 'eva.taylor@example.com', '555-5678', '2023-02-17'),
('Frank', 'Brown', 'frank.brown@example.com', '555-6789', '2022-09-25');

-- 4.2 Insert Clients
INSERT INTO real_estate_sample.client (first_name, last_name, email, phone_number, client_type) VALUES
('George', 'Miller', 'george.miller@example.com', '555-1111', 'buyer'),
('Hannah', 'Garcia', 'hannah.garcia@example.com', '555-2222', 'seller'),
('Ian', 'Martinez', 'ian.martinez@example.com', '555-3333', 'landlord'),
('Julia', 'Rodriguez', 'julia.rodriguez@example.com', '555-4444', 'tenant'),
('Kevin', 'Lopez', 'kevin.lopez@example.com', '555-5555', 'buyer'),
('Laura', 'Anderson', 'laura.anderson@example.com', '555-6666', 'seller');

-- 4.3 Insert Properties
INSERT INTO real_estate_sample.property (address, city, state, price) VALUES
('123 Maple St', 'Springfield', 'IL', 250000),
('456 Oak Ave', 'Riverside', 'CA', 325000),
('789 Pine Dr', 'Orlando', 'FL', 275000),
('101 Elm St', 'Austin', 'TX', 300000),
('202 Cedar Ln', 'Seattle', 'WA', 400000),
('303 Birch Rd', 'Denver', 'CO', 350000);

-- 4.4 Insert Features
INSERT INTO real_estate_sample.feature (feature_name) VALUES
('Swimming Pool'),
('Garden'),
('Garage'),
('Fireplace'),
('Hardwood Floors'),
('Solar Panels');

-- 4.5 Insert Property_Features
INSERT INTO real_estate_sample.property_feature (property_id, feature_id)
SELECT p.property_id, f.feature_id
FROM real_estate_sample.property p
JOIN real_estate_sample.feature f ON (p.property_id % 6 + 1) = f.feature_id;

-- 4.6 Insert Listings
INSERT INTO real_estate_sample.listing (property_id, agent_id, listing_date, listing_price)
SELECT
    p.property_id,
    a.agent_id,
    CURRENT_DATE - (interval '10 days' * p.property_id),
    p.price * 1.05
FROM real_estate_sample.property p
JOIN real_estate_sample.agent a ON (p.property_id % 6 + 1) = a.agent_id
LIMIT 6;

-- 4.7 Insert Transactions
INSERT INTO real_estate_sample.transaction (property_id, client_id, transaction_date, transaction_amount, transaction_type)
SELECT
    p.property_id,
    c.client_id,
    CURRENT_DATE - (interval '5 days' * p.property_id),
    p.price,
    CASE WHEN p.property_id % 2 = 0 THEN 'sale' ELSE 'rent' END
FROM real_estate_sample.property p
JOIN real_estate_sample.client c ON (p.property_id % 6 + 1) = c.client_id
LIMIT 6;

-- 4.8 Insert Commissions
INSERT INTO real_estate_sample.commission (agent_id, transaction_id, commission_amount)
SELECT
    a.agent_id,
    t.transaction_id,
    t.transaction_amount * 0.03
FROM real_estate_sample.transaction t
JOIN real_estate_sample.agent a ON (t.property_id % 6 + 1) = a.agent_id
LIMIT 6;


-- 5
-- 5.1 FUNCTION TO UPDATE PROPERTY COLUMN

-- Drop if exists for safe rerun
DROP FUNCTION IF EXISTS real_estate_sample.update_property_column(
    integer,
    text,
    text
);

-- Create the function
CREATE OR REPLACE FUNCTION real_estate_sample.update_property_column(
    p_property_id INT,
    p_column_name TEXT,
    p_new_value TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    sql_statement TEXT;
BEGIN
    -- Build dynamic SQL for flexible column update
    sql_statement := FORMAT('UPDATE real_estate_sample.property SET %I = $1 WHERE property_id = $2', p_column_name);

    -- Execute safely using parameters
    EXECUTE sql_statement USING p_new_value, p_property_id;
    
    -- Confirmation
    RAISE NOTICE 'Property ID % updated: % = %', p_property_id, p_column_name, p_new_value;
END;
$$;

-- 5.2 FUNCTION TO ADD NEW TRANSACTION

-- Drop if exists for safe rerun
DROP FUNCTION IF EXISTS real_estate_sample.add_transaction(
    integer,
    integer,
    date,
    numeric,
    varchar
);

-- Create the function
CREATE OR REPLACE FUNCTION real_estate_sample.add_transaction(
    p_property_id INT,
    p_client_id INT,
    p_transaction_date DATE,
    p_transaction_amount NUMERIC,
    p_transaction_type VARCHAR
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert a new transaction record
    INSERT INTO real_estate_sample.transaction(
        property_id,
        client_id,
        transaction_date,
        transaction_amount,
        transaction_type
    )
    VALUES (
        p_property_id,
        p_client_id,
        p_transaction_date,
        p_transaction_amount,
        p_transaction_type
    );
    
    -- Confirmation
    RAISE NOTICE 'Transaction added: property_id %, client_id %, amount %, type %', p_property_id, p_client_id, p_transaction_amount, p_transaction_type;
END;
$$;

-- 5.3 TEST: USING THE FUNCTIONS


-- Example 1: Update a property price
SELECT real_estate_sample.update_property_column(
    1,                -- property_id
    'price',          -- column name
    '290000'          -- new value
);

-- Example 2: Insert a new transaction
SELECT real_estate_sample.add_transaction(
    2,                         -- property_id
    3,                         -- client_id
    CURRENT_DATE,              -- transaction_date
    320000,                    -- transaction_amount
    'sale'                     -- transaction_type
);


-- 5.4 (Optional Extra) BONUS: Auto-Update Property Status
-- Drop trigger and function if exist
DROP TRIGGER IF EXISTS trg_update_property_status ON real_estate_sample.transaction;
DROP FUNCTION IF EXISTS real_estate_sample.update_property_status();

-- Create a function to auto-update property status
CREATE OR REPLACE FUNCTION real_estate_sample.update_property_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- When a transaction happens, update property status
    UPDATE real_estate_sample.property
    SET status = CASE
                    WHEN NEW.transaction_type = 'sale' THEN 'sold'
                    WHEN NEW.transaction_type = 'rent' THEN 'rented'
                    ELSE status
                 END
    WHERE property_id = NEW.property_id;
    
    RETURN NEW;
END;
$$;

-- Create the trigger on INSERT to transaction
CREATE TRIGGER trg_update_property_status
AFTER INSERT ON real_estate_sample.transaction
FOR EACH ROW
EXECUTE FUNCTION real_estate_sample.update_property_status();

-- 5.5 TEST: Insert another transaction to test the trigger
-- Insert a transaction that should automatically mark the property as 'sold'
SELECT real_estate_sample.add_transaction(
    3,                         -- property_id
    4,                         -- client_id
    CURRENT_DATE,              -- transaction_date
    350000,                    -- transaction_amount
    'sale'                     -- transaction_type
);

-- Check the property status changed:
SELECT * FROM real_estate_sample.property WHERE property_id = 3;

--6. Create a View for Latest Quarter Analytics

-- Drop the view if already exists for rerunnable script
DROP VIEW IF EXISTS real_estate_sample.vw_latest_quarter_analytics;

-- Create the view
CREATE OR REPLACE VIEW real_estate_sample.vw_latest_quarter_analytics AS
WITH transaction_quarters AS (
    SELECT
        transaction_id,
        property_id,
        client_id,
        transaction_date,
        transaction_amount,
        transaction_type,
        EXTRACT(YEAR FROM transaction_date) AS year,
        EXTRACT(QUARTER FROM transaction_date) AS quarter
    FROM
        real_estate_sample.transaction
),
latest_quarter AS (
    SELECT
        MAX(year) AS max_year,
        MAX(quarter) AS max_quarter
    FROM
        transaction_quarters
)
SELECT
    t.property_id,
    t.client_id,
    t.transaction_date,
    t.transaction_amount,
    t.transaction_type
FROM
    transaction_quarters t
    CROSS JOIN latest_quarter lq
WHERE
    t.year = lq.max_year
    AND t.quarter = lq.max_quarter
ORDER BY
    t.transaction_date DESC;


-- 7. Create Read-Only Manager Role
-- Drop role if exists for rerunnable script
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager_readonly') THEN
        DROP ROLE manager_readonly;
    END IF;
END
$$;

-- Create the manager_readonly role
CREATE ROLE manager_readonly
    LOGIN                  -- Allow login
    PASSWORD 'SecurePassword123!'  -- 🔒 Replace with a real secure password later
    NOSUPERUSER            -- No superuser privileges
    NOCREATEDB             -- Cannot create databases
    NOCREATEROLE           -- Cannot create roles
    NOINHERIT              -- Only has what is granted explicitly
    NOREPLICATION;         -- Cannot do replication

-- Grant SELECT permissions on all tables in the schema real_estate_sample
GRANT USAGE ON SCHEMA real_estate_sample TO manager_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA real_estate_sample TO manager_readonly;

-- Also automatically grant SELECT on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA real_estate_sample
GRANT SELECT ON TABLES TO manager_readonly;
