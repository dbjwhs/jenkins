// Jenkinsfile.js
const pipeline = require('@jenkins-cd/pipeline-js');

pipeline.pipeline({
    agent: {
        docker: {
            image: 'node:latest',
            args: '-v $HOME/.npm:/root/.npm'
        }
    },
    stages: {
        Checkout: {
            steps: () => {
                git 'https://your-repository-url.git'
            }
        },
        Install: {
            steps: () => {
                sh 'npm install'
            }
        },
        Test: {
            steps: () => {
                sh 'npm test'
            }
        }
    }
});