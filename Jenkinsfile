pipeline {
    agent any

    stages {
        stage('Git Checkout') {
            steps {
                    echo 'Cloning project codebase...'
                	git branch: 'main', url: '(https://github.com/Muafah/HONO)/dynamic-nodejs-app.git'
                checkout scm
            }
        }
        stage('Build') {
            steps {
                // Example: Using Maven
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                // Example: Running unit tests
                sh 'mvn test'
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    docker.build("node.js:${env.BUILD_ID}")
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-credentials') {
                        docker.image("node.js:${env.BUILD_ID}").push('latest')
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f k8s-deployment.yaml'
            }
        }
    }
}
