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
        formal = os.getenv('FORMAL', 'false').lower() == 'true'
        result = greet(name, language, formal)
        style = 'formal' if formal else 'informal'
        self.assertTrue(translations[language][style] in result)

if __name__ == '__main__':
    unittest.main()
'''
                withEnv(["NAME=${params.NAME}", "LANGUAGE=${params.LANGUAGE}", "FORMAL=${params.FORMAL}"]) {
                    sh 'python -m unittest test_translator.py -v'
                    sh "python -c 'from translator import greet; print(greet(\"${params.NAME}\", \"${params.LANGUAGE}\", ${params.FORMAL}))'"
                }
            }
        }
    }
}