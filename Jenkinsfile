pipeline {
    agent any
    
    environment {
        // Azure credentials from Jenkins
        ARM_SUBSCRIPTION_ID     = credentials('azure-subscription-id')
        ARM_TENANT_ID           = credentials('azure-tenant-id')
        ARM_CLIENT_ID           = credentials('azure-client-id')
        ARM_CLIENT_SECRET       = credentials('azure-client-secret')
        
        // Terraform backend configuration
        TF_BACKEND_RESOURCE_GROUP = 'terraform-state-rg'
        TF_BACKEND_STORAGE_ACCOUNT = 'tfstatemaimoona'
        TF_BACKEND_CONTAINER     = 'tfstate'
        TF_BACKEND_KEY          = "${env.BRANCH_NAME}/terraform.tfstate"
        
        // Determine environment based on branch
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
                sh '''
                terraform init -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" \
                               -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" \
                               -backend-config="container_name=${TF_BACKEND_CONTAINER}" \
                               -backend-config="key=${TF_BACKEND_KEY}"
                '''
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh """
                terraform plan \
                  -var-file="./environments/${ENVIRONMENT}/terraform.tfvars" \
                  -out=tfplan
                """
                archiveArtifacts artifacts: 'tfplan', fingerprint: true
            }
        }
        
        stage('Manual Approval') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Approve production deployment?'
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                anyOf {
                    branch 'main'
                    branch 'staging'
                }
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend(color: 'good', message: "Terraform ${ENVIRONMENT} deployment succeeded: ${env.BUILD_URL}")
        }
        failure {
            slackSend(color: 'danger', message: "Terraform ${ENVIRONMENT} deployment failed: ${env.BUILD_URL}")
        }
    }
}