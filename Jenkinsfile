pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['staging', 'production'], description: 'Deployment environment')
        booleanParam(name: 'DESTROY_ENABLED', defaultValue: false, description: 'Enable Terraform destroy')
    }

    environment {
        // These sensitive values are retrieved from Jenkins credentials
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_TENANT_ID = credentials('azure-tenant-id')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        TF_IN_AUTOMATION = 'true'  // Important for Terraform in CI/CD
    }

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET')]) {
                    bat """
                    terraform init ^
                        -backend-config="resource_group_name=terraform-state-rg" ^
                        -backend-config="storage_account_name=tfstatemoona" ^
                        -backend-config="container_name=tfstate" ^
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
                withCredentials([string(credentialsId: 'azure-client-secret', variable: 'ARM_CLIENT_SECRET')]) {
                    bat """
                    echo "--- Debugging Azure Credentials ---"
                    echo "ARM_CLIENT_ID: %ARM_CLIENT_ID%"
                    echo "ARM_TENANT_ID: %ARM_TENANT_ID%"
                    echo "ARM_SUBSCRIPTION_ID: %ARM_SUBSCRIPTION_ID%"
                    REM echo "ARM_CLIENT_SECRET: %ARM_CLIENT_SECRET%"
                    
                    echo "Attempting az login with Service Principal..."
                    # Explicitly log in using the Service Principal credentials
                    az login --service-principal --username %ARM_CLIENT_ID% --password %ARM_CLIENT_SECRET% --tenant %ARM_TENANT_ID%
                    
                    echo "Attempting az account show to verify authentication context after login..."
                    az account show --output json
                    
                    echo "Running terraform plan..."
                    terraform plan -var-file=envs/${params.ENVIRONMENT}.tfvars
                    """
                }
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
}
