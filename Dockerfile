FROM jenkins/jenkins:lts

# Switch to root to install additional packages
USER root

# Install Docker and other necessary tools
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Switch back to jenkins user
USER jenkins

# Copy the plugins.txt file
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# Copy the jenkins.yaml configuration file
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml

# Install plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt