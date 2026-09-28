# System Architecture

## 1. Overview

The IoT smart-home security system will use a locally hosted architecture consisting of an ESP32-S3-EYE, Wi-Fi network, Node.js backend, SQLite database, and Flutter mobile application.

The architecture is made to keep the primary system processing and data storage local rather than making cloud services a required part of the system.

## 2. Major Components

### ESP32-S3-EYE

The ESP32-S3-EYE is the the IoT hardware portion of the system.

Its planned responsibilities include:

* Detecting any security events.
* Capturing any images when a security event occurs.
* Connecting to the local Wi-Fi network.
* Sending the event information and captured image information to the backend.

### Wi-Fi Network

The Wi-Fi network will provide communication between the ESP32-S3-EYE and the locally hosted Node.js backend.

The network will also allow the Flutter mobile application to communicate with the backend when the mobile device has access to the local system.

### Node.js Backend

The Node.js backend will act as the central application service.

Its planned responsibilities include:

* Receiving security events from the ESP32-S3-EYE.
* Processing incoming event information.
* Handling communication with the SQLite database.
* Providing API endpoints for the Flutter application.
* Handling authentication.
* Providing event and image information to authorized users.
* Supporting synchronization-related operations.

### SQLite Database

SQLite will be used for local data storage for the backend.

The database will store information required by the system, which includes user information, security events, captured image information, and synchronization-related information.

### Flutter Mobile Application

The Flutter application will provide the user interface for monitoring the security system.

Its planned responsibilities include:

* User authentication.
* Displaying security events.
* Displaying captured images.
* Providing access to locally available information while offline.
* Synchronizing information when connectivity is restored.

## 3. Initial Architecture

```text
                 Local Wi-Fi Network
                         |
              +----------+----------+
              |                     |
              v                     v
       ESP32-S3-EYE          Flutter Mobile App
              |                     |
              |                     |
              v                     v
          Node.js Backend <----------+
              |
              v
        SQLite Database
```

The Node.js backend will serve as the central application service. The ESP32-S3-EYE will send security event information to the backend, while the Flutter application will use the backend API to retrieve and manage information.

## 4. Communication Flow

The planned communication flow for a security event is:

1. The ESP32-S3-EYE detects a security event.
2. The ESP32-S3-EYE captures an image.
3. The ESP32-S3-EYE sends the event information to the Node.js backend over Wi-Fi.
4. The Node.js backend validates and processes the request.
5. The backend stores the appropriate information in SQLite.
6. The Flutter application requests available security-event information through the backend API.
7. The backend returns the requested information to the authenticated application.
8. The Flutter application displays the event to the user.

## 5. Local-First Design

The system will prioritize local processing and storage.

The Node.js backend and SQLite database will be hosted locally rather than requiring a remote cloud service for normal operation.

The Flutter application will also use an offline-first approach. Information that is already available locally on the mobile device should remain accessible when the backend or network is temporarily unavailable.

When connectivity is restored, synchronization will be used to update applicable information.

## 6. Security

Security will be considered at the communication, backend, database, and mobile application levels.

The planned security mechanisms include:

* Authentication for protected resources.
* Controlled access to security-event information.
* Protection of captured image information.
* Validation of requests received by the backend.
* Separation between public and protected API functionality.

The exact authentication and communication security implementation will be finalized during implementation.

## 7. Design Considerations

The architecture separates the system into distinct components so that each part can be developed and tested independently.

The main separation is:

```text
Hardware
   |
   v
Communication
   |
   v
Backend
   |
   v
Database
   ^
   |
   v
Mobile Application
```

This will allow the ESP32-S3-EYE, backend, database, and mobile application to be tested individually before full system integration.

## 8. Planned Implementation Order

The planned implementation order is:

1. ESP32-S3-EYE functionality.
2. Node.js backend setup.
3. SQLite database setup.
4. Initial API implementation.
5. Flutter application setup.
6. Backend and mobile integration.
7. ESP32 and backend integration.
8. Offline-first functionality.
9. Synchronization.
10. Full-system testing.
