# Jenkins CI/CD Setup with Docker and Python Tests

## Directory Setup
```bash
jenkins-setup/
├── Dockerfile
├── docker-compose.yml
├── jenkins.yaml
├── plugins.txt
└── Jenkinsfile
```

## File Contents

### docker-compose.yml
```yaml
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    group_add:
      - "998"
    user: root
    restart: always
    networks:
      - jenkins-network

networks:
  jenkins-network:
    driver: bridge

volumes:
  jenkins_home:
```

### Dockerfile
```dockerfile
FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
```

### plugins.txt
```text
configuration-as-code:latest
job-dsl:latest
workflow-job:latest
workflow-cps:latest
git:latest
workflow-multibranch:latest
```

### jenkins.yaml
```yaml
jenkins:
  systemMessage: "Jenkins configured using JCasC"
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "admin"

  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false

  remotingSecurity:
    enabled: true
```

### Jenkinsfile
```groovy
pipeline {
    agent { docker { image 'python:3.9' } }
    parameters {
        string(name: 'NAME', defaultValue: 'World', description: 'Name to greet')
        choice(name: 'LANGUAGE', choices: ['English', 'Spanish', 'French', 'German', 'Italian'], description: 'Language')
        booleanParam(name: 'FORMAL', defaultValue: false, description: 'Use formal greeting')
    }
    stages {
        stage('Test') {
            steps {
                writeFile file: 'translator.py', text: '''
translations = {
    'English': {'informal': 'Hello', 'formal': 'Good day'},
    'Spanish': {'informal': 'Hola', 'formal': 'Buenos días'},
    'French': {'informal': 'Salut', 'formal': 'Bonjour'},
    'German': {'informal': 'Hallo', 'formal': 'Guten Tag'},
    'Italian': {'informal': 'Ciao', 'formal': 'Buongiorno'}
}

def greet(name, language, formal=False):
    style = 'formal' if formal else 'informal'
    greeting = translations[language][style]
    return f"{greeting}, {name}!"
'''
                writeFile file: 'test_translator.py', text: '''
import unittest
import os
from translator import greet, translations

class TestTranslator(unittest.TestCase):
    def test_greeting_style(self):
        name = os.getenv('NAME', 'World')
        language = os.getenv('LANGUAGE', 'English')
        formal = os.getenv('FORMAL', 'False').lower() == 'true'
        result = greet(name, language, formal)
        style = 'formal' if formal else 'informal'
        self.assertTrue(translations[language][style] in result)

if __name__ == '__main__':
    unittest.main()
'''
                withEnv(["NAME=${params.NAME}", "LANGUAGE=${params.LANGUAGE}", "FORMAL=${params.FORMAL}"]) {
                    sh 'python -m unittest test_translator.py -v'
                    sh '''python -c "from translator import greet; print(greet('${NAME}', '${LANGUAGE}', False))"'''
                }
            }
        }
    }
}
```

## Quick Start
1. Create files with above contents
2. Run: `docker-compose up -d`
3. Access: http://localhost:8080
4. Login: admin/admin

## Features
- Containerized Jenkins
- Python test automation
- Multi-language greetings
- Formal/informal options
- Parameterized builds
- Docker-in-Docker support
- Automated testing