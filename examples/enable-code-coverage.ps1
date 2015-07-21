<#
  .SYNOPSIS    
    Enables code coverage on all build definitions for a specific team project
  .PARAMETER CollectionUrl
    URL of the team project collection, for example: "https://my.tfs.server/tfs/MyCollection"
  .PARAMETER TeamProject
    Name of the team project for which to enable code coverage, for example: "MyTeamProject"
  .PARAMETER WhatIf
    PowerShell standard WhatIf switch, will log what would happen but will not actually change anything
  .EXAMPLE
    ./EnableCodecoverageForAllDefinitions -TeamProjectCollectionUrl "https://my.tfs.server/tfs/MyCollection" -TeamProject "MyTeamProject" 
  .EXAMPLE
    ./EnableCodecoverageForAllDefinitions -TeamProjectCollectionUrl "https://my.tfs.server/tfs/MyCollection" -TeamProject "MyTeamProject" -WhatIf  
#>
Param(
    [Parameter(Mandatory=$true)]$CollectionUrl,
    [Parameter(Mandatory=$true)]$TeamProject,
    [switch] $WhatIf
);

#see https://github.com/sanderaernouts/tfs-build-tools
if((Get-Module TfsBuildTools) -ne $null) { Remove-Module TfsBuildTools}
Import-Module TfsBuildTools

Write-Host "Enabeling code coverage for all build definitions at: `"$CollectionUrl/$TeamProject`""

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"

Set-BuildServer -Collection $CollectionUrl

Get-BuildDefinition -TeamProject $TeamProject | %{
    Write-Host "Updating: $($_.Name)..."
    $settings = Get-AutomatedTestSettings -BuildDefinition $_
    
    foreach($setting in $settings) {
        $setting.HasRunSettingsFile = $true;
        $setting.RunSettingsForTestRun.HasRunSettingsFile = $true
        $setting.RunSettingsForTestRun.TypeRunSettings = "CodeCoverageEnabled"

        if($WhatIf) {
            Write-Warning "Would have set AutomatedTestSettings.HasRunSettingsFile = `$true"
            Write-Warning "AutomatedTestSettings.RunSettingsForTestRun.HasRunSettingsFile = `$true" 
            Write-Warning "AutomatedTestSettings.RunSettingsForTestRun.TypeRunSettings = `"CodeCoverageEnabled`""
        }
    }

    Set-AutomatedTestSettings -BuildDefinition $_ -AutomatedTestSettings $settings

    if($WhatIf) {
        Write-Warning "Would have saved build definition"
    }else{
        Save-BuildDefinition -BuildDefinition $_ 
    }
}

$ErrorActionPreference = $oldErrorActionPreference