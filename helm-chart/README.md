# Helm Chart - DevOps Stack

Deploy Spring Boot, Kafka, and MySQL to any Kubernetes cluster.

## Quick Start

### Install
```bash
helm install my-stack . -n dev --create-namespace
```

### Verify
```bash
kubectl get pods -n dev
kubectl get svc -n dev
```

### Uninstall
```bash
helm uninstall my-stack -n dev
```

---

## Configuration

Edit `values.yaml` to customize:

```yaml
namespace: dev              # Kubernetes namespace
replicaCount: 1            # Pod replicas

app:
  image: mycodev2-app      # Docker image name
  tag: latest              # Image tag
  port: 8080               # Container port
  memory: 256Mi            # Memory limit
  cpu: 250m                # CPU limit

kafka:
  port: 9092               # Kafka broker port
  memory: 1Gi              # Memory limit
  cpu: 250m                # CPU limit

mysql:
  port: 3306               # MySQL port
  memory: 512Mi            # Memory limit
  cpu: 250m                # CPU limit
  password: password       # Root password
```

---

## Customization Examples

### Deploy to specific namespace
```bash
helm install my-stack . -n production --create-namespace
```

### Override values
```bash
helm install my-stack . -n dev \
  --set app.tag=v1.2.3 \
  --set replicaCount=3
```

### Using custom image registry
```bash
helm install my-stack . -n dev \
  --set app.image=myregistry/myapp \
  --set app.tag=1.0.0
```

---

## Included Resources

- **Spring Boot Deployment** - REST API application
- **MySQL Deployment** - Database with persistent storage
- **Kafka Deployment** - Message broker (KRaft mode)
- **Services** - ClusterIP and NodePort
- **ConfigMaps** - Environment configuration
- **Probes** - Health checks (startup, liveness, readiness)

---

## Environment Variables

Automatically configured for all services:

### Spring Boot
- `DB_HOST` - MySQL host
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASS` - Database password
- `KAFKA_BROKER` - Kafka endpoint

### MySQL
- `MYSQL_DATABASE` - Database to create
- `MYSQL_ROOT_PASSWORD` - Root password

### Kafka
- `KAFKA_BROKER_ID` - Broker ID
- `KAFKA_ADVERTISED_LISTENERS` - Advertised endpoints
- `CLUSTER_ID` - Cluster identifier

---

## Troubleshooting

### Check pod status
```bash
kubectl get pods -n dev
kubectl describe pod -n dev <pod-name>
```

### View logs
```bash
kubectl logs -n dev -l app=spring-app
kubectl logs -n dev -l app=mysql
kubectl logs -n dev -l app=kafka
```

### Check services
```bash
kubectl get svc -n dev
```

### Access application
```bash
# Port-forward to local
kubectl port-forward -n dev svc/spring-app-service 8080:8080

# Test endpoint
curl http://localhost:8080/api/messages
```

---

## Resource Limits

| Component | CPU | Memory |
|-----------|-----|--------|
| Spring Boot | 250m | 256Mi |
| Kafka | 250m | 1Gi |
| MySQL | 250m | 512Mi |

Adjust in `values.yaml` as needed.

