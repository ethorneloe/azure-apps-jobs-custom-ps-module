# STATUS
This is a work in progress, and these steps are not yet completed/tested.

# Overview
This repository provides a step-by-step guide for running custom PowerShell module functions as Azure Container Apps Jobs.

# Goals
- To provide easy-to-follow configuration steps suitable for learning and experimentation using Azure CLI.
- To demonstrate how `Azure Container Apps Jobs` can be used to execute custom PowerShell module functions imported from a storage account.  The custom PowerShell module is deployed to the storage account via GitHub Actions as a versioned folder.

# Prerequisites
- An Azure subscription with privileged access.
- A GitHub account.
- Familiarity with Azure resource deployment and GitHub repo configuration.
- A workstation with Azure CLI installed.

# Why Use Azure Container Apps Jobs with Custom PowerShell Module Functions
- **Ephemeral Execution** - Each job runs in its own container which is created and destroyed whenever the job needs to execute.
- **Managed Identity** - Managed identities can be assigned to the job for secure role-based access control to Azure resources.
- **Private VNET** - Private VNET is available for enabling access to private Azure resources and on-prem resources if required.
- **Flexibility and Independence** - Dockerfiles and entrypoints can be customised to suit different jobs with different dependencies.
- **Auto-Scaling** - Jobs can be scaled using KEDA Scalers such as `Azure Event Hubs`, `Azure Storage Queue`, `Azure Service Bus`.
- **Cron String Support** - Jobs can be scheduled with cron string as often as once per-minute (`Azure Automation` only supports hourly unless multiple schedules are created, or another cron supporting resource is used to trigger runbooks with webhook.)

# Architecture


# Configuration Steps

## Copy the repo
1. Feel free to make a copy of this repo using the button below.  When the repo creation page comes up, set the scope of the repo to `private`.
[![Create a Copy](https://img.shields.io/badge/-Create%20a%20Copy-darkgreen)](https://github.com/ethorneloe/azure-apps-jobs-custom-ps-module/generate)

### Storage account deployment workflow
This needs to be stup later after the Azure resources are created
1. The `deploy-module-to-storage-account.yml` workflow deploys the versioned folder of the PowerShell module to the Azure Storage Account.  

We have to have steps to build the Azure resources, then deploy the custom module into the storage account.  So you will need a workflow to deploy the module to the storage account as a versioned folder. 


## Docker
The docker file in this repo uses the microsoft azure powershell image as a base, and adds a PowerShell entrypoint that makes use of the Azure Container Apps Job environment variables to execute the custom module function.



## Azure

### Configure Variables, Storage Account, Key Vault, and User-Assigned Managed Identity

1. Make sure you have the latest version of Azure CLI installed.
   ```
   az upgrade
   ```
   More details on installation can be found [here](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   <br /><br />
1. Add the containerapp extension.
   ```
   az extension add -n containerapp
   ```
   <br />
1. Log into Azure.
   ```
   az login --only-show-errors --output none
   ```
   <br />
1. Save your subscription ID to a variable.

   PowerShell
   ```
   $SUBSCRIPTION_ID = az account show --query "id" -o tsv
   ```

   Bash
   ```
   SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
   ```
   <br />
1. Place `Dockerfile` and `entrypoint.sh`(included in this repo, or use your own) together into a local folder. If using `Windows`, make sure the `entrypoint.sh` file is using `Linux` line-endings.  Fill in values for the variables below and execute.
    
   PowerShell
   ```powershell
   $DOCKERFILE_PATH = '<Local path that contains your Dockerfile(just the containing folder without the filename)>'
   $LOCATION = '<Your Preferred Azure Location>'
   ```
   
   Bash
   ```Bash
   DOCKERFILE_PATH='<Local path that contains your Dockerfile(just the containing folder without the filename)>'
   LOCATION='<Your Preferred Azure Location>'
   ```
   
   <br />
1. Execute this as is, or feel free to change the naming convention as required.

   PowerShell
   ```powershell
   $RANDOM_5_DIGITS = -join (('0123456789abcdefghijklmnopqrstuvwxyz').ToCharArray() | Get-Random -Count 5)
   $CONTAINER_IMAGE_NAME = 'pscustommodule:1.0'
   $CONTAINER_REGISTRY_NAME = "pscustommodule$RANDOM_5_DIGITS"
   $CONTAINER_APPS_ENVIRONMENT_NAME = "cae-pscustommodule-$RANDOM_5_DIGITS"
   $FUNCTION_NAME = 'Get-ResourceCount'
   $CONTAINER_APPS_JOB_NAME = "caj-pscustommodule_$FUNCTION_NAME"
   $GITHUB_SERVICE_PRINCIPLE_NAME = "sp-github-pscustommodule-$RANDOM_5_DIGITS"
   $KEYVAULT_NAME = "kv-pscustommodule-$RANDOM_5_DIGITS"
   $KEYVAULT_SECRET_NAME = "$FUNCTION_NAME-params"
   $LOG_ANALYTICS_WORKSPACE_NAME = "workspace-pscustommodule-$RANDOM_5_DIGITS"
   $STORAGE_ACCOUNT_NAME = 'pscustommodule$RANDOM_5_DIGITS'
   $STORAGE_ACCOUNT_CONTAINER_NAME = 'pscustommodules'
   $MODULE_NAME='CustomModule'
   $MODULE_VERSION = '1.0.0'
   $RESOURCE_GROUP_NAME = "rg-pscustommodule-$RANDOM_5_DIGITS"
   $UAMI_NAME = "uami-pscustommodule-$RANDOM_5_DIGITS"
   ```
   
   Bash
   ```Bash
   RANDOM_5_DIGITS=$(openssl rand -base64 25 | tr -d '+/' | sed -e 's|\(.\{5\}\).*|\1|' | tr '[:upper:]' '[:lower:]')
   CONTAINER_IMAGE_NAME='pscustommodule:1.0'
   CONTAINER_REGISTRY_NAME="pscustommodule$RANDOM_5_DIGITS"
   CONTAINER_APPS_ENVIRONMENT_NAME="cae-pscustommodule-$RANDOM_5_DIGITS"
   FUNCTION_NAME='Get-ResourceCount'
   CONTAINER_APPS_JOB_NAME="caj-pscustommodule_$FUNCTION_NAME"
   GITHUB_SERVICE_PRINCIPLE_NAME="sp-github-pscustommodule-$RANDOM_5_DIGITS"
   KEYVAULT_NAME="kv-pscustommodule-$RANDOM_5_DIGITS"
   KEYVAULT_SECRET_NAME="$FUNCTION_NAME-params"
   LOG_ANALYTICS_WORKSPACE_NAME="workspace-pscustommodule-$RANDOM_5_DIGITS"
   STORAGE_ACCOUNT_NAME='pscustommodule$RANDOM_5_DIGITS'
   STORAGE_ACCOUNT_CONTAINER_NAME='pscustommodules'
   MODULE_NAME='CustomModule'
   MODULE_VERSION='1.0.0'
   RESOURCE_GROUP_NAME="rg-pscustommodule-$RANDOM_5_DIGITS"
   UAMI_NAME="uami-pscustommodule-$RANDOM_5_DIGITS"
   ```
   <br />
1. Create the resource group.
   ```
   az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --output none
   ```
   <br />
1. Create the key vault.    

   PowerShell
   ```powershell
   az keyvault create `
     --name $KEYVAULT_NAME `
     --resource-group $RESOURCE_GROUP_NAME `
     --location $LOCATION `
     --enable-rbac-authorization true `
     --output none
   ```
   
   Bash
   ```bash
   az keyvault create \
     --name $KEYVAULT_NAME \
     --resource-group $RESOURCE_GROUP_NAME \
     --location $LOCATION \
     --enable-rbac-authorization true \
     --output none
   ```
   <br />
1. Save your Azure user account ID into a variable.

   PowerShell
   ```powershell
   $USER_ID = az ad signed-in-user show --query id -o tsv
   ```

   Bash
   ```bash
   USER_ID=$(az ad signed-in-user show --query id -o tsv)
   ```

   <br />
1. Create a role assignment for your account on the key vault to enable administration.

   PowerShell
   ```powershell
   az role assignment create `
     --assignee $USER_ID `
     --role '00482a5a-887f-4fb3-b363-3b7fe8e74483' `
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" `
     --output none
   ```

   Bash
   ```bash
   az role assignment create \
     --assignee $USER_ID \
     --role '00482a5a-887f-4fb3-b363-3b7fe8e74483' \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
     --output none
   ```
   <br />
1. Create a user-assigned managed identity(uami).  This will be used to access the secret, the container registry later on, and also can be used inside the GitHub workflows that run in the container apps job for performing operations in Azure.
   
   PowerShell
   ```powershell
   az identity create `
     --resource-group $RESOURCE_GROUP_NAME `
     --name $UAMI_NAME `
     --location $LOCATION `
     --output none
   ```
   
   Bash
   ```bash
   az identity create \
     --resource-group $RESOURCE_GROUP_NAME \
     --name $UAMI_NAME \
     --location $LOCATION \
     --output none
   ```
   <br />   
1. Get the `id` and `clientId` of the `uami`.

   PowerShell
   ```powershell
   $UAMI_CLIENT_ID = az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId --output tsv
   $UAMI_RESOURCE_ID = az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query id --output tsv
   ```
   
   Bash
   ```bash
   UAMI_CLIENT_ID=$(az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId --output tsv)
   UAMI_RESOURCE_ID=$(az identity show --name $UAMI_NAME --resource-group $RESOURCE_GROUP_NAME --query id --output tsv)
   ```
   <br />
1. Create a file that contains the parameters for the example module function(Get-ResourceCount).
   ```
   {
      "ResourceGroupName" : "<Resource group name created earler>",
      "ManagedIdentityClientId" : "<Client Id of uami created earlier>"
   }
   ```
1. Place params filepath into a variable.
   PowerShell
   ```powershell
   $FUNCTION_PARAMS_FILEPATH = '<your local params filepath>'
   ```
   
   Bash
   ```bash
   FUNCTION_PARAMS_FILEPATH='<your local params filepath>'
   ```
1. Create a new secret in the key vault for the Function parameters.  *The goal here is to show how function params can be pulled from a keyvault with Azure Container Apps Jobs*
   
   PowerShell
   ```powershell
    az keyvault secret set `
      --vault-name $KEYVAULT_NAME `
      --name $KEYVAULT_SECRET_NAME `
      --file $FUNCTION_PARAMS_FILEPATH `
      --output none
    ```
   
   Bash
   ```bash
   az keyvault secret set \
     --vault-name $KEYVAULT_NAME \
     --name $KEYVAULT_SECRET_NAME \
     --file $FUNCTION_PARAMS_FILEPATH \
     --output none
   ```
   <br />
1. Save the key vault secret URI in a variable as it will be used later.
   
   PowerShell
   ```powershell
   $KEYVAULT_SECRET_URI = az keyvault secret show `
     --name $KEYVAULT_SECRET_NAME `
     --vault-name $KEYVAULT_NAME `
     --query id `
     --output tsv
   ```
   
   Bash
   ```bash
   KEYVAULT_SECRET_URI=$(az keyvault secret show \
     --name $KEYVAULT_SECRET_NAME \
     --vault-name $KEYVAULT_NAME \
     --query id \
     --output tsv)
   ```
   <br />
1. Create a `Key Vault Secrets User` role assignment on the key vault for the `uami`. Note the value used with `--role` which corresponds to the `Key Vault Secrets User` role. Microsoft recommends using the id for roles in the event they are renamed.
   
   PowerShell
   ```powershell
   az role assignment create `
     --role '4633458b-17de-408a-b874-0445c86b69e6' `
     --assignee $UAMI_CLIENT_ID `
     --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP_NAME `
     --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
     --role '4633458b-17de-408a-b874-0445c86b69e6' \
     --assignee $UAMI_CLIENT_ID \
     --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP_NAME \
     --output none
   ```
   <br />
1. Create the storage account

   PowerShell
   ```powershell
    az storage account create `
      --name $STORAGE_ACCOUNT_NAME `
      --resource-group $RESOURCE_GROUP_NAME `
      --location $LOCATION `
      --sku Standard_LRS `
      --kind StorageV2 `
      --allow-blob-public-access false `
      --min-tls-version TLS1_2 `
      --output none
   ```
   
   Bash
   ```bash
       az storage account create \
      --name $STORAGE_ACCOUNT_NAME \
      --resource-group $RESOURCE_GROUP_NAME \
      --location $LOCATION \
      --sku Standard_LRS \
      --kind StorageV2 \
      --allow-blob-public-access false \
      --min-tls-version TLS1_2 \
      --output none
   ```

1. Grant yourself contributor access to the storage account.
   
    PowerShell
   ```powershell
   az role assignment create `
     --role 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' `
     --assignee $USER_ID `
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" `
     --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
     --role 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' \
     --assignee $USER_ID \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" \
     --output none
   ```
   <br />
1.  Create a blob container for the custom PowerShell modules.

    PowerShell
   ```powershell
   az storage container create `
    --account-name $STORAGE_ACCOUNT_NAME `
    --name $STORAGE_ACCOUNT_CONTAINER_NAME `
    --auth-mode login `
    --public-access off `
    --output none
   ```
   
   Bash
   ```bash
   az storage container create \
    --account-name $STORAGE_ACCOUNT_NAME \
    --name $STORAGE_ACCOUNT_CONTAINER_NAME \
    --auth-mode login \
    --public-access off \
    --output none
   ```

1. Grant yourself the `Storage Blob Data Owner` role on the blob container.
   
    PowerShell
   ```powershell
   az role assignment create `
    --assignee $USER_ID `
    --role "Storage Blob Data Owner" `
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default/containers/$STORAGE_ACCOUNT_CONTAINER_NAME" `
    --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
    --assignee $USER_ID \
    --role "Storage Blob Data Owner" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default/containers/$STORAGE_ACCOUNT_CONTAINER_NAME" \
    --output none
   ```

1. Grant the `uami` read access to the blob container.

   PowerShell
   ```powershell
   az role assignment create `
     --assignee $UAMI_CLIENT_ID `
     --role "Storage Blob Data Reader" `
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default/containers/$STORAGE_ACCOUNT_CONTAINER_NAME" `
     --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
     --assignee $UAMI_CLIENT_ID \
     --role "Storage Blob Data Reader" \
     --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default/containers/$STORAGE_ACCOUNT_CONTAINER_NAME" \
     --output none
   ```
1. Create the service principle to be used for deployment from GitHub.

1. Grant the service principle contributor access to the blob container.

   If you have not already done so, take some time if you like to check the resources in the Azure Portal to confirm the `uami` and `keyvault` resources are present and the secret is configured correctly with the Function params.  Also check the role assignment on the keyvault for the `uami`.  Continue to the next steps if everything looks ok.
   <br />
### Create Container App Resources and Log Analytics Workspace

1. Create the container registry(acr).
   
   PowerShell
   ```powershell
   az acr create `
     --resource-group $RESOURCE_GROUP_NAME `
     --name $CONTAINER_REGISTRY_NAME `
     --sku Basic `
     --output none
   ```
   
   Bash
   ```bash
   az acr create \
     --resource-group $RESOURCE_GROUP_NAME \
     --name $CONTAINER_REGISTRY_NAME \
     --sku Basic \
     --output none
   ```
   <br />
1. Get the resource ID of the `acr` for role assignment
   
   PowerShell
   ```powershell
   $ACR_RESOURCE_ID = az acr show --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_REGISTRY_NAME --query id --output tsv
   ```
   
   Bash
   ```bash
   ACR_RESOURCE_ID=$(az acr show --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_REGISTRY_NAME --query id --output tsv)
   ```
   <br />  
1. Grant the `uami` access to the `acr` to ensure the container apps job can pull images from the `acr`.
   
   PowerShell
   ```powershell
   az role assignment create `
     --assignee $UAMI_CLIENT_ID `
     --scope $ACR_RESOURCE_ID `
     --role '7f951dda-4ed3-4680-a7ca-43fe172d538d' `
     --output none
   ```
   
   Bash
   ```bash
   az role assignment create \
     --assignee $UAMI_CLIENT_ID \
     --scope $ACR_RESOURCE_ID \
     --role '7f951dda-4ed3-4680-a7ca-43fe172d538d' \
     --output none
   ```
   <br />
1. Create a new container based on the Dockerfile.
   
   PowerShell
   ```powershell
   az acr build `
     --registry "$CONTAINER_REGISTRY_NAME" `
     --image "$CONTAINER_IMAGE_NAME" `
     --file "$DOCKERFILE_PATH\Dockerfile" $DOCKERFILE_PATH
   ```
   
   Bash
   ```bash
   az acr build \
     --registry "$CONTAINER_REGISTRY_NAME" \
     --image "$CONTAINER_IMAGE_NAME" \
     --file "$DOCKERFILE_PATH/Dockerfile" $DOCKERFILE_PATH
   ```
   <br />
1. Create a Log Analytics Workspace(law) to associate with the Container Apps Environment(cae).
   
   PowerShell
   ```powershell
   az monitor log-analytics workspace create `
     --resource-group $RESOURCE_GROUP_NAME `
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME `
     --location $LOCATION `
     --output none
   ```
   
   Bash
   ```bash
   az monitor log-analytics workspace create \
     --resource-group $RESOURCE_GROUP_NAME \
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME \
     --location $LOCATION \
     --output none
   ```
   <br />   
1. Save the `law` ID into a variable.  
   *The ID we need here is the `customerId`*
   
   PowerShell
   ```powershell
   $LOG_ANALYTICS_WORKSPACE_ID = az monitor log-analytics workspace show `
     --query customerId `
     --resource-group $RESOURCE_GROUP_NAME `
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME `
     --output tsv
   ```
   
   Bash
   ```bash
   LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show \
     --query customerId \
     --resource-group $RESOURCE_GROUP_NAME \
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME \
     --output tsv)
   ```
   <br />  
1. Save the `law` key into a variable.
   
   PowerShell
   ```powershell
   $LOG_ANALYTICS_WORKSPACE_KEY = az monitor log-analytics workspace get-shared-keys `
     --resource-group $RESOURCE_GROUP_NAME `
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME `
     --query primarySharedKey `
     --output tsv
   ```
   
   Bash
   ```bash
   LOG_ANALYTICS_WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
     --resource-group $RESOURCE_GROUP_NAME \
     --workspace-name $LOG_ANALYTICS_WORKSPACE_NAME \
     --query primarySharedKey \
     --output tsv)
   ```
   <br />   
1. Create the `cae` for the container apps job(caj).
   
   PowerShell
   ```powershell
   az containerapp env create `
     --name $CONTAINER_APPS_ENVIRONMENT_NAME `
     --resource-group $RESOURCE_GROUP_NAME `
     --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_ID `
     --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_KEY `
     --logs-destination log-analytics `
     --location $LOCATION `
     --output none `
     --only-show-errors
   ```
   
   Bash
   ```bash
   az containerapp env create \
     --name $CONTAINER_APPS_ENVIRONMENT_NAME \
     --resource-group $RESOURCE_GROUP_NAME \
     --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_ID \
     --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_KEY \
     --logs-destination log-analytics \
     --location $LOCATION \
     --output none \
     --only-show-errors
   ```
   <br />

1. Configure env vars for the job.  The powershell file called by the entrypoint script will use these to execute the module function.
   
   PowerShell       
   ```powershell
   $ENV_VARS = @(
     "PARAMS=secretref:$FUNCTION_NAME-params",
     "FUNCTION_NAME=$FUNCTION_NAME",
     "UAMI_CLIENT_ID=$UAMI_CLIENT_ID",
     "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME",
     "STORAGE_ACCOUNT_CONTAINER_NAME=$STORAGE_ACCOUNT_CONTAINER_NAME",
     "MODULE_NAME=$MODULE_NAME",
     "MODULE_VERSION=$MODULE_VERSION",
     "TERM=dumb"
   )
   ```
   
   Bash
   ```Bash
   ENV_VARS=(
     "PARAMS=secretref:$FUNCTION_NAME-params",
     "FUNCTION_NAME=$FUNCTION_NAME",
     "UAMI_CLIENT_ID=$UAMI_CLIENT_ID",
     "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME",
     "STORAGE_ACCOUNT_CONTAINER_NAME=$STORAGE_ACCOUNT_CONTAINER_NAME",
     "MODULE_NAME=$MODULE_NAME",
     "MODULE_VERSION=$MODULE_VERSION",
     "TERM=dumb"
   )
   ```
   <br />

1. Create the `caj`.  
   *Note that the `--mi-user-assigned` option is not needed when `--registry-identity` is the same identity, and there will be a warning about how the `uami` is already added if you supply both.*
   
   PowerShell
   ```powershell
   az containerapp job create `
     --name "$CONTAINER_APPS_JOB_NAME" `
     --resource-group "$RESOURCE_GROUP_NAME" `
     --environment "$CONTAINER_APPS_ENVIRONMENT_NAME" `
     --trigger-type "Manual" `
     --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" `
     --registry-identity $UAMI_RESOURCE_ID `
     --cpu "2.0" `
     --memory "4Gi" `
     --secrets "$FUNCTION_NAME-params=keyvaultref:$KEYVAULT_SECRET_URI,identityref:$UAMI_RESOURCE_ID" `
     --env-vars $ENV_VARS `
     --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" `
     --output none
   ```

   Bash
   ```bash
   az containerapp job create \
     --name "$CONTAINER_APPS_JOB_NAME" \
     --resource-group "$RESOURCE_GROUP_NAME" \
     --environment "$CONTAINER_APPS_ENVIRONMENT_NAME" \
     --trigger-type "Manual" \
     --image "$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME" \
     --registry-identity $UAMI_RESOURCE_ID \
     --cpu "2.0" \
     --memory "4Gi" \
     --secrets "$FUNCTION_NAME-params=keyvaultref:$KEYVAULT_SECRET_URI,identityref:$UAMI_RESOURCE_ID" \
     --env-vars $ENV_VARS \
     --registry-server "$CONTAINER_REGISTRY_NAME.azurecr.io" \
     --output none
   ```

   <br />
## Testing the Solution

Run the job manually.  Check that the module function executes and output is displayed in job logs.


