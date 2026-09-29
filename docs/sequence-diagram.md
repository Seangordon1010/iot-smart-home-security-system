# Security Event Sequence Diagram

## 1. Purpose

This sequence shows the planned flow of a security event from detection by the ESP32-S3-EYE through storage by the backend and display in the Flutter mobile application.

## 2. Security Event Flow

```text
User          ESP32-S3-EYE       Node.js Backend       SQLite       Flutter App
 |                  |                    |                |              |
 |                  |                    |                |              |
 |                  | Detect Event       |                |              |
 |                  |------------------->|                |              |
 |                  | Capture Image      |                |              |
 |                  |                    |                |              |
 |                  | Send Event/Image   |                |              |
 |                  |------------------->|                |              |
 |                  |                    | Validate Data  |              |
 |                  |                    |--------------->|              |
 |                  |                    | Store Event    |              |
 |                  |                    |--------------->|              |
 |                  |                    |<---------------|              |
 |                  |                    | Storage Result |              |
 |                  |                    |                |              |
 |                  |                    |                |              |
 |                  |                    |                |   Request    |
 |                  |                    |<------------------------------|
 |                  |                    |                |              |
 |                  |                    | Retrieve Data  |              |
 |                  |                    |--------------->|              |
 |                  |                    |<---------------|              |
 |                  |                    | Event Data     |              |
 |                  |                    |------------------------------>|
 |                  |                    |                |              |
 |                  |                    |                |       Display|
 |<-----------------------------------------------------------------------|
 |                         Security Event                                |
```

## 3. Sequence Description

### Step 1: Event Detection

The ESP32-S3-EYE picks up on a security event.

### Step 2: Image Capture

The ESP32-S3-EYE captures an image from the ongoing event.

### Step 3: Event Transmission

The ESP32-S3-EYE sends the event information and usable image information to the Node.js backend over the local Wi-Fi network.

### Step 4: Backend Processing

The Node.js backend receives the request and accepts the incoming information.

### Step 5: Database Storage

The backend stores the event information in the SQLite database.

### Step 6: Mobile Request

The authenticated Flutter application requests any available security-event information from the Node.js backend.

### Step 7: Database Retrieval

The backend retrieves the requested information from SQLite.

### Step 8: Response

The backend sends the requested event information to the Flutter application.

### Step 9: Display

The Flutter application displays any available security event and associated information to the user.

## 4. Offline Scenario

If the Flutter application can't communicate with the backend, the application should use information that has already been stored locally on the mobile device.

```text
Flutter App
    |
    | Backend unavailable
    v
Local Mobile Data
    |
    v
Display Previously Available Events
```

After connectivity is restored, the application will perform the planned synchronization process.

## 5. Synchronization Scenario

The planned synchronization flow is:

1. The mobile application detects that backend connectivity has been restored.
2. The application identifies locally stored information that requires synchronization.
3. The application communicates with the backend.
4. The backend processes the synchronization request.
5. Applicable information is stored or updated.
6. The mobile application's local information is updated.
