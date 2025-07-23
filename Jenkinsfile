pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['staging', 'production'], description: 'Deployment environment')
        booleanParam(name: 'DESTROY_ENABLED', defaultValue: false, description: 'Enable Terraform destroy')
    }

    environment {
        // Store these sensitive values in Jenkins credentials
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_TENANT_ID = credentials('azure-tenant-id')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        TF_IN_AUTOMATION = 'true'  // Important for Terraform in CI/CD
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET')]) {
                    bat """
                    terraform init \\
                        -backend-config="resource_group_name=Project003_RG" \\
                        -backend-config="storage_account_name=project3tfg" \\
                        -backend-config="container_name=pro-container" \\
                        -backend-config="key=${params.ENVIRONMENT}.tfstate"
                    """
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                bat 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                bat "terraform plan -var-file=envs/${params.ENVIRONMENT}.tfvars"
            }
        }

        stage('Approval Gate') {
            when {
                expression { 
                    return params.ENVIRONMENT == 'production' || params.DESTROY_ENABLED 
                }
            }
            steps {
                script {
                    def message = params.DESTROY_ENABLED ? 
                        "Approve DESTROY of ${params.ENVIRONMENT} environment?" : 
                        "Approve PRODUCTION deployment?"
                    
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: message
                    }
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                withCredentials([string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET')]) {
                    script {
                        if (params.DESTROY_ENABLED) {
                            bat "terraform destroy -auto-approve -var-file=envs/${params.ENVIRONMENT}.tfvars"
                        } else {
                            bat "terraform apply -auto-approve -var-file=envs/${params.ENVIRONMENT}.tfvars"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (currentBuild.result == 'SUCCESS' && !params.DESTROY_ENABLED) {
                    def output = bat script: 'terraform output -json', returnStdout: true
                    writeJSON file: 'terraform_output.json', json: output
                    archiveArtifacts artifacts: 'terraform_output.json'
                }
            }
            cleanWs()
        }
        failure {
            echo "Pipeline failed for environment: ${params.ENVIRONMENT}"
            // Consider adding notification here (Slack, email, etc.)
        }
        success {
            echo "Pipeline succeeded for environment: ${params.ENVIRONMENT}"
        }
    }
}
