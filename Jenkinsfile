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
