. .\TfsBuildTools.BuildDefinition.ps1

Function New-AdvancedTestSettings 
{
    Param(
        [switch]$analyzeTestImpact,
        [switch]$disableTests,
        [string]$preActionScriptArguments = [System.String]::Empty,
        [string]$preActionScriptPath = [System.String]::Empty,
        [string]$postActionScriptArguments = [System.String]::Empty,
        [string]$postActionScriptPath = [System.String]::Empty 
    );

    return [PSCustomObject]@{
        AnalyzeTestImpact=if($analyzeTestImpact){$true}else{$false}; 
        DisableTests= if($disableTests){$true}else{$false};
        PreActionScriptPath= $preActionScriptPath;
        PreActionScriptArguments= $preActionScriptArguments;
        PostActionScriptPath= $postActionScriptPath; 
        PostActionScriptArguments= $postActionScriptArguments;
   };
}

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
