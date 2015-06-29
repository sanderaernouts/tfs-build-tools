Function Clear-WorkspaceMappings 
{
    Param(
        [Parameter(Mandatory=$true)][Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $BuildDefinition
    )

    $buildDefinition.Workspace.Mappings.Clear()
}

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