Trace-VstsEnteringInvocation $MyInvocation

# Initialize Azure.
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Initialize-Azure

Import-Module $PSScriptRoot\vfs

$fileUrl = Get-VstsInput -Name fileUrl -Require
$sitecoreUrl = Get-VstsInput -Name sitecoreUrl -Require


$login = Get-AzureRmWebAppPublishingCredentials "sitecore-kempen-di-dev-rg" "sitecore-kempen-dev-cm"

Delete-FileFromWebApp -webAppName "sitecore-kempen-dev-cm" -username $login.Properties.PublishingUserName -password $login.Properties.PublishingPassword -kuduPath "app_data/unicorn/"
