pipeline {
    agent any
    
    environment {
        // Azure Authentication
        ARM_SUBSCRIPTION_ID = 'e7b30fd7-35da-4052-be87-91cd396d34a2'
        ARM_TENANT_ID = '05a0f98e-063b-4bd9-b1c6-29e7cc58a8fc'
        ARM_CLIENT_ID = 'd9af479b-5e41-45a9-a4fa-80af60cb1161'
        ARM_CLIENT_SECRET = credentials('azure-client-secret')  // Store in Jenkins credentials
        
        // Terraform Backend Configuration
        TF_BACKEND_RESOURCE_GROUP = 'terraform-state-rg'
        TF_BACKEND_STORAGE_ACCOUNT = 'tfstatemoona'
        TF_BACKEND_CONTAINER = 'tfstate'
        TF_BACKEND_KEY = "${env.BRANCH_NAME == 'main' ? 'production/terraform.tfstate' : 'staging/terraform.tfstate'}"
        
        // Environment Configuration
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}"
        TF_VAR_environment = "${ENVIRONMENT}"
    }
    
    stages {
        stage('Verify Azure Access') {
            steps {
                script {
                    echo "Initializing Terraform for ${ENVIRONMENT} environment"
                    echo "Using state file: ${TF_BACKEND_KEY}"
                    
                    // Verify Azure connectivity
                    sh '''
                    az login --service-principal \
                        -u ${ARM_CLIENT_ID} \
                        -p ${ARM_CLIENT_SECRET} \
                        --tenant ${ARM_TENANT_ID}
                    az account set --subscription ${ARM_SUBSCRIPTION_ID}
                    '''
                }
            }
        }
        
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    sh """
                    terraform init \
                        -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" \
                        -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" \
                        -backend-config="container_name=${TF_BACKEND_CONTAINER}" \
                        -backend-config="key=${TF_BACKEND_KEY}" \
                        -backend-config="subscription_id=${ARM_SUBSCRIPTION_ID}" \
                        -backend-config="tenant_id=${ARM_TENANT_ID}" \
                        -backend-config="client_id=${ARM_CLIENT_ID}" \
                        -backend-config="client_secret=${ARM_CLIENT_SECRET}"
                    """
                }
            }
        }
        
        stage('Terraform Format') {
            steps {
                script {
                    sh 'terraform fmt -check -recursive'
                }
            }
        }
        
        stage('Terraform Validate') {
            steps {
                script {
                    sh 'terraform validate'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                script {
                    sh """
                    terraform plan \
                        -out=tfplan \
                        -var "environment=${ENVIRONMENT}" \
                        -var "subscription_id=${ARM_SUBSCRIPTION_ID}" \
                        -var "tenant_id=${ARM_TENANT_ID}"
                    """
                    
                    // Save plan as artifact
                    archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: false
                }
            }
        }
        
        stage('Manual Approval') {
            when {
                branch 'main'
            }
            steps {
                script {
                    timeout(time: 24, unit: 'HOURS') {
                        input(
                            message: 'Approve Terraform Apply?',
                            ok: 'Apply'
                        )
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Terraform Destroy (Staging Only)') {
            when {
                not { branch 'main' }
                expression { params.DESTROY_ENABLED }
            }
            steps {
                script {
                    sh 'terraform destroy -auto-approve -var "environment=${ENVIRONMENT}"'
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up sensitive files
                sh '''
                rm -rf .terraform*
                rm -f terraform.tfstate*
                rm -f tfplan
                '''
                
                // Clean workspace
                cleanWs()
            }
        }
        success {
            echo "Terraform execution succeeded for ${ENVIRONMENT} environment"
            // slackSend color: 'good', message: "Terraform ${currentBuild.currentResult}: ${env.JOB_NAME} ${env.BUILD_NUMBER} (${env.BRANCH_NAME})"
        }
        failure {
            echo "Terraform execution failed for ${ENVIRONMENT} environment"
            // slackSend color: 'danger', message: "Terraform ${currentBuild.currentResult}: ${env.JOB_NAME} ${env.BUILD_NUMBER} (${env.BRANCH_NAME})"
        }
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
}