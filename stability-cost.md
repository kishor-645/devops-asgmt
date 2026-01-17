# Stability & Cost Optimization Strategy

## Overview
This document explains the architectural decisions and optimizations made to ensure high stability and cost efficiency in the DevOps assignment.

## Security & Stability Decisions

### 1. Non-Root User in Docker
**Decision:** Application runs as non-root user `appuser` (UID 1000)

**Why:**
- **Security Best Practice:** Prevents container escape vulnerabilities from gaining root privileges
- **Industry Standard:** Kubernetes Pod Security Standards enforce this requirement
- **Compliance:** Meets NIST and CIS Docker Benchmark recommendations

**Implementation:**
```dockerfile
RUN groupadd -g 1000 appuser && useradd -u 1000 -g appuser -m appuser
USER appuser
```

---

## Cost Optimization Strategy

### 1. Kind (Kubernetes in Docker) Cluster
**Decision:** Use Kind cluster on GitHub-hosted runners for CI/CD instead of persistent cloud infrastructure

**Benefits:**
- **Zero Infrastructure Costs:** No long-running cloud instances (no EC2, AKS, EKS bills)
- **Ephemeral Environment:** Cluster spins up for tests, tears down after—charged only for GitHub Actions compute
- **Cost Savings:** ~$200-500/month compared to persistent Kubernetes clusters
- **No Lock-in:** Can switch to any cloud provider without changing pipeline structure

### 2. Resource Limits & Requests
**Decision:** All containers have defined requests and limits

**Why:**
- **Prevents Runaway Costs:** Limits prevent pods consuming unlimited resources
- **Stable Scheduling:** Kubernetes scheduler ensures nodes aren't overbooked
- **Performance Predictability:** Resources are guaranteed available when needed

**Example from helm-chart/templates/app.yaml:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 3. JVM Tuning for Containers
**Decision:** Configure JVM to respect container memory limits

**Implementation (in Dockerfile):**
```dockerfile
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

**Why:**
- **Prevents OOM Kills:** JVM recognizes container limit (512Mi) and uses only 75% = ~384Mi
- **Cost Savings:** No unnecessary memory allocation or pod restarts

---

## Stability Improvements

### 1. Health Checks (Readiness & Liveness Probes)
**Purpose:** Kubernetes auto-restarts unhealthy containers

**Liveness Probe:** Detects crashed/hung applications
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

**Readiness Probe:** Prevents traffic during startup
```yaml
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 5
```

### 2. Init Containers for Dependency Management
**Purpose:** Ensures MySQL and Kafka are ready before Spring Boot starts

**Why `fail-fast=false` is NOT used here:**
- Spring Boot automatically waits for datasource availability
- MySQL must be running before app connects (prevents application crashes)
- This is stable, industry-standard behavior

```yaml
initContainers:
  - name: wait-for-mysql
    image: busybox:1.28
    command: ['sh', '-c', 'until nc -z mysql-service 3306; do echo waiting for mysql; sleep 2; done;']
```

---

## GitHub Actions CI/CD Pipeline

### Cost-Free Benefits:
1. **GitHub-hosted runners:** 2,000 free minutes/month per account
2. **Private repo:** No additional charges
3. **Temporary infrastructure:** No persistent costs

### Stability Features:
1. **Automated testing:** Maven tests on every push
2. **Docker image verification:** Ensures non-root user and layers are correct
3. **Helm deployment validation:** Confirms charts work in clean environment
4. **Smoke tests:** Verifies pods reach Ready state before marking success

---

## Comparison: This Approach vs. Alternatives

| Factor | Kind + GH Actions | Persistent EKS | Persistent GKE |
|--------|------------------|----------------|----------------|
| **Monthly Cost** | ~$0-50 (GH actions) | $150-300 (cluster) | $150-300 (cluster) |
| **Setup Time** | <5 minutes | 30+ minutes | 30+ minutes |
| **Maintenance** | Zero | Patches, upgrades | Patches, upgrades |
| **Proof of Deployment** | ✅ Green checkmark in GitHub | ❌ External link | ❌ External link |
| **Reproducibility** | ✅ Same env every time | ⚠️ Drift over time | ⚠️ Drift over time |

---

## Final Checklist

- ✅ Dockerfile uses non-root user `appuser` (UID 1000)
- ✅ JVM configured with `MaxRAMPercentage=75.0` for container limits
- ✅ Helm chart includes health probes (liveness & readiness)
- ✅ Init containers ensure dependency ordering
- ✅ GitHub Actions pipeline runs on Kind cluster
- ✅ Zero persistent infrastructure costs
- ✅ All logs visible in GitHub Actions tab
- ✅ Reproducible deployment on every push

---

## How to Verify

1. **Push to main branch:**
   ```bash
   git add .
   git commit -m "feat: ci/cd pipeline with stability & cost optimization"
   git push origin main
   ```

2. **View pipeline execution:**
   - Navigate to GitHub repository
   - Click **Actions** tab
   - Watch pipeline build → test → deploy → verify in real-time

3. **Check deployment logs:**
   - Expand each step to see Maven output, Docker build logs, Helm deployment
   - Verify "Waiting for app to be ready..." completes successfully
   - Confirm service endpoints are accessible

---

## Conclusion

This DevOps assignment demonstrates **production-grade practices** at minimal cost:
- Security hardening (non-root containers)
- Cost optimization (ephemeral infrastructure)
- Reliability (health checks, init containers)
- Auditability (GitHub Actions logs)

This approach scales from side projects to enterprise deployments without architectural changes.
