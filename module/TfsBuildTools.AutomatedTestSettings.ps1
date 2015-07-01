. .\TfsBuildTools.BuildDefinition.ps1

Function New-AutomatedTestSettings 
{
    Param(
        [switch]$analyzeTestImpact,
        [switch]$disableTests,
        [string]$preActionScriptArguments = [System.String]::Empty,
        [string]$preActionScriptPath = [System.String]::Empty,
        [string]$postActionScriptArguments = [System.String]::Empty,
        [string]$postActionScriptPath = [System.String]::Empty 
    );

    return [array]@([PSCustomObject]@{ 
        "AssemblyFileSpec"= "**\\*test*.dll;**\\*test*.appx"; 
        "RunSettingsFileName"= $null; 
        "TestCaseFilter"= ""; 
        "RunSettingsForTestRun"= [PSCustomObject]@{ 
            "ServerRunSettingsFile"= ""; 
            "TypeRunSettings"= "Default"; 
            "HasRunSettingsFile"= $false 
        };
        "HasRunSettingsFile"= $false; 
        "HasTestCaseFilter"= $false; 
        "ExecutionPlatform"= "X86"; 
        "FailBuildOnFailure"= $false; 
        "RunName"= "" 
    })
}

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
                "ServerRunSettingsFile"=$setting.RunSettingsForTestRun.ServerRunSettingsFile; 
                "TypeRunSettings"=$setting.RunSettingsForTestRun.TypeRunSettings; 
                "HasRunSettingsFile"=$setting.RunSettingsForTestRun.HasRunSettingsFile; 
            };
            "HasRunSettingsFile"=$setting.HasRunSettingsFile; 
            "HasTestCaseFilter"=$setting.HasTestCaseFilter; 
            "ExecutionPlatform"=$setting.ExecutionPlatform; 
            "FailBuildOnFailure"=$setting.FailBuildOnFailure; 
            "RunName"=$setting.RunName;
        };
        [Microsoft.TeamFoundation.Build.Common.BuildParameter]$buildParameter = New-Object Microsoft.TeamFoundation.Build.Common.BuildParameter -ArgumentList @($params)
        
        Write-Host $buildParameter
        $buildParameters += $buildParameter;
    
    }

    Set-ProcessParameter -BuildDefinition $BuildDefinition -Key "AutomatedTests" -Value $buildParameters
}