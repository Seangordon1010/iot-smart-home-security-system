# Project Requirements

## 1. Problem Statement

The project will develop a locally hosted IoT security monitoring system that provides residential security monitoring without depending entirely on cloud services.

The system will use an ESP32-S3-EYE to detect security events and capture images. A locally hosted Node.js backend will process and manage security events, while SQLite will provide local data storage. A Flutter mobile application will provide the user interface for monitoring security events.

## 2. Project Scope

The project will focus on a small-scale residential IoT security monitoring system.

### Included Functionality

The system will include:

* Security-event detection.
* Image capture.
* Wi-Fi communication.
* Local Node.js backend processing.
* SQLite data storage.
* Flutter mobile monitoring.
* User authentication.
* Offline-first mobile functionality.
* Synchronization after connectivity is restored.
* Performance and reliability evaluation.

### Out of Scope

The following functionality is outside the current project scope:

* Professional security monitoring.
* Emergency-service integration.
* Large-scale commercial deployment.
* Facial recognition.

## 3. Functional Requirements

### FR-01: Security Event Detection

The system shall detect a security event using the ESP32-S3-EYE.

### FR-02: Image Capture

The ESP32-S3-EYE shall capture an image when a security event occurs.

### FR-03: Network Communication

The ESP32-S3-EYE shall transmit security-event information to the locally hosted backend using Wi-Fi.

### FR-04: Event Processing

The Node.js backend shall receive and process security-event information.

### FR-05: Data Storage

The system shall store required security-event information using SQLite.

### FR-06: Mobile Monitoring

The Flutter mobile application shall allow users to view security events.

### FR-07: Authentication

The system shall require authentication for protected mobile and backend resources.

### FR-08: Offline Access

The mobile application shall provide access to locally available information when the backend or network is temporarily unavailable.

### FR-09: Synchronization

The system shall synchronize applicable information after connectivity is restored.

## 4. Nonfunctional Requirements

### Performance

The system should provide measurable event-to-application latency.

System resource usage should be measurable during testing.

### Security

Protected backend resources should require authentication.

Security-event information should be protected from unauthorized access.

### Reliability

The system should continue to provide appropriate functionality during temporary network interruptions.

The synchronization process should reliably transfer applicable information after connectivity is restored.

### Usability

The mobile application should provide a clear interface for viewing security events.

### Maintainability

The system should separate the ESP32, backend, database, and mobile application components so that individual components can be developed and tested independently.

## 5. Success Criteria

The completed system will be considered successful if it can demonstrate the following:

1. The ESP32-S3-EYE can detect a security event.
2. The ESP32-S3-EYE can capture an image associated with the event.
3. The event can be transmitted to the backend.
4. The backend can receive and process the event.
5. Event information can be stored in SQLite.
6. The Flutter application can display security events.
7. Authentication can prevent unauthorized access to protected resources.
8. The mobile application can provide appropriate offline functionality.
9. Information can synchronize after connectivity is restored.
10. Performance and reliability measurements can be collected from the completed system.

## 6. Planned Technology Stack

| Component          | Technology   |
| ------------------ | ------------ |
| IoT Hardware       | ESP32-S3-EYE |
| Communication      | Wi-Fi        |
| Backend            | Node.js      |
| Database           | SQLite       |
| Mobile Application | Flutter      |
| Repository         | GitHub       |

## 7. Current Project Status

The requirements, scope, success criteria, hardware configuration, and planned software technologies have been established during the initial project period.

Initial ESP32-S3-EYE testing has also been performed using official ESP32 example code to verify the development environment and board functionality.
