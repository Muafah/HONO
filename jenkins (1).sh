#!/bin/bash
# Hardware requirements: Amazon Linux 2 Kernel 5.10 AMI with mimum t2.medium type instance & port 8080(jenkins), 9100 (node-exporter) should be allowed on the security groups

#Note: Dont use the latest EC2 Linux of 2023 as it doesnt have amazon-linux-extras which was used in the Jenkins installation as per the old AMI.

# Installing Jenkins
sudo yum update
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key # Note: Refer this link to change this key line frequently https://pkg.jenkins.io/redhat-stable/
sudo yum upgrade
sudo amazon-linux-extras install java-openjdk11 
sudo yum install jenkins 
sudo su && echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

#Install git
sudo yum install git