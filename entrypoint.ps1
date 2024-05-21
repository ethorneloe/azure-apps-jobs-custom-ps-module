$uamiClientId = $env:UAMI_CLIENT_ID
$storageAccountName = $env:STORAGE_ACCOUNT_NAME
$functionName = $env:FUNCTION_NAME
$paramsString = $env:PARAMS
$moduleName = $env:MODULE_NAME
$moduleVersion = $env:MODULE_VERSION
$containerName = $env:STORAGE_ACCOUNT_CONTAINER_NAME

# Configure Concise view for errors and set the output rendering to Plain text.  This keeps error output on one line and removes ansi sequences.
$PSStyle.OutputRendering = 'PlainText'
$ErrorView = 'ConciseView'

# Connect with managed identity
try {
    $AzureContext = (Connect-AzAccount -Identity -AccountId $uamiClientId).context
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
}
catch {
    Write-Error "Unable to connect with managed identity. Ensure that the managed identity is correctly configured."
    return 1
}

# Create a storage context with managed identity
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# Determine the latest version if not specified
if (-not $moduleVersion) {
    $allBlobs = Get-AzStorageBlob -Container $containerName -Prefix "$moduleName/" -Context $storageContext
    $versionFolders = $allBlobs.Name | Where-Object { $_ -match "$moduleName/(\d+\.\d+\.\d+)/" } | ForEach-Object { $Matches[1] } | Sort-Object -Descending { [Version]$_ }
    $moduleVersion = $versionFolders[0]
}

$modulePathBlobPrefix = "$moduleName/$moduleVersion"

# Get all blobs in the container with the prefix corresponding to the module name
$blobList = Get-AzStorageBlob -Container $containerName -Prefix $modulePathBlobPrefix -Context $storageContext

# Download the blobs and replicate the directory structure
foreach ($blob in $blobList) {

    $localFilePath = Join-Path -Path (Get-Location) -ChildPath $blob.Name

    # Ensure the directory structure exists
    $localModulePath = Split-Path -Path $localFilePath -Parent
    If (-Not (Test-Path -Path $localModulePath)) {
        New-Item -ItemType Directory -Path $localModulePath -Force | Out-Null
    }

    # Download the blob
    Get-AzStorageBlobContent -Blob $blob.Name -Container $containerName -Context $storageContext -Destination $localFilePath -Force | Out-Null
}

# Import the custom module
try {
    Import-Module "$localModulePath\$moduleName.psd1" -Force
}
catch {
    Write-Error "Unable to import module $moduleName from $localModulePath"
    Return 1
}

# Execute module function with params
$Params = ConvertFrom-Json -InputObject $paramsString -AsHashtable
& $functionName @Params
