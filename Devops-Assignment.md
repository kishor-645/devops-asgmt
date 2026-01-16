# DevOps Engineer – Hands-On Assignment (3–4 Hours)

## Objective
Assess the candidate’s ability to:
*   **Design CI/CD pipelines**
*   **Deploy applications on Kubernetes**
*   **Manage multi-environment stability**
*   **Automate deployments**
*   **Handle MySQL, Kafka**
*   **Apply cost-optimization and reliability thinking**
*   **Work effectively on Ubuntu**

---

## Time Limit
⏱ **3 to 4 Hours**

---

## Tools Allowed
*   **GitHub** (public or private repo)
*   **Jenkins** or **GitHub Actions**
*   **Kubernetes** (kind / minikube / k3s)
*   **Docker**
*   **Ubuntu**
*   **Maven**
*   **MySQL** (Docker-based)
*   **Kafka** (Docker-based)
*   **Any scripting language** (Bash preferred)

---

## Assignment Overview
The candidate will:
1.  Set up a **CI/CD pipeline**
2.  Deploy a **Spring Boot application** to Kubernetes
3.  Manage **Dev & QA environments**
4.  Integrate **MySQL + Kafka**
5.  Demonstrate **stability and cost optimization**

---

## Part 1: Repository & Git Flow (30 mins)

### Tasks
*   **Create a GitHub repository with the following structure:**
    ```text
    /app
    └── sample-spring-boot-app
    /docker
    /k8s
    ├── dev
    ├── qa
    /ci
    README.md
    ```
*   **Implement GitHub Flow:**
    *   `main` → Production-ready
    *   `feature/*` → Feature branches
*   **Protect main branch** with PR requirement (document if unable to enforce).

### Expected Output
*   Clean repo structure
*   Meaningful commits
*   Clear README instructions

---

## Part 2: CI/CD Pipeline (45–60 mins)

### Tasks
Create a **CI/CD pipeline** using **Jenkins or GitHub Actions**.

**Pipeline stages:**
1.  Checkout code
2.  Build using **Maven**
3.  Run unit tests
4.  Build Docker image
5.  Push image (Docker Hub / GHCR)
6.  Deploy to **Dev** Kubernetes namespace

### Validation Criteria
*   Pipeline is **fully automated**
*   Clear separation of stages
*   Fail-fast behavior
*   Environment-specific configuration

---

## Part 3: Kubernetes Deployment (45–60 mins)

### Tasks
Deploy the application to Kubernetes:
*   **Use Namespaces:**
    *   `dev`
    *   `qa`
*   **Create:**
    *   Deployment
    *   Service
    *   ConfigMap
*   **Resource constraints:**
    *   CPU & memory requests/limits
*   **Health checks:**
    *   Liveness
    *   Readiness

### Bonus (Optional)
*   Helm chart instead of raw YAML
*   Horizontal Pod Autoscaler (HPA)

### Validation Criteria
*   Clean manifests
*   Environment isolation
*   Proper resource usage (cost awareness)

---

## Part 4: Database & Kafka Setup (45 mins)

### MySQL
*   Deploy MySQL using Docker or Kubernetes
*   Initialize schema via script
*   Connect application using environment variables

### Kafka
*   Deploy Kafka (Docker-based)
*   **Configure:**
    *   Topic creation
    *   Producer in application
*   **Demonstrate:**
    *   Message publish on API call

### Validation Criteria
*   Correct configuration
*   Stability awareness
*   No hardcoded secrets

---

## Part 5: Stability, Cost & Ops Thinking (30 mins)

### Tasks
Provide a **short markdown document** answering:
1.  How would you ensure **stability** across Dev / QA / Prod?
2.  How would you **rollback** a failed deployment?
3.  What **cost optimizations** have you applied?
4.  How would you **monitor**:
    *   Pod health
    *   Kafka lag
    *   DB performance
5.  What would you **automate next** if given more time?

---

## Deliverables
Candidate must submit:
*   GitHub repository link
*   CI/CD pipeline configuration
*   Kubernetes manifests / Helm charts
*   README with setup & run instructions
*   Stability & cost optimization document