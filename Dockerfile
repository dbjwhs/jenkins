# MIT License
# Copyright (c) 2025 dbjwhs

FROM jenkins/jenkins:lts

# Switch to root to install additional packages
USER root

# Install Docker and other necessary tools
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Switch back to jenkins user
USER jenkins

# Copy the plugins.txt file
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# Copy the jenkins.yaml configuration file
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml

# Install plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt