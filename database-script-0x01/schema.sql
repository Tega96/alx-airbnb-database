/** Write SQL queries to define the database schema (create tables, set constraints). 

-- Create the database
CREATE DATABASE airbnb_booking_system;
USE airbnb_booking_system;

-- User table 
CREATE TABLE user(
    user_id VARCHAR(36) PRIMARY KEY DEFAULT UUID(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('guest', 'host', 'admin') NOT NULL DEFAULT 'guest',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (email),
    INDEX idx_user_role (role)
);

-- User Profile table (for user details)
CREATE TABLE user_profile(
    user_profile_id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_profile_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    INDEX idx_user_profile_user_id (user_id),
    INDEX idx_user_profile_phone (phone_number)
);

-- location table
CREATE TABLE location(
    location_id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL, 
    postal_code VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location_country_city (country, city),
    INDEX idx_location_postal_code (postal_code),
    INDEX idx_location_coordinates (latitude, longitude)
);

-- property table
CREATE TABLE property(
    property_id VARCHAR(36) DEFAULT PRIMARY KEY (UUID()),
    host_id VARCHAR(36) NOT NULL,
    location_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price_per_night DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_property_host
        FOREIGN KEY (host_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_property_location
        FOREIGN KEY (location_id)
        REFERENCES location(location_id)
        ON DELETE RESTRICT,
) 
*/




-- User table (core entity, role-agnostic)
CREATE TABLE user (
    user_id UUID PRIMARY KEY DEFAULT UUID(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, 
    phone_number VARCHAR(20), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (email),
    INDEX idx_user_created_at (created_at)
);

-- Host table (separate host- specific data)
CREATE TABLE host (
    host_id UUID PRIMARY KEY DEFAULT UUID(),
    user_id UUID UNIQUE NOT NULL, 
    is_verified BOOLEAN DEFAULT FALSE,
    verification_date TIMESTAMP NULL, 
    host_since TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_host_user_id (user_id),
    INDEX idx_host_verified (is_verified),
    INDEX idx_host_since (host_since)
);

-- Property table
CREATE TABLE property (
    property_id UUID PRIMARY KEY DEFAULT UUID(),
    host_id UUID NOT NULL,
    name VARCHAR(200) NOT NULL, 
    description TEXT NOT NULL,
    location VARCHAR(500) NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL CHECK (base_price >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES host(host_id) ON DELETE CASCADE,
    INDEX idx_property_host_id (host_id),
    INDEX idx_property_location (location(100)),
    INDEX idx_property_price (base_price),
    INDEX idx_property_active (is_active),
    INDEX idx_property_created_at (created_at)
);

-- Property price history for auit trail
CREATE TABLE property_price_history (
    price_history_id UUID PRIMARY KEY DEFAULT UUID(),
    property_id UUID NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES property(property_id) ON DELETE CASCADE,
    INDEX idx_price_history_property (property_id),
    INDEX idx_price_history_date (effective_from, effective_to),
    INDEX idx_price_history_created (created_at)
);

-- Booking table
CREATE TABLE booking (
    booking_id UUID PRIMARY KEY DEFAULT UUID(),
    property_id UUID NOT NULL, 
    guest_id UUID NOT NULL,
    start_date DATE NOT NULL, 
    end_date DATE NOT NULL, 
    nightly_rate DECIMAL(10, 2) NOT NULL CHECK (nightly_rate >= 0),
    status ENUM('pending', 'confirmed', 'canceled', 'completed') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREING KEY (property_id) REFERENCES property(property_id) ON DELETE CASCADE,
    FOREING KEY (guest_id) REFERENCES user(user_id) ON DELETE CASCADE,
    CHECK (enc_date > start_date),
    INDEX idx_booking_property_id (property_id),
    INDEX idx_booking_guest_id (guest_id),
    INDEX idx_booking_dates (start_date, end_date),
    INDEX idx_booking_status (status),
    INDEX idx_booking_created_at (created_at)
);

-- Payment table with 1:1 relationship to booking
CREATE TABLE payment (
    payment_id UUID PRIMARY KEY DEFAULT UUID(),
    booking_id UUID NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('credit_card', 'paypal', 'stripe') NOT NULL,
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    transaction_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    INDEX idx_payment_booking_id (booking_id),
    INDEX idx payment_status (payment_status),
    INDEX idx_payment_date (payment_date), 
    INDEX idx_payment_transaction (transaction_id)
);

-- Review table with booking reference
CREATE TABLE review (
    review_id UUID PRIMARY KEY DEFAULT UUID(),
    property_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    booking_id UUID NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >=1 AND rating <= 5),
    comment TEXT NOT NULL,
    host_response TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    UNIQUE KEY uique_booking_review (booking_id), -- One review per booking
    INDEX idx_review_property_id (property_id),
    INDEX idx_review_guest_id (guest_id),
    INDEX idx_review_rating (rating),
    INDEX idx_review_created_at (created_at)
);

--Message table
CREATE TABLE message (
    message_id UUID PRIMARY KEY DEFAULT UUID(),
    sender_id UUID NOT NULL,
    recipient_id UUID NOT NULL, 
    booking_id UUID NOT NULL,
    message_body TEXT NOT NULL, 
    is_read BOOLEAN DEFAULT FALSE,
    send_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (sender_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE SET NULL,
    INDEX idx_message_sender_id (sender_id),
    INDEX idx_message_recipient_id (recipient_id),
    INDEX idx_message_booking_id (booking_id),
    INDEX idx_message_sent_at (sent_at),
    INDEX idx_message_read_status (is_read)
);

-- Additional composit indexes for common query patterns
CREATE INDEX idx_booking_dates_status ON booking (start_date, end_date, status);
CREATE INDEX idx_property_host_active ON property (host_id, is_active);
CREATE INDEX idx_review_property_rating ON review (property_id, rating);
CREATE INDEX idx_message_conversation ON message (LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id), sent_at);
CREATE INDEX idx_price_history_property_effective ON property_price_history (property_id, effective_from, effective_to);


INSERT INTO user (user_id, first_name, last_name, email, password_hash, phone_number, created_at) VALUES
-- Guest
('a1b2c3d4-1234-5678-9abc-123456789001', 'John', 'Smith', 'john.smith@email.com,$2b#2@@hashedpassword1', '+1-223-23223', '2025-01-15 10:30:00'),
('a1b2c3d4-1234-5678-9abc-123456789002', 'Sarah', 'Johnson', 'sarah.j@email.com', '$2b$10$hashedpassword2', '+1-555-0102', '2023-02-20 14:15:00'),
('a1b2c3d4-1234-5678-9abc-123456789003', 'Mike', 'Chen', 'mike.chen@email.com', '$2b$10$hashedpassword3', '+1-555-0103', '2023-03-10 09:45:00'),
('a1b2c3d4-1234-5678-9abc-123456789004', 'Emily', 'Davis', 'emily.davis@email.com', '$2b$10$hashedpassword4', '+1-555-0104', '2023-04-05 16:20:00'),
('a1b2c3d4-1234-5678-9abc-123456789005', 'David', 'Wilson', 'david.wilson@email.com', '$2b$10$hashedpassword5', '+1-555-0105', '2023-05-12 11:10:00'),

-- Hosts (who are also users)
('a1b2c3d4-1234-5678-9abc-123456789006', 'Maria', 'Garcia', 'maria.garcia@email.com', '$2b$10$hashedpassword6', '+1-555-0106', '2023-01-08 08:00:00'),
('a1b2c3d4-1234-5678-9abc-123456789007', 'James', 'Brown', 'james.brown@email.com', '$2b$10$hashedpassword7', '+1-555-0107', '2023-02-14 13:25:00'),
('a1b2c3d4-1234-5678-9abc-123456789008', 'Lisa', 'Taylor', 'lisa.taylor@email.com', '$2b$10$hashedpassword8', '+1-555-0108', '2023-03-22 17:40:00');


-- Insert Hosts (linked to users)
INSERT INTO host (host_id, user_id, is_verified, verification_date, host_since, created_at) VALUES
('b1c2d3e4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789006', TRUE, '2023-01-20 10:00:00', '2023-01-08 08:00:00', '2023-01-20 10:00:00'),
('b1c2d3e4-1234-5678-9abc-123456789002', 'a1b2c3d4-1234-5678-9abc-123456789007', TRUE, '2023-02-28 14:30:00', '2023-02-14 13:25:00', '2023-02-28 14:30:00'),
('b1c2d3e4-1234-5678-9abc-123456789003', 'a1b2c3d4-1234-5678-9abc-123456789008', FALSE, NULL, '2023-03-22 17:40:00', '2023-03-22 17:40:00');


-- Insert Properties
INSERT INTO property (property_id, host_id, name, description, location, base_price, is_active, created_at) VALUES
-- Maria Garcia's properties
('c1d2e3f4-1234-5678-9abc-123456789001', 'b1c2d3e4-1234-5678-9abc-123456789001', 'Cozy Downtown Apartment', 'Beautiful apartment in the heart of downtown with amazing city views. Perfect for couples or solo travelers.', '123 Main St, New York, NY', 125.00, TRUE, '2023-01-25 09:00:00'),
('c1d2e3f4-1234-5678-9abc-123456789002', 'b1c2d3e4-1234-5678-9abc-123456789001', 'Luxury Penthouse Suite', 'Stunning penthouse with panoramic views, premium amenities, and private balcony.', '456 Park Ave, New York, NY', 350.00, TRUE, '2023-02-10 11:30:00'),

-- James Brown's properties
('c1d2e3f4-1234-5678-9abc-123456789003', 'b1c2d3e4-1234-5678-9abc-123456789002', 'Beachfront Villa', 'Beautiful villa steps away from the beach. Perfect for family vacations with private pool.', '789 Ocean Dr, Miami, FL', 275.00, TRUE, '2023-03-05 14:15:00'),
('c1d2e3f4-1234-5678-9abc-123456789004', 'b1c2d3e4-1234-5678-9abc-123456789002', 'Mountain Cabin Retreat', 'Cozy cabin in the mountains with fireplace and hiking trails. Ideal for nature lovers.', '101 Forest Rd, Denver, CO', 150.00, TRUE, '2023-04-12 10:45:00'),

-- Lisa Taylor's property
('c1d2e3f4-1234-5678-9abc-123456789005', 'b1c2d3e4-1234-5678-9abc-123456789003', 'Modern Studio Loft', 'Contemporary studio in arts district with high ceilings and designer furnishings.', '202 Arts Blvd, Chicago, IL', 95.00, TRUE, '2023-05-01 16:20:00');



-- Insert Property Price History (showing price changes over time)
INSERT INTO propertyPriceHistory (price_history_id, property_id, price, effective_from, effective_to, created_at) VALUES
-- Cozy Downtown Apartment price history
('d1e2f3a4-1234-5678-9abc-123456789001', 'c1d2e3f4-1234-5678-9abc-123456789001', 115.00, '2023-01-25 09:00:00', '2023-05-01 00:00:00', '2023-01-25 09:00:00'),
('d1e2f3a4-1234-5678-9abc-123456789002', 'c1d2e3f4-1234-5678-9abc-123456789001', 125.00, '2023-05-01 00:00:00', NULL, '2023-05-01 00:00:00'),

-- Beachfront Villa price history
('d1e2f3a4-1234-5678-9abc-123456789003', 'c1d2e3f4-1234-5678-9abc-123456789003', 250.00, '2023-03-05 14:15:00', '2023-06-15 00:00:00', '2023-03-05 14:15:00'),
('d1e2f3a4-1234-5678-9abc-123456789004', 'c1d2e3f4-1234-5678-9abc-123456789003', 275.00, '2023-06-15 00:00:00', NULL, '2023-06-15 00:00:00');


-- Insert Bookings
INSERT INTO booking (booking_id, property_id, guest_id, start_date, end_date, nightly_rate, status, created_at) VALUES
-- Completed bookings with reviews
('e1f2a3b4-1234-5678-9abc-123456789001', 'c1d2e3f4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789001', '2023-06-01', '2023-06-05', 125.00, 'completed', '2023-05-15 14:30:00'),
('e1f2a3b4-1234-5678-9abc-123456789002', 'c1d2e3f4-1234-5678-9abc-123456789003', 'a1b2c3d4-1234-5678-9abc-123456789002', '2023-07-10', '2023-07-15', 275.00, 'completed', '2023-06-20 11:15:00'),

-- Upcoming confirmed bookings
('e1f2a3b4-1234-5678-9abc-123456789003', 'c1d2e3f4-1234-5678-9abc-123456789002', 'a1b2c3d4-1234-5678-9abc-123456789003', '2023-12-20', '2023-12-27', 350.00, 'confirmed', '2023-11-10 09:45:00'),
('e1f2a3b4-1234-5678-9abc-123456789004', 'c1d2e3f4-1234-5678-9abc-123456789004', 'a1b2c3d4-1234-5678-9abc-123456789004', '2024-01-05', '2024-01-08', 150.00, 'confirmed', '2023-12-01 16:20:00'),

-- Pending booking
('e1f2a3b4-1234-5678-9abc-123456789005', 'c1d2e3f4-1234-5678-9abc-123456789005', 'a1b2c3d4-1234-5678-9abc-123456789005', '2024-02-14', '2024-02-16', 95.00, 'pending', '2023-12-05 10:30:00'),

-- Canceled booking
('e1f2a3b4-1234-5678-9abc-123456789006', 'c1d2e3f4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789002', '2023-08-15', '2023-08-20', 125.00, 'canceled', '2023-07-20 13:45:00');


-- Insert Payments
INSERT INTO payment (payment_id, booking_id, amount, payment_date, payment_method, payment_status, transaction_id, created_at) VALUES
-- Completed payments
('f1a2b3c4-1234-5678-9abc-123456789001', 'e1f2a3b4-1234-5678-9abc-123456789001', 500.00, '2023-05-15 15:00:00', 'credit_card', 'completed', 'txn_001234567890', '2023-05-15 15:00:00'),
('f1a2b3c4-1234-5678-9abc-123456789002', 'e1f2a3b4-1234-5678-9abc-123456789002', 1375.00, '2023-06-20 12:00:00', 'paypal', 'completed', 'txn_001234567891', '2023-06-20 12:00:00'),

-- Pending payment for confirmed booking
('f1a2b3c4-1234-5678-9abc-123456789003', 'e1f2a3b4-1234-5678-9abc-123456789003', 2450.00, '2023-11-10 10:00:00', 'stripe', 'completed', 'txn_001234567892', '2023-11-10 10:00:00'),

-- Pending payment
('f1a2b3c4-1234-5678-9abc-123456789004', 'e1f2a3b4-1234-5678-9abc-123456789005', 190.00, NULL, 'credit_card', 'pending', NULL, '2023-12-05 10:30:00'),

-- Refunded payment for canceled booking
('f1a2b3c4-1234-5678-9abc-123456789005', 'e1f2a3b4-1234-5678-9abc-123456789006', 625.00, '2023-07-20 14:00:00', 'credit_card', 'refunded', 'txn_001234567893', '2023-07-20 14:00:00');


-- Insert Reviews
INSERT INTO review (review_id, property_id, guest_id, booking_id, rating, comment, host_response, created_at) VALUES
-- Reviews for completed stays
('g1h2i3j4-1234-5678-9abc-123456789001', 'c1d2e3f4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789001', 'e1f2a3b4-1234-5678-9abc-123456789001', 5, 'Amazing apartment with stunning views! The location was perfect and Maria was a wonderful host. Would definitely stay again!', 'Thank you John! So glad you enjoyed your stay. You were a perfect guest!', '2023-06-06 10:00:00'),

('g1h2i3j4-1234-5678-9abc-123456789002', 'c1d2e3f4-1234-5678-9abc-123456789003', 'a1b2c3d4-1234-5678-9abc-123456789002', 'e1f2a3b4-1234-5678-9abc-123456789002', 4, 'Beautiful villa right on the beach! The pool was fantastic and the views were incredible. Minor issue with wifi but overall great stay.', 'Thanks Sarah! We''ve addressed the wifi issue. Hope to host you again!', '2023-07-16 14:30:00'),

-- Review without host response
('g1h2i3j4-1234-5678-9abc-123456789003', 'c1d2e3f4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789003', 'e1f2a3b4-1234-5678-9abc-123456789006', 3, 'Nice apartment but the street noise was louder than expected. Good location though.', NULL, '2023-08-21 09:15:00');


-- Insert Messages
INSERT INTO message (message_id, sender_id, recipient_id, booking_id, message_body, is_read, sent_at, read_at) VALUES
-- Pre-booking inquiries
('h1i2j3k4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789001', 'a1b2c3d4-1234-5678-9abc-123456789006', NULL, 'Hi Maria, is the downtown apartment available for June 1-5?', TRUE, '2023-05-10 08:30:00', '2023-05-10 09:15:00'),
('h1i2j3k4-1234-5678-9abc-123456789002', 'a1b2c3d4-1234-5678-9abc-123456789006', 'a1b2c3d4-1234-5678-9abc-123456789001', NULL, 'Hi John! Yes, those dates are available. The apartment would be perfect for your stay!', TRUE, '2023-05-10 09:15:00', '2023-05-10 10:00:00'),

-- Booking-related messages
('h1i2j3k4-1234-5678-9abc-123456789003', 'a1b2c3d4-1234-5678-9abc-123456789002', 'a1b2c3d4-1234-5678-9abc-123456789007', 'e1f2a3b4-1234-5678-9abc-123456789002', 'Hello James, what time is check-in for the beach villa?', TRUE, '2023-07-08 16:45:00', '2023-07-08 17:20:00'),
('h1i2j3k4-1234-5678-9abc-123456789004', 'a1b2c3d4-1234-5678-9abc-123456789007', 'a1b2c3d4-1234-5678-9abc-123456789002', 'e1f2a3b4-1234-5678-9abc-123456789002', 'Hi Sarah! Check-in is anytime after 3 PM. I''ll send you the lockbox code the morning of your arrival.', TRUE, '2023-07-08 17:20:00', '2023-07-08 18:00:00'),

-- Unread message
('h1i2j3k4-1234-5678-9abc-123456789005', 'a1b2c3d4-1234-5678-9abc-123456789005', 'a1b2c3d4-1234-5678-9abc-123456789008', 'e1f2a3b4-1234-5678-9abc-123456789005', 'Hi Lisa, I have a question about parking at your studio loft.', FALSE, '2023-12-06 11:30:00', NULL);


-- Insert additional sample data for richer testing
INSERT INTO booking (booking_id, property_id, guest_id, start_date, end_date, nightly_rate, status, created_at) VALUES
-- More varied booking scenarios
('e1f2a3b4-1234-5678-9abc-123456789007', 'c1d2e3f4-1234-5678-9abc-123456789004', 'a1b2c3d4-1234-5678-9abc-123456789001', '2023-09-15', '2023-09-18', 150.00, 'completed', '2023-08-20 13:00:00'),
('e1f2a3b4-1234-5678-9abc-123456789008', 'c1d2e3f4-1234-5678-9abc-123456789005', 'a1b2c3d4-1234-5678-9abc-123456789004', '2023-10-01', '2023-10-03', 95.00, 'completed', '2023-09-15 10:45:00');


INSERT INTO payment (payment_id, booking_id, amount, payment_date, payment_method, payment_status, transaction_id, created_at) VALUES
('f1a2b3c4-1234-5678-9abc-123456789006', 'e1f2a3b4-1234-5678-9abc-123456789007', 450.00, '2023-08-20 14:00:00', 'credit_card', 'completed', 'txn_001234567894', '2023-08-20 14:00:00'),
('f1a2b3c4-1234-5678-9abc-123456789007', 'e1f2a3b4-1234-5678-9abc-123456789008', 190.00, '2023-09-15 11:30:00', 'paypal', 'completed', 'txn_001234567895', '2023-09-15 11:30:00');


INSERT INTO idx_review_guest_ideview (review_id, property_id, guest_id, booking_id, rating, comment, host_response, created_at) VALUES
('g1h2i3j4-1234-5678-9abc-123456789004', 'c1d2e3f4-1234-5678-9abc-123456789004', 'a1b2c3d4-1234-5678-9abc-123456789001', 'e1f2a3b4-1234-5678-9abc-123456789007', 5, 'Absolutely loved the mountain cabin! The fireplace was so cozy and the hiking trails were amazing. Perfect getaway!', 'So happy you enjoyed your mountain retreat, John! You''re always welcome back!', '2023-09-19 08:45:00');