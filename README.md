# README.md
# DevOps Spring Boot Application

This is a production-grade Spring Boot application demonstrating DevOps best practices with Kafka, MySQL, and containerization.

## Project Structure

```
/app
  └── sample-spring-boot-app
      ├── pom.xml
      └── src/...
/docker
  ├── Dockerfile
  └── docker-compose.yml
/k8s
  ├── dev
  │   ├── app-deploy.yaml
  │   ├── mysql-deploy.yaml
  │   └── kafka-deploy.yaml
  └── qa
README.md
```

## Components

### Producer-Consumer Architecture
- **Producer**: REST API endpoint sends data to Kafka Topic
- **Consumer**: Kafka listener picks up messages and saves to MySQL
- **Verification**: REST API endpoint retrieves data from MySQL

### Technology Stack
- Spring Boot 3.2.2
- Java 17
- Apache Kafka
- MySQL 8.0
- Docker & Docker Compose
- Kubernetes (K8s manifests for dev/qa)

## Quick Start with Docker Compose

Navigate to `/docker` directory:

```bash
cd docker
docker-compose up --build -d
```

## API Endpoints

**Produce a Message:**
```bash
curl -X POST -H "Content-Type: text/plain" -d "Hello DevOps World" http://localhost:8081/api/messages
```

**Retrieve Messages:**
```bash
curl http://localhost:8081/api/messages
```

## Kubernetes Deployment

Kubernetes manifests are available in `/k8s` directory for both dev and qa environments.

# Produce
curl -X POST -H "Content-Type: text/plain" -d "K8s_Test_Message" http://localhost:8081/api/messages

# Consume
curl http://localhost:8081/api/messages