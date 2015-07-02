<#
  .SYNOPSIS    
    Clears all workspace mappings form the specified build definition
  .PARAMETER BuildDefinition 
    The builddefintion for which to clear the workspace mappings
  .EXAMPLE
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    Clear-WorkspaceMapping -BuildDefinition $definition
#>
Function Clear-WorkspaceMappings 
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $buildDefinition.Workspace.Mappings.Clear()
}

<#
  .SYNOPSIS    
    Sets the workspace mapping for the specified build definition
  .PARAMETER BuildDefinition 
    The builddefintion for to set the workspace mappings
  .PARAMETER Mappings
    An array of workspace mappings. Mappings can be created using New-WorkspaceMapping or retrieved using Get-WorkspaceMappings 
  .EXAMPLE
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $mappings = @()
    $mappings += New-WorkspaceMapping -ServerItem "$/path/to/item" -LocalItem "C:\ws\user\local\path\to\item" -Type "Map"
    
    Set-WorkspaceMapping -BuildDefinition $definition -Mappings $mappings
#>
Function Set-WorkspaceMappings 
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition,
        [Parameter(Mandatory=$true)][array]$Mappings,
        [switch] $NoClear

    )

    if($NoClear -eq $false)
    {
        Write-Verbose "Clearing current workspace mappings"
        Clear-WorkspaceMappings $BuildDefinition
    }

    foreach($mapping in $mappings)
    {
        [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType] $type = [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType]::Map;

        if($mapping.Type -eq "Cloak") 
        {
            Write-Verbose "Cloaked workspace mapping"
            $type = [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType]::Cloak;
        }

        $BuildDefinition.Workspace.AddMapping($mapping.ServerItem, $mapping.LocalItem, $type) | Out-Null
        Write-Verbose "Mapped workspace path: server:`"$($mapping.ServerItem)`" to local`"$($mapping.LocalItem)`" as: `"$($mapping.Type)`""
    };
}

<#
  .SYNOPSIS    
    Gets the workspace mapping for the specified build definition
  .PARAMETER BuildDefinition 
    The builddefintion for to get the workspace mappings
  .EXAMPLE
    Set-BuildServer -Collection "https://tfs.example.com/tfs/myCollection"
    $definition = Get-BuildDefinition -TeamProject "MyProject" -Name "MyNewBuild"
    $mappings = @()
    $mappings += New-WorkspaceMapping -ServerItem "$/path/to/item" -LocalItem "C:\ws\user\local\path\to\item" -Type "Map"
    
    Set-WorkspaceMapping -BuildDefinition $definition -Mappings $mappings
#>
Function Get-WorkspaceMappings
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    [array]$mappings = @();

    foreach($workspaceMapping in $BuildDefinition.Workspace.Mappings) 
    {
        $mappings += CreateWorkspaceMappingPSCustomObject -WorkspaceMapping $workspaceMapping
    }

    return [array]$mappings;
}

<#
  .SYNOPSIS    
    Creates a single new workspace mapping
  .PARAMETER ServerItem 
    The server path to the item, for example $/path/to/item
  .PARAMETER LocalItem 
    The local path to the item, for example c:\ws\user\path\to\item
  .PARAMETER Type
  .EXAMPLE
    $mappings = @()
    $mappings += New-WorkspaceMapping -ServerItem "$/path/to/item" -LocalItem "C:\ws\user\local\path\to\item" -Type "Map"
#>
Function New-WorkspaceMapping {
    Param(
        [string] $ServerItem,
        [string] $LocalItem,
        [string] $Type
    )


    return [PSCustomObject]@{
            ServerItem = $ServerItem
            LocalItem = $LocalItem;
            Type = $Type
    }
}

<#private functions #>
function CreateWorkspaceMappingPSCustomObject {
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IWorkspaceMapping] $WorkspaceMapping
    )

    $mappingType = "Map"

    if($workspaceMapping.MappingType -eq [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType]::Cloak)
    {
        $mappingType = "Cloak"
    }
    
    return New-WorkspaceMapping -ServerItem $WorkspaceMapping.ServerItem -LocalItem $WorkspaceMapping.LocalItem -Type $mappingType
}