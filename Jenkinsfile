pipeline {
    agent any
    
    environment {
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID = credentials('azure-tenant-id')
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_CLIENT_SECRET = credentials('azure-client-secret')
        TF_BACKEND_RESOURCE_GROUP = 'terraform-state-rg'
        TF_BACKEND_STORAGE_ACCOUNT = 'tfstatemaimoona'
        TF_BACKEND_CONTAINER = 'tfstate'
        TF_BACKEND_KEY = "${env.BRANCH_NAME}/terraform.tfstate"
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    if (isUnix()) {
                        sh '''
                        terraform init -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" \
                                     -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" \
                                     -backend-config="container_name=${TF_BACKEND_CONTAINER}" \
                                     -backend-config="key=${TF_BACKEND_KEY}"
                        '''
                    } else {
                        bat """
                        terraform init -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" ^
                                     -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" ^
                                     -backend-config="container_name=${TF_BACKEND_CONTAINER}" ^
                                     -backend-config="key=${TF_BACKEND_KEY}"
                        """
                    }
                }
            }
        }
        
        stage('Terraform Validate') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'terraform validate'
                    } else {
                        bat 'terraform validate'
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        // Remove or replace slackSend if you don't have the plugin
    }
}