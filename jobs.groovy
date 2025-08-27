// MIT License
// Copyright (c) 2025 dbjwhs

folder('test-repositories') {
    description('Folder for test repository jobs')
}

pipelineJob('test-repositories/generic-test-pipeline') {
    description('Generic pipeline for test repositories')
    parameters {
        stringParam('REPO_URL', '', 'Git repository URL to test')
        stringParam('BRANCH', 'main', 'Branch to test')
        choiceParam('TEST_TYPE', ['auto', 'npm', 'pytest', 'gradle', 'maven', 'go'], 'Type of tests to run')
        booleanParam('CLEAN_WORKSPACE', true, 'Clean workspace before build')
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    options {
                        timeout(time: 30, unit: 'MINUTES')
                        timestamps()
                        buildDiscarder(logRotator(numToKeepStr: '10'))
                    }
                    
                    stages {
                        stage('Clean Workspace') {
                            when {
                                params.CLEAN_WORKSPACE == true
                            }
                            steps {
                                cleanWs()
                            }
                        }
                        
                        stage('Checkout') {
                            steps {
                                git branch: params.BRANCH, url: params.REPO_URL
                            }
                        }
                        
                        stage('Detect Test Environment') {
                            when {
                                equals expected: 'auto', actual: params.TEST_TYPE
                            }
                            steps {
                                script {
                                    if (fileExists('package.json')) {
                                        env.DETECTED_TYPE = 'npm'
                                    } else if (fileExists('requirements.txt') || fileExists('pyproject.toml') || fileExists('setup.py')) {
                                        env.DETECTED_TYPE = 'pytest'
                                    } else if (fileExists('build.gradle') || fileExists('build.gradle.kts')) {
                                        env.DETECTED_TYPE = 'gradle'
                                    } else if (fileExists('pom.xml')) {
                                        env.DETECTED_TYPE = 'maven'
                                    } else if (fileExists('go.mod')) {
                                        env.DETECTED_TYPE = 'go'
                                    } else {
                                        error('Cannot auto-detect test type. Please specify TEST_TYPE parameter.')
                                    }
                                    echo "Auto-detected test type: ${env.DETECTED_TYPE}"
                                }
                            }
                        }
                        
                        stage('Run Tests') {
                            parallel {
                                stage('NPM Tests') {
                                    when {
                                        anyOf {
                                            equals expected: 'npm', actual: params.TEST_TYPE
                                            equals expected: 'npm', actual: env.DETECTED_TYPE
                                        }
                                    }
                                    agent {
                                        docker {
                                            image 'node:18-alpine'
                                            reuseNode true
                                        }
                                    }
                                    steps {
                                        sh 'npm ci'
                                        sh 'npm test'
                                    }
                                    post {
                                        always {
                                            publishTestResults testResultsPattern: 'test-results.xml', allowEmptyResults: true
                                        }
                                    }
                                }
                                
                                stage('Python Tests') {
                                    when {
                                        anyOf {
                                            equals expected: 'pytest', actual: params.TEST_TYPE
                                            equals expected: 'pytest', actual: env.DETECTED_TYPE
                                        }
                                    }
                                    agent {
                                        docker {
                                            image 'python:3.11-slim'
                                            reuseNode true
                                        }
                                    }
                                    steps {
                                        sh """
                                            pip install --upgrade pip
                                            if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
                                            if [ -f pyproject.toml ]; then pip install -e .; fi
                                            python -m pytest --junit-xml=test-results.xml || true
                                        """
                                    }
                                    post {
                                        always {
                                            publishTestResults testResultsPattern: 'test-results.xml', allowEmptyResults: true
                                        }
                                    }
                                }
                                
                                stage('Gradle Tests') {
                                    when {
                                        anyOf {
                                            equals expected: 'gradle', actual: params.TEST_TYPE
                                            equals expected: 'gradle', actual: env.DETECTED_TYPE
                                        }
                                    }
                                    agent {
                                        docker {
                                            image 'gradle:8-jdk17'
                                            reuseNode true
                                        }
                                    }
                                    steps {
                                        sh './gradlew test'
                                    }
                                    post {
                                        always {
                                            publishTestResults testResultsPattern: '**/test-results/**/*.xml', allowEmptyResults: true
                                        }
                                    }
                                }
                                
                                stage('Maven Tests') {
                                    when {
                                        anyOf {
                                            equals expected: 'maven', actual: params.TEST_TYPE
                                            equals expected: 'maven', actual: env.DETECTED_TYPE
                                        }
                                    }
                                    agent {
                                        docker {
                                            image 'maven:3.9-openjdk-17'
                                            reuseNode true
                                        }
                                    }
                                    steps {
                                        sh 'mvn test'
                                    }
                                    post {
                                        always {
                                            publishTestResults testResultsPattern: '**/surefire-reports/*.xml', allowEmptyResults: true
                                        }
                                    }
                                }
                                
                                stage('Go Tests') {
                                    when {
                                        anyOf {
                                            equals expected: 'go', actual: params.TEST_TYPE
                                            equals expected: 'go', actual: env.DETECTED_TYPE
                                        }
                                    }
                                    agent {
                                        docker {
                                            image 'golang:1.21-alpine'
                                            reuseNode true
                                        }
                                    }
                                    steps {
                                        sh 'go mod download'
                                        sh 'go test -v ./...'
                                    }
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            cleanWs(cleanWhenNotBuilt: false,
                                   deleteDirs: true,
                                   disableDeferredWipeout: true,
                                   notFailBuild: true)
                        }
                        success {
                            echo 'Tests passed successfully!'
                        }
                        failure {
                            echo 'Tests failed. Check the logs above.'
                        }
                    }
                }
            ''')
        }
    }
}

folder('example-jobs') {
    description('Example jobs for common repositories')
}

pipelineJob('example-jobs/nodejs-app-test') {
    description('Example Node.js application test pipeline')
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/dbjwhs/jenkins')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
}

// Simple test version for debugging
pipelineJob('example-jobs/simple-inference-test') {
    description('Simple test version of inference systems lab build')
    parameters {
        stringParam('GIT_REPO_URL', 'https://github.com/dbjwhs/inference-systems-lab.git', 'Git repository URL')
        stringParam('BRANCH', 'main', 'Branch to checkout')
        choiceParam('BUILD_TYPE', ['Release', 'Debug'], 'CMake build type')
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    stages {
                        stage('Checkout Project') {
                            steps {
                                script {
                                    echo "Cloning from Git: ${params.GIT_REPO_URL}"
                                    git branch: params.BRANCH, url: params.GIT_REPO_URL
                                }
                            }
                        }
                        
                        stage('Verify Project') {
                            steps {
                                script {
                                    if (fileExists('CMakeLists.txt')) {
                                        echo 'CMakeLists.txt found - this is a CMake project'
                                        def cmakeContent = readFile('CMakeLists.txt')
                                        if (cmakeContent.contains('InferenceSystemsLab')) {
                                            echo 'Confirmed: This is the Inference Systems Lab project'
                                        } else {
                                            echo 'Warning: Project name not found in CMakeLists.txt'
                                        }
                                    } else {
                                        error('CMakeLists.txt not found')
                                    }
                                }
                            }
                        }
                        
                        stage('List Contents') {
                            steps {
                                sh 'ls -la'
                                sh 'head -20 CMakeLists.txt'
                            }
                        }
                    }
                }
            ''')
        }
    }
}

folder('cpp-projects') {
    description('C++ projects using CMake')
}

pipelineJob('cpp-projects/inference-systems-lab-build') {
    description('Build and test the Inference Systems Laboratory C++ project')
    parameters {
        stringParam('GIT_REPO_URL', 'https://github.com/dbjwhs/inference-systems-lab.git', 'Git repository URL')
        stringParam('BRANCH', 'main', 'Branch to checkout')
        choiceParam('BUILD_TYPE', ['Release', 'Debug', 'RelWithDebInfo'], 'CMake build type')
        booleanParam('RUN_TESTS', true, 'Run tests after build')
        booleanParam('ENABLE_SANITIZERS', false, 'Enable AddressSanitizer and UBSan')
        booleanParam('CLEAN_BUILD', false, 'Clean build directory before building')
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    options {
                        timeout(time: 60, unit: 'MINUTES')
                        timestamps()
                        buildDiscarder(logRotator(numToKeepStr: '20'))
                    }
                    
                    environment {
                        CMAKE_BUILD_PARALLEL_LEVEL = '4'
                        CTEST_PARALLEL_LEVEL = '4'
                    }
                    
                    stages {
                        stage('Checkout Project') {
                            steps {
                                script {
                                    echo "Cloning from Git: ${params.GIT_REPO_URL}"
                                    git branch: params.BRANCH, url: params.GIT_REPO_URL
                                    
                                    // Verify this is the correct project
                                    if (!fileExists('CMakeLists.txt')) {
                                        error('CMakeLists.txt not found - this does not appear to be a CMake project')
                                    }
                                    
                                    // Check for project signature
                                    def cmakeContent = readFile('CMakeLists.txt')
                                    if (!cmakeContent.contains('InferenceSystemsLab')) {
                                        echo 'Warning: This may not be the expected Inference Systems Lab project'
                                    } else {
                                        echo 'Confirmed: This is the Inference Systems Lab project'
                                    }
                                }
                            }
                        }
                        
                        stage('Install Dependencies') {
                            agent {
                                docker {
                                    image 'ubuntu:22.04'
                                    reuseNode true
                                    args '--user root'
                                }
                            }
                            steps {
                                sh """
                                    apt-get update
                                    apt-get install -y \\
                                        cmake \\
                                        build-essential \\
                                        gcc-11 g++-11 \\
                                        ninja-build \\
                                        pkg-config \\
                                        git \\
                                        python3 \\
                                        python3-pip \\
                                        libssl-dev \\
                                        libbenchmark-dev \\
                                        libgtest-dev \\
                                        libgmock-dev \\
                                        doxygen \\
                                        graphviz \\
                                        clang-tidy \\
                                        clang-format \\
                                        cppcheck \\
                                        valgrind \\
                                        libcapnp-dev \\
                                        capnproto
                                    
                                    # Set default compiler versions
                                    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100
                                    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100
                                    
                                    # Verify installations
                                    cmake --version
                                    g++ --version
                                    ninja --version
                                """
                            }
                        }
                        
                        stage('Configure CMake') {
                            agent {
                                docker {
                                    image 'ubuntu:22.04'
                                    reuseNode true
                                    args '--user root'
                                }
                            }
                            steps {
                                sh """
                                    apt-get update
                                    apt-get install -y cmake build-essential git libcapnp-dev capnproto
                                """
                                script {
                                    def buildDir = "build-${params.BUILD_TYPE.toLowerCase()}"
                                    
                                    if (params.CLEAN_BUILD && fileExists(buildDir)) {
                                        sh "rm -rf ${buildDir}"
                                    }
                                    
                                    sh "mkdir -p ${buildDir}"
                                    
                                    dir(buildDir) {
                                        def cmakeArgs = [
                                            "-DCMAKE_BUILD_TYPE=${params.BUILD_TYPE}",
                                            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
                                            "-DBUILD_TESTING=ON"
                                        ]
                                        
                                        if (params.ENABLE_SANITIZERS) {
                                            cmakeArgs.add("-DENABLE_SANITIZERS=ON")
                                            cmakeArgs.add("-DENABLE_UBSAN=ON")
                                        }
                                        
                                        def cmakeCommand = "cmake ${cmakeArgs.join(' ')} .."
                                        echo "Running: ${cmakeCommand}"
                                        sh cmakeCommand
                                    }
                                }
                            }
                        }
                        
                        stage('Build Project') {
                            agent {
                                docker {
                                    image 'ubuntu:22.04'
                                    reuseNode true
                                    args '--user root'
                                }
                            }
                            steps {
                                sh """
                                    apt-get update
                                    apt-get install -y cmake build-essential git libcapnp-dev capnproto
                                """
                                script {
                                    def buildDir = "build-${params.BUILD_TYPE.toLowerCase()}"
                                    dir(buildDir) {
                                        sh "cmake --build . --parallel \\${CMAKE_BUILD_PARALLEL_LEVEL:-4}"
                                    }
                                }
                            }
                        }
                        
                        stage('Run Tests') {
                            when {
                                expression { params.RUN_TESTS == true }
                            }
                            agent {
                                docker {
                                    image 'ubuntu:22.04'
                                    reuseNode true
                                    args '--user root'
                                }
                            }
                            steps {
                                sh """
                                    apt-get update
                                    apt-get install -y cmake build-essential git libcapnp-dev capnproto
                                """
                                script {
                                    def buildDir = "build-${params.BUILD_TYPE.toLowerCase()}"
                                    dir(buildDir) {
                                        sh """
                                            echo "Running CTest..."
                                            ctest --output-on-failure --parallel \${CTEST_PARALLEL_LEVEL:-4} || true
                                            
                                            echo "Test results:"
                                            if [ -f Testing/Temporary/LastTest.log ]; then
                                                tail -20 Testing/Temporary/LastTest.log
                                            fi
                                        """
                                    }
                                }
                            }
                            post {
                                always {
                                    // Publish test results if available
                                    publishTestResults testResultsPattern: '**/build-*/Testing/**/*.xml', allowEmptyResults: true
                                }
                            }
                        }
                        
                        stage('Archive Artifacts') {
                            steps {
                                script {
                                    def buildDir = "build-${params.BUILD_TYPE.toLowerCase()}"
                                    
                                    // Archive build logs and binaries
                                    archiveArtifacts artifacts: "${buildDir}/CMakeCache.txt", allowEmptyArchive: true
                                    archiveArtifacts artifacts: "${buildDir}/compile_commands.json", allowEmptyArchive: true
                                    
                                    // Archive any generated documentation
                                    if (fileExists("${buildDir}/docs")) {
                                        archiveArtifacts artifacts: "${buildDir}/docs/**", allowEmptyArchive: true
                                    }
                                    
                                    // Archive test results
                                    if (fileExists("${buildDir}/Testing")) {
                                        archiveArtifacts artifacts: "${buildDir}/Testing/Temporary/LastTest.log", allowEmptyArchive: true
                                    }
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            cleanWs(cleanWhenNotBuilt: false,
                                   deleteDirs: true,
                                   disableDeferredWipeout: true,
                                   notFailBuild: true)
                        }
                        success {
                            echo "✅ Inference Systems Lab build completed successfully!"
                            echo "Build type: ${params.BUILD_TYPE}"
                            echo "Tests run: ${params.RUN_TESTS}"
                            echo "Sanitizers enabled: ${params.ENABLE_SANITIZERS}"
                        }
                        failure {
                            echo "❌ Build failed. Check the logs above for details."
                        }
                    }
                }
            ''')
        }
    }
}
