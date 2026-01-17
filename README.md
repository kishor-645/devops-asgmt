# DevOps Full-Stack Application

A complete **Spring Boot + Kafka + MySQL** application deployed on Kubernetes with automated CI/CD via GitHub Actions.

## 📋 Application Overview

This project demonstrates a production-grade DevOps setup with:

- **Spring Boot 3.2.2** - RESTful backend application (Java 17)
- **Apache Kafka 7.5.0** - Message broker (KRaft mode, single node)
- **MySQL 8.0** - Relational database for persistence
- **Kubernetes (Kind)** - Container orchestration
- **Helm** - Infrastructure-as-Code templating
- **GitHub Actions** - Automated CI/CD pipeline

## 🔄 Architecture Flow

```
GitHub Push (main/feature/*)
         ↓
  GitHub Actions CI/CD
         ↓
  Maven Build & Tests
         ↓
  Docker Image Build
         ↓
  Kubernetes Deploy (Dev Namespace)
         ↓
  MySQL + Kafka + Spring Boot
         ↓
  Automated Testing + Public URL
```

## 🔌 How It Uses Kafka & MySQL

### Kafka Message Flow
1. **Producer**: Spring Boot app receives POST request to `/api/messages`
2. **Topic**: Messages published to Kafka topic `messages`
3. **Consumer**: Spring Boot listener consumes messages
4. **Persistence**: Consumer stores messages in MySQL database

### MySQL Database
- **Database**: `devopsdb`
- **Table**: `messages` (auto-created by Spring Data JPA)
- **Connection**: Established via environment variables (DB_HOST, DB_USER, DB_PASS)

### API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/messages` | GET | Retrieve all messages from database |
| `/api/messages` | POST | Send a message (publishes to Kafka) |
| `/health` | GET | Health check endpoint |

## 🚀 How to Run

### Prerequisites
- Docker
- kubectl
- Helm 3+
- Maven 3.8+
- Java 17+

### Local Development (Kind Cluster)

```bash
# 1. Start Kind cluster
kind create cluster --name kind --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
EOF

# 2. Build application
mvn -f app/sample-spring-boot-app/pom.xml clean package

# 3. Build Docker image
docker build -t mycodev2-app:latest -f docker/Dockerfile .

# 4. Load into Kind
kind load docker-image mycodev2-app:latest --name kind

# 5. Create dev namespace
kubectl create namespace dev

# 6. Deploy via Helm
helm install my-stack ./helm-chart -n dev --create-namespace

# 7. Wait for pods to be ready
kubectl get pods -n dev --watch

# 8. Port-forward to access locally
kubectl port-forward -n dev svc/spring-app-service 8080:8080

# 9. Access application
curl http://localhost:8080/api/messages
```

### Automated CI/CD (GitHub Actions)

Push to `main` branch or create a pull request with `feature/*` to trigger:

```bash
git add .
git commit -m "feat: your feature"
git push origin main
```

The pipeline will:
1. Build Maven project
2. Run tests
3. Build Docker image
4. Deploy to Kind cluster
5. Run smoke tests
6. Expose via Cloudflare Tunnel (public URL)
7. Hold for 3-minute testing window

## 🧪 Testing the Application

### From Local Machine (After Port-Forward)

```bash
# Get all messages
curl http://localhost:8080/api/messages

# Send a message
curl -X POST http://localhost:8080/api/messages \
  -H "Content-Type: application/json" \
  -d '{"content":"Hello Kafka!"}'

# Verify message was persisted to MySQL
curl http://localhost:8080/api/messages
```

### From GitHub Actions (Automatic)

The workflow automatically:
1. Tests all endpoints
2. Verifies producer-consumer flow
3. Confirms database persistence
4. Exposes public URL via Cloudflare Tunnel

## 📊 Kubernetes Resources

### Namespaces
- **dev**: Development environment (auto-created)

### Deployments
- **spring-app-service**: Spring Boot application (1 replica)
- **mysql**: MySQL database (1 instance)
- **kafka**: Kafka broker (1 broker, KRaft mode)

### Services
- **spring-app-service**: NodePort (port 30081) + ClusterIP (port 8080)
- **mysql**: ClusterIP (port 3306)
- **kafka**: ClusterIP (port 9092)

### Resource Limits
| Service | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|-------------|----------------|-----------|--------------|
| Spring App | 250m | 256Mi | 500m | 512Mi |
| Kafka | 250m | 512Mi | 500m | 1024Mi |
| MySQL | 250m | 256Mi | 500m | 512Mi |

## 🏥 Health Checks

All services have configured:
- **Startup Probe**: Initial grace period before liveness check
- **Liveness Probe**: Automatically restarts unhealthy pods
- **Readiness Probe**: Only serves traffic when ready

## 📦 Deployment Structure

```
.
├── .github/workflows/
│   └── pipeline.yml              # GitHub Actions CI/CD workflow
├── app/
│   └── sample-spring-boot-app/   # Spring Boot application
│       ├── pom.xml
│       └── src/
├── docker/
│   └── Dockerfile                # Multi-stage Docker build
├── helm-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── app.yaml              # Spring Boot deployment
│       ├── kafka.yaml            # Kafka deployment
│       └── mysql.yaml            # MySQL deployment
├── Devops-Assignment.md          # Assignment requirements
└── README.md                      # This file
```

## 🔐 Security Features

- **Non-root User**: All containers run as non-root (appuser:1000)
- **Resource Limits**: CPU/Memory constraints prevent resource exhaustion
- **Health Probes**: Automatic pod recovery on failure
- **Init Containers**: Ensure dependencies (MySQL, Kafka) ready before startup

## 🚨 Troubleshooting

### Pod not starting?
```bash
# Check pod logs
kubectl logs -n dev <pod-name>

# Describe pod for events
kubectl describe pod -n dev <pod-name>

# Check events in namespace
kubectl get events -n dev
```

### Cannot connect to database?
```bash
# Verify MySQL is ready
kubectl get pod -n dev -l app=mysql

# Check MySQL logs
kubectl logs -n dev -l app=mysql
```

### Kafka consumer not consuming?
```bash
# Verify Kafka is ready
kubectl get pod -n dev -l app=kafka

# Check Kafka logs
kubectl logs -n dev -l app=kafka

# Verify topic exists
kubectl exec -it -n dev <kafka-pod> -- kafka-topics.sh --list --bootstrap-server localhost:9092
```

## 📈 Next Steps (Production Deployment)

To extend this for production:
1. **Multi-region**: Deploy to AWS/Azure with cross-region replication
2. **Monitoring**: Add Prometheus + Grafana for metrics
3. **Logging**: Integrate ELK stack for centralized logging
4. **Auto-scaling**: Configure HPA based on CPU/memory metrics
5. **Database**: Replace in-memory with managed cloud database (RDS/CloudSQL)
6. **Kafka**: Deploy Kafka cluster with replication factor > 1
7. **Security**: Add network policies, RBAC, and pod security policies
8. **Backup**: Implement automated database backup strategy

## 📝 Notes

- **Dev Namespace Only**: Currently configured for dev environment only
- **Single Replica**: All services run on 1 pod (not production-ready)
- **Local Storage**: Kafka and MySQL use emptyDir volumes (data lost on restart)
- **Manual Testing Window**: 3-minute hold for manual verification after deployment

## 🎯 Assignment Requirements Coverage

✅ **Part 1**: GitHub repository structure with clean git flow  
✅ **Part 2**: Fully automated CI/CD pipeline (GitHub Actions)  
✅ **Part 3**: Kubernetes deployment with namespaces, services, resource constraints, health checks  
✅ **Part 4**: MySQL + Kafka integration with environment variables  
✅ **Part 5**: Production thinking built into architecture

---

**Created**: January 2026  
**Technologies**: Spring Boot, Kafka, MySQL, Kubernetes, Helm, GitHub Actions, Docker
