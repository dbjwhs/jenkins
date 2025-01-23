# Basic Setup Tutorial for Jenkins on MacBook Pro with Docker

This guide explains how to set up Jenkins with Docker containers and JavaScript configuration on a MacBook Pro.

## Prerequisites
`Docker Desktop`

https://www.docker.com/

`Docker Compose`
```shell
brew install docker-compose
```

## Directory Structure
```
jenkins-setup/
├── Dockerfile
├── docker-compose.yml
├── jenkins.yaml
└── plugins.txt
```

## Docker Compose Configuration
`docker-compose.yml`:
```yaml
version: '3.8'
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - ./jenkins.yaml:/var/jenkins_home/jenkins.yaml
    networks:
      - jenkins-network
    environment:
      - CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml

networks:
  jenkins-network:
    driver: bridge

volumes:
  jenkins_home:
```

## Dockerfile Configuration
```dockerfile
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
```

## Jenkins Configuration (jenkins.yaml)
```yaml
jenkins:
  systemMessage: "Jenkins configured using JCasC"
  numExecutors: 2
  scmCheckoutRetryCount: 2
  mode: NORMAL
  
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "admin"

  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false

  clouds:
    - docker:
        name: "docker"
        dockerApi:
          dockerHost:
            uri: "unix:///var/run/docker.sock"
```

## Essential Plugins (plugins.txt)
```text
configuration-as-code:latest
job-dsl:latest
workflow-aggregator:latest
docker-workflow:latest
git:latest
blueocean:latest
docker-plugin:latest
matrix-auth:latest

# Node.js and JavaScript specific plugins
nodejs:latest
checkstyle:latest
cobertura:latest
junit:latest
pipeline-utility-steps:latest
dashboard-view:latest
warnings-ng:latest
```

## Installation Steps

1. Create all the files in a directory according to the structure above

2. Build and start Jenkins:
```bash
docker-compose build
docker-compose up -d
```

3. Access Jenkins:
- Open browser: `http://localhost:8080`
- Login with:
  - Username: admin
  - Password: admin

## Plugin Categories and Their Uses

### Node.js Development
- `nodejs`: Manages Node.js installations
- `npm`: Enhanced npm support

### Code Quality
- `checkstyle`: For ESLint reports
- `cobertura`: Code coverage reporting
- `sonarqube-scanner`: For SonarQube integration
- `warnings-ng`: Enhanced warning parsers for ESLint, Jest, etc.

### Testing & Reporting
- `junit`: For test result visualization
- `test-results-analyzer`: Advanced test result analysis
- `timestamper`: Adds timestamps to console output

### Pipeline Utilities
- `pipeline-utility-steps`: Additional pipeline steps
- `credentials`: Manages credentials
- `credentials-binding`: Use credentials in pipelines

### UI & Visualization
- `dashboard-view`: Create custom dashboard views
- `build-monitor-plugin`: Large screen build monitor

## Security Note
Remember to change the default admin password after first login for production environments.

## Additional Resources
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Configuration as Code](https://jenkins.io/projects/jcasc/)
- [Docker Documentation](https://docs.docker.com/)

This setup provides a solid foundation for running JavaScript tests in Docker containers with Jenkins as the CI/CD controller.