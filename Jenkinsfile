pipeline {
    agent { docker { image 'python:3.9' } }
    parameters {
        string(name: 'NAME', defaultValue: 'World', description: 'Name to greet')
        choice(name: 'LANGUAGE', choices: ['English', 'Spanish', 'French', 'German', 'Italian'], description: 'Language')
    }
    stages {
        stage('Test') {
            steps {
                writeFile file: 'translator.py', text: '''
translations = {
    'English': 'Hello',
    'Spanish': 'Hola',
    'French': 'Bonjour',
    'German': 'Hallo',
    'Italian': 'Ciao'
}

def greet(name, language):
    greeting = translations.get(language, 'Hello')
    return f"{greeting} {name}!"
'''
                writeFile file: 'test_translator.py', text: '''
import unittest
import os
from translator import greet, translations

class TestTranslator(unittest.TestCase):
    def test_greetings(self):
        name = os.getenv('NAME', 'World')
        language = os.getenv('LANGUAGE', 'English')
        result = greet(name, language)
        self.assertTrue(translations[language] in result)
        self.assertTrue(name in result)

if __name__ == '__main__':
    unittest.main()
'''
                withEnv(["NAME=${params.NAME}", "LANGUAGE=${params.LANGUAGE}"]) {
                    sh 'python -m unittest test_translator.py -v'
                    sh "python -c 'from translator import greet; print(greet(\"${params.NAME}\", \"${params.LANGUAGE}\"))'"
                }
            }
        }
    }
}