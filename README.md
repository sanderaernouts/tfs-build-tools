# tfs-build-tools
A PowerShell module to interact with the build service of Team Foundation Server (TFS). At this moment the module is focused on creating, retrieving and/or editing build definitions. If you experience any issues please log them under issues. Feel free to submit pull request to expand the functionality of this module.

##Available commandlets
- Clear-WorkspaceMappings
- Get-AdvancedBuildSettings
- Get-AdvancedTestSettings
- Get-AutomatedTestSettings
- Get-BuildController
- Get-BuildDefinition
- Get-BuildServer
- Get-BuildTemplate
- Get-ProcessParameter
- Get-ProcessParameters
- Get-ProjectsToBuild
- Get-WorkspaceMappings
- New-AdvancedBuildSettings
- New-AdvancedTestSettings
- New-AutomatedTestSettings
- New-BuildDefinition
- New-ProjectsToBuild
- New-WorkspaceMapping
- Save-BuildDefinition
- Set-AdvancedBuildSettings
- Set-AdvancedTestSettings
- Set-AutomatedTestSettings
- Set-BuildServer
- Set-ProcessParameter
- Set-ProcessParameters
- Set-ProjectsToBuild
- Set-WorkspaceMappings
- Test-BuildDefinition
- Test-ProcessParameter

##Installation
###Dependencies
* Visual Studio Team Explorer 2013

###Steps
Go to https://github.com/sanderaernouts/tfs-build-tools/releases and download latest release of the TfsWorkItemTools.zip archive. Unzip the archive and run the install.ps1 script. This will place necesary files in your "%USERPROFILE%\Documents\WindowsPowerShell\Modules" folder.

##Uninstalation
Remove the TfBuildTools folder from the following location "%USERPROFILE%\Documents\WindowsPowerShell\Modules"

##Usage
Importing the module into your script:
```powershell
Import-Module -Name TfsBuildTools
```

View available cmdlets:
```powershell
Get-Command -Module TfsBuildTools
```

View help information per cmdlet:
```powershell
Get-Help Get-BuildDefinition
```

*note: you can use the -Detailed or -Full switch of the Get-Help cmdlet to more help information including examples*

View the full help documentation for all cmdlets in the module:
```powershell
Get-Command -Module TfsBuildTools | Get-Help -Full
```

This module uses a Azure PowerShell like approach for setting the build server (similar behaviour as [Set-AzureSubscription](https://msdn.microsoft.com/en-us/library/dn495189.aspx)). Before you can use most of the commands in this module you will have to set the build server. It is stored as a private module variable and used by the other cmdlets to prevent the need to pass the build server into each and every cmdlet.

##Example
```powershell
Import-Module TfsBuildTools

#First set the buildserver to be used by this module by passing in the collection URL and request to use the ByPassRules flag
Set-BuildServer "https://your.tfs.server/tfs/yourcollection"

#Enable code coverage for all build settings
Get-BuildDefinition -TeamProject "MyTeamProject" | % {
  $settings = New-AutomatedTestSettings -HasTestSettings -TypeRunSettings "CodeCoverageEnabled"
  Set-AdvancedTestSettings -BuildDefinition $_ -AdvancedTestSettings $settings
  Save-BuildDefinition -BuildDefinition $_
}
```
