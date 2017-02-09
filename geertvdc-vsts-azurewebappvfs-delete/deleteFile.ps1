Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$filePath = Get-VstsInput -Name filePath -Require
$allowUnsafe = Get-VstsInput -Name allowUnsafe
$alternativeKuduUrl = Get-VstsInput -Name alternativeKuduUrl 

# Initialize Azure.
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Initialize-Azure

Import-Module $PSScriptRoot\vfs

$fileUrl = Get-VstsInput -Name fileUrl -Require
$sitecoreUrl = Get-VstsInput -Name sitecoreUrl -Require

$webapp = Get-AzureRmWebApp -name "$WebAppName"
$resourceGroup = $webapp.ResourceGroup

$login = Get-AzureRmWebAppPublishingCredentials "$resourceGroup" "$WebAppName"

Delete-FileFromWebApp -webAppName "$WebAppName" -username $login.Properties.PublishingUserName -password $login.Properties.PublishingPassword -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeKuduUrl
