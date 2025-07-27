# envs/production.tfvars
# Variables for the production environment, matching variables.tf

project_name   = "MyWebAppProject" # Same project name
environment    = "production"      # Matches the 'production' choice in Jenkins
location       = "West US 2"       # Different region for production (example)
vm_count       = 2                 # More VMs for production
vm_size        = "Standard_B2ms"   # Larger VM size for production (example)

# IMPORTANT: Replace these with actual secure credentials for your production VMs
# These are example values. DO NOT use these exact values in production.
admin_username = "prodadmin"
admin_password = "ProductionSuperSecurePassword456!"

tags = {
  Environment = "production"
  Project     = "MyWebApp"
  Owner       = "Maimoona"
  CostCenter  = "12345"
}
