# TicketHub: Ticket Booking System Design

## Introduction

TicketHub is an online ticket-booking platform that allows customers to browse events, view available seats, reserve seats, make payments and access their purchased tickets.

The system must support ordinary daily traffic as well as sudden increases in demand when tickets for a popular concert become available. Its most important responsibility is to prevent two customers from successfully purchasing the same seat.

This document explains the requirements, traffic estimates, API design, database structure, architecture, double-booking prevention and design trade-offs.

---

# Part A: System Design Fundamentals

## 1. What happens when a user enters a URL and presses Enter?

Several steps take place before a webpage appears:

1. The browser checks whether it already has the required information in its cache.
2. If necessary, DNS translates the domain name into an IP address.
3. The browser establishes a connection to the server, usually using TCP and TLS for HTTPS.
4. It sends an HTTP request to the server.
5. The request may pass through a CDN, firewall, load balancer or other infrastructure before reaching an application server.
6. The application server processes the request and may retrieve information from a database or cache.
7. The server sends an HTTP response.
8. The browser interprets the returned HTML, CSS and JavaScript, requests additional resources and renders the page.

For TicketHub, this process allows customers to open the website, browse events and retrieve information about available seats.

## 2. Why should application servers be stateless?

Application servers should be stateless so that any server can handle any incoming request without depending on information stored only on another server.

For example, if a customer browses TicketHub and the next request is handled by a different application server, the customer's session should still work.

Session information can be stored in a shared system, such as a database or distributed cache, rather than in an individual application server.

Stateless servers make horizontal scaling easier, improve fault tolerance and allow a load balancer to distribute requests across several servers.

## 3. What is caching, and why is it useful?

Caching stores frequently requested information in a location where it can be retrieved quickly.

TicketHub can cache information such as event names, descriptions, venue details and promotional images. This reduces repeated database queries and improves response times.

However, seat availability and booking information require special care. A cached seat list may become outdated. Therefore, cached information can help display seats, but the system must verify the current seat status in the primary database before confirming a hold or purchase.

## 4. What is object storage used for?

Object storage is designed to store files such as images, documents and videos.

TicketHub can use object storage for event posters, venue images and downloadable ticket documents. These files can be served through a CDN to reduce the load on application servers.

The relational database should store information about the files, such as their names and storage locations, rather than storing large files directly.

## 5. What is the difference between vertical and horizontal scaling?

Vertical scaling means increasing the resources of an existing server, such as adding more CPU, memory or storage.

Horizontal scaling means adding more servers and distributing incoming requests among them.

For TicketHub, horizontal scaling is more suitable for a popular concert sale because many customers may access the platform at the same time. Additional application servers can handle more requests.

However, scaling application servers alone is not enough. The database, cache, payment processing and other components must also be designed to handle increased demand.

## 6. What is rate limiting?

Rate limiting controls how many requests a user or client can make within a specified period.

It helps protect TicketHub from excessive requests, automated abuse and denial-of-service attempts.

For example, the platform can limit repeated seat-hold requests from one account or IP address. Limits should be applied fairly so that genuine customers are not unnecessarily blocked during a popular sale.

## 7. What is the difference between relational and document databases?

A relational database stores information in structured tables connected through relationships. It supports transactions and constraints that help maintain data consistency.

A document database stores information in flexible document structures, often using JSON-like formats.

TicketHub needs strong consistency when managing seats, orders and payments. A relational database such as PostgreSQL is suitable because it supports transactions, foreign keys, unique constraints and row-level locking.

## 8. Why are monitoring and logging important?

Monitoring helps administrators understand whether a system is operating correctly. It can track response times, error rates, database performance, server resources and payment failures.

Logging records important system events, such as successful bookings, failed payments and rejected seat-hold attempts.

For TicketHub, these tools help identify problems during high-demand ticket sales and support investigation of booking disputes.

---

# Part B: TicketHub System Design

## 1. Requirements

### 1.1 Functional requirements

The system should allow customers to:

- Register and log in securely.
- Browse available events.
- View event details, dates, venues and ticket prices.
- View the seating layout and current seat availability.
- Select one or more available seats.
- Temporarily hold selected seats while completing a booking.
- Make payments through an integrated payment provider.
- Receive confirmation after successful payment.
- View and access purchased tickets.

The system should also allow administrators to:

- Create, update and manage events.
- Configure venues, seating arrangements and ticket prices.
- Monitor bookings and payment statuses.
- View ticket sales and event availability.

### 1.2 Non-functional requirements

**Performance:** Event pages and seat information should load quickly under normal conditions. The system should handle increased demand during popular ticket sales.

**Correctness and consistency:** A seat must not be confirmed as sold to more than one customer. Booking and payment records must remain consistent.

**Fairness:** Customers should have a fair opportunity to access tickets. The system should control automated abuse, repeated requests and excessive traffic without giving unfair priority to selected customers.

**Availability:** The platform should remain accessible during important ticket-sale periods. Failures in one application server should not bring down the entire service.

**Security:** Customer accounts, personal information and payment-related communication must be protected. Access to booking operations should require authentication and authorization.

**Scalability:** The platform should support growth in users and requests by allowing infrastructure components to scale as demand increases.

**Reliability:** The system should handle failed requests, interrupted payments and duplicate payment notifications without creating incorrect bookings.

---

## 2. Traffic Estimates

TicketHub has the following supplied traffic figures:

- 2 million registered users.
- 50,000 visitors on a normal day.
- Each normal-day visitor views 10 pages.
- 5,000 tickets are sold on a normal day.
- During a popular concert sale, 200,000 people try to buy 20,000 seats within the first 10 minutes.

### 2.1 Normal-day traffic

Daily page views:

50,000 visitors × 10 pages = 500,000 page views per day.

Average page requests per second:

500,000 ÷ 86,400 seconds = approximately 5.79 page requests per second.

Average ticket sales per second:

5,000 ÷ 86,400 seconds = approximately 0.058 ticket sales per second.

This represents average traffic across the whole day. Actual traffic may be higher during busy periods.

### 2.2 Popular concert sale traffic

The sale attracts 200,000 people within 10 minutes.

Convert 10 minutes into seconds:

10 × 60 = 600 seconds.

Average incoming users per second:

200,000 ÷ 600 = approximately 333.33 users per second.

The event has 20,000 available seats.

Average number of competing customers per seat:

200,000 ÷ 20,000 = 10 customers per seat.

If all 20,000 seats are sold within the 10-minute period, the average successful ticket sales rate is:

20,000 ÷ 600 = approximately 33.33 sales per second.

### 2.3 Traffic comparison

| Measurement | Normal day | Popular concert sale |
|---|---:|---:|
| Visitors or incoming customers | 50,000 per day | 200,000 in 10 minutes |
| Page views | 500,000 per day | Not specified |
| Average page requests per second | 5.79 | Cannot be calculated from the supplied facts |
| Tickets or seats | 5,000 sold per day | 20,000 available |
| Average successful sales rate | 0.058 per second | 33.33 per second if all seats sell within 10 minutes |

The popular concert sale creates a much greater concentration of demand. The platform must therefore be prepared for sudden traffic spikes rather than relying only on normal-day averages.

The number of page views during the concert sale is not provided, so it would be inaccurate to invent a peak page-request rate. The design should use load testing to establish the actual capacity required.

---

## 3. API Design

TicketHub will expose a REST API. The API allows the frontend to communicate with the application server using HTTP methods.

All booking operations require authentication. The customer's identity should be obtained from the authenticated session or access token, not trusted from a user ID supplied in the request body.

### 3.1 Browse events

**Endpoint:** `GET /api/events`

**Purpose:** Retrieves a list of available events.

**Example response:**

```json
{
  "events": [
    {
      "id": 101,
      "name": "Summer Music Festival",
      "venue": "City Arena",
      "date": "2026-12-20"
    }
  ]
}
```

### 