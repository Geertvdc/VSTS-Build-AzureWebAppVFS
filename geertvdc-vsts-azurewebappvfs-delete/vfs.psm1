

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

function Get-KuduApiAuthorisationToken($username, [securestring]$password){
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password))))
}

function Delete-FileFromWebApp($webAppName, $slotName = "", $username, [securestring]$password, $filePath, $allowUnsafe = $false, $alternativeUrl){

		Write-Host "user $username"
		Write-Host "webapp $webAppName"
		Write-Host "path $filePath"

    $kuduApiAuthorisationToken = Get-KuduApiAuthorisationToken $username $password
    if ($slotName -eq ""){
        $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
    }
    else{
        $kuduApiUrl = "https://$webAppName`-$slotName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
    }

		if($alternativeUrl -ne ""){
				$kuduApiUrl = $kuduApiUrl.Replace("scm.azurewebsites.net","$alternativeUrl")
		}

		Write-Host "url $kuduApiUrl"
    if($allowUnsafe){
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

		Invoke-RestMethod -Uri $kuduApiUrl `
												-Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
												-Method DELETE `
												-ContentType "multipart/form-data"
}