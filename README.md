## CICD pipeline using Jenkins, integrating GitHub for version control, and deploying to kubernetes cluster

## CICD setup
1) ###### GitHub setup
    Fork GitHub Repository by using the existing repo "HONO" (https://github.com/Muafah/HONO.git)     
    - Go to GitHub (github.com)
    - Login to your GitHub Account
    - Fork repository "HONO" (https://github.com/Muafah/HONO.git) & name it "HONO.git"
    - Clone your newly created repo to your local

2) ###### Jenkins
    - Create an **Amazon Linux 2 VM** instance and call it "Jenkins"
    - Instance type: t2.medium
    - Security Group (Open): 8080, 9100 and 22 to 0.0.0.0/0
    - Key pair: Select or create a new keypair
    - **Attach Jenkins server with IAM role having "AdministratorAccess"**
    - Launch Instance
    - After launching this Jenkins server, attach a tag as **Key=Application, value=jenkins**
    - SSH into the instance and Run the following commands in the **jenkins.sh** file found in the **installation-files** directory

## Installing Jenkins
- sudo yum update
- sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
- sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key # Note: Refer this link to change this key line frequently https://pkg.jenkins.io/redhat-stable/
- sudo yum upgrade
- sudo amazon-linux-extras install java-openjdk11
- sudo yum install jenkins
- sudo su && echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
- sudo systemctl enable jenkins
- sudo systemctl start jenkins
- sudo systemctl status jenkins

#Install git
- sudo yum install git

### Jenkins setup
1) #### Access Jenkins
    Copy your Jenkins Public IP Address and paste on the browser = **ExternalIP:8080**
    - Login to your Jenkins instance using your Shell (GitBash or your Mac Terminal)
    - Copy the Path from the Jenkins UI to get the Administrator Password
        - Run: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
        - Copy the password and login to Jenkins
    - Plugins: Choose Install Suggested Plugings 
    - Provide 
        - Username: **teamdynamic**
        - Password: **teamdynamic**
        - Name and Email can also be admin. You can use `teamdynamics` all, as its a poc.
    - Continue and Start using Jenkins

2)  #### Pipeline creation
    - Click on **New Item**
    - Enter an item name: **dynamic-pipeline** & select the category as **Pipeline**
    - Now scroll-down and in the Pipeline section --> Definition --> Select Pipeline script from SCM
    - SCM: **Git**
    - Repositories
        - Repository URL: FILL YOUR OWN REPO URL (that we created by importing in the first step) (https://github.com/Muafah/HONO.git)  
        - Branch Specifier (blank for 'any'): */main
        - Script Path: Jenkinsfile
    - Save

3)  #### Plugin installations:
    - Click on "Manage Jenkins"
    - Click on "Plugin Manager"
    - Click "Available"
    - Search and Install the following Plugings "Install Without Restart"
    - Install plugins for GitHub integration, Docker, Kubernetes, and any other tools you plan to use (e.g., Pipeline, Blue Ocean, etc.).       
      

4)  #### Credentials setup(AWS):
    - Click on Manage Jenkins --> Manage Credentials --> Global credentials (unrestricted) --> Add Credentials
        1)  ###### DOCKER Credential (DOCKERHUB_CREDENTIALS)
            - Kind: Username and Password
            - Username: "Enter your Dockerhub user name" 
            - Password: "Enter your Dockerhub password"          
            - Description: DOCKERHUB_CREDENTIALS
            - Click on Create
        2) AWS credentials
           - secret key
           - secret access key           


### Performing continous integration with GitHub webhook

1) #### Add jenkins webhook to github
    - Goto Settings --> Webhooks --> Click on Add webhook 
    - Payload URL: **htpp://REPLACE-JENKINS-SERVER-PUBLIC-IP:8080/github-webhook/**    (Note: The IP should be public as GitHub is outside of the AWS VPC where Jenkins server is hosted)
    - Click on Add webhook

2) #### Configure on the Jenkins side to pull based on the event
    - Access your jenkins server, pipeline **dynamic-pipeline**
    - Once pipeline is accessed --> Click on Configure --> In the General section --> **Select GitHub project checkbox** and fill your repo URL of the project.
    - Scroll down --> In the Build Triggers section -->  **Select GitHub hook trigger for GITScm polling checkbox**

Once both the above steps are done click on Save.

5) #### Jenkins pipeline
 Write a Jenkinsfile
Define the Stages:
Create a Jenkinsfile in the root of your GitHub repository. This file will define the pipeline stages:
groovy

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

### Finally observe the whole flow and understand the integrations

6) ###  Set Up Docker for Containerization
## Install Docker:
  # Install Docker on the machine where Jenkins is running.
  # !/bin/bash
sudo yum update -y
sudo yum -y install docker
sudo service docker start
sudo systemctl enable docker.service 
sudo usermod -a -G docker ec2-user 
sudo chmod 666 /var/run/docker.sock

 ## Create a Dockerfile:
- Write a Dockerfile to define the environment for your application:
## Dockerfile
FROM node:10-alpine

RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app

COPY package*.json ./

USER node

RUN npm install

COPY --chown=node:node . .

EXPOSE 8080

CMD [ "node", "app.js" ]

- Build and Test Docker Image Locally:
- Build the Docker image locally to ensure it's working:
  ### Copy code
- docker build -t your-image-name .
- docker run -p 8080:8080 your-image-name

7) ## Set Up Kubernetes for Deployment
# Install Kubernetes:
- Set up a Kubernetes cluster using Minikube, k3s, or a cloud provider like GKE (Google Kubernetes Engine), EKS (Amazon Elastic Kubernetes Service), or AKS (Azure Kubernetes Service).
Create Kubernetes Deployment and Service Files:
- Write the Kubernetes YAML files (k8s-deployment.yaml, k8s-service.yaml) for deploying your application:
yaml
# Copy code
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
spec:
  replicas: 2
  selector:
  matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app-container
        image: node.js:latest
        ports:
        - containerPort: 8080
# Service
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: LoadBalancer
  selector:
    app: your-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
Deploy to Kubernetes:
Use kubectl to deploy the application:
bash
## Copy code
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml

8) ## Integrate Jenkins with Kubernetes
# Install Kubernetes Plugin in Jenkins:
- Go to Manage Jenkins > Manage Plugins > Available and install the Kubernetes plugin. (same as step 3)
Configure Kubernetes in Jenkins:
- Go to Manage Jenkins > Configure System > Cloud > Kubernetes and add your Kubernetes cluster details.
Set Up Kubernetes Agents:
Configure Jenkins to use Kubernetes pods as agents for running jobs.

9) ## Monitoring and Maintenance
# Monitor Jenkins Jobs:
- Regularly check Jenkins jobs for failures or errors.
- Monitor Kubernetes Deployments:
-Use kubectl commands to monitor the health of your application in Kubernetes:
bash
# Copy code
- kubectl get pods
- kubectl logs pod-name
# Set Up Alerts and Notifications:
Integrate Jenkins with Slack, email, or other notification services for real-time alerts.

10) ## Scale and Improve
Scaling Kubernetes Deployments:
Adjust the number of replicas in your Kubernetes deployment based on load.
## CI/CD Pipeline Enhancements:
Add stages for security checks, performance testing, or automated rollbacks.

11) ## Documentation and Cleanup
- Document the Pipeline:
- Ensure all steps, configurations, and scripts are well-documented.
- Clean Up Resources:
- Regularly clean up unused Docker images, old deployments, and logs.


12) challenges faced during execution of this project and how we solced the challenges
First challenge was getting bulid failues and this had to do with properly intalling git in our jenkins server
2ndly putting the right docker credentials in out junkins pipeline was a blocker.
3rdly 
