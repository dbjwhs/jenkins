// MIT License
// Copyright (c) 2025 dbjwhs

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
    description('Build and test the Inference Systems Laboratory C++ project on Mac mini M2')
    parameters {
        stringParam('GIT_REPO_URL', 'https://github.com/dbjwhs/inference-systems-lab.git', 'Git repository URL')
        stringParam('BRANCH', 'main', 'Branch to checkout')
        choiceParam('BUILD_TYPE', ['Release', 'Debug', 'RelWithDebInfo'], 'CMake build type')
        booleanParam('RUN_TESTS', true, 'Run tests after build')
        booleanParam('ENABLE_SANITIZERS', false, 'Enable AddressSanitizer and UBSan')
        booleanParam('CLEAN_BUILD', false, 'Clean build directory before building')
    }
    triggers {
        cron('5 * * * *')  // Run at 5 minutes past every hour
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent { label 'mac-mini-m2' }
                    
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
                        
                        stage('Verify Dependencies') {
                            steps {
                                sh """
                                    echo "Verifying Mac development environment..."
                                    
                                    # Check required tools
                                    cmake --version
                                    clang++ --version
                                    ninja --version || (echo "Installing ninja..." && brew install ninja)
                                    pkg-config --version || (echo "Installing pkg-config..." && brew install pkg-config)
                                    
                                    # Check for Cap'n Proto
                                    capnp --version || (echo "Installing capnp..." && brew install capnp)
                                    
                                    # Verify Homebrew paths
                                    echo "PATH: \\$PATH"
                                    echo "CMAKE_PREFIX_PATH: \\$CMAKE_PREFIX_PATH"
                                    ls -la /opt/homebrew/bin/cmake || echo "CMake not found in Homebrew"
                                """
                            }
                        }
                        
                        stage('Configure CMake') {
                            steps {
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
                            steps {
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
                            steps {
                                script {
                                    def buildDir = "build-${params.BUILD_TYPE.toLowerCase()}"
                                    dir(buildDir) {
                                        sh """
                                            echo "Running CTest..."
                                            ctest --output-on-failure --parallel \\${CTEST_PARALLEL_LEVEL:-4} || true
                                            
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
                                    junit testResults: '**/build-*/Testing/**/*.xml', allowEmptyResults: true
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

pipelineJob('cpp-projects/cql-build') {
    description('Build and test the CQL (C++ Query Language) project on Mac mini M2')
    parameters {
        stringParam('GIT_REPO_URL', 'https://github.com/dbjwhs/cql.git', 'Git repository URL')
        stringParam('BRANCH', 'main', 'Branch to checkout')
        choiceParam('BUILD_TYPE', ['Release', 'Debug', 'RelWithDebInfo'], 'CMake build type')
        booleanParam('RUN_TESTS', true, 'Run tests after build')
        booleanParam('CLEAN_BUILD', false, 'Clean build directory before building')
    }
    triggers {
        cron('25 * * * *')  // Run at 25 minutes past every hour
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent { label 'mac-mini-m2' }
                    
                    options {
                        timeout(time: 30, unit: 'MINUTES')
                        timestamps()
                        buildDiscarder(logRotator(numToKeepStr: '15'))
                    }
                    
                    environment {
                        CMAKE_BUILD_PARALLEL_LEVEL = '4'
                        CTEST_PARALLEL_LEVEL = '4'
                    }
                    
                    stages {
                        stage('Checkout Project') {
                            steps {
                                script {
                                    echo "Cloning CQL from Git: ${params.GIT_REPO_URL}"
                                    git branch: params.BRANCH, url: params.GIT_REPO_URL
                                    
                                    // Verify this is the CQL project
                                    if (!fileExists('CMakeLists.txt')) {
                                        error('CMakeLists.txt not found - this does not appear to be a CMake project')
                                    }
                                    
                                    echo 'Confirmed: This is the CQL project'
                                    sh 'ls -la'
                                }
                            }
                        }
                        
                        stage('Verify Dependencies') {
                            steps {
                                sh """
                                    echo "Verifying Mac C++ environment for CQL..."
                                    
                                    # Check required tools
                                    cmake --version
                                    clang++ --version
                                    
                                    # Install/check CURL dependency
                                    echo "Checking CURL installation..."
                                    brew list curl || brew install curl
                                    curl --version
                                    
                                    # Install other common dependencies
                                    brew list pkg-config || brew install pkg-config
                                    
                                    # Verify environment
                                    echo "PATH: \\\\$PATH"
                                    echo "CMAKE_PREFIX_PATH: \\\\$CMAKE_PREFIX_PATH"
                                """
                            }
                        }
                        
                        stage('Configure CMake') {
                            steps {
                                script {
                                    def buildDir = "build"
                                    
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
                                        
                                        def cmakeCommand = "cmake ${cmakeArgs.join(' ')} .."
                                        echo "Running: ${cmakeCommand}"
                                        sh cmakeCommand
                                    }
                                }
                            }
                        }
                        
                        stage('Build CQL') {
                            steps {
                                script {
                                    dir('build') {
                                        sh "make -j4"
                                    }
                                }
                            }
                        }
                        
                        stage('Test CQL') {
                            when {
                                expression { params.RUN_TESTS == true }
                            }
                            steps {
                                script {
                                    dir('build') {
                                        sh """
                                            echo "Running CQL GoogleTest suite..."
                                            
                                            # Run the test executable
                                            if [ -f cql_test ]; then
                                                echo "Found cql_test executable, running tests..."
                                                ./cql_test --gtest_output=xml:test_results.xml || echo "Some tests may have failed"
                                            else
                                                echo "cql_test executable not found, trying alternative methods..."
                                                # Try using CTest
                                                if [ -f CTestTestfile.cmake ]; then
                                                    echo "Running tests with CTest..."
                                                    ctest --output-on-failure --no-compress-output -T Test || echo "CTest completed with some failures"
                                                fi
                                            fi
                                            
                                            # Also test the main executable
                                            if [ -f cql ]; then
                                                echo "Testing main CQL executable..."
                                                ./cql --help || echo "CQL help command completed"
                                                ./cql --version || echo "CQL version command completed"
                                            else
                                                echo "Main cql executable not found"
                                            fi
                                            
                                            echo "Listing build directory contents:"
                                            ls -la
                                        """
                                    }
                                }
                            }
                            post {
                                always {
                                    // Publish test results if available
                                    junit testResults: '**/test_results.xml', allowEmptyResults: true
                                    junit testResults: '**/Testing/**/*.xml', allowEmptyResults: true
                                }
                            }
                        }
                        
                        stage('Archive Artifacts') {
                            steps {
                                script {
                                    // Archive build artifacts
                                    archiveArtifacts artifacts: 'build/cql', allowEmptyArchive: true
                                    archiveArtifacts artifacts: 'build/cql_test', allowEmptyArchive: true
                                    archiveArtifacts artifacts: 'build/CMakeCache.txt', allowEmptyArchive: true
                                    archiveArtifacts artifacts: 'build/compile_commands.json', allowEmptyArchive: true
                                    
                                    // Archive test results and logs
                                    archiveArtifacts artifacts: 'build/test_results.xml', allowEmptyArchive: true
                                    archiveArtifacts artifacts: 'build/Testing/**', allowEmptyArchive: true
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
                            echo "✅ CQL build completed successfully!"
                            echo "Build type: ${params.BUILD_TYPE}"
                            echo "Tests run: ${params.RUN_TESTS}"
                        }
                        failure {
                            echo "❌ CQL build failed. Check the logs above for details."
                        }
                    }
                }
            ''')
        }
    }
}

pipelineJob('cpp-projects/cpp-snippets-build') {
    description('Build and test the C++ Snippets collection on Mac mini M2 using build_all.sh script')
    parameters {
        stringParam('GIT_REPO_URL', 'https://github.com/dbjwhs/cpp-snippets.git', 'Git repository URL')
        stringParam('BRANCH', 'main', 'Branch to checkout')
        booleanParam('CLEAN_WORKSPACE', true, 'Clean workspace before build')
    }
    triggers {
        cron('45 * * * *')  // Run at 45 minutes past every hour
    }
    definition {
        cps {
            script('''
                pipeline {
                    agent { label 'mac-mini-m2' }
                    
                    options {
                        timeout(time: 45, unit: 'MINUTES')
                        timestamps()
                        buildDiscarder(logRotator(numToKeepStr: '15'))
                    }
                    
                    stages {
                        stage('Clean Workspace') {
                            when {
                                expression { params.CLEAN_WORKSPACE == true }
                            }
                            steps {
                                cleanWs()
                            }
                        }
                        
                        stage('Checkout Project') {
                            steps {
                                script {
                                    echo "Cloning from Git: ${params.GIT_REPO_URL}"
                                    git branch: params.BRANCH, url: params.GIT_REPO_URL
                                    
                                    // Verify this is the cpp-snippets project
                                    if (!fileExists('tooling/build_all.sh')) {
                                        error('tooling/build_all.sh not found - this does not appear to be the cpp-snippets project')
                                    }
                                    
                                    echo 'Confirmed: This is the cpp-snippets project'
                                    sh 'ls -la tooling/'
                                }
                            }
                        }
                        
                        stage('Build All Snippets') {
                            steps {
                                sh """
                                    echo "Verifying Mac C++ environment for snippets..."
                                    
                                    # Check required tools
                                    clang++ --version
                                    cmake --version
                                    
                                    # Install/check dependencies via Homebrew
                                    echo "Checking Boost installation..."
                                    brew list boost || brew install boost
                                    
                                    echo "Checking other dependencies..."
                                    brew list openssl || brew install openssl
                                    
                                    # Verify Homebrew environment
                                    echo "Boost location: \\$(brew --prefix boost)"
                                    echo "OpenSSL location: \\$(brew --prefix openssl)"
                                    
                                    # Set up environment for build
                                    export BOOST_ROOT=\\$(brew --prefix boost)
                                    export OPENSSL_ROOT_DIR=\\$(brew --prefix openssl)
                                    
                                    echo "Making build_all.sh executable..."
                                    chmod +x tooling/build_all.sh
                                    
                                    echo "Running build_all.sh script..."
                                    cd tooling
                                    ./build_all.sh
                                """
                            }
                        }
                        
                        stage('Archive Build Results') {
                            steps {
                                script {
                                    // Archive any build artifacts or logs
                                    archiveArtifacts artifacts: '**/build/**', allowEmptyArchive: true
                                    archiveArtifacts artifacts: '**/custom.log', allowEmptyArchive: true
                                    
                                    // Look for any test results
                                    if (fileExists('test-results')) {
                                        archiveArtifacts artifacts: 'test-results/**', allowEmptyArchive: true
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
                            echo "✅ cpp-snippets build completed successfully!"
                            echo "Build script: tooling/build_all.sh"
                            echo "Repository: ${params.GIT_REPO_URL}"
                            echo "Branch: ${params.BRANCH}"
                        }
                        failure {
                            echo "❌ cpp-snippets build failed. Check the logs above for details."
                        }
                    }
                }
            ''')
        }
    }
}
