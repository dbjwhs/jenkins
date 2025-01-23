folder('javascript-tests') {
    description('Folder for JavaScript test jobs')
}

pipelineJob('javascript-tests/node-test') {
    definition {
        cps {
            script('''
                pipeline {
                    agent {
                        docker {
                            image 'node:latest'
                            args '-v $HOME/.npm:/root/.npm'
                        }
                    }
                    stages {
                        stage('Checkout') {
                            steps {
                                git 'https://your-repository-url.git'
                            }
                        }
                        stage('Install') {
                            steps {
                                sh 'npm install'
                            }
                        }
                        stage('Test') {
                            steps {
                                sh 'npm test'
                            }
                        }
                    }
                }
            ''')
        }
    }
}