pipeline {
    agent any

    stages {
        stage('Git Checkout') {
            steps {
                    echo 'Cloning project codebase...'
                	git branch: 'main', url: '(https://github.com/Tean-Dynamic/HONO.git'
            }
        }
        
        stage('Build-Image') {
            steps {
                // Example: Using Maven
                sh 'docker build -t $teamimage:$vi.'
                sh 'docker images'
            }
        }
        
       stage('Login to Dockerhub') {

			steps {
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
			}
		}
        
        stage('Build-Container') {
            steps {
                script {
                    sh 'docker run --name $CONTAINER_NAME-$BUILD_NUMBER -p 8089:8080 -d $IMAGE_REPO_NAME:$BUILD_NUMBER'
				    sh 'docker ps'
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                     
                       sh 'docker push $IMAGE_REPO_NAME:$BUILD_NUMBER'
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
