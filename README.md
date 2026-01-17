# DevOps Full-Stack Application

Spring Boot application with Kafka and MySQL deployed on Kubernetes.

## What is this app?

A full-stack application demonstrating:
- **Spring Boot** REST API (Java 17)
- **Kafka** message broker (KRaft mode)
- **MySQL** database
- **Kubernetes** deployment (Kind cluster)
- **Helm** templating for infrastructure

## How it works

```
Client Request → Spring Boot API → Kafka Producer
                                      ↓
                                  Message Queue
                                      ↓
                              Kafka Consumer
                                      ↓
                                 MySQL Database
```

**Flow:**
1. POST message to `/api/messages` → Spring Boot receives it
2. Message published to Kafka topic
3. Consumer listens and saves to MySQL
4. GET `/api/messages` → retrieves from database

---

## Testing Options

### Option 1: GitHub Actions Pipeline (Automated)

Push to main branch to trigger automatic deployment:

```bash
git add .
git commit -m "your changes"
git push origin main
```

**What happens:**
- Maven builds the project
- Docker image created
- Kind cluster deployed
- Helm installs all services
- Public URL exposed via Cloudflare Tunnel
- 3-minute testing window

Check **GitHub Actions** tab in your repo for logs and public URL.

---

### Option 2: Local Setup with Kind & Helm

**Quick setup:**

```bash
bash setup-local.sh
```

The script will:
1. Build Docker image
2. Create Kind cluster
3. Load image to Kind
4. Deploy with Helm
5. Port-forward to localhost:8080
6. Test endpoints

Application available at: `http://localhost:8080/api/messages`

**Manual setup:**

```bash
# Build image
docker build -t mycodev2-app:latest -f docker/Dockerfile .

# Create cluster
kind create cluster --name kind

# Load image
kind load docker-image mycodev2-app:latest --name kind

# Deploy
kubectl create namespace dev
helm install my-stack ./helm-chart -n dev --create-namespace

# Wait for pods
kubectl get pods -n dev --watch

# Port-forward
kubectl port-forward -n dev svc/spring-app-service 8080:8080

# In another terminal - test
curl http://localhost:8080/api/messages
```

**Helm chart configuration:**

See `helm-chart/README.md` for custom values and advanced setup.

---

## Kubernetes Architecture

### Namespaces
- `dev` - Development environment

### Deployments & Services

| Service | Type | Port | Purpose |
|---------|------|------|---------|
| spring-app-service | NodePort/ClusterIP | 8080 | REST API |
| mysql | ClusterIP | 3306 | Database |
| kafka | ClusterIP | 9092 | Message Broker |

### Resource Limits
- Spring App: 256Mi memory, 250m CPU
- Kafka: 1Gi memory, 250m CPU
- MySQL: 512Mi memory, 250m CPU

### Health Checks
All services have:
- **Startup Probe** - allows initialization time
- **Liveness Probe** - auto-restart if unhealthy
- **Readiness Probe** - only route traffic when ready

---

## File Structure

```
.github/workflows/
├── pipeline.yml              # GitHub Actions CI/CD
app/
├── sample-spring-boot-app/   # Spring Boot source code
│   ├── pom.xml
│   └── src/
docker/
├── Dockerfile                # Multi-stage build
helm-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── app.yaml              # Spring Boot deployment
    ├── kafka.yaml            # Kafka deployment
    └── mysql.yaml            # MySQL deployment
README.md                      # This file
```

---

## Troubleshooting

**Pods not starting?**
```bash
kubectl logs -n dev <pod-name>
kubectl describe pod -n dev <pod-name>
```

**Can't connect to database?**
```bash
# Check MySQL status
kubectl get pod -n dev -l app=mysql
kubectl logs -n dev -l app=mysql
```

**Message not appearing in database?**
```bash
# Check Kafka
kubectl get pod -n dev -l app=kafka
kubectl logs -n dev -l app=kafka

# Check Spring Boot app
kubectl logs -n dev -l app=spring-app
```

---

## Cleanup

### Local Setup
```bash
kind delete cluster --name kind
```

### GitHub Actions
- Automatically cleans up after workflow completes
- Rerun workflow to test again

---

## Technologies

- Java 17
- Spring Boot 3.2.2
- Kafka 7.5.0
- MySQL 8.0
- Kubernetes
- Helm 3
- Docker
- GitHub Actions
