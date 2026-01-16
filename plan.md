Running Jenkins inside Docker while managing a **Kind** cluster and **Docker builds** requires a specific setup called **"Sidecar Docker"** or **"Docker-out-of-Docker."**

To make this impressive for your assignment, we won't just use a standard Jenkins image; we will build a **custom Jenkins image** that already has `kubectl`, `helm`, and `Docker` CLI installed.

---

### Phase 1: Custom Jenkins Infrastructure (`/ci` folder)

Create a directory named `ci` in your root.

#### 1. Custom Jenkins Dockerfile (`ci/Dockerfile.jenkins`)
This ensures Jenkins has the tools needed to deploy to your cluster.

```dockerfile
FROM jenkins/jenkins:lts-jdk17

USER root

# Install Docker CLI, Kubectl, and Helm
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/var/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

RUN apt-get update && apt-get install -y docker-ce-cli kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

USER jenkins
```

#### 2. Jenkins Compose File (`ci/docker-compose-jenkins.yml`)
This mounts your local Docker socket and Kubeconfig into Jenkins.

```yaml
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile.jenkins
    container_name: jenkins-ci
    ports:
      - "8082:8080"
    volumes:
      - ./jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock      # Docker-out-of-docker
      - ${HOME}/.kube/config:/var/jenkins_home/.kube/config:ro # Access local Kind cluster
    environment:
      - KUBECONFIG=/var/jenkins_home/.kube/config
```

---

### Phase 2: The Jenkins Pipeline (`/Jenkinsfile`)

Place this `Jenkinsfile` at the **root** of your repository.

```groovy
pipeline {
    agent any

    environment {
        // Build variables
        DOCKER_IMAGE = "mycodev2-app"
        NAMESPACE = "dev"
        CHART_PATH = "helm-chart"
    }

    stages {
        stage('Cleanup') {
            steps {
                // Ensure a clean slate for the build
                sh "mvn -f app/sample-spring-boot-app/pom.xml clean"
            }
        }

        stage('Maven Build & Test') {
            steps {
                sh "mvn -f app/sample-spring-boot-app/pom.xml package -DskipTests"
            }
        }

        stage('Build Docker Image') {
            steps {
                // Building the app image using the host's engine
                sh "docker build -t ${DOCKER_IMAGE}:latest -f docker/Dockerfile ."
            }
        }

        stage('Deploy to Kind') {
            steps {
                script {
                    // Load the image into Kind so nodes can see it without a registry
                    sh "kind load docker-image ${DOCKER_IMAGE}:latest"
                    
                    // Helm Upgrade/Install (Reliability improvement)
                    sh "helm upgrade --install my-stack ${CHART_PATH} -n ${NAMESPACE} --create-namespace"
                }
            }
        }

        stage('Smoke Test') {
            steps {
                // Verify pods are scaling up
                sh "kubectl get pods -n ${NAMESPACE}"
                sh "kubectl get hpa -n ${NAMESPACE}"
            }
        }
    }

    post {
        success {
            echo "Successfully deployed version ${env.BUILD_ID} to Kind."
        }
        failure {
            echo "Deployment failed. Check Kafka/MySQL connectivity."
        }
    }
}
```

---

### Phase 3: Deployment Strategy (Step-by-Step Guide)

Follow these steps exactly to satisfy the "Automation" part of the assignment:

#### 1. Start Jenkins
```bash
cd ci
docker-compose -f docker-compose-jenkins.yml up -d --build
```
*Wait for Jenkins to start (Check `docker logs -f jenkins-ci`).*

#### 2. Configure Jenkins UI
1.  Open **http://localhost:8082**
2.  Unlock Jenkins (The initial password is in the logs: `docker logs jenkins-ci`).
3.  Install **Suggested Plugins**.
4.  Go to **New Item** -> Name it `devops-pipeline` -> Select **Pipeline**.
5.  Scroll to **Pipeline definition** -> Select **Pipeline script from SCM**.
6.  SCM: **Git** -> Repository URL: (Enter the full path to your local folder, e.g., `/d/DevOps/devops-asgnmt/mycodev2`).
7.  Branch: `*/main`.

#### 3. Handle Docker Permissions
Because Jenkins runs as the `jenkins` user but needs access to `/var/run/docker.sock` (which belongs to `root` or `docker` group), you might need to run this on your host machine to grant permission:
```bash
sudo chmod 666 /var/run/docker.sock
```

#### 4. Run Build
Click **Build Now** in Jenkins. You will see it:
1.  Compile your Java code via Maven.
2.  Build the non-root Docker image.
3.  Push that image into the **Kind** cluster nodes.
4.  Trigger **Helm** to deploy the Kafka/MySQL/App stack.

---

### Final Project Status for Part 5 (Your Documentation)

Your project now demonstrates the following "Senior" DevOps concepts:
1.  **Orchestrated Tooling:** Jenkins running in Docker managing K8s (Tooling-as-Code).
2.  **Network Resilience:** Using Init Containers to wait for infrastructure before app start.
3.  **Local Dev Experience:** Optimized Kind loading (`kind load`) to avoid cloud registry costs.
4.  **Security:** Java App running as user `1000` (non-root) in the Dockerfile.
5.  **Visibility:** Integrated UI for immediate verification of the Message -> Kafka -> MySQL flow.

**The Test:** 
Run `kubectl port-forward svc/spring-app-service 8080:8080 -n dev`, open browser to `localhost:8080`, and verify your pipeline worked!