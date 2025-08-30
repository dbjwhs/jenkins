# Jenkins CI/CD Infrastructure for C++ Projects

A production-ready Jenkins setup running on M2 Mac mini, configured with Infrastructure as Code (IaC) using Docker, JCasC, and Job DSL for automated C++ project builds and testing.

## 🎯 Overview

This repository provides a complete Jenkins CI/CD solution optimized for C++ development on Apple Silicon (M2) hardware. It features:

- **Jenkins LTS** running in Docker with monthly update automation
- **Jenkins Configuration as Code (JCasC)** for reproducible infrastructure
- **Job DSL** for programmatic pipeline creation
- **Native M2 Mac mini agent** for optimal build performance
- **Docker-in-Docker** support for containerized builds
- **Dark theme** support for improved developer experience
- **Automated C++ project pipelines** with GoogleTest integration

## 📋 Prerequisites

- Docker and Docker Compose installed
- M2 Mac mini (for native builds) or any Docker-compatible system
- Git for version control
- SSH access configured (for Mac agent connectivity)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/dbjwhs/jenkins.git
cd jenkins
```

### 2. Configure Environment
Create a `.env` file with your SSH key for Mac mini agent:
```bash
echo "MAC_MINI_SSH_KEY=$(cat ~/.ssh/jenkins_agent_key)" > .env
```

### 3. Start Jenkins
```bash
docker-compose up -d
```

### 4. Access Jenkins
- **URL**: http://localhost:8080
- **Username**: dbjwhs
- **Password**: jenkins

## 🏗️ Architecture

### Core Components

| File | Purpose |
|------|---------|
| `Dockerfile` | Custom Jenkins image with Docker CLI and plugins |
| `docker-compose.yaml` | Container orchestration with volume mounts |
| `jenkins.yaml` | JCasC configuration for Jenkins settings and agents |
| `jobs.groovy` | Job DSL scripts defining all pipelines |
| `plugins.txt` | Required Jenkins plugins list |
| `update-jenkins-lts.sh` | Automated LTS version updater |

### Jenkins Agent Configuration

The setup includes a native M2 Mac mini agent configured for high-performance C++ builds:

- **Label**: `mac-mini-m2`
- **Executors**: 4 parallel build slots
- **Connection**: SSH with key authentication
- **Tools**: Homebrew, CMake, Clang++, Ninja, GoogleTest

## 📦 Configured Pipelines

### C++ Projects (`cpp-projects/`)

#### 1. **Inference Systems Lab** (`inference-systems-lab-build`)
- Advanced C++ project with Cap'n Proto serialization
- Configurable build types (Release/Debug/RelWithDebInfo)
- Optional AddressSanitizer and UBSan support
- Automated hourly builds (5 minutes past the hour)

#### 2. **CQL - C++ Query Language** (`cql-build`)
- SQL-like query language implementation in C++
- GoogleTest integration for comprehensive testing
- CURL dependency management
- Automated hourly builds (25 minutes past the hour)

#### 3. **C++ Snippets Collection** (`cpp-snippets-build`)
- Collection of C++ examples and utilities
- Boost and OpenSSL integration
- Batch build system using `build_all.sh`
- Automated hourly builds (45 minutes past the hour)

### Example Jobs (`example-jobs/`)
- `nodejs-app-test`: Node.js application testing template
- `simple-inference-test`: Simplified test pipeline for debugging

## 🛠️ Common Operations

### View Logs
```bash
docker-compose logs -f jenkins
```

### Stop Jenkins
```bash
docker-compose down
```

### Update to Latest LTS
```bash
./update-jenkins-lts.sh
```

### Clean Up Old Jobs
```bash
./cleanup-jobs.sh
```

### Setup Mac Agent
```bash
./setup-mac-agent.sh
```

## 🔧 Configuration Details

### Security
- Local authentication with predefined admin user
- Script approval for Job DSL and Pipeline scripts
- SSH key-based authentication for agents
- No anonymous access

### Build Features
- Parallel builds (4 executors)
- Build artifacts archiving
- JUnit test result publishing
- Build history retention (15-20 builds)
- Workspace cleanup post-build

### Environment Variables
- `CMAKE_BUILD_PARALLEL_LEVEL`: Controls CMake parallel compilation
- `CTEST_PARALLEL_LEVEL`: Controls CTest parallel execution
- `HOMEBREW_PREFIX`: Points to Homebrew installation
- `CMAKE_PREFIX_PATH`: Helps CMake find dependencies

## 📝 Development Workflow

### Adding New C++ Projects

1. Edit `jobs.groovy` to add your pipeline definition
2. Use existing pipelines as templates
3. Commit changes and push to repository
4. Pull changes on the Jenkins server
5. Restart Jenkins to apply configuration

### Customizing Build Parameters

Each pipeline supports:
- Git repository URL
- Branch selection
- Build type (Release/Debug)
- Test execution toggle
- Clean build option

## 🔍 Troubleshooting

### Jenkins Won't Start
Check Docker logs: `docker-compose logs jenkins`

### Mac Agent Connection Issues
Verify SSH key permissions: `./fix-jenkins-user.sh`

### Build Failures
1. Check agent connectivity
2. Verify Homebrew packages installed
3. Review build logs in Jenkins UI
4. Ensure CMakeLists.txt exists in project

### Script Approval Required
Run: `./auto-approve.sh` or approve in Jenkins UI

## 📚 Documentation

Additional documentation available in:
- `MAC_SETUP.md` - Mac mini Jenkins agent setup guide
- `MAC_AGENT_SETUP.md` - Detailed agent configuration
- `docs/SCRIPT_APPROVALS.md` - Script security documentation
- `CLAUDE.md` - AI assistant instructions and context

## 🚧 Project Status

✅ **Completed**
- Docker-based Jenkins deployment
- JCasC configuration
- Mac mini M2 agent integration
- C++ project pipelines (3 active)
- Dark theme support
- Automated script approvals

🔄 **In Progress**
- LTS update automation refinement
- Additional C++ project templates

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. **Submit a Pull Request** (never commit directly to main)
5. Await review and approval

## 📄 License

MIT License - Copyright (c) 2025 dbjwhs

## 🔗 Related Projects

- [inference-systems-lab](https://github.com/dbjwhs/inference-systems-lab) - C++ inference engine
- [cql](https://github.com/dbjwhs/cql) - C++ Query Language implementation
- [cpp-snippets](https://github.com/dbjwhs/cpp-snippets) - C++ code examples

## 💡 Tips

- Use `docker-compose logs -f` to monitor Jenkins startup
- Check `/var/jenkins_home/jobs/` for job configurations
- Review `Testing/Temporary/LastTest.log` for test details
- Enable sanitizers for memory safety checks during development
- Schedule builds during off-peak hours to optimize resource usage

---

For issues or questions, please open a GitHub issue or check the existing documentation.
