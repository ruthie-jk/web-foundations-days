
# Day 8 Assignment: Designing a Scalable Ticket Booking System

## 1. Introduction

This project designs an online ticket-booking system that allows users to browse events, view available seats, reserve seats, make payments and access purchased tickets.

The system must remain reliable during normal traffic and handle sudden increases in demand during major ticket sales.

The main challenge is preventing two customers from purchasing the same seat while maintaining good performance and providing a fair booking experience.

---

# Part A: System Design Interview Questions

## 1. What happens when a user types a URL and presses Enter?

1. The browser checks whether the requested resource is already available in its cache.
2. DNS translates the domain name into an IP address.
3. The browser establishes a connection with the server using TCP. HTTPS also performs a TLS handshake.
4. The browser sends an HTTP request to the server.
5. The request may pass through a CDN, firewall and load balancer.
6. An application server processes the request.
7. The server may retrieve information from a cache or database.
8. The server returns an HTTP response.
9. The browser interprets the HTML, CSS and JavaScript and displays the page.

## 2. Why must application servers be stateless behind a load balancer?

Application servers should not depend on information stored only in their local memory.

A load balancer may send consecutive requests from the same user to different application servers.

If session information is stored locally on one server, another server may not recognize the user.

Stateless servers allow requests to be handled by any available server.

Shared session information can be stored in a distributed cache or database, while authentication can use securely validated tokens.

This improves scalability, reliability and fault tolerance.

## 3. When would you use a cache, and what problem does caching introduce?

A cache stores frequently requested information temporarily so that it can be retrieved faster.

In a ticket-booking system, caching can be used for:

- Event listings.
- Event descriptions.
- Venue information.
- Seat layout information that changes infrequently.

Caching reduces database queries and improves response time.

However, cached data can become stale.

For example, a seat might have been sold while the cached event page still shows it as available.

To prevent this, seat availability must be verified against the authoritative database before a reservation is confirmed. Cache invalidation or short expiration periods can also reduce stale information.

## 4. Why store images in object storage rather than in a database?

Event posters, venue photographs and other images are better stored in object storage.

Object storage is designed to handle large files efficiently.

Advantages include:

- Lower database storage overhead.
- Better scalability for large media files.
- Easier delivery through a CDN.
- Reduced database backup and recovery size.

The database can store the image URL and related metadata instead of the image itself.

## 5. What is the difference between vertical and horizontal scaling?

**Vertical scaling** means increasing the resources of one server, such as adding more RAM, CPU power or storage.

**Horizontal scaling** means adding more servers and distributing requests between them.

Vertical scaling is easier to implement initially but has hardware limits and can leave one server as a single point of failure.

Horizontal scaling supports larger workloads and improves availability but requires load balancing and coordination between servers.

For a major ticket sale, horizontal scaling is preferable.

## 6. How would you stop one user from overloading your API?

I would implement rate limiting.

Rate limiting controls how many requests a user can make within a specific period.

For example, a user might be allowed a limited number of event-search requests per minute.

Other protections include:

- Authentication and request validation.
- IP-based limits for unauthenticated requests.
- User-based limits for authenticated requests.
- CAPTCHA or waiting-room mechanisms where appropriate.
- Monitoring suspicious activity.
- Returning HTTP 429 Too Many Requests when limits are exceeded.

Limits should be applied fairly so that legitimate customers are not unnecessarily blocked.

## 7. When would you choose a document database over a relational database?

A document database is useful when application data has flexible or frequently changing structures.

For example, event descriptions may contain different optional attributes depending on the type of event.

A document database such as MongoDB can store this information in flexible JSON-like documents.

A relational database such as PostgreSQL is more suitable for the core ticket-booking transactions because users, events, seats and orders have clear relationships and require strong consistency.

For this system, I would choose a relational database for bookings and payments, while considering a document database for flexible event metadata if necessary.

## 8. What would you monitor to know whether your system is healthy?

I would monitor:

- API response times.
- HTTP error rates.
- Requests per second.
- CPU and memory usage.
- Database query performance.
- Database connection usage.
- Cache hit and miss rates.
- Payment success and failure rates.
- Number of available seats.
- Failed or expired seat holds.
- Queue length and processing delays.

Alerts should be configured for unusual traffic, high error rates, payment failures and database problems.

Monitoring helps the team detect and resolve issues before they significantly affect customers.

---

# Part B: Ticket Booking System Design

## 1. Requirements

### Functional Requirements

The system should allow users to:

1. Register and log in.
2. Browse available events.
3. View event details and venue information.
4. View seat layouts and availability.
5. Select and temporarily hold seats.
6. Make payments for held seats.
7. Receive booking confirmation.
8. View their purchased tickets.
9. Cancel eligible bookings according to event policies.

### Non-Functional Requirements

**Performance**

- Event listings should load quickly.
- Common browsing requests should have low response times.
- The system should handle sudden traffic increases.

**Correctness**

- A seat must never be sold to two customers.
- Payment status and booking status must remain consistent.
- Orders must not be confirmed without successful payment.

**Fairness**

- Users should have a fair opportunity to access tickets.
- Rate limiting should prevent abusive request patterns.
- A virtual waiting room can control entry during major sales.
- The system should not allow users to hold unlimited seats.

**Availability**

- The system should remain operational during high demand.
- Failed application servers should not stop the entire service.

**Security**

- Users should only access their own orders and tickets.
- Payment information must be handled securely.
- API endpoints must validate requests and permissions.

---

## 2. Traffic Estimation

Assume the platform has:

- 100,000 registered users.
- 10,000 daily active users during normal periods.
- 100,000 users attempting to access a major sale.
- An average of 20 browsing requests per active user daily.
- An average of 2 booking-related requests per active user daily.

### Normal Traffic

Daily browsing requests:

10,000 × 20 = 200,000 requests.

Average browsing requests per second:

200,000 / 86,400 = approximately 2.3 requests per second.

Daily booking-related requests:

10,000 × 2 = 20,000 requests.

Average booking-related requests per second:

20,000 / 86,400 = approximately 0.23 requests per second.

### Big Sale Traffic

Assume 100,000 users attempt to access the system within 10 minutes.

Average incoming users per second:

100,000 / 600 = approximately 167 users per second.

If each user generates 10 browsing requests during this period:

1,000,000 / 600 = approximately 1,667 browsing requests per second.

If 20% of users attempt to book seats:

20,000 / 600 = approximately 33 booking attempts per second.

### Comparison

| Metric | Normal Traffic | Big Sale |
|---|---:|---:|
| Active users | 10,000 daily | 100,000 in 10 minutes |
| Browsing requests/sec | 2.3 | 1,667 |
| Booking attempts/sec | 0.23 | 33 |

The big sale creates a significant increase in traffic.

The system must therefore support horizontal scaling, caching, rate limiting and controlled access through a waiting room.

These are planning estimates, not measured production traffic.

---

## 3. API Design

The API uses REST principles and JSON for communication.

Base URL:

`https://api.ticketbooking.com/v1`

| Method | Endpoint | Description | Success Status |
|---|---|---|---|
| GET | /events | Browse events | 200 OK |
| GET | /events/{id} | View event details | 200 OK |
| GET | /events/{id}/seats | View event seats | 200 OK |
| POST | /holds | Temporarily hold selected seats | 201 Created |
| GET | /holds/{id} | Check seat hold status | 200 OK |
| DELETE | /holds/{id} | Release a seat hold | 204 No Content |
| POST | /orders/{id}/payments | Initiate payment | 202 Accepted |
| GET | /orders/{id} | View order details | 200 OK |
| GET | /tickets | View purchased tickets | 200 OK |

### Example: Browse Events

Request:

`GET /events`

Response:

```json
{
  "events": [
    {
      "id": 1,
      "name": "Summer Music Festival",
      "venue": "City Arena",
      "date": "2027-01-15"
    }
  ]
}
```

### Example: View Seats

Request:

`GET /events/1/seats`

Response:

```json
{
  "eventId": 1,
  "seats": [
    {
      "id": 101,
      "number": "A1",
      "status": "available"
    },
    {
      "id": 102,
      "number": "A2",
      "status": "sold"
    }
  ]
}
```

### Example: Hold Seats

Request:

`POST /holds`

Request body:

```json
{
  "eventId": 1,
  "seatIds": [101, 103],
  "userId": 25
}
```

Response:

```json
{
  "holdId": 5001,
  "status": "held",
  "expiresAt": "2027-01-15T10:15:00Z"
}
```

A seat hold should expire after a short period, such as five minutes, if payment is not completed.

### Example: Initiate Payment

Request:

`POST /orders/5001/payments`

Request body:

```json
{
  "paymentMethod": "card",
  "idempotencyKey": "payment-5001-attempt-1"
}
```

Response:

```json
{
  "paymentId": 9001,
  "status": "pending",
  "message": "Payment processing has started."
}
```

The payment provider should confirm the final result through a verified callback or webhook.

### Example: View Tickets

Request:

`GET /tickets`

Response:

```json
{
  "tickets": [
    {
      "ticketId": 7001,
      "event": "Summer Music Festival",
      "seat": "A1",
      "status": "confirmed"
    }
  ]
}
```

The API should also return appropriate errors, including:

- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 429 Too Many Requests
- 500 Internal Server Error

---

## 4. Database Design

A relational database such as PostgreSQL is suitable because the system requires reliable relationships and transactions.

### Users Table

| Column | Data Type | Key |
|---|---|---|
| id | BIGINT | Primary Key |
| name | VARCHAR(100) | |
| email | VARCHAR(150) | UNIQUE |
| password_hash | VARCHAR(255) | |
| created_at | TIMESTAMP | |

### Events Table

| Column | Data Type | Key |
|---|---|---|
| id | BIGINT | Primary Key |
| name | VARCHAR(150) | |
| description | TEXT | |
| venue | VARCHAR(150) | |
| event_date | TIMESTAMP | |
| created_at | TIMESTAMP | |

### Seats Table

| Column | Data Type | Key |
|---|---|---|
| id | BIGINT | Primary Key |
| event_id | BIGINT | Foreign Key |
| seat_number | VARCHAR(20) | |
| price | DECIMAL(10,2) | |
| status | VARCHAR(20) | |
| held_until | TIMESTAMP | Nullable |

A unique constraint on `(event_id, seat_number)` prevents duplicate seat definitions for the same event.

### Orders Table

| Column | Data Type | Key |
|---|---|---|
| id | BIGINT | Primary Key |
| user_id | BIGINT | Foreign Key |
| total_amount | DECIMAL(10,2) | |
| status | VARCHAR(20) | |
| created_at | TIMESTAMP | |

### Seat Holds Table

| Column | Data Type | Key |
|---|---|---|
| id | BIGINT | Primary Key |
| seat_id | BIGINT | Foreign Key, UNIQUE |
| order_id | BIGINT | Foreign Key |
| user_id | BIGINT | Foreign Key |
| expires_at | TIMESTAMP | |

Expired holds are removed or released so seats can become available again.

### Order Items Table

| Column | Data Type | Key |
|---|---|---|
| id | BIGINT | Primary Key |
| order_id | BIGINT | Foreign Key |
| seat_id | BIGINT | Foreign Key, UNIQUE |
| price | DECIMAL(10,2) | |

The unique constraint on `seat_id` ensures a seat cannot appear in two completed orders.

### Relationships

- One user can create many orders.
- One event can contain many seats.
- One order can contain many order items.
- Each order item represents one purchased seat.
- A seat can have one active hold at a time.
- A seat can belong to only one completed order.

### SQL Table Creation

```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    venue VARCHAR(150) NOT NULL,
    event_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE seats (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES events(id),
    seat_number VARCHAR(20) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'available',
    held_until TIMESTAMP,
    UNIQUE (event_id, seat_number),
    CHECK (status IN ('available', 'held', 'sold'))
);

CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE seat_holds (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seat_id BIGINT NOT NULL UNIQUE REFERENCES seats(id),
    order_id BIGINT NOT NULL REFERENCES orders(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    expires_at TIMESTAMP NOT NULL
);

CREATE TABLE order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    seat_id BIGINT NOT NULL UNIQUE REFERENCES seats(id),
    price DECIMAL(10,2) NOT NULL
);

CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_seats_event ON seats(event_id);
CREATE INDEX idx_orders_user ON orders(user_id);
```

The database constraints provide additional protection against duplicate bookings.

---

## 5. Preventing Double-Booking

Double-booking happens when two or more users attempt to purchase the same seat at almost the same time.

For example:

- User A selects seat A1.
- User B also selects seat A1.
- Both users attempt to pay.

Without proper protection, both requests might incorrectly treat the seat as available.

### Solution: Transactions and Database Constraints

The system should use database transactions and row-level locking.

When a user requests a seat hold:

1. Begin a database transaction.
2. Lock the selected seat rows using `SELECT ... FOR UPDATE`.
3. Check whether the seats are available.
4. Check whether any existing holds have expired.
5. Create the order and temporary seat holds.
6. Mark the seats as held.
7. Commit the transaction.

Example:

```sql
BEGIN;

SELECT id, status, held_until
FROM seats
WHERE id = 101
FOR UPDATE;

-- Check that the seat is available
-- or that its previous hold has expired.

UPDATE seats
SET status = 'held',
    held_until = CURRENT_TIMESTAMP + INTERVAL '5 minutes'
WHERE id = 101;

COMMIT;
```

Only one transaction can hold the same seat row for modification at a time.

A second customer must wait until the first transaction finishes. The second request then checks the updated seat status and cannot hold the same active reservation.

### Completing Payment

1. The payment provider processes the payment.
2. The application verifies the payment result.
3. A database transaction checks that the hold is still valid.
4. The system marks the seat as sold.
5. The purchased seat is added to order_items.
6. The order is marked as paid.
7. The transaction commits.

The unique constraint on `order_items.seat_id` provides another layer of protection.

Payment requests should use idempotency keys so that repeated requests or payment callbacks do not create duplicate charges or orders.

If payment fails or the hold expires, the hold should be released and the seat made available again, following the payment provider's final payment status.

---

## 6. System Architecture

### Architecture Diagram

```text
                    CUSTOMERS
                        |
                        v
                   DNS SERVICE
                        |
                        v
                       CDN
                        |
                        v
                 WAITING ROOM
                        |
                        v
                 LOAD BALANCER
                        |
              +---------+---------+
              |                   |
              v                   v
         APP SERVER 1        APP SERVER 2
              |                   |
              +---------+---------+
                        |
             +----------+----------+
             |          |          |
             v          v          v
           CACHE    MESSAGE     API SERVICES
                    QUEUE            |
                       |             |
                       v             v
                    WORKERS     PRIMARY DATABASE
                       |             |
                       v             v
                 NOTIFICATIONS  READ REPLICA
                                     |
                                     v
                               BACKUPS

         OBJECT STORAGE <---- EVENT IMAGES / POSTERS

         PAYMENT SERVICE <---- SECURE PAYMENT INTEGRATION
```

### Component Responsibilities

**DNS Service**

Translates the domain name into the server's IP address.

**CDN**

Delivers static resources such as event posters, images and frontend files.

**Waiting Room**

Controls the number of customers entering the booking system during high-demand sales.

**Load Balancer**

Distributes incoming requests across available application servers.

**Application Servers**

Handle user requests, authentication, event browsing, booking and order processing.

**Cache**

Stores frequently requested event and venue information to reduce database load.

**Message Queue**

Stores background tasks such as sending booking confirmations.

**Workers**

Process queued tasks without slowing down the main application.

**Primary Database**

Stores authoritative booking information and handles transactions.

**Read Replica**

Handles additional read requests to reduce the load on the primary database.

**Object Storage**

Stores event posters, venue images and other media.

**Payment Service**

Integrates with an external payment provider to process transactions securely.

**Backups**

Provide recovery options in case of data loss or database failure.

### How the System Survives a Big Sale

1. The CDN serves static content without requiring every request to reach the application servers.
2. The waiting room controls traffic and prevents the backend from receiving more requests than it can handle.
3. The load balancer distributes requests across multiple application servers.
4. Horizontal scaling allows additional application servers to be added when demand increases.
5. Caching reduces repeated database queries for event information.
6. Database transactions and row-level locks protect seat reservations.
7. Read replicas handle additional browsing traffic.
8. Message queues process background tasks asynchronously.
9. Monitoring detects failures and performance problems.

---

## 7. Trade-offs

### 1. Caching vs Data Accuracy

Caching improves performance and reduces database load.

However, cached seat information may become outdated when another customer purchases a ticket.

The system should cache event descriptions and other relatively stable information, but verify seat availability against the primary database before confirming a hold.

### 2. Fairness vs Maximum Throughput

A waiting room improves fairness by controlling how customers enter the system.

However, it may increase the waiting time for customers.

The system must balance fair access with fast processing.

### 3. Read Replicas vs Immediate Consistency

Read replicas reduce the workload on the primary database.

However, replication delays can cause users to see outdated information.

Critical booking and payment operations should use the primary database rather than relying on potentially stale replica data.

### 4. Strong Consistency vs Scalability

Strong consistency is important for ticket reservations because the same seat must not be sold twice.

However, database locking and transaction coordination can reduce throughput when many customers compete for the same seats.

The system should use carefully designed transactions, suitable database indexes and controlled traffic to maintain correctness while supporting high demand.

---

## 8. Reflection

This assignment helped me understand how system design concepts apply to real-world applications.

I learned that designing a ticket-booking system involves more than creating API endpoints and database tables. It requires considering performance, fairness, reliability, security and data consistency.

One of the most important concepts I learned was how database transactions and constraints prevent double-booking. I also understood why caching is useful for improving performance but should not be trusted for critical seat availability decisions.

The traffic estimation exercise helped me understand how a system that works under normal conditions can struggle when thousands of users access it simultaneously.

I also learned how load balancers, horizontal scaling, waiting rooms, message queues and database replication contribute to building scalable applications.

Overall, this assignment improved my understanding of system architecture and how to make design decisions by considering both technical requirements and user experience.
