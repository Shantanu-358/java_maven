pipeline {
    agent {
        node {
            label 'agent'
        }
    }

    environment {
        APP_NAME = 'cloud-demo-app'
        DEPLOY_DIR = '/opt/cloud-demo'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '==> [Stage 1/3] Pulling latest code from GitHub...'
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                echo '==> [Stage 2/3] Compiling and running unit tests with Maven...'
                sh 'mvn clean package'
            }
            post {
                always {
                    // Record test results inside Jenkins UI
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '==> [Stage 3/3] Deploying executable JAR and restarting systemd service...'
                // Executes the automated deployment script
                sh 'sudo bash scripts/deploy.sh target/app.jar'
            }
        }
    }

    post {
        success {
            echo '========================================================'
            echo 'Deployment SUCCESS! Your app is LIVE on Port 80.'
            echo '========================================================'
        }
        failure {
            echo '========================================================'
            echo 'Deployment FAILED! Inspect the console logs above.'
            echo '========================================================'
        }
        always {
            // Free up workspace disk space on Free Tier storage
            cleanWs()
        }
    }
}