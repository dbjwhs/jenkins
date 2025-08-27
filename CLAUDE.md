# Jenkins CI/CD Setup for M2 Mac Mini

This repository contains a complete Jenkins setup using Docker and JCasC (Jenkins Configuration as Code) optimized for M2 Mac mini.

## Overview

- **Jenkins LTS** running in Docker container
- **JCasC** for infrastructure as code configuration
- **Groovy DSL** for pipeline job definitions
- **Docker-in-Docker** support for containerized builds
- **Monthly LTS updates** with easy upgrade process
- **Multi-repository testing** support

## Commands

### Start Jenkins
```bash
docker-compose up -d
```

### Stop Jenkins
```bash
docker-compose down
```

### Update to Latest LTS
```bash
./update-jenkins-lts.sh
```

### Check Logs
```bash
docker-compose logs -f jenkins
```

### Access Jenkins
- URL: http://localhost:8080
- Username: dbjwhs
- Password: jenkins

## Architecture

- **Dockerfile**: Custom Jenkins image with Docker CLI and plugins
- **docker-compose.yaml**: Container orchestration with volume mounts
- **jenkins.yaml**: JCasC configuration for Jenkins settings
- **jobs.groovy**: Job DSL scripts for pipeline creation
- **plugins.txt**: Required Jenkins plugins list

## Testing Strategy

The setup supports running tests from multiple repositories by:
1. Defining pipeline jobs in `jobs.groovy`
2. Using parameterized builds for flexibility
3. Docker agents for isolated test environments
4. Automatic test result reporting

## LTS Update Process

Monthly updates are handled via:
1. Automated script checks for latest LTS
2. Updates Docker image tag
3. Preserves configuration and data
4. Validates functionality post-update

## Current Status

✅ Basic Jenkins setup complete  
✅ JCasC configuration active  
✅ Docker-in-Docker enabled  
✅ Test pipeline example working  
⏳ Multi-repo job templates pending  
⏳ LTS update automation pending  

## Next Steps

1. Configure jobs for your specific test repositories
2. Set up GitHub credentials for private repos
3. Implement automated LTS update process
4. Add monitoring and backup strategies