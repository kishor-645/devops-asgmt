# Jenkins Setup & Pipeline Creation Guide

Complete step-by-step guide to start Jenkins, configure the profile, and create a pipeline job using the current Jenkinsfile.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Start Jenkins](#step-1-start-jenkins)
3. [Step 2: Access Jenkins](#step-2-access-jenkins)
4. [Step 3: Configure Jenkins Profile](#step-3-configure-jenkins-profile)
5. [Step 4: Create Pipeline Job](#step-4-create-pipeline-job)
6. [Step 5: Run Your First Build](#step-5-run-your-first-build)
7. [Troubleshooting](#troubleshooting)
8. [Get Admin Password](#get-admin-password)

---

## Prerequisites

Before starting, ensure you have:

- ✅ Docker installed and running
- ✅ Docker Compose installed
- ✅ Kind cluster running (for Kubernetes deployment)
- ✅ kubectl installed and configured
- ✅ Helm 3.x installed
- ✅ Maven installed (for local builds)
- ✅ Git repository accessible

**Verify prerequisites:**
```bash
docker --version
docker-compose --version
kind get clusters
kubectl version
helm version
mvn --version
```

---

## Step 1: Start Jenkins

### 1.1 Navigate to CI Directory

```bash
cd ci
```

### 1.2 Start Jenkins using Docker Compose

```bash
docker-compose -f docker-compose-jenkins.yml up -d --build
```

This will:
- Build the custom Jenkins Docker image
- Start the Jenkins container
- Mount Docker socket for Docker-in-Docker
- Mount kubeconfig for Kubernetes access
- Expose Jenkins on port 8082

### 1.3 Wait for Jenkins to Start

Jenkins takes 2-3 minutes to fully start. Monitor the startup:

```bash
# Watch logs in real-time
docker logs -f jenkins-ci
```

Wait until you see output like:
```
Jenkins initial setup is required. An admin user has been created and a password generated.
*****
<32-character-password>
*****
```

### 1.4 Verify Jenkins is Running

```bash
# Check container status
docker ps | grep jenkins-ci

# Test Jenkins API
curl http://localhost:8082/api/json
```

---

## Step 2: Access Jenkins

### 2.1 Open Jenkins in Browser

```
URL: http://localhost:8082
```

You should see the **Jenkins Unlock** page.

### 2.2 Get the Admin Password

**Using Helper Script**
```bash
chmod +x ci/get-jenkins-password.sh
./ci/get-jenkins-password.sh
```

### 2.3 Unlock Jenkins

1. Open browser: `http://localhost:8082`
2. Paste the admin password
3. Click **Continue**

---

## Step 3: Configure Jenkins Profile

### 3.1 Initial Setup Wizard

Jenkins will show the **Getting Started** page with two options:

**Select Plugins**
- Click **Select plugins to install**
- Choose from available plugins

### 3.2 Required Plugins for Pipeline

Ensure these plugins are installed. Go to:
**Manage Jenkins → Plugin Manager → Available**

Search and install:
- ✅ **Pipeline** (workflow-aggregator)
- ✅ **Git plugin** (git)
- ✅ **Docker plugin** (docker-plugin)
- ✅ **Kubernetes plugin** (kubernetes)

To install:
1. Search for plugin name
2. Check the checkbox
3. Click **Install without restart**
4. Plugins will install in background

### 3.3 Create Admin User

After plugin installation, you'll be prompted to create an admin user:

| Field | Value |
|-------|-------|
| **Username** | admin |
| **Password** | admin@123 |
| **Full name** | Jenkins Admin |
| **Email** | admin@example.com |

Or use the initial admin user if you prefer.

### 3.4 Configure Jenkins URL

1. Go to **Manage Jenkins → Configure System**
2. Find **Jenkins Location** section
3. Set **Jenkins URL** to: `http://localhost:8082/`
4. Click **Save**

### 3.5 Configure Git (Optional but Recommended)

1. Go to **Manage Jenkins → Configure System**
2. Scroll to **Git** section
3. Set **Path to Git executable**: `/usr/bin/git`
4. Click **Save**

### 3.6 Configure Docker (Optional)

1. Go to **Manage Jenkins → Configure System**
2. Scroll to **Docker** section
3. Set **Docker Host URI**: `unix:///var/run/docker.sock`
4. Click **Save**

---

## Step 4: Create Pipeline Job

### 4.1 Create New Job

1. Click **Create a job** (or **New Item** on sidebar)
2. Enter job name: **`devops-pipeline`**
3. Select **Pipeline** job type
4. Click **OK**

### 4.2 Configure Pipeline Job

You're now on the job configuration page.

#### 4.2.1 General Configuration

- **Description**: (optional)
  ```
  Spring Boot Deployment Pipeline
  Automatically builds, containerizes, and deploys to Kubernetes
  ```

#### 4.2.2 Build Triggers (Optional)

Leave as default (manual trigger) or enable:
- **GitHub hook trigger for GITScm polling** (if using GitHub)
- **Poll SCM** (manual polling schedule)

#### 4.2.3 Advanced Project Options

Leave defaults.

#### 4.2.4 Pipeline Configuration

This is the most important section.

**Option A: Pipeline script from SCM** (Recommended)

1. Under **Definition**, select **Pipeline script from SCM**
2. Select **Git** as SCM
3. Configure Git:

| Field | Value |
|-------|-------|
| **Repository URL** | Your Git repo URL |
| **Branch** | `*/main` or `*/master` |
| **Script Path** | `Jenkinsfile` |

Example repository URL:
```
https://github.com/yourusername/mycodev2.git
```

4. Leave other Git options as default
5. Click **Save**

## Step 5: Run Your First Build

### 5.1 Trigger Build

1. Open your pipeline job: `http://localhost:8082/job/devops-pipeline`
2. Click **Build Now** (on left sidebar)

Jenkins will start executing the pipeline.

### 5.2 Monitor Build Progress

1. You'll see a build appear under **Build History**
2. Click the build number to view console output
3. Watch real-time logs as pipeline executes

### 5.3 Pipeline Stages

The pipeline will execute 5 stages:

| Stage | What It Does | Duration |
|-------|--------------|----------|
| **Cleanup** | Maven clean | ~10 sec |
| **Maven Build & Test** | Compile and package | ~1-2 min |
| **Build Docker Image** | Create container | ~30-60 sec |
| **Deploy to Kind** | Load image and deploy with Helm | ~1-2 min |
| **Smoke Test** | Verify pods and HPA | ~10 sec |

**Total build time: ~5-10 minutes** (first build takes longer)

### 5.4 Verify Deployment

After successful build, verify pods are running:

```bash
# Check pods in dev namespace
kubectl get pods -n dev

# Check services
kubectl get svc -n dev

# Check HPA
kubectl get hpa -n dev

# View app logs
kubectl logs -f deployment/spring-app -n dev
```

### 5.5 Access Your Application

Port forward to access the Spring Boot app:

```bash
kubectl port-forward svc/spring-app-service 8080:8080 -n dev
```

Open browser: `http://localhost:8080`

---

## Build Environment & Variables

The pipeline uses these environment variables:

```groovy
environment {
    DOCKER_IMAGE = "mycodev2-app"      // Docker image name
    NAMESPACE = "dev"                   // Kubernetes namespace
    CHART_PATH = "helm-chart"           // Helm chart path
}
```

### Modifying Variables

To change these values:

1. Go to job configuration
2. Click **Pipeline** section
3. Find the `environment` block
4. Modify values
5. Click **Save**

Or edit the Jenkinsfile directly in your Git repository.

---

## Understanding the Pipeline

### Stage: Cleanup
```groovy
sh "mvn -f app/sample-spring-boot-app/pom.xml clean"
```
- Removes previous build artifacts
- Prepares fresh build

### Stage: Maven Build & Test
```groovy
sh "mvn -f app/sample-spring-boot-app/pom.xml package -DskipTests"
```
- Compiles Java source code
- Packages into JAR file
- Skips unit tests for speed (change `-DskipTests` to run tests)

### Stage: Build Docker Image
```groovy
sh "docker build -t ${DOCKER_IMAGE}:latest -f docker/Dockerfile ."
```
- Reads `docker/Dockerfile`
- Creates container image
- Tags as `mycodev2-app:latest`

### Stage: Deploy to Kind
```groovy
sh "kind load docker-image ${DOCKER_IMAGE}:latest"
sh "helm upgrade --install my-stack ${CHART_PATH} -n ${NAMESPACE} --create-namespace"
```
- Loads Docker image into Kind cluster
- Deploys using Helm charts
- Creates namespace if needed

### Stage: Smoke Test
```groovy
sh "kubectl get pods -n ${NAMESPACE}"
sh "kubectl get hpa -n ${NAMESPACE}"
```
- Verifies pods are running
- Verifies HPA is active

---

## Troubleshooting

### Issue: Build fails at Maven stage

**Error**: `mvn: command not found`

**Solution**:
```bash
# Verify Maven is installed
mvn --version

# If not installed, install Maven
brew install maven  # macOS
apt-get install maven  # Linux
```

### Issue: Build fails at Docker stage

**Error**: `Cannot connect to Docker daemon`

**Solution**:
```bash
# Ensure Docker is running
docker ps

# Check Docker socket mount in docker-compose
docker exec jenkins-ci ls -l /var/run/docker.sock

# Restart Jenkins
docker-compose -f docker-compose-jenkins.yml restart
```

### Issue: Build fails at Kubernetes stage

**Error**: `kind: command not found` or cluster not found

**Solution**:
```bash
# Verify Kind is installed
kind version

# Verify Kind cluster exists
kind get clusters

# If cluster doesn't exist, create it
kind create cluster
```

### Issue: Build fails at Helm stage

**Error**: `helm: command not found`

**Solution**:
```bash
# Verify Helm is installed
helm version

# If not installed, install Helm
brew install helm  # macOS
# For Linux, see: https://helm.sh/docs/intro/install/
```

### Issue: Insufficient privileges for Docker

**Error**: `permission denied while trying to connect to Docker daemon`

**Solution**:
```bash
# Add jenkins user to docker group
docker exec jenkins-ci usermod -aG docker jenkins

# Restart Jenkins
docker-compose -f docker-compose-jenkins.yml restart
```

### Issue: Cannot access http://localhost:8082

**Error**: `Connection refused`

**Solution**:
```bash
# Check if Jenkins container is running
docker ps | grep jenkins-ci

# Check if port 8082 is in use
lsof -i :8082

# Check Jenkins logs
docker logs jenkins-ci

# Restart Jenkins
docker-compose -f docker-compose-jenkins.yml restart
```

### Issue: Git clone fails

**Error**: `fatal: could not read Username`

**Solution**: 
Configure Git credentials in Jenkins:
1. Go to **Manage Jenkins → Manage Credentials**
2. Click **System → Global credentials**
3. Click **Add Credentials**
4. Select **Username and password**
5. Enter GitHub username and personal token
6. Set Credential ID: `github-credentials`
7. Click **Create**

Then update pipeline job to use credentials:
```groovy
git url: 'https://github.com/user/repo.git', 
    credentialsId: 'github-credentials', 
    branch: 'main'
```

---

## Get Admin Password

### Quick Commands

**From Docker logs:**
```bash
docker logs jenkins-ci | grep -A 1 "Jenkins initial setup"
```

**From container file:**
```bash
docker exec jenkins-ci cat /var/jenkins_home/secrets/initialAdminPassword
```

**Using helper script:**
```bash
chmod +x ci/get-jenkins-password.sh
./ci/get-jenkins-password.sh
```

---

## Complete Quick Reference

### Start Jenkins
```bash
cd ci
docker-compose -f docker-compose-jenkins.yml up -d --build
```

### Get Admin Password
```bash
docker logs jenkins-ci | grep -A 1 "Jenkins initial setup"
```

### Access Jenkins
```
http://localhost:8082
```

### View Logs
```bash
docker logs -f jenkins-ci
```

### Stop Jenkins
```bash
docker-compose -f docker-compose-jenkins.yml down
```

### Reset Jenkins (DELETE ALL DATA)
```bash
docker-compose -f docker-compose-jenkins.yml down -v
rm -rf jenkins_home
```

---

## Post-Build Checklist

After successful build, verify:

- [ ] Jenkins job executed successfully
- [ ] Docker image was built
- [ ] Image loaded into Kind cluster
- [ ] Helm deployment succeeded
- [ ] Pods are running: `kubectl get pods -n dev`
- [ ] Services are available: `kubectl get svc -n dev`
- [ ] HPA is configured: `kubectl get hpa -n dev`
- [ ] Application accessible: `http://localhost:8080` (after port-forward)

---

## Next Steps

1. ✅ Start Jenkins (`docker-compose up`)
2. ✅ Configure Jenkins profile (unlock + plugins)
3. ✅ Create pipeline job (`devops-pipeline`)
4. ✅ Run first build (click "Build Now")
5. ✅ Monitor deployment
6. 📊 Customize pipeline as needed

---

## Support & Resources

- **Jenkins Documentation**: https://jenkins.io/doc/
- **Jenkins Pipeline**: https://jenkins.io/doc/book/pipeline/
- **Docker Compose**: https://docs.docker.com/compose/
- **Kubernetes**: https://kubernetes.io/docs/
- **Helm**: https://helm.sh/docs/

---

**Ready to start?**

```bash
cd ci
docker-compose -f docker-compose-jenkins.yml up -d --build
```

Jenkins will be ready in 2-3 minutes! 🚀
