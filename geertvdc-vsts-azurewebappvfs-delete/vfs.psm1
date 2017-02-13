
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

function Get-FileListFromWebApp($webAppName, $slotName = "", $username, $password, $filePath, $allowUnsafe = $false, $alternativeUrl, $continueIfFileNotExist){

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

    if($allowUnsafe -eq $true){
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
    	$dirList = Invoke-RestMethod -Uri $kuduApiUrl `
									 -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
									 -Method GET `
									 -ContentType "multipart/form-data"		
		return $dirList
	}
	catch {
		if($_.Exception.Response.StatusCode.value__ -eq "404" -and $continueIfFileNotExist -eq $true){
			Write-Output "File not found (but ignored because of setting)"
		}
		else {
			throw $_.Exception
		}
	}
}

function Remove-FileFromWebApp($webAppName, $slotName = "", $username, $password, $filePath, $allowUnsafe = $false, $alternativeUrl, $continueIfFileNotExist, $deleteRecursive){

	Write-Output "Remove-FileFromWebApp path: $filePath"
	if($deleteRecursive -eq $true -and $filePath.EndsWith("/")){
		
		Write-Output "Recursive delete so Get-FileListFromWebApp to see which files to delete: $filePath"
		$dirs = Get-FileListFromWebApp -webAppName "$webAppName" -username $username -password $password -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist
		foreach($file in $dirs){
			$href = $file.href
			$filename = $href.Substring($file.href.IndexOf("/vfs/site/wwwroot/")+18)

			Remove-FileFromWebApp -webAppName "$webAppName" -username $username -password $password -filePath "$filename" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $deleteRecursive
		}

		Remove-FileFromWebApp -webAppName "$webAppName" -username $username -password $password -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $false

		return
	}

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

	Write-Output "url $kuduApiUrl"

    if($allowUnsafe -eq $true){
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
			Write-Output "File not found (but ignored because of setting)"
		}
		else {
			throw $_.Exception
		}		
	}
}