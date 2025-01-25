pipeline {
    agent { docker { image 'python:3.9' } }
    parameters {
        string(name: 'MESSAGE', defaultValue: 'Hello World', description: 'Message to print')
    }
    stages {
        stage('Run Test') {
            steps {
                writeFile file: 'test_hello.py', text: '''
import unittest
import os

def get_message(msg):
    return f"{msg} from Python!"

class TestHello(unittest.TestCase):
    def test_message(self):
        message = os.getenv('MESSAGE', 'Hello World')
        expected = f"{message} from Python!"
        self.assertEqual(get_message(message), expected)

if __name__ == '__main__':
    unittest.main()
'''
                withEnv(["MESSAGE=${params.MESSAGE}"]) {
                    sh 'python -m unittest test_hello.py -v'
                    sh "python -c 'print(\"${params.MESSAGE} from Python!\")'"
                }
            }
        }
    }
}