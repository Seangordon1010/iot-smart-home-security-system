# IoT Smart Home Security System

## Project Overview

This project is designed to be a small-scale IoT smart-home security monitoring system created to provide local residential security monitoring through a mobile application.

The system will use an ESP32-S3-EYE development board to detect security events and capture images. A locally hosted Node.js backend will receive and manage security events and communicate with a SQLite database. A Flutter mobile application will allow users to monitor security events and access available information when the system is offline.

## System Components

The planned system consists of the following components:

* **ESP32-S3-EYE** - IoT hardware used for security-event detection and image capture.
* **Node.js Backend** - Locally hosted backend responsible for receiving and managing security events.
* **SQLite Database** - Local database used to store system information and security events.
* **Flutter Mobile Application** - Mobile interface used to monitor security events.
* **Wi-Fi Network** - Communication between the ESP32-S3-EYE and the local backend.

## Planned Architecture


ESP32-S3-EYE
      |
      | Wi-Fi
      v
Node.js Backend
      |
      v
SQLite Database
      ^
      |
      | API
      v
Flutter Mobile Application

The detailed architecture and communication design will be documented in the `docs` directory.

## Project Goals

The main goals of the project are to:

1. Detect security and motion events using the ESP32-S3-EYE.
2. Collect images associated with security events.
3. Send security-event information to a locally hosted backend.
4. Store this security information using SQLite.
5. Create and provide a Flutter mobile interface for monitoring.
6. Support authenticated access to protected resources.
7. Provide offline-first mobile functionality.
8. Synchronize information after connectivity is restored.
9. Evaluate system performance, reliability, and synchronization behavior.

## Project Scope

The project focuses on local IoT security monitoring for a small-scale residential environment.

The project does not include anything that bigger systems would have such as:

* Professional security monitoring.
* Emergency-service integration.
* Large-scale commercial deployment.
* Facial recognition.

## Evaluation

The completed system will be evaluated using measurements and tests from these categories:

* Event-to-application latency.
* CPU utilization.
* RAM utilization.
* Network bandwidth.
* Event delivery reliability.
* Network interruption behavior.
* Synchronization reliability.
* Authentication and access control.

## Repository Structure


docs/       Project documentation
esp32/      ESP32-S3-EYE development files
backend/    Node.js backend files
mobile/     Flutter mobile application files


## Project Status

The project is currently in the initial development stage.

Week 1 work done so far:

* Problem statement.
* Project scope.
* Functional requirements.
* Nonfunctional requirements.
* Success criteria.
* Initial hardware configuration.
* Development environment setup.
* GitHub repository setup.
* Initial ESP32-S3-EYE testing using official ESP32 example code.
