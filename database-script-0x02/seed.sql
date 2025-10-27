USE airbnb_booking_system;

-- Insert Users (hosts, guests, and admin)
INSERT INTO users(user_id, email, password_hash, role) VALUES
(UUID(), 'admin@airbnbproperty.com', '&98nfunweunf0wiinrw0', 'admin'),
(UUID(), 'sarah@gmail.com', '0409jg08473888**02340', 'host')