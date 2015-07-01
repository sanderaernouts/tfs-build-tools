<#
  .SYNOPSIS    
    Sets the build server to be used by this module. This cmdlet must be executed before for instance creating a new build definition using New-BuildDefinition. The IBuildServer instance is a service requested from a team project collection and thus operates at TPC level.
  .PARAMETER Collection 
   Collection URL, for example https://tfs.example.com/tfs/myCollection 
  .EXAMPLE   
   Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection" 
#>
function Set-BuildServer
{
    param(
        [Parameter(Mandatory=$True,Position=1)][string] $Collection
    )

    loadDependencies
      
	$uri = [URI]$Collection
    $tpc = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($uri)
    $Script:TFSBuildServer = $tpc.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
}

<#
  .SYNOPSIS    
    Returns the instance of the IBuildServer service currently set for this module. If no buildserver is set yet an error will be thrown.
  .EXAMPLE   
   Get-BuildServer"
#>
function Get-BuildServer
{
    verifyBuildServerIsSet
    return $Script:TFSBuildServer
}

<#
  .SYNOPSIS    
    Return the first buildcontroller in the list of buildcontrollers registered at the IBuildServer service
  .EXAMPLE   
   Get-BuildController
#>
Function Get-BuildController
{
    $buildControllers = getAllBuildControllers
    
    return getFirstBuildController -buildControllers $buildControllers
}

<#
  .SYNOPSIS    
    Returns the build template marked as the default template for the specified team project
  .PARAMETER TeamProject 
    The name of the team project within the team project collection for which the buildserver is set.
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $defaultTemplate = Get-BuildTemplate -TeamProject "MyTeamProject" 
   
#>
Function Get-BuildTemplate
{
    Param(
        [Parameter(Mandatory=$true)][string] $TeamProject
    );

    $buildServer = Get-BuildServer

    $templates = $BuildServer.QueryProcessTemplates($TeamProject);
    
    $defaultTemplate = $templates | where { 
        $_.TemplateType -eq [Microsoft.TeamFoundation.Build.Client.ProcessTemplateType]::Default 
    }

    return $defaultTemplate;
}

#region private functions
function verifyBuildServerIsSet
{
    if($Script:TFSBuildServer -eq $null)
    {
        Write-Error "No build server was set, run Set-BuildServer first" -ErrorAction Stop
    }
} 

function loadDependencies 
{
    #load types
    add-type -Path "$($env:VS120COMNTOOLS)..\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Build.Workflow.dll"
    
    #load assemblies
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client") 
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client") 
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Workflow")
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Common") 
}

function getAllBuildControllers 
{
    $buildServer = Get-BuildServer
    $includeAgents = $false
    $buildControllers = $BuildServer.QueryBuildControllers($includeAgents);

    if(!$buildControllers -or $buildControllers.Count -eq 0)
    {
        Write-Error "unable to find any build controllers" -ErrorAction Stop;
    }

    return $buildControllers
}

function getFirstBuildController 
{
    param(
        [Parameter(Mandatory=$true)]$buildControllers
    )
    Write-Verbose "Found $($buildControllers.Count) controllers, selecting first controller in list"
    $buildController = $result[0];
    Write-Verbose "Selected $($buildController.Name)"

    return $buildController
}

#endregion