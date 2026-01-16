# CI/CD - Jenkins Configuration

This directory contains all the necessary files to run Jenkins for automated CI/CD of the DevOps project.

## Files

### `Dockerfile.jenkins`
Custom Jenkins Docker image with pre-installed tools:
- Docker CLI (for building and pushing container images)
- kubectl (for deploying to Kubernetes clusters)
- Helm (for Kubernetes package management)

### `docker-compose-jenkins.yml`
Docker Compose configuration that:
- Builds the custom Jenkins image
- Mounts the Docker socket for Docker-in-Docker capability
- Mounts the local kubeconfig for Kind cluster access
- Exposes Jenkins on port 8082

### `start-jenkins.sh`

Quick startup script:
```bash
cd ci
chmod +x start-jenkins.sh
./start-jenkins.sh
```

This script:
- Verifies Docker is running
- Verifies Kind cluster exists
- Sets proper Docker permissions
- Starts the Jenkins container

### Using Docker Compose directly
```bash
cd ci
docker-compose -f docker-compose-jenkins.yml up -d --build
```

## Accessing Jenkins

1. Open **http://localhost:8082** in your browser
2. Wait for Jenkins to fully start (check logs)
3. Unlock with the initial password from logs:
   ```bash
   docker logs jenkins-ci | grep -A 7 "Jenkins initial setup"
   ```

## How It Works

1. **Jenkins Container** runs with:
   - Docker socket mounted: `/var/run/docker.sock` → Docker daemon on host
   - Kubeconfig mounted: Local cluster config → Access to Kind cluster
   - Port 8082 exposed for web UI

2. **Pipeline Execution**:
   - Jenkins pulls code from repository
   - Maven builds Spring Boot application
   - Docker builds container image using host Docker daemon
   - Kind cluster loads the image
   - Helm deploys the full stack (MySQL, Kafka, Spring app)

3. **Security**:
   - Kubeconfig is read-only
   - Jenkins isolated in container with minimal permissions
   - No credentials stored in git (use Jenkins Credentials store)

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│         Docker Desktop / Host           │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Jenkins Container (8082)      │  │
│  │  - Docker CLI                    │  │
│  │  - kubectl                       │  │
│  │  - Helm                          │  │
│  │                                  │  │
│  │  ┌─────────────────────────────┐ │  │
│  │  │  Pipeline Execution:        │ │  │
│  │  │  1. Maven Build             │ │  │
│  │  │  2. Docker Build            │ │  │
│  │  │  3. Kind Load Image         │ │  │
│  │  │  4. Helm Deploy             │ │  │
│  │  │  5. Smoke Test              │ │  │
│  │  └─────────────────────────────┘ │  │
│  └───────┬──────────────────────┬────┘  │
│          │                      │       │
│  ┌───────▼──────────┐  ┌────────▼────┐ │
│  │  Docker Daemon   │  │  Kind       │ │
│  │  (builds image)  │  │  Cluster    │ │
│  │  (8082->8080)    │  │  (deployed) │ │
│  └──────────────────┘  └─────────────┘ │
└─────────────────────────────────────────┘
```

## Troubleshooting

### Jenkins won't start
```bash
# Check logs
docker logs jenkins-ci

# Check if port 8082 is available
lsof -i :8082
```

### Docker build stage fails
```bash
# Verify Docker socket is mounted
docker exec jenkins-ci docker ps

# Fix permissions (Linux/macOS)
sudo chmod 666 /var/run/docker.sock
```

### Kubeconfig not accessible
```bash
# Check if kubeconfig is mounted
docker exec jenkins-ci ls -la /var/jenkins_home/.kube/config

# Verify KUBECONFIG env var is set
docker exec jenkins-ci echo $KUBECONFIG
```

## Related Files

- **Root `Jenkinsfile`**: Pipeline definition (build stages, deployment logic)
- **Root `docker/Dockerfile`**: Application image definition
- **Root `helm-chart/`**: Kubernetes deployment manifests
- **Root `JENKINS_SETUP.md`**: Detailed configuration guide

## Next Steps

1. Start Jenkins using the script above
2. Configure the pipeline job in Jenkins UI
3. Trigger the first build
4. Monitor the pipeline execution
5. Verify deployment to Kind cluster

See `../JENKINS_SETUP.md` for complete configuration instructions.
