. .\TfsBuildTools.BuildServer.ps1

<#
  .SYNOPSIS    
    Creates a new build definition with the specified name for the specified team project. If not template and/or controller is set the default template and the first build controller in the list of registered controllers will be set. This CmdLet requires a buildserver to be set for the module using Set-BuildServer. Note that the defintion will not be saved only created, you can save the definition by calling Save-BuildDefinition.
  .PARAMETER TeamProject 
    The name of the team project within the team project collection for which the buildserver is set.
  .PARAMETER Name 
    The name of the build definition, note that the name must not yet exist for the team project.
  .PARAMETER BuildTemplate 
    The template to set for this build definition (can be obtained using Get-BuildTemplate).
  .PARAMETER BuildController 
    The default build controller to set for this build definition (can be obtained using Get-BuildController).
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $defaultTemplate = Get-BuildTemplate -TeamProject "MyTeamProject" 
    $firstBuildController = Get-BuildController
    $buildDefinition = New-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild" -BuildTemplate $defaultTemplate -BuildController $firstController
    Save-BuildDefinition $buildDefinition
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $buildDefinition = New-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    Save-BuildDefinition $buildDefinition
   
#>
function New-BuildDefinition
{
    Param(
        [Parameter(Mandatory=$true)][string] $TeamProject,
        [Parameter(Mandatory=$true)][string] $Name,
        $BuildTemplate = $null,
        [Microsoft.TeamFoundation.Build.Client.IBuildController] $BuildController = $null
    );

    $buildServer = Get-BuildServer
    
    if(Test-BuildDefinition -TeamProject $TeamProject -Name $Name)
    {
        Write-Error "a build definition with the name `"$name`" already exists, remove the definition or pick a different name" -ErrorAction Stop;
    }

    if($BuildTemplate -eq $null) {
        Write-Verbose "No template was specified, using default template"
        $BuildTemplate = Get-BuildTemplate -TeamProject $TeamProject
    }

    if($BuildController -eq $null)
    {
        Write-Verbose "No controller was specified, using first controller"
        $BuildController = Get-BuildController      
    }

    $buildDefinition = $buildServer.CreateBuildDefinition($TeamProject)
    $buildDefinition.Name = $Name
    $buildDefinition.Process = $BuildTemplate
    $buildDefinition.BuildController = $BuildController

    return $buildDefinition
}

<#
  .SYNOPSIS    
    Saves a build definition.
  .PARAMETER BuildDefintion 
    The builddefiniton to save.
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $buildDefinition = New-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    Save-BuildDefinition $buildDefinition
   
#>
Function Save-BuildDefinition {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    try {
        $BuildDefinition.Save();
    }
    finally{
        $ErrorActionPreference = $oldErrorActionPreference;
    }
}

<#
  .SYNOPSIS    
    Tests whether a build definition with the specified name exists for the specified team project. This CmdLet requires a buildserver to be set for the module using Set-BuildServer.
  .PARAMETER TeamProject 
    The name of the team project the build definition is linked to.
  .PARAMETER Name 
    The name of the build definition to test.
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    Test-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
   
#>
Function Test-BuildDefinition {
    Param(
        [Parameter(Mandatory=$true)][string] $TeamProject,
        [Parameter(Mandatory=$true)][string] $Name
    );

    $buildServer = Get-BuildServer
    $buildDefintions = Get-BuildDefinition -TeamProject $TeamProject -Name $Name

    return ($buildDefintions.Count -gt 0)
}


<#
  .SYNOPSIS    
    Gets the builddefintions registerd for a specific team project filtered by name. This CmdLet requires a buildserver to be set for the module using Set-BuildServer.
  .PARAMETER TeamProject 
    The name of the team project the build definition is linked to.
  .PARAMETER Name 
    The name of the build definition(s) to retrieve. If no name is specified the filter '*' will be used meaning all builddefinitions for a team project will be returned
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    Get-BuildDefinition -TeamProject "MyProject" | % { Write-Host $_.Name }
   
#>
Function Get-BuildDefinition {
    Param(
        [Parameter(Mandatory=$true)][string] $TeamProject,
        [string] $Name
    );

    if(!$Name) { $Name = '*' }


    $buildServer = Get-BuildServer

    $spec = $buildServer.CreateBuildDefinitionSpec($TeamProject, $Name);
    $result = $buildServer.QueryBuildDefinitions($spec);

    if($result -eq $null)
    {
        return @()
    }

    if($result.Definitions -eq $null)
    {
        return @()
    }
 
    return $result.Definitions
}


<#
  .SYNOPSIS    
    Gets the process parameters from the specified build definition
  .PARAMETER BuildDefinition 
    The builddefinition to retrieve the process parameters from
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $parameters = Get-ProcessParameters -BuildDefinition $definition
   
#>
Function Get-ProcessParameters {
    Param (
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $deserializedParamters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::DeserializeProcessParameters($BuildDefinition.ProcessParameters)
    return $deserializedParamters
}

<#
  .SYNOPSIS    
    Set the process parameters for the specified build definition. Note that -Parameters must be an IDictonary[String, Object] serializable by Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers.SerializeProcessParameters(..). It is therefore advisable to Set-ProcessParameter to set a single parameter or use Get-ProcessParameters to retrieve this object an add/modify the parameters from there. Note that for complex parameters such as AdvancedTestSettings specific CmdLets exist.
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the process parameters
  .PARAMETER ProcessParameters 
    The process parameters to set for the builddefinition. This must be an IDictonary[String, Object] serializable by Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers.SerializeProcessParameters(..).
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $parameters = Get-ProcessParameters -BuildDefinition $definition
    $parameters.Set_Item("MyCustomParameter", "Test");
    Set-ProcessParameters -BuildDefinition $definition -ProcessParameters $parameters   
#>
Function Set-ProcessParameters 
{
    Param (
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][System.Collections.Generic.IDictionary[String, Object]]$ProcessParameters
    )

    $serializedParameters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::SerializeProcessParameters($ProcessParameters);
    $buildDefinition.ProcessParameters = $serializedParameters;
}

<#
  .SYNOPSIS    
    Sets a single process parameter for the specified build definition.
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the process parameters
  .PARAMETER Key 
    The dictionary key of the process parameter
  .PARAMETER Value 
    The Value of the process parameter. Note that since the process parameters dictonary has string keys and Object values you are responsible to provide the correct type for the specific parameter key or your build definition might not open correctly in Visual Studio and the TfsBuild runner.
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    Set-ProcessParameter -BuildDefinition $definition -Key "MyCustomParameter" -Value  "Test" 
#>
Function Set-ProcessParameter
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][string]$Key,
        [Parameter(Mandatory=$true)][object]$value
    )

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition
    $processParameters.Set_Item($Key, $Value)
    Set-ProcessParameters -BuildDefinition $BuildDefinition -ProcessParameters $processParameters
}

<#
  .SYNOPSIS    
    Gets a single process parameter for the specified build definition.
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the process parameters
  .PARAMETER Key 
    The dictionary key of the process parameter
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    Get-ProcessParameter -BuildDefinition $definition -Key "MyCustomParameter"
#>
Function Get-ProcessParameter
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][string]$Key
    )

    $processParameterExists = Test-ProcessParameter -BuildDefinition $BuildDefinition -Key $Key

    if(-not $processParameterExists) 
    {
        Write-Error "No process parameter could be found for the key: `"$Key`' in build definition `"$($BuildDefition.Name)`""
    }

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition
    return $processParameters.Get_Item($Key)
}

<#
  .SYNOPSIS    
    Tests whether a single key for a process parameter already exists in the process parameter dictionary for the specified build definition.
  .PARAMETER BuildDefinition 
    The builddefinition for which to set the process parameters
  .PARAMETER Key 
    The dictionary key of the process parameter
  .EXAMPLE  
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    Test-ProcessParameter -BuildDefinition $definition -Key "MyCustomParameter"
#>
Function Test-ProcessParameter
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][string]$Key
    )

    $processParameters = Get-ProcessParameters -BuildDefinition $BuildDefinition
    return $processParameters.ContainsKey($Key)
}
