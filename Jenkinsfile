pipeline {
    agent any

    parameters {
        booleanParam(name: 'DESTROY_ENABLED', defaultValue: false, description: 'Enable Terraform destroy in staging')
    }

    environment {
        // Azure Authentication
        ARM_SUBSCRIPTION_ID = 'e7b30fd7-35da-4052-be87-91cd396d34a2'
        ARM_TENANT_ID = '05a0f98e-063b-4bd9-b1c6-29e7cc58a8fc'
        ARM_CLIENT_ID = 'd9af479b-5e41-45a9-a4fa-80af60cb1161'
        ARM_CLIENT_SECRET = credentials('azure-client-secret')

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

                    // Azure login with error handling
                    bat """
                    az login --service-principal ^
                        -u %ARM_CLIENT_ID% ^
                        -p %ARM_CLIENT_SECRET% ^
                        --tenant %ARM_TENANT_ID% || exit /b 1
                    az account set --subscription %ARM_SUBSCRIPTION_ID% || exit /b 1
                    """
                }
            }
        }

        stage('Checkout SCM') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${env.BRANCH_NAME}"]],
                    extensions: [[$class: 'CleanCheckout']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Maimoona1104/terraform-azure-jenkins.git',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    bat """
                    set ARM_CLIENT_SECRET=%ARM_CLIENT_SECRET%
                    terraform init -input=false ^
                      -backend-config="resource_group_name=${TF_BACKEND_RESOURCE_GROUP}" ^
                      -backend-config="storage_account_name=${TF_BACKEND_STORAGE_ACCOUNT}" ^
                      -backend-config="container_name=${TF_BACKEND_CONTAINER}" ^
                      -backend-config="key=${TF_BACKEND_KEY}" || exit /b 1
                    """
                }
            }
        }

        stage('Terraform Format') {
            steps {
                bat 'terraform fmt -check -recursive || exit /b 1'
            }
        }

        stage('Terraform Validate') {
            steps {
                bat 'terraform validate || exit /b 1'
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    bat """
                    terraform plan -out=tfplan -input=false -var "environment=${ENVIRONMENT}" || exit /b 1
                    """
                    archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: false
                }
            }
        }

        stage('Manual Approval') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Approve deployment to production?', ok: 'Deploy'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        bat 'terraform apply -input=false -auto-approve tfplan || exit /b 1'
                    } else {
                        bat "terraform apply -input=false -auto-approve -var \"environment=${ENVIRONMENT}\" || exit /b 1"
                    }
                }
            }
        }

        stage('Terraform Destroy (Staging Only)') {
            when {
                allOf {
                    not { branch 'main' }
                    expression { params.DESTROY_ENABLED }
                }
            }
            steps {
                script {
                    bat "terraform destroy -input=false -auto-approve -var \"environment=${ENVIRONMENT}\" || exit /b 1"
                }
            }
        }
    }

    post {
        always {
            script {
                // Clean up sensitive files
                bat """
                @echo off
                if exist .terraform rmdir /s /q .terraform
                if exist terraform.tfstate del /f /q terraform.tfstate
                if exist terraform.tfstate.backup del /f /q terraform.tfstate.backup
                if exist tfplan del /f /q tfplan
                """
                cleanWs()
            }
        }
        success {
            echo "Terraform execution succeeded for ${ENVIRONMENT} environment"
        }
        failure {
            echo "Terraform execution failed for ${ENVIRONMENT} environment"
        }
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '5'))
        retry(2) // Retry the build up to 2 times if it fails
    }
}