. .\TfsBuildTools.BuildDefinition.ps1

Function New-ProjectsToBuild 
{
    Param(
        [array]$serverPaths = @()
    );

    $projectsToBuild = [string[]]@()

    $serverPaths | % {
        $projectsToBuild += $_
    }
    
    return $projectsToBuild
}

Function Get-ProjectsToBuild {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition

    if($processParameters.ContainsKey("ProjectsToBuild"))
    {
        return (Get-ProcessParameter -BuildDefinition $BuildDefinition -Key "ProjectsToBuild")
    }

    return New-ProjectsToBuild
}


Function Set-ProjectsToBuild {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][string[]]$ProjectsToBuild
    )

    Set-ProcessParameter -BuildDefinition $BuildDefinition -Key "ProjectsToBuild" -Value $ProjectsToBuild 
}
