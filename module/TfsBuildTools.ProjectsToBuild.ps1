. .\TfsBuildTools.BuildDefinition.ps1

<#
  .SYNOPSIS    
    Creates a new list of projects to build based on the version control server paths passed in
  .PARAMETER ServerPaths 
    a list of server paths to pointing to the projects to build
  
  .EXAMPLE  
    $projectsToBuild = New-ProjectsToBuild -ServerPaths @("$/myproject/path/to/solution", "$/myotherproject/path/to/solution")
#>
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

<#
  .SYNOPSIS    
    Gets the projects to build from the specified build defintion, if no projects to build parameter exists in the process parameter dictonary and empty array of projects to build is returned.
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the process parameters
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $projectsToBuild = Get-ProjectsToBuild -BuildDefinition $definition
#>
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

<#
  .SYNOPSIS    
    Sets the projects to build for the specfied build definition
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the process parameters
  .PARAMETER ProjectsToBuild 
    A list of projects to build (can be created using New-ProjectsToBuid or retrieved using Get-ProjectsToBuild).
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $projectsToBuild = New-ProjectsToBuild -ServerPaths @("$/path/to/my/solution.sln")
    Set-ProjectsToBuild -BuildDefinition $definition -ProjectsToBuild $projectsToBuild
#>
Function Set-ProjectsToBuild {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][string[]]$ProjectsToBuild
    )

    Set-ProcessParameter -BuildDefinition $BuildDefinition -Key "ProjectsToBuild" -Value $ProjectsToBuild 
}
