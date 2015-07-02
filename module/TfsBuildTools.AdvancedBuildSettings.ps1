. .\TfsBuildTools.BuildDefinition.ps1

<#
  .SYNOPSIS    
    Creates new advanced build settings, none of the parameters are required. If no parameters are passed, the default settings are returned
  .PARAMETER MSBuildArguments
    Arguments to be passed to MSBuild, default is ""
  .PARAMETER MSBuildPlatform
    Platform that should be used by MSBuild, default is "Auto"
  .PARAMETER PreActionScriptArguments
    Arguments to pas to the pre action script, default is ""
  .PARAMETER PreActionScriptPath
    Location of the script to run before MSBuild, default is ""
  .PARAMETER PostActionScriptArguments
    Arguments to be passed to the post action script, default is ""
  .PARAMETER PostActionScriptPath 
    Location of the script to run after MSBuild, default is ""
  .PARAMETER RunCodeAnalysis
    A switch indication whether to run static code analysis, default is false
  .EXAMPLE  
    $settings = New-AdvancedBuildSettings
  .EXAMPLE
    $settings = New-AdvancedBuildSettings -RunCodeAnalysis -MSBuildPlatform "X86"
   
#>
Function New-AdvancedBuildSettings 
{
    Param(
        [string]$MSBuildArguments = [System.String]::Empty,
        [string]$MSBuildPlatform = "Auto",
        [string]$PreActionScriptArguments = [System.String]::Empty,
        [string]$PreActionScriptPath = [System.String]::Empty,
        [string]$PostActionScriptArguments = [System.String]::Empty,
        [string]$PostActionScriptPath = [System.String]::Empty,
        [string]$RunCodeAnalysis = "AsConfigured"  
    );

    return [PSCustomObject]@{
        MSBuildArguments = $MSBuildArguments;
        MSBuildPlatform = $MSBuildPlatform;
        PreActionScriptArguments = $PreActionScriptArguments;
        PreActionScriptPath = $PreActionScriptPath;
        PostActionScriptArguments = $PostActionScriptArguments
        PostActionScriptPath = $PostActionScriptPath;
        RunCodeAnalysis= $RunCodeAnalysis;
   };
}

<#
  .SYNOPSIS    
    Gets the advanced build settings for the specified build definition, if no advanced build settings exist yet the default settings will be returned
  .PARAMETER BuildDefinition 
    The builddefinition for which to get the advanced build settings
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $settings = Get-AdvancedBuildSettings -BuildDefinition $definition
#>
Function Get-AdvancedBuildSettings {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition
    $advancedBuildSettingsKey = "AdvancedBuildSettings"
    $parameterExists = Test-ProcessParameter -BuildDefinition $BuildDefinition -Key $advancedBuildSettingsKey

    if($parameterExists)
    {
        $advancedBuildSettings = Get-ProcessParameter -BuildDefinition $BuildDefinition -Key $advancedBuildSettingsKey
        return ConvertFrom-Json $advancedBuildSettings.ToString();
    }

    Write-Verbose("No advanced build settings found yet, creating default settings");
    return New-AdvancedBuildSettings
}

<#
  .SYNOPSIS    
    Gets the advanced build settings for the specified build definition, if no advanced build settings exist yet the default settings will be returned
  .PARAMETER BuildDefinition 
    The builddefinition for which to get the advanced build settings
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $settings = New-AdvancedBuildSettings -RunCodeAnalysis -MSBuildPlatform "X86"
    Set-AdvancedBuildSettings -Definition $definition -AdvancedBuildSettings $settings
#>
Function Set-AdvancedBuildSettings {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)]$AdvancedBuildSettings
    )

    $params = @{
        "MSBuildArguments" = $AdvancedBuildSettings.MSBuildArguments;
        "MSBuildPlatform" = $AdvancedBuildSettings.MSBuildPlatform;
        "PreActionScriptArguments" = $AdvancedBuildSettings.PreActionScriptArguments;
        "PreActionScriptPath" = $AdvancedBuildSettings.PreActionScriptArguments;
        "PostActionScriptArguments" = $AdvancedBuildSettings.PostActionScriptArguments;
        "PostActionScriptPath" = $AdvancedBuildSettings.PostActionScriptPath;
        "RunCodeAnalysis"= $AdvancedBuildSettings.RunCodeAnalysis;
    };
    
    $buildParameter = New-Object Microsoft.TeamFoundation.Build.Common.BuildParameter -ArgumentList @($params);
    
    Set-ProcessParameter -BuildDefinition $BuildDefinition -Key "AdvancedBuildSettings" -Value $buildParameter 
}