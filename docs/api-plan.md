# API Plan

## 1. Overview

The Node.js backend will allow for an API for communication between the Flutter mobile application and the local IoT security system.

The API will give the access to authentication, security events, captured images, synchronization, and system status.

## 2. API Design

The initial API will use HTTP requests between the Flutter mobile application and Node.js backend.

The ESP32-S3-EYE will also communicate with the Node.js backend over the local Wi-Fi network.

The exact request and response methods may be changed during implementation.

## 3. Authentication

### POST `/api/auth/login`

Authenticates a user.

**Request:**

```json
{
  "username": "example",
  "password": "example"
}
```

**Response:**

```json
{
  "authenticated": true,
  "user_id": 1
}
```

Authentication details will be changed as needed during implementation.

## 4. Security Events

### GET `/api/events`

Retrieves available security events for an authenticated user.

**Response:**

```json
{
  "events": [
    {
      "event_id": 1,
      "event_type": "motion",
      "detected_at": "2026-09-25T15:30:00",
      "device_id": "esp32-s3-eye-01",
      "status": "new"
    }
  ]
}
```

### GET `/api/events/:id`

Retrieves information for a specific security event.

**Response:**

```json
{
  "event_id": 1,
  "event_type": "motion",
  "detected_at": "2026-09-25T15:30:00",
  "device_id": "esp32-s3-eye-01",
  "status": "new"
}
```

## 5. Image Information

### GET `/api/events/:id/images`

Retrieves image information that comes from a security event.

**Response:**

```json
{
  "images": [
    {
      "image_id": 1,
      "event_id": 1,
      "image_path": "images/event-1.jpg",
      "captured_at": "2026-09-25T15:30:00"
    }
  ]
}
```

## 6. IoT Event Submission

### POST `/api/events`

Receives a security event from the ESP32-S3-EYE.

**Planned Request:**

```json
{
  "event_type": "motion",
  "device_id": "esp32-s3-eye-01",
  "detected_at": "2026-09-25T15:30:00",
  "image": "image-data"
}
```

The backend will validate the request and store the applicable event information.

## 7. Synchronization

### GET `/api/sync`

Retrieves information required by the mobile application to synchronize its local data.

### POST `/api/sync`

Sends locally stored mobile information to the backend for synchronization.

**Planned Request:**

```json
{
  "records": []
}
```

The exact synchronization data structure will be refined during implementation.

## 8. System Status

### GET `/api/status`

Provides basic information about the availability of the backend and system.

**Example Response:**

```json
{
  "status": "online"
}
```

## 9. Initial Endpoint Summary

| Method | Endpoint                 | Purpose                              |
| ------ | ------------------------ | ------------------------------------ |
| POST   | `/api/auth/login`        | Authenticate user                    |
| GET    | `/api/events`            | Retrieve security events             |
| GET    | `/api/events/:id`        | Retrieve one security event          |
| GET    | `/api/events/:id/images` | Retrieve event images                |
| POST   | `/api/events`            | Submit security event                |
| GET    | `/api/sync`              | Retrieve synchronization information |
| POST   | `/api/sync`              | Submit synchronization information   |
| GET    | `/api/status`            | Check system status                  |

## 10. Security Considerations

Protected API endpoints should make users authenticate.

The backend should validate incoming requests before processing them.

Sensitive information should not be sent back to unauthorized users.

Authentication credentials shouldn't be stored or transmitted as plain-text information beyond what is needed for the authentication process.

## 11. Design Considerations

This is the initial API design. Endpoint names, request fields, response fields, authentication methods, and synchronization behavior may be adjusted during implementation.

The API needs to stay small enough to support the project's required functionality without adding any unnecessary complications.

