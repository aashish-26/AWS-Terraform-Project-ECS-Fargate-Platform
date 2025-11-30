# dev.tfvars
# Placeholder values for Azure dev environment.

environment = "dev"
location    = "eastus"
project     = "infra-project"

# App Service Plan SKU: B1 (Basic) is the cheapest paid tier.
# If your subscription supports Free tier, you can change this to "F1"
# 
# IMPORTANT: If you get quota errors ("Current Limit (Basic VMs): 0"), you need to:
# 1. Go to Azure Portal → Subscriptions → Your subscription → Usage + quotas
# 2. Search for "App Service Plans" or "App Service (Basic VMs)"
# 3. Click "Request increase" and request at least 1 VM
# 4. Wait for approval, then re-run terraform apply
#
# See docs/TROUBLESHOOTING.md for more details.
# app_service_sku_name = "B1"

