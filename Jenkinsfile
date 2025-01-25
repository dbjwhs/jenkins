pipeline {
    agent { docker { image 'python:3.9' } }
    stages {
        stage('Run Python') {
            steps {
                sh 'python -c "print(\'Hello World from Python!\')"'
            }
        }
    }
}