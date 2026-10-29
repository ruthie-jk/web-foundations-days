# SnapShare Photo App Scaling Plan

## 1. Assumptions

This plan estimates the resources needed to scale SnapShare, a photo-sharing application where users upload photos and view feeds from people they follow.

The following assumptions are used:

- SnapShare has 10 million registered users.
- 10% of registered users are active each day.
- Each daily active user uploads one photo per day.
- Each daily active user views 50 feed pages per day.
- Each original photo is 2 MB, and each thumbnail is 50 KB.
- Each uploaded photo produces one thumbnail.
- A year has 365 days, and photos are retained for the full year.
- Average traffic is calculated over 86,400 seconds per day.
- Peak traffic is estimated at five times the average rate.
- Storage calculations use decimal units (1 TB = 1,000,000 MB) and exclude backups, replication, metadata, and other overhead.

## 2. Traffic and Storage Estimates

### Daily Active Users

Daily active users (DAU) are 10% of the registered users.

DAU = 10,000,000 × 10%

**DAU = 1,000,000 users**

### Photo Uploads Per Second

Each active user uploads one photo per day.

Daily uploads = 1,000,000 × 1 = 1,000,000 uploads

Average uploads per second = 1,000,000 ÷ 86,400

**Average upload rate ≈ 11.57 uploads/second**

Peak uploads per second = 11.57 × 5

**Peak upload rate ≈ 57.87 uploads/second**

### Feed Views Per Second

Each active user views 50 feed pages per day.

Daily feed views = 1,000,000 × 50 = 50,000,000 views

Average feed views per second = 50,000,000 ÷ 86,400

**Average feed view rate ≈ 578.70 views/second**

Peak feed views per second = 578.70 × 5

**Peak feed view rate ≈ 2,893.52 views/second**

These estimates represent feed page requests, not the total number of individual photo-image requests. A single feed page may load multiple photos.

### Photo Storage Per Year

Original photos:

1,000,000 uploads/day × 365 days × 2 MB

**Original photo storage = 730 TB/year**

Thumbnails:

1,000,000 uploads/day × 365 days × 50 KB

**Thumbnail storage = 18.25 TB/year**

Total estimated photo storage:

730 TB + 18.25 TB

**Total = 748.25 TB/year**

This is the estimated storage required for original photos and thumbnails before accounting for backups, replication, metadata, and storage overhead.

## 3. Read-Heavy or Write-Heavy?

SnapShare is a **read-heavy system** because users view approximately 50 million feed pages daily, compared with one million daily photo uploads.

This means the system must efficiently serve large numbers of feed requests while remaining reliable during traffic spikes. The architecture uses a CDN to deliver cached photos, an application cache to reduce repeated database queries, and a database read replica to handle read queries separately from writes. The system can also scale application servers horizontally to handle additional traffic.

## 4. Why Photos Should Not Be Stored in the Database

Original photos and thumbnails should be stored in object storage rather than directly inside the relational database.

Storing large image files in database tables would increase database storage requirements, backup sizes, and the amount of data handled by database operations. It could also make database maintenance and scaling more expensive.

Object storage is designed to store and retrieve large files efficiently and can scale to accommodate hundreds of terabytes or more. The database should store photo metadata, such as the photo ID, owner ID, caption, upload time, object-storage key, and thumbnail key. The actual image files remain in object storage, while the CDN can cache frequently requested images closer to users.

## 5. Architecture Diagram

```text
                         SNAPSHARE ARCHITECTURE

                                  Users
                                    |
                    +---------------+---------------+
                    |                               |
                 Feed reads                    Photo uploads
                    |                               |
                    v                               v
                  [CDN]                     [Load Balancer]
                    |                               |
                    |                         [App Servers]
                    |                               |
                    |                     Request upload authorization
                    |                               |
                    |                               v
                    |                       [Object Storage]
                    |                         Original photos
                    |                               |
                    |                       Upload completed
                    |                               |
                    |                               v
                    |                         [App Servers]
                    |                          /          \
                    |                         v            v
                    |                  [Database]      [Queue]
                    |                  (Primary DB)       |
                    |                       |             v
                    |                       |        [Thumbnail
                    |                       |          Worker]
                    |                       |             |
                    |                       |             v
                    |                       |      [Object Storage]
                    |                       |       Thumbnail files
                    |                       |
                    |                       v
                    |                 [Read Replica]
                    |                       ^
                    |                       |
                    |                 Feed read queries
                    |
                    v
              Cached photo files

        [App Servers] <----> [Application Cache]
               |
               +----------> [Database Primary]


The CDN serves cached image files, while feed requests pass through the load balancer and application servers. The application cache reduces repeated data lookups, and feed reads can use the database read replica. Original photos and generated thumbnails are stored in object storage.

## 6. Component Summary

- **CDN:** Caches and delivers frequently requested photos closer to users, reducing image-loading latency and requests reaching the origin storage.
- **Load balancer:** Distributes incoming requests across multiple application servers so that one server does not become overloaded.
- **Application servers:** Handle user requests, validate uploads, generate feed responses, and coordinate database, storage, and queue operations.
- **Application cache:** Stores frequently accessed feed data and metadata to reduce repeated database queries and improve response times.
- **Primary database:** Stores structured information such as users, photo metadata, captions, follow relationships, and object-storage keys while handling writes.
- **Database read replica:** Handles eligible read queries to reduce the primary database's workload, although replication lag can temporarily make its data stale.
- **Object storage:** Stores original photos and thumbnails separately from database records, allowing large image files to scale independently of structured data.
- **Queue:** Holds thumbnail-generation jobs until workers can process them, preventing image processing from delaying the upload request.
- **Thumbnail worker:** Processes queued jobs, creates smaller thumbnail images, saves them in object storage, and records their availability.

## 7. Step-by-Step Photo Upload Flow

1. A user selects a photo and initiates an upload from the SnapShare application.
2. The application server authenticates the user, validates the request, checks upload permissions, and authorizes the upload.
3. The server provides a short-lived, authorized upload URL or equivalent mechanism for uploading the file directly to object storage.
4. The client uploads the original photo to object storage, avoiding unnecessary transfer of the large file through the application server.
5. After the upload succeeds, the application records the photo's metadata, owner, upload time, and storage key in the primary database.
6. The application adds a thumbnail-generation job to the queue, including the photo identifier and original object's storage key.
7. A thumbnail worker retrieves the job and reads the original photo from object storage.
8. The worker generates a smaller thumbnail and saves it as a separate object in storage.
9. The worker updates the photo metadata to record the thumbnail's storage key and processing status.
10. When a user opens a feed, the application retrieves feed metadata from the cache or an appropriate database read replica and provides the relevant image URLs.
11. The CDN serves cached images when available; otherwise, it retrieves the requested image from object storage and can cache it for subsequent requests.

Thumbnail generation happens asynchronously, so the original upload can complete before the thumbnail is ready. The application should display a processing state until the thumbnail becomes available.

If a worker fails or the queue is delayed, the job should be retried with a limit on the number of attempts. Failed jobs can be moved to a dead-letter queue for investigation and later recovery. Workers should be idempotent, meaning that retrying a job does not create duplicate or inconsistent results. Monitoring queue length and processing time helps the team detect backlogs before they significantly affect users.

## 8. Architectural Trade-Offs

### Trade-Off 1: CDN Caching vs. Content Freshness

A CDN improves performance by serving frequently requested photos from locations closer to users and reducing traffic to object storage. However, cached images may remain available after a photo has been updated or deleted. SnapShare can use versioned image URLs, appropriate cache expiration policies, and cache invalidation to balance fast delivery with content freshness.

### Trade-Off 2: Read Replicas vs. Immediate Consistency

A database read replica distributes read traffic away from the primary database, improving scalability and helping feed requests remain responsive. However, replication is not always instantaneous, so a newly uploaded photo or updated caption may not immediately appear in reads served by the replica. SnapShare can send requests requiring immediate consistency to the primary database while allowing ordinary feed reads to use the replica.

### Trade-Off 3: Asynchronous Thumbnail Processing vs. Immediate Availability

Using a queue allows users to upload original photos without waiting for thumbnails to be generated, making uploads more responsive and allowing workers to scale independently. However, thumbnails may be temporarily unavailable when workers are overloaded or fail. Bounded retries, dead-letter queues, idempotent workers, and monitoring help recover failed jobs and prevent a growing backlog from going unnoticed.

### Trade-Off 4: Direct Object Storage Uploads vs. Implementation Complexity

Direct uploads reduce application-server bandwidth usage and make large-file handling easier to scale. However, they introduce additional security and coordination requirements, including short-lived upload permissions, file validation, upload completion checks, and cleanup of abandoned uploads. These controls are necessary to prevent unauthorized access and wasted storage.