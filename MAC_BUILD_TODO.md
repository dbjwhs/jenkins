# macOS Native C++ Build Setup for Jenkins

This document outlines the implementation plan for setting up native macOS C++ builds using the Mac mini as both Jenkins master (containerized) and Jenkins agent (native).

## Current Architecture

- **Jenkins Master**: Running in Docker container on Mac mini M2
- **Build Environment**: Currently using Ubuntu Docker containers (suboptimal for macOS)
- **Target**: Add native macOS build capability alongside existing Docker-based builds

## Implementation Plan

### Phase 1: Mac Mini Agent Setup

#### Prerequisites Installation
```bash
# Install Xcode command line tools (if not already installed)
xcode-select --install

# Verify Homebrew installation
brew --version

# Install essential C++ build tools
brew install cmake ninja ccache pkg-config openssl boost

# Create Jenkins agent workspace
sudo mkdir -p /Users/jenkins/agent
sudo chown $(whoami):staff /Users/jenkins/agent
chmod 755 /Users/jenkins/agent
```

#### Jenkins Agent Configuration
1. **Access Jenkins UI**: http://localhost:8080
2. **Navigate**: Manage Jenkins → Manage Nodes and Clouds → New Node
3. **Configuration**:
   - Name: `macos-native-m2`
   - Type: Permanent Agent
   - Number of executors: 4 (M2 has 8 CPU cores)
   - Remote root directory: `/Users/jenkins/agent`
   - Labels: `macos native m2 cpp`
   - Usage: "Only build jobs with label expressions matching this node"
   - Launch method: "Launch agent by connecting it to the controller"
   - Availability: "Keep this agent online as much as possible"

#### Agent Connection Setup
```bash
# Download agent JAR (Jenkins will provide the exact command)
curl -sO http://localhost:8080/jnlpJars/agent.jar

# Create launch script
cat > ~/launch-jenkins-agent.sh << 'EOF'
#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
export CMAKE_PREFIX_PATH="/opt/homebrew"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig"

cd /Users/jenkins/agent
java -jar agent.jar -url http://localhost:8080/ -secret [SECRET] -name macos-native-m2 -workDir /Users/jenkins/agent
EOF

chmod +x ~/launch-jenkins-agent.sh
```

### Phase 2: Pipeline Integration

#### Update jobs.groovy for macOS Builds
Add new pipeline job for native macOS C++ builds:

```groovy
pipelineJob('cpp-projects/cpp-snippets-macos-native') {
    description('Build and test C++ Snippets using native macOS toolchain')
    parameters {
        stringParam('GIT_REPO_URL', 'https://github.com/dbjwhs/cpp-snippets.git', 'Git repository URL')
        stringParam('BRANCH', 'main', 'Branch to checkout')
        choiceParam('BUILD_TYPE', ['Release', 'Debug', 'RelWithDebInfo'], 'CMake build type')
        booleanParam('USE_CCACHE', true, 'Use ccache for faster builds')
        booleanParam('CLEAN_WORKSPACE', false, 'Clean workspace before build')
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent { label 'macos native m2' }
                    
                    environment {
                        PATH = "/opt/homebrew/bin:${env.PATH}"
                        CMAKE_PREFIX_PATH = "/opt/homebrew"
                        PKG_CONFIG_PATH = "/opt/homebrew/lib/pkgconfig"
                        HOMEBREW_NO_AUTO_UPDATE = "1"
                    }
                    
                    options {
                        timeout(time: 30, unit: 'MINUTES')
                        timestamps()
                        buildDiscarder(logRotator(numToKeepStr: '10'))
                    }
                    
                    stages {
                        stage('Environment Setup') {
                            steps {
                                sh '''
                                    echo "=== System Information ==="
                                    uname -a
                                    sysctl -n machdep.cpu.brand_string
                                    
                                    echo "=== Tool Versions ==="
                                    cmake --version
                                    c++ --version
                                    ninja --version || echo "ninja not available"
                                    ccache --version || echo "ccache not available"
                                    
                                    echo "=== Homebrew Status ==="
                                    brew --version
                                    brew list | grep -E "(cmake|boost|pkg-config)"
                                '''
                            }
                        }
                        
                        stage('Checkout Project') {
                            steps {
                                script {
                                    if (params.CLEAN_WORKSPACE) {
                                        cleanWs()
                                    }
                                    
                                    git branch: params.BRANCH, url: params.GIT_REPO_URL
                                    
                                    if (!fileExists('tooling/build_all.sh')) {
                                        error('tooling/build_all.sh not found - invalid project structure')
                                    }
                                }
                            }
                        }
                        
                        stage('Install Dependencies') {
                            steps {
                                script {
                                    // Check if Brewfile exists for project-specific dependencies
                                    if (fileExists('Brewfile')) {
                                        sh 'brew bundle --quiet'
                                    } else {
                                        sh '''
                                            # Install common C++ dependencies
                                            brew list cmake >/dev/null 2>&1 || brew install cmake
                                            brew list boost >/dev/null 2>&1 || brew install boost
                                            brew list pkg-config >/dev/null 2>&1 || brew install pkg-config
                                            brew list ninja >/dev/null 2>&1 || brew install ninja
                                        '''
                                    }
                                    
                                    if (params.USE_CCACHE) {
                                        sh '''
                                            brew list ccache >/dev/null 2>&1 || brew install ccache
                                            ccache --zero-stats
                                        '''
                                    }
                                }
                            }
                        }
                        
                        stage('Build All Projects') {
                            steps {
                                script {
                                    sh """
                                        echo "Making build_all.sh executable..."
                                        chmod +x tooling/build_all.sh
                                        
                                        # Set up ccache if enabled
                                        if [ "${params.USE_CCACHE}" = "true" ]; then
                                            export CMAKE_CXX_COMPILER_LAUNCHER=ccache
                                        fi
                                        
                                        # Run native macOS build
                                        cd tooling
                                        ./build_all.sh
                                    """
                                }
                            }
                        }
                        
                        stage('Build Statistics') {
                            steps {
                                script {
                                    if (params.USE_CCACHE) {
                                        sh 'ccache --show-stats'
                                    }
                                    
                                    sh '''
                                        echo "=== Build Summary ==="
                                        find . -name "*.dylib" -o -name "*.a" | wc -l | xargs echo "Libraries built:"
                                        find . -type f -perm +111 -path "./*/build/*" | grep -v "\\." | wc -l | xargs echo "Executables built:"
                                        
                                        echo "=== Disk Usage ==="
                                        du -sh . 2>/dev/null || echo "Could not calculate disk usage"
                                    '''
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            script {
                                // Archive build artifacts
                                archiveArtifacts artifacts: '**/build/**/*.dylib', allowEmptyArchive: true
                                archiveArtifacts artifacts: '**/build/**/CMakeCache.txt', allowEmptyArchive: true
                                archiveArtifacts artifacts: '**/custom.log', allowEmptyArchive: true
                            }
                        }
                        success {
                            echo "✅ Native macOS build completed successfully!"
                        }
                        failure {
                            echo "❌ Native macOS build failed. Check logs for details."
                        }
                    }
                }
            ''')
        }
    }
}
```

### Phase 3: Performance Optimizations

#### Ccache Setup
```bash
# Configure ccache
ccache --set-config max_size=5G
ccache --set-config cache_dir=/Users/jenkins/.ccache
ccache --set-config compiler_check=content
```

#### Ninja Build System
```bash
# Use Ninja for faster builds
cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C build -j$(sysctl -n hw.ncpu)
```

#### Homebrew Optimization
```bash
# Disable automatic updates during builds
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
```

### Phase 4: Advanced Features

#### Multi-Architecture Support
```groovy
// Build for both Intel and Apple Silicon
choiceParam('TARGET_ARCH', ['native', 'x86_64', 'arm64', 'universal'], 'Target architecture')
```

```bash
# Universal binary build
cmake -B build -S . -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

#### Xcode Integration
```bash
# Generate Xcode project for debugging
cmake -B build-xcode -S . -G Xcode
```

### Phase 5: Monitoring and Maintenance

#### Health Checks
```bash
# Create health check script
cat > ~/jenkins-agent-health.sh << 'EOF'
#!/bin/bash
echo "=== Agent Health Check ==="
date
df -h /Users/jenkins/agent
brew doctor --quiet
ccache --show-stats 2>/dev/null || echo "ccache not configured"
EOF
```

#### Log Rotation
```bash
# Set up log rotation for agent logs
sudo cat > /etc/newsyslog.d/jenkins-agent.conf << 'EOF'
/Users/jenkins/agent/remoting/logs/*.log jenkins:staff 644 5 100000 * GZ
EOF
```

## Benefits of Native macOS Builds

### Performance Advantages
- **2-3x faster** compilation compared to Docker on macOS
- **Native CPU optimization** (Apple Silicon M2 optimizations)
- **Direct filesystem access** (no virtualization overhead)
- **Memory efficiency** (no Docker daemon overhead)

### Toolchain Access
- **Full Xcode integration** for debugging and profiling
- **Metal Performance Shaders** for GPU-accelerated compute
- **Instruments profiling** for performance analysis
- **Native Apple frameworks** access

### Development Experience
- **Faster iteration cycles** for local testing
- **Better error reporting** with native stack traces
- **Consistent environment** with developer machines
- **Real-time debugging** capabilities

## Comparison: Docker vs Native

| Aspect | Docker Container | Native macOS |
|--------|------------------|--------------|
| Build Speed | Slower (virtualization) | Faster (native) |
| Memory Usage | Higher (container overhead) | Lower (direct) |
| Toolchain | Limited (Ubuntu tools) | Full (Xcode + Homebrew) |
| Debugging | Basic | Advanced (Instruments) |
| Dependencies | Manual apt packages | Homebrew ecosystem |
| Maintenance | Container updates | System updates |

## Implementation Timeline

### Week 1
- [ ] Set up Mac mini as Jenkins agent
- [ ] Test basic pipeline connectivity
- [ ] Install essential build dependencies

### Week 2
- [ ] Create native macOS pipeline job
- [ ] Test cpp-snippets build on native agent
- [ ] Performance comparison with Docker builds

### Week 3
- [ ] Implement ccache and build optimizations
- [ ] Add comprehensive monitoring
- [ ] Documentation and runbook creation

### Week 4
- [ ] Production deployment
- [ ] Team training and adoption
- [ ] Continuous improvement based on feedback

## Success Metrics

- **Build Time**: Target 50% reduction compared to Docker
- **Resource Usage**: Monitor CPU/memory efficiency
- **Reliability**: 99%+ successful build rate
- **Developer Satisfaction**: Faster feedback cycles

## Rollback Plan

If issues arise:
1. Keep existing Docker-based jobs as backup
2. Selective migration (critical projects first)
3. Gradual rollback to Docker if needed
4. Parallel running during transition period

## Maintenance Requirements

### Daily
- Monitor agent connectivity
- Check build queue health

### Weekly  
- Review build performance metrics
- Update Homebrew packages
- Clean up workspace artifacts

### Monthly
- System updates and security patches
- Ccache cleanup and optimization
- Review and update dependencies

## Security Considerations

- Agent runs in isolated workspace
- No sensitive data stored on agent
- Regular security updates via Homebrew
- Network isolation for build processes

## Future Enhancements

### Phase 2 Considerations
- **Multiple macOS agents** for parallel builds
- **Cross-compilation** support for iOS/watchOS
- **Artifact caching** optimization
- **Integration testing** with real devices
- **Code signing** and notarization pipeline

This comprehensive plan provides a roadmap for implementing native macOS C++ builds while maintaining the existing Docker-based infrastructure as a fallback option.
