. .\TfsBuildTools.BuildDefinition.ps1

Function New-AdvancedBuildSettings 
{
    Param(
        [string]$msBuildArguments = [System.String]::Empty,
        [string]$msBuildPlatform = "Auto",
        [string]$preActionScriptArguments = [System.String]::Empty,
        [string]$preActionScriptPath = [System.String]::Empty,
        [string]$postActionScriptArguments = [System.String]::Empty,
        [string]$postActionScriptPath = [System.String]::Empty,
        [string]$runCodeAnalysis = "AsConfigured"  
    );

    return [PSCustomObject]@{
        MSBuildArguments = $msBuildArguments;
        MSBuildPlatform = $msBuildPlatform;
        PreActionScriptArguments = $preActionScriptArguments;
        PreActionScriptPath = $preActionScriptPath;
        PostActionScriptArguments = $postActionScriptArguments
        PostActionScriptPath = $postActionScriptPath;
        RunCodeAnalysis= $runCodeAnalysis;
   };
}

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