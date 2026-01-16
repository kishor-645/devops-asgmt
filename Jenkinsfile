pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "mycodev2-app"
        DOCKER_TAG = "latest"
        NAMESPACE = "dev"
        KIND_CLUSTER = "k8s"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📦 Checking out repository..."
                checkout scm
                sh "echo 'Repository checked out successfully'"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh '''
                    cd docker/
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -f Dockerfile .
                    cd ..
                '''
                sh "docker images | grep ${DOCKER_IMAGE}"
            }
        }

        stage('Load Image to Kind') {
            steps {
                echo "📥 Loading Docker image into Kind cluster..."
                sh '''
                    kind load docker-image ${DOCKER_IMAGE}:${DOCKER_TAG} --name ${KIND_CLUSTER}
                    echo "✅ Image loaded successfully into Kind cluster '${KIND_CLUSTER}'"
                '''
            }
        }

        stage('Deploy with Helm') {
            steps {
                echo "⚙️ Deploying application with Helm..."
                sh '''
                    helm upgrade --install mycode ./helm-chart \
                        -n ${NAMESPACE} \
                        --create-namespace \
                        --set app.replicaCount=1 \
                        --wait
                    echo "✅ Helm deployment completed"
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "✔️ Verifying deployment..."
                sh '''
                    echo "Pods in ${NAMESPACE} namespace:"
                    kubectl get pods -n ${NAMESPACE}
                    
                    echo ""
                    echo "Services in ${NAMESPACE} namespace:"
                    kubectl get svc -n ${NAMESPACE}
                    
                    echo ""
                    echo "Deployment status:"
                    kubectl get deployment -n ${NAMESPACE}
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! Application deployed to Kind cluster."
        }
        failure {
            echo "❌ Pipeline failed. Check logs above for details."
        }
    }
}
