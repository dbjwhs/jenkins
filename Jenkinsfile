pipeline {
    agent { docker { image 'python:3.9' } }
    parameters {
        string(name: 'MESSAGE', defaultValue: 'Hello World', description: 'Message to print')
        choice(name: 'LANGUAGE', choices: ['English', 'Spanish', 'French'], description: 'Message language')
    }
    stages {
        stage('Run Test') {
            steps {
                writeFile file: 'translator.py', text: '''
translations = {
    'English': {'hello': 'Hello'},
    'Spanish': {'hello': 'Hola'},
    'French': {'hello': 'Bonjour'}
}

def translate(message, language):
    base = translations[language]['hello']
    return f"{base} {message} from Python!"
'''
                writeFile file: 'test_translator.py', text: '''
import unittest
import os
from translator import translate

class TestTranslator(unittest.TestCase):
    def test_translation(self):
        message = os.getenv('MESSAGE', 'World')
        language = os.getenv('LANGUAGE', 'English')
        result = translate(message, language)
        self.assertTrue(result.endswith('from Python!'))
        self.assertTrue(message in result)

if __name__ == '__main__':
    unittest.main()
'''
                withEnv(["MESSAGE=${params.MESSAGE}", "LANGUAGE=${params.LANGUAGE}"]) {
                    sh 'python -m unittest test_translator.py -v'
                    sh "python -c 'from translator import translate; print(translate(\"${params.MESSAGE}\", \"${params.LANGUAGE}\"))'"
                }
            }
        }
    }
}