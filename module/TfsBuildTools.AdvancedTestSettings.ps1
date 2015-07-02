. .\TfsBuildTools.BuildDefinition.ps1


<#
  .SYNOPSIS    
    Creates new advanced test settings, all parameters are optional. If no values are passed the default values are use for these settings.
  .PARAMETER analyzeTestImpact 
    A switch indicating whether or not to run test impact analysis, default is false.
  .PARAMETER disableTests 
    A switch to indicate test should not be run as part of the build, default is false
  .PARAMETER preActionScriptArguments 
    Arguments to be passed to the preAction script, default is ""
  .PARAMETER preActionScriptPath 
    TFVC server path pointing to the script that should be executed before MSTest, default is ""
  .PARAMETER postActionScriptArguments 
    Arguments to be passed to the postAction script, default is ""
  .PARAMETER postActionScriptPath 
    TFVC server path pointing to the script that should be executed after MSTest, default is ""
  .EXAMPLE  
    $defaultSettings = New-AdvancedTestSettings
  .EXAMPLE
    $customSettings = New-AdvancedTestSettings -analyzeTestImpace -postActionScript "$/path/to/post/action/script.ps1"
#>
Function New-AdvancedTestSettings 
{
    Param(
        [switch]$AnalyzeTestImpact,
        [switch]$DisableTests,
        [string]$PreActionScriptArguments = [System.String]::Empty,
        [string]$PreActionScriptPath = [System.String]::Empty,
        [string]$PostActionScriptArguments = [System.String]::Empty,
        [string]$PostActionScriptPath = [System.String]::Empty 
    );

    return [PSCustomObject]@{
        AnalyzeTestImpact=if($AnalyzeTestImpact){$true}else{$false}; 
        DisableTests= if($DisableTests){$true}else{$false};
        PreActionScriptPath= $PreActionScriptPath;
        PreActionScriptArguments= $PreActionScriptArguments;
        PostActionScriptPath= $PostActionScriptPath; 
        PostActionScriptArguments= $PostActionScriptArguments;
   };
}

<#
  .SYNOPSIS    
    Gets the advanced test settings for the specified build definition, if no advanced test settings exist yet the default settings will be returned
  .PARAMETER BuildDefinition 
    The builddefinition for which to get the advanced test settings
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $advancedTestSettings = Get-AdvancedTestSettings -BuildDefinition $definition
#>
Function Get-AdvancedTestSettings {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition

    if($processParameters.ContainsKey("AdvancedTestSettings"))
    {
        $json = $processParameters["AdvancedTestSettings"].ToString();
        return ConvertFrom-Json $json
    }

    Write-Verbose("No advanced test settings found yet, creating default settings");
    return New-AdvancedTestSettings
}

<#
  .SYNOPSIS    
    Sets the advanced test settings for the specified build definition
  .PARAMETER BuildDefinition 
    The builddefinition for to set the advanced test settings
  .PARAMETER Key 
    The advanced test settings object, can be created using New-AdvancedTestSettings or retrieved using Get-AdvancedTestSettings
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $settings = New-AdvancedTestSettings -disableTests
    Set-AdvancedTestSettings -BuildDefinition $definition -AdvancedTestSettings $settings
#>
Function Set-AdvancedTestSettings {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)]$AdvancedTestSettings
    )

    $params = @{ 
        "AnalyzeTestImpact"=$AdvancedTestSettings.AnalyzeTestImpact; 
        "DisableTests"= $AdvancedTestSettings.DisableTests;
        "PreActionScriptPath"= $AdvancedTestSettings.PreActionScriptPath;
        "PreActionScriptArguments"= $AdvancedTestSettings.PreActionScriptArguments;
        "PostActionScriptPath"= $AdvancedTestSettings.PostActionScriptPath; 
        "PostActionScriptArguments"= $AdvancedTestSettings.PostActionScriptArguments;
   };
    
    $buildParameter = New-Object Microsoft.TeamFoundation.Build.Common.BuildParameter -ArgumentList @($params);
    
    Set-ProcessParameter -BuildDefinition $BuildDefinition -Key "AdvancedTestSettings" -Value $buildParameter 
}
