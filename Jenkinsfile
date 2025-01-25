pipeline {
    agent { docker { image 'python:3.9' } }
    parameters {
        string(name: 'MESSAGE', defaultValue: 'Hello World', description: 'Message to print')
    }
    stages {
        stage('Run Python') {
            steps {
                sh "python -c 'print(\"${params.MESSAGE} from Python!\")'"
            }
        }
    }
}