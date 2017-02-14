# Azure WebApp Virtual File System Tasks

## Deleting files
Delete files from Azure Web Apps through KUDU Virtual File System Rest API (Put & Get coming soon)

This task was created because sometimes web apps create certain files containing configuration after initial deployments. This task helps you reset your web app to a certain state wehre resetting the full directory isn't an option (otherwise use Webdeploy's advanced parameter called "Remove Additional Files at Destination")

Using the task is easy: fill in the following parameters:

- Azure subscription (select your Azure RM connection)
- App Service Name (select the web app you want to delete files at)
- File URL (enter the file url within the wwwroot that you want to delete. use path ending on / for directories)

optionally add the following parameters

- Recursive delete (Default **ON** if you select a directory also delete all files and directories in this directory)
- Skip non existing path (If file or directory does not exist any more do not throw error but continue)
- Allow self signed certificates (**only use this when you you run in an ASE and have your own certificates**)
- Alternative kudu URL (When running in ASE and the SCM url is different fill in the exact url here)

![screenshot](https://raw.githubusercontent.com/Geertvdc/VSTS-Build-AzureWebAppVFS/master/geertvdc.vsts.azurewebappvfs.extension/images/2.png)

## Putting files & Getting files
Coming soon! (let me know in comments if you need this let me know your requirements)

## Extra links

[Source for this VSTS extension on Github](https://github.com/Geertvdc/VSTS-Build-AzureWebAppVFS)

[My blog](https://mobilefirstcloudfirst.net/2017/02/created-open-source-vsts-build-release-task-azure-web-app-virtual-file-system/)