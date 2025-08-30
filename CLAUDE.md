# Jenkins CI/CD Infrastructure for C++ Projects

This repository contains a production-ready Jenkins CI/CD setup optimized for C++ development on Apple Silicon (M2 Mac mini) using Docker, JCasC, and Job DSL.

**IMPORTANT**: 
- Jenkins runs on a REMOTE M2 Mac mini server, not locally. Changes to configuration files need to be pulled on the remote machine and Jenkins restarted there.
- ALL changes must be submitted via Pull Request for review and approval. Never commit directly to main branch.
- The setup is specifically optimized for C++ projects with native M2 compilation for maximum performance.

## Overview

- **Jenkins LTS** running in Docker container with automated updates
- **JCasC** (Jenkins Configuration as Code) for reproducible infrastructure
- **Job DSL** for programmatic pipeline creation
- **Native M2 Mac mini agent** for high-performance C++ builds
- **Docker-in-Docker** support for containerized builds
- **Dark theme** enabled for better developer experience
- **Automated C++ pipelines** with GoogleTest integration

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

- **Dockerfile**: Custom Jenkins image with Docker CLI and required plugins
- **docker-compose.yaml**: Container orchestration with volume mounts and environment configuration
- **jenkins.yaml**: JCasC configuration for Jenkins settings, security, and Mac agent
- **jobs.groovy**: Job DSL scripts defining all C++ project pipelines
- **plugins.txt**: Required Jenkins plugins list (40+ plugins for full functionality)
- **.env**: Environment file containing SSH keys and credentials (not in git)

## Active C++ Projects

The following C++ projects are configured with automated builds:

1. **inference-systems-lab**: Advanced C++ project with Cap'n Proto serialization
   - Hourly builds at :05
   - AddressSanitizer/UBSan support
   - Multiple build configurations

2. **cql**: C++ Query Language implementation
   - Hourly builds at :25
   - GoogleTest integration
   - CURL dependency management

3. **cpp-snippets**: Collection of C++ examples
   - Hourly builds at :45
   - Boost and OpenSSL integration
   - Batch build system

## Testing Strategy

The setup provides comprehensive C++ testing through:
1. Native M2 compilation for optimal performance
2. GoogleTest framework integration
3. Parameterized builds for different configurations
4. JUnit XML test result publishing
5. Automatic workspace cleanup post-build
6. Optional memory sanitizers (ASan, UBSan)

## Mac Mini Agent Configuration

- **Host**: Configured as `host.docker.internal` for Docker networking
- **Executors**: 4 parallel build slots
- **Tools**: Homebrew, CMake, Clang++, Ninja, GoogleTest, Cap'n Proto
- **Authentication**: SSH key-based (stored in .env file)

## Current Status

✅ Jenkins Docker setup complete  
✅ JCasC configuration with dark theme  
✅ Mac mini M2 agent integrated  
✅ Three C++ projects with hourly builds  
✅ GoogleTest integration working  
✅ Script approval automation  
✅ Docker-in-Docker enabled  
🔄 LTS update automation in progress  

## Next Steps

1. Monitor build performance and adjust schedules
2. Add code coverage reporting
3. Implement build notifications
4. Set up backup strategy for Jenkins home
5. Add more C++ project templates as needed
