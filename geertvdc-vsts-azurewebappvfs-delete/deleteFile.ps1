Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$filePath = Get-VstsInput -Name filePath -Require
$deleteRecursive = Get-VstsInput -Name deleteRecursive 
$allowUnsafe = Get-VstsInput -Name allowUnsafe
$alternativeKuduUrl = Get-VstsInput -Name alternativeKuduUrl 
$continueIfFileNotExist = Get-VstsInput -Name continueIfFileNotExist 


# Initialize Azure.
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Initialize-Azure
Write-Output "Azure Initialized"

Import-Module $PSScriptRoot\vfs
Write-Output "VFS scripts Initialized"

$webapp = Get-AzureRmWebApp -name "$WebAppName"
$resourceGroup = $webapp.ResourceGroup

Write-Output "Retrieved web app: $webapp in Resource group: $resourceGroup"
Write-Output "Retrieving publishing profile"
$login = Get-AzureRmWebAppPublishingCredentials "$resourceGroup" "$WebAppName"
Write-Output "Publishing profile retrieved"

$pw = $login.Properties.PublishingPassword

Remove-FileFromWebApp -webAppName "$WebAppName" -username $login.Properties.PublishingUserName -password $pw -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeKuduUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $deleteRecursive
