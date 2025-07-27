# envs/staging.tfvars
# Variables for the staging environment, matching variables.tf

project_name   = "MyWebAppProject" # A name for your project
environment    = "staging"         # Matches the 'staging' choice in Jenkins
location       = "East US"         # Default in variables.tf, but explicitly set
vm_count       = 1                 # Single VM for staging
vm_size        = "Standard_B1s"    # Small VM size for staging

# IMPORTANT: Replace these with actual secure credentials for your staging VMs
# These are example values. DO NOT use these exact values in production.
admin_username = "stagingadmin"
admin_password = "StagingSecurePassword123!"

tags = {
  Environment = "staging"
  Project     = "MyWebApp"
  Owner       = "Maimoona1"
}
