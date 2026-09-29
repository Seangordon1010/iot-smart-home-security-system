# Database Design

## 1. Overview

The system will use SQLite as the local database for the Node.js backend.

The database will store information thats required to manage users, authentication, security events, captured images, and synchronization.

## 2. Planned Tables

The database design contains the following tables:

```text
users
security_events
images
sync_records
```

## 3. Users Table

The `users` table will hold the information required to identify authenticated users.

| Column        | Type    | Description                           |
| ------------- | ------- | ------------------------------------- |
| user_id       | INTEGER | Unique identifier for the user        |
| username      | TEXT    | User login name                       |
| password_hash | TEXT    | Stored password hash                  |
| created_at    | TEXT    | Date and time the account was created |

### Primary Key

`user_id`

## 4. Security Events Table

The `security_events` table will hold information about detected security events.

| Column      | Type    | Description                          |
| ----------- | ------- | ------------------------------------ |
| event_id    | INTEGER | Unique identifier for the event      |
| event_type  | TEXT    | Type of security event               |
| detected_at | TEXT    | Date and time the event was detected |
| device_id   | TEXT    | Identifier for the ESP32 device      |
| status      | TEXT    | Current event status                 |
| created_at  | TEXT    | Date and time the record was created |

### Primary Key

`event_id`

## 5. Images Table

The `images` table will hold the  information about the images captured during security events.

| Column      | Type    | Description                              |
| ----------- | ------- | ---------------------------------------- |
| image_id    | INTEGER | Unique identifier for the image          |
| event_id    | INTEGER | Security event associated with the image |
| image_path  | TEXT    | Local path or reference to the image     |
| captured_at | TEXT    | Date and time the image was captured     |

### Primary Key

`image_id`

### Foreign Key

`event_id` references:

```text
security_events(event_id)
```

## 6. Synchronization Records Table

The `sync_records` table will track information needed for synchronization between the mobile application and backend.

| Column       | Type    | Description                                      |
| ------------ | ------- | ------------------------------------------------ |
| sync_id      | INTEGER | Unique synchronization record identifier         |
| record_type  | TEXT    | Type of record being synchronized                |
| record_id    | INTEGER | Identifier of the associated record              |
| sync_status  | TEXT    | Current synchronization status                   |
| last_sync_at | TEXT    | Date and time of the most recent synchronization |

### Primary Key

`sync_id`

## 7. Database Relationships

The planned relationships are:

```text
users
  |
  | authentication
  |
  v

security_events
  |
  | 1-to-many
  v
images

sync_records
  |
  | tracks synchronization
  v
security_events / images
```

A security event can have one or more associated images.

## 8. Initial Database Diagram

```text
+----------------------+
| users                |
+----------------------+
| PK user_id           |
| username             |
| password_hash        |
| created_at           |
+----------------------+

+----------------------+
| security_events      |
+----------------------+
| PK event_id          |
| event_type           |
| detected_at          |
| device_id            |
| status               |
| created_at           |
+----------+-----------+
           |
           | 1-to-many
           |
           v
+----------------------+
| images               |
+----------------------+
| PK image_id          |
| FK event_id          |
| image_path           |
| captured_at          |
+----------------------+

+----------------------+
| sync_records         |
+----------------------+
| PK sync_id           |
| record_type          |
| record_id            |
| sync_status          |
| last_sync_at         |
+----------------------+
```

## 9. Design Considerations

The database design may change during implementation as the data produced by the ESP32-S3-EYE and required by the Flutter application becomes clearer.

The database will remain local to the Node.js backend.

Sensitive information such as authentication should not and will not be stored as plain-text passwords. Passwords should be represented using certain password-hashing techniques during implementation.

The database structure will be tested after it gets implemented to ensure that records can be created, retrieved, updated, and synchronized correctly.

* Indexes where appropriate.
* Data retention considerations.

A database diagram will be added after the database structure has been designed.
