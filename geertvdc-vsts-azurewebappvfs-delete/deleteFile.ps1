Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$filePath = Get-VstsInput -Name filePath -Require
$allowUnsafe = Get-VstsInput -Name allowUnsafe
$alternativeKuduUrl = Get-VstsInput -Name alternativeKuduUrl 
$continueIfFileNotExist = Get-VstsInput -Name continueIfFileNotExist 


# Initialize Azure.
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Initialize-Azure

Write-Output "Azure Initialized"

#Import-Module $PSScriptRoot\vfs

$webapp = Get-AzureRmWebApp -name "$WebAppName"
$resourceGroup = $webapp.ResourceGroup

Write-Output "Retrieved web app: $webapp in Resource group: $resourceGroup"

function Get-AzureRmWebAppPublishingCredentials($resourceGroupName, $webAppName, $slotName = $null){
	if ([string]::IsNullOrWhiteSpace($slotName)){
		$resourceType = "Microsoft.Web/sites/config"
		$resourceName = "$webAppName/publishingcredentials"
	}
	else{
		$resourceType = "Microsoft.Web/sites/slots/config"
		$resourceName = "$webAppName/$slotName/publishingcredentials"
	}
	$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    	return $publishingCredentials
}

function Get-KuduApiAuthorisationToken($username, $password){
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password))))
}

Write-Output "Retrieving publishing profile"
$login = Get-AzureRmWebAppPublishingCredentials "$resourceGroup" "$WebAppName"
Write-Output "Publishing profile retrieved"

function Remove-FileFromWebApp($webAppName, $slotName = "", $username, $password, $filePath, $allowUnsafe = $false, $alternativeUrl, $continueIfFileNotExist){

		Write-Output "user $username"
		Write-Output "webapp $webAppName"
		Write-Output "path $filePath"
		Write-Output "allowunsafe $allowUnsafe"

    $kuduApiAuthorisationToken = Get-KuduApiAuthorisationToken $username $password
    if ($slotName -eq ""){				
        $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
				Write-Output "slotname empty deploying to $kuduApiUrl"
    }
    else{
        $kuduApiUrl = "https://$webAppName`-$slotName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
				Write-Output "slotname not empty deploying to $kuduApiUrl"
    }

		if($alternativeUrl -ne ""){
			  Write-Output "replacing scm.azurewebsites.net by $alternativeUrl"
				$kuduApiUrl = $kuduApiUrl.Replace("scm.azurewebsites.net","$alternativeUrl")
		}

		Write-Output "url $kuduApiUrl"

    if($allowUnsafe -eq $true){
			Write-Output "adding ignore for self signed certificates"
	 		add-type @"
	   		using System.Net;
	   		using System.Security.Cryptography.X509Certificates;
		 		public class TrustAllCertsPolicy : ICertificatePolicy {
		   		public bool CheckValidationResult(
			 		ServicePoint srvPoint, X509Certificate certificate,
			 		WebRequest request, int certificateProblem) {
			   		return true;
			 		}
		 		}
"@
			[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
		}

		try {
			Invoke-RestMethod -Uri $kuduApiUrl `
												-Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
												-Method DELETE `
												-ContentType "multipart/form-data"			
		}
		catch {
			if($_.Exception.Response.StatusCode.value__ -eq "404" -and $continueIfFileNotExist -eq $true){
				Write-Output "File not found"
			}
			else {
				throw $_.Exception
			}
			
		}

}

#$pw = ConvertTo-SecureString $login.Properties.PublishingPassword -AsPlainText -Force 
$pw = $login.Properties.PublishingPassword

Write-Output "Deleting file from Web App"
Remove-FileFromWebApp -webAppName "$WebAppName" -username $login.Properties.PublishingUserName -password $pw -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeKuduUrl -continueIfFileNotExist $continueIfFileNotExist
Write-Output "File $filePath deleted"