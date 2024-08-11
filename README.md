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
    - Enter an item name: **hono-pipeline** & select the category as **Pipeline**
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


### Performing continous integration with GitHub webhook

1) #### Add jenkins webhook to github
    - Access your repo **jenkins_with_terraform_deployment** on github
    - Goto Settings --> Webhooks --> Click on Add webhook 
    - Payload URL: **htpp://REPLACE-JENKINS-SERVER-PUBLIC-IP:8080/github-webhook/**    (Note: The IP should be public as GitHub is outside of the AWS VPC where Jenkins server is hosted)
    - Click on Add webhook

2) #### Configure on the Jenkins side to pull based on the event
    - Access your jenkins server, pipeline **hono-pipeline**
    - Once pipeline is accessed --> Click on Configure --> In the General section --> **Select GitHub project checkbox** and fill your repo URL of the project.
    - Scroll down --> In the Build Triggers section -->  **Select GitHub hook trigger for GITScm polling checkbox**

Once both the above steps are done click on Save.

5) #### Jenkins pipeline
 Write a Jenkinsfile
Define the Stages:
Create a Jenkinsfile in the root of your GitHub repository. This file will define the pipeline stages:
groovy
Copy code
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
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
                    docker.build("your-image-name:${env.BUILD_ID}")
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-credentials') {
                        docker.image("your-image-name:${env.BUILD_ID}").push('latest')
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
- Install Docker on the machine where Jenkins is running.
 ## Create a Dockerfile:
- Write a Dockerfile to define the environment for your application:
## Dockerfile
FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/your-app.jar /app/your-app.jar
ENTRYPOINT ["java", "-jar", "your-app.jar"]
Build and Test Docker Image Locally:
Build the Docker image locally to ensure it's working:
bash
Copy code
docker build -t your-image-name .
docker run -p 8080:8080 your-image-name


