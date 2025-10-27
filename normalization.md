    User {
        UUID user_id PK "Primary Key, Indexed"
        VARCHAR first_name NOT NULL
        VARCHAR last_name NOT NULL
        VARCHAR email UNIQUE NOT NULL "Indexed"
        VARCHAR password_hash NOT NULL
        VARCHAR phone_number NULL
        ENUM role NOT NULL "guest, host, admin"
        TIMESTAMP created_at "DEFAULT CURRENT_TIMESTAMP"
    }

    Property {
        UUID property_id PK "Primary Key, Indexed"
        UUID host_id FK "References User(user_id)"
        VARCHAR name NOT NULL
        TEXT description NOT NULL
        VARCHAR location NOT NULL
        DECIMAL pricepernight NOT NULL
        TIMESTAMP created_at "DEFAULT CURRENT_TIMESTAMP"
        TIMESTAMP updated_at "ON UPDATE CURRENT_TIMESTAMP"
    }

    Booking {
        UUID booking_id PK "Primary Key, Indexed"
        UUID property_id FK "References Property(property_id), Indexed"
        UUID user_id FK "References User(user_id)"
        DATE start_date NOT NULL
        DATE end_date NOT NULL
        DECIMAL total_price NOT NULL
        ENUM status NOT NULL "pending, confirmed, canceled"
        TIMESTAMP created_at "DEFAULT CURRENT_TIMESTAMP"
    }

    Payment {
        UUID payment_id PK "Primary Key, Indexed"
        UUID booking_id FK "References Booking(booking_id), Indexed"
        DECIMAL amount NOT NULL
        TIMESTAMP payment_date "DEFAULT CURRENT_TIMESTAMP"
        ENUM payment_method NOT NULL "credit_card, paypal, stripe"
    }

    Review {
        UUID review_id PK "Primary Key, Indexed"
        UUID property_id FK "References Property(property_id)"
        UUID user_id FK "References User(user_id)"
        INTEGER rating NOT NULL "CHECK: 1-5"
        TEXT comment NOT NULL
        TIMESTAMP created_at "DEFAULT CURRENT_TIMESTAMP"
    }

    Message {
        UUID message_id PK "Primary Key, Indexed"
        UUID sender_id FK "References User(user_id)"
        UUID recipient_id FK "References User(user_id)"
        TEXT message_body NOT NULL
        TIMESTAMP sent_at "DEFAULT CURRENT_TIMESTAMP"
    }

    User ||--o{ Property : hosts
    User ||--o{ Booking : makes
    User ||--o{ Review : writes
    User ||--o{ Message : sends
    User ||--o{ Message : receives
    
    Property ||--o{ Booking : has
    Property ||--o{ Review : receives
    
    Booking ||--|| Payment : has
    Booking }o--|| User : made_by