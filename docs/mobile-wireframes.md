# Mobile Interface Wireframes

## 1. Overview

The Flutter mobile application will be used for the user interface for monitoring the IoT smart-home security system.

The initial interface will focus on authentication, viewing security events, viewing event details, and handling offline information.

## 2. Planned Screens

The initial application design will have the following screens:

1. Login Screen
2. Security Events Screen
3. Event Details Screen
4. Offline Status Indicator
5. Synchronization Status

## 3. Login Screen

The login screen will let authorized users enter their account information.

### Planned Elements

* Username field.
* Password field.
* Login button.
* Authentication error message when needed.

```text
+--------------------------------+
|       Smart Home Security      |
|                                |
| Username                       |
| [________________________]     |
|                                |
| Password                       |
| [________________________]     |
|                                |
|        [ Login ]               |
|                                |
| Authentication message         |
+--------------------------------+
```

## 4. Security Events Screen

The security events screen will show any available security events.

### Planned Elements

* Application title.
* Current connection status.
* List of security events.
* Event type.
* Event timestamp.
* Event status.
* Navigation to event details.

```text
+--------------------------------+
| Security Events        ONLINE  |
+--------------------------------+
|                                |
| Motion Event                   |
| September 25, 2026  3:30 PM   |
| Status: New                    |
|                                |
+--------------------------------+
|                                |
| Motion Event                   |
| September 25, 2026  2:45 PM   |
| Status: Viewed                 |
|                                |
+--------------------------------+
```

## 5. Event Details Screen

The event details screen will show any additional information about a selected security event.

### Planned Elements

* Event type.
* Date and time.
* Device identifier.
* Captured image.
* Event status.

```text
+--------------------------------+
| Event Details                  |
+--------------------------------+
|                                |
| Event: Motion                  |
| Device: ESP32-S3-EYE-01       |
| Time: 3:30 PM                  |
| Status: New                    |
|                                |
|       [ Captured Image ]       |
|                                |
+--------------------------------+
```

## 6. Offline State

The application should tells users when the backend is unavailable.

Previously available local information should still be accessed when possible.

```text
+--------------------------------+
| Security Events       OFFLINE  |
+--------------------------------+
|                                |
| Previously downloaded events   |
| remain available.              |
|                                |
| Last synchronized:             |
| September 25, 2026 3:20 PM     |
|                                |
+--------------------------------+
```

## 7. Synchronization State

The application should provide an indication when synchronization is occurring.

Possible states include:

* Syncing.
* Synchronized.
* Synchronization required.
* Synchronization failed.

```text
+--------------------------------+
| Security Events                |
+--------------------------------+
|                                |
| Synchronizing...               |
|                                |
| [====================]         |
|                                |
+--------------------------------+
```

## 8. Navigation

The initial navigation flow is:

```text
Login
  |
  v
Security Events
  |
  v
Event Details
```

Connection and synchronization status will be visible within the right screens.

## 9. Offline-First Considerations

The interface should be able to tell the difference between information available locally and information that requires a backend connection.

The application should not remove  any information thats been previously syncronized just because the backend becomes unavailable.

The interface should communicate connection and synchronization status clearly to the user.

## 10. Accessibility and Usability Considerations

The mobile interface should use:

* Clear labels.
* Readable text.
* Consistent navigation.
* Clear status messages.
* Distinguishable online and offline states.
* Simple interaction flows.

The interface will be refined during implementation and testing.
