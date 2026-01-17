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

---

## CI/CD Pipeline (GitHub Actions)

This project includes a **fully automated CI/CD pipeline** that verifies the entire stack on every push.

### What the Pipeline Does:

1. **Compiles & Tests:** Runs Maven clean package on the Spring Boot application
2. **Builds Docker Image:** Creates non-root container image with JVM optimization
3. **Spins Up Kubernetes Cluster:** Creates temporary Kind cluster on GitHub-hosted runners
4. **Deploys via Helm:** Installs the complete stack (MySQL, Kafka, App) into the `dev` namespace
5. **Verifies Deployment:** Runs smoke tests to confirm pods are ready and services are accessible

### How to Trigger:

```bash
git add .
git commit -m "your commit message"
git push origin main
```

### View Pipeline Logs:

1. Go to your GitHub repository
2. Click the **Actions** tab at the top
3. Click the latest workflow run to see live logs
4. Expand each step to see detailed output (Maven build, Docker build, Helm deployment, Kubernetes verification)

### Why This Approach?

- **Zero Infrastructure Costs:** Uses ephemeral Kind clusters (no persistent cloud instances)
- **Reproducible:** Proves your code works in a clean environment
- **Auditable:** All logs and artifacts visible in GitHub
- **Fast Feedback:** Pipeline completes in ~5-10 minutes

### Additional Documentation:

For details on **stability improvements**, **cost optimization**, and the **reasoning behind architectural decisions**, see [stability-cost.md](./stability-cost.md).

---