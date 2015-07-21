. .\TfsBuildTools.BuildDefinition.ps1
<#
  .SYNOPSIS    
    Creates a new list of automated test settings with 1 entry. None of the parameters are required, if no parameters are specified the default settings will be returned
  .PARAMETER AssemblyFileSpec
  The assembly file spec determing which assemblies will be loaded as tests, default is "**\*test*.dll;**\*test*.appx"
  .PARAMETER RunSettingsFileName
  The name of the run settings file, default is $null
  .PARAMETER TestCaseFilter
  A filter to be applied to the test cases to execute, default is ""
  .PARAMETER ServerRunSettingsFile
  The location of the server run settings file, default is ""
  .PARAMETER TypeRunSettings
  The type of run settings, default is "Default'
  .PARAMETER HasRunSettingsFile
  A switch indicating whether run settings have been specified, default is false
  .PARAMETER ExecutionPlatform
  The execution platform for MSTest, default is "X86'
  .PARAMETER FailBuildOnFailure
  A switch indicating whether to fail the build when the test runs fail
  .PARAMETER RunName
  The name of the run settings
  .EXAMPLE
  $defaultSettings = New-AutomatedTestSettings
  .EXAMPLE 
  $automatedTestSettings = New-AutomatedTestSettings -HasRunSettingsFile -TypeRunSettings "EnableCodeCoverage" 
  
#>
Function New-AutomatedTestSettings 
{
    Param(
        [string]$AssemblyFileSpec = "**\*test*.dll;**\*test*.appx",
        [string]$RunSettingsFileName = $null,
        [string]$TestCaseFilter=[string]::Empty,
        [string]$ServerRunSettingsFile=[string]::Empty,
        [string]$TypeRunSettings="Default",
        [switch]$HasRunSettingsFile,
        [string]$ExecutionPlatform="X86",
        [switch]$FailBuildOnFailure,
        [string]$RunName=[string]::Empty

    );

    return [array]@([PSCustomObject]@{ 
        "AssemblyFileSpec"= $AssemblyFileSpec; 
        "RunSettingsFileName"= $RunSettingsFileName; 
        "TestCaseFilter"=$TestCaseFilter; 
        "RunSettingsForTestRun"= [PSCustomObject]@{ 
            "HasRunSettingsFile"= if($HasRunSettingsFile){$true}else{$false}; 
            "ServerRunSettingsFile"= $ServerRunSettingsFile; 
            "TypeRunSettings"= $TypeRunSettings; 
        };
        "HasRunSettingsFile"= if($HasRunSettingsFile){$true}else{$false}; ; 
        "HasTestCaseFilter"= ($TestCaseFilter -ne [string]::Empty); 
        "ExecutionPlatform"= "X86"; 
        "FailBuildOnFailure"= if($FailBuildOnFailure){$true}else{$false}; 
        "RunName"= $RunName
    })
}


<#
  .SYNOPSIS    
    Gets the automated test settings for the specified build definition
  .PARAMETER BuildDefinition 
    The builddefinition for which to get the automated test settings
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $automatedTestSettings = Get-AutomatedTestSettings -BuildDefinition $definition
#>
Function Get-AutomatedTestSettings {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition
    $automatedTestsKey = "AutomatedTests"
    $parameterExists = Test-ProcessParameter -BuildDefinition $BuildDefinition -Key $automatedTestsKey
    
    if($parameterExists)
    {
        [array]$array = @();
        $automatedTestSettings = Get-ProcessParameter -BuildDefinition $BuildDefinition -Key $automatedTestsKey
        $automatedTestSettings | %{
            $array += ConvertFrom-Json $_.ToString()
        }

        return $array
    }

    Write-Verbose("No automated test settings found yet, creating default settings");
    return New-AutomatedTestSettings
}

<#
  .SYNOPSIS    
    Sets the automated test settings for the specified build definition
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the automated test settings
  .PARAMETER AutomatedTestSettings 
    The automated test settings for the build definition
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $automatedTestSettings = New-AutomatedTestSettings -HasRunSettingsFile -TypeRunSettings "EnableCodeCoverage"
    Set-AutomatedTestSettings -BuildDefinition $definition -AutomatedTestSettings $automatedTestSettings
#>
Function Set-AutomatedTestSettings {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)]$AutomatedTestSettings
    )

    [Microsoft.TeamFoundation.Build.Common.BuildParameter[]]$buildParameters = @();

    foreach($setting in $AutomatedTestSettings)
    {
        $params = @{ 
            "AssemblyFileSpec"=$setting.AssemblyFileSpec;
            "RunSettingsFileName"=$setting.RunSettingsFileName;
            "TestCaseFilter"=$setting.TestCaseFilter;
            "RunSettingsForTestRun"= @{ 
                "HasRunSettingsFile"=$setting.RunSettingsForTestRun.HasRunSettingsFile;
                "ServerRunSettingsFile"=$setting.RunSettingsForTestRun.ServerRunSettingsFile; 
                "TypeRunSettings"=$setting.RunSettingsForTestRun.TypeRunSettings; 
            };
            "HasRunSettingsFile"=$setting.HasRunSettingsFile; 
            "HasTestCaseFilter"=$setting.HasTestCaseFilter; 
            "ExecutionPlatform"=$setting.ExecutionPlatform; 
            "FailBuildOnFailure"=$setting.FailBuildOnFailure; 
            "RunName"=$setting.RunName;
        };
        [Microsoft.TeamFoundation.Build.Common.BuildParameter]$buildParameter = New-Object Microsoft.TeamFoundation.Build.Common.BuildParameter -ArgumentList @($params)
        
        $buildParameters += $buildParameter;
    
    }

    Set-ProcessParameter -BuildDefinition $BuildDefinition -Key "AutomatedTests" -Value $buildParameters
}