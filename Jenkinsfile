pipeline {
    agent any

    parameters {
        booleanParam(name: 'DESTROY_ENABLED', defaultValue: false, description: 'Enable Terraform destroy in staging')
        string(name: 'ENVIRONMENT', defaultValue: 'staging', description: 'Deployment environment')
    }

    environment {
        ARM_CLIENT_ID = '77c9545d-ef6e-4418-8e09-6f7a1a692bd8'
        ARM_TENANT_ID = '05a0f98e-063b-4bd9-b1c6-29e7cc58a8fc'
        // ARM_CLIENT_SECRET will come from Jenkins credentials securely
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Azure Login') {
            steps {
                script {
                    // Use your updated credential ID here
                    withCredentials([string(credentialsId: 'azure client secret new', variable: 'ARM_CLIENT_SECRET')]) {
                        bat """
                        az login --service-principal -u %ARM_CLIENT_ID% -p %ARM_CLIENT_SECRET% --tenant %ARM_TENANT_ID%
                        """
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                bat 'terraform init -backend-config=${ENVIRONMENT}/backend.tfvars'
            }
        }

        stage('Terraform Plan') {
            steps {
                bat 'terraform plan -var-file=${ENVIRONMENT}/terraform.tfvars'
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    if (params.DESTROY_ENABLED) {
                        bat 'terraform destroy -auto-approve -var-file=${ENVIRONMENT}/terraform.tfvars'
                    } else {
                        bat 'terraform apply -auto-approve -var-file=${ENVIRONMENT}/terraform.tfvars'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo "Build failed on environment: ${params.ENVIRONMENT}"
        }
        success {
            echo "Build succeeded on environment: ${params.ENVIRONMENT}"
        }
    }
}
