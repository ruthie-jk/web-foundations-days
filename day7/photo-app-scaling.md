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
```

The CDN serves cached image files, while feed requests pass through the load balancer and application servers. The application cache reduces repeated data lookups, and feed reads can use the database read replica. Original photos and generated thumbnails are stored in object storage.

## 6. Components and the Problems They Solve

- **CDN:** Caches and delivers frequently requested photos from locations closer to users, reducing latency and load on the origin storage.
- **Load balancer:** Distributes incoming application requests across multiple app servers to prevent one server from becoming overloaded.
- **App servers:** Handle application logic, authentication, upload authorization, feed generation, and database interactions.
- **Application cache:** Keeps frequently accessed information, such as feed data or profile metadata, available without repeatedly querying the database.
- **Database primary:** Stores structured information such as users, follow relationships, photo metadata, captions, and object-storage keys.
- **Database read replica:** Handles eligible read queries so that the primary database can focus on writes and other primary responsibilities.
- **Object storage:** Stores original photos and thumbnails separately from structured database records, allowing image storage to scale independently.
- **Queue:** Holds thumbnail-generation jobs so that photo uploads do not have to wait for image processing to finish.
- **Thumbnail worker:** Processes queued jobs, generates smaller thumbnail images, stores them in object storage, and updates the relevant photo metadata when necessary.

## 7. Photo Upload Flow

1. A user selects a photo and submits it through the SnapShare application.
2. The app server authenticates the user, validates the request, and authorizes the upload.
3. The app server provides a short-lived upload URL or equivalent authorization for the object-storage destination.
4. The client uploads the original photo directly to object storage, reducing the amount of large-file traffic passing through the application servers.
5. Once the upload succeeds, the application records the photo metadata and storage key in the primary database.
6. The application adds a thumbnail-generation job to the queue.
7. A thumbnail worker retrieves the job and downloads or reads the original photo from object storage.
8. The worker generates a 50 KB thumbnail and saves it in object storage.
9. The worker records the thumbnail's storage key or marks thumbnail processing as complete.
10. When users view a feed, the app retrieves feed metadata from the cache or an appropriate database replica and returns image URLs or keys.
11. The CDN serves cached thumbnails or original photos when available and fetches missing objects from object storage.

The thumbnail process runs asynchronously, meaning the upload does not have to wait for thumbnail generation to finish. The application can show a temporary processing state until the thumbnail is ready.

## 8. Trade-Offs

### Trade-Off 1: CDN Caching vs. Freshness

A CDN reduces latency and object-storage traffic by caching popular photos. However, cached content can become outdated after an image is replaced or deleted. SnapShare can use cache expiration, versioned image URLs, and cache invalidation to balance performance with freshness.

### Trade-Off 2: Read Replicas vs. Consistency

A read replica reduces the read load on the primary database. However, replication can lag behind the primary, meaning a newly uploaded photo or updated caption might not immediately appear in every read. The application can read recent changes from the primary when immediate consistency is required.

### Trade-Off 3: Asynchronous Thumbnail Processing vs. Immediate Availability

A queue allows uploads to complete without waiting for thumbnail generation, improving responsiveness. However, queue delays or worker failures can leave thumbnails temporarily unavailable. Retries, monitoring, and a dead-letter queue can help recover failed jobs.

### Trade-Off 4: Direct Uploads vs. Complexity

Uploading directly to object storage reduces application-server bandwidth and makes large-file handling easier to scale. However, it requires secure upload authorization, validation, and cleanup for incomplete or abandoned uploads.

## 9. Conclusion

SnapShare should use a horizontally scalable application architecture with a CDN, load balancer, application cache, primary database and read replica, object storage, and an asynchronous thumbnail-processing pipeline.

Based on the stated assumptions, the system supports approximately 1 million daily active users, 11.57 average photo uploads per second, 578.70 average feed views per second, and about 748.25 TB of original-photo and thumbnail storage per year.

The design prioritizes efficient read performance, independent scaling of image storage, and responsive uploads while accounting for consistency, caching, and background-processing trade-offs.