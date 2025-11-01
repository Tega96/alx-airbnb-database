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