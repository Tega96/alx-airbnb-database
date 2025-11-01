## Primary Indexes:
- All primary keys are automatically indexed
- Foreign keys have explicit indexes for join performances

## Query Optimization Indexes:
1. User Queries:
    *   `idx_user_email` - Fast login/authentication
    *   `idx_user_created_at` - Analytics and reporting
2. Property Search:
    *   `idx_property_location` - Location based searches
    * `idx_property_price` - Price range queries
    * `idx_property_active` - Filter active properties
    * `idx_property_host_active` = Host dashboard queries
3. Booking Management:
    * `idx_booking_dates_status` - Date ranges and status queries
    * `idx_booking_dates` - Availability checking
    * `idx_booking_status` - Status filtering
4. Review System:
    * `idx_review_property_rating` - Property ratin calculations
    * `idx_review_rating` - Quality analysis
5. Message System:
    * `idx_message_conversation` - Efficient conversation retrieval
    * `idx_message_read_status` - Unread message counts
6. Payment tracking:
    * `idx_payment_status` - Payment reconcilliation
    * `idx_payment_date` - Financial reporting

## Constrains and Data Integrity

### Foreign Key Constraints:
* `ON DELETE CASCADE` for strong relationship integrity
* `ON DELETE SET NULL` for optional booking context in messages

### Check Constraints:
* Price validation(`>= 0`)
* Rating range validation (1-5)
* Date logic validation (`end_date > start_date`)

### Unique Constraints:
- One review per booking
- One payment per booking
- Unique email addresses
- Unique transaction IDs
