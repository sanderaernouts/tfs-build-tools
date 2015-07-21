<#
  .SYNOPSIS    
    Enables code coverage on all build definitions for a specific team project
  .PARAMETER CollectionUrl
    URL of the team project collection, for example: "https://my.tfs.server/tfs/MyCollection"
  .PARAMETER TeamProject
    Name of the team project for which to enable code coverage, for example: "MyTeamProject"
  .PARAMETER WhatIf
    PowerShell standard WhatIf switch, will log what would happen but will not actually change anything
  .EXAMPLE
    ./EnableCodecoverageForAllDefinitions -TeamProjectCollectionUrl "https://my.tfs.server/tfs/MyCollection" -TeamProject "MyTeamProject" 
  .EXAMPLE
    ./EnableCodecoverageForAllDefinitions -TeamProjectCollectionUrl "https://my.tfs.server/tfs/MyCollection" -TeamProject "MyTeamProject" -WhatIf  
#>
Param(
    [Parameter(Mandatory=$true)]$CollectionUrl,
    [Parameter(Mandatory=$true)]$TeamProject,
    [switch] $WhatIf
);

# "static" variables
$newFormatRegex = "\$\(BuildDefinitionName\)_\d+?\.\d+?\.\d+?\.\$\(BuildID\)"
$oldFormatRegex = "\$\(BuildDefinitionName\)_(?<major>\d+?)\.(?<minor>\d+?)\.(\$\(year:yy\)){0,1}\$\(DayOfYear\)\$\(Rev:\.r\)"

function AlreadyHasNewFormat {
    Param([string] $buildNumberFormat);

    
    $matches = [regex]::matches($buildNumberFormat, $newFormatRegex)

    return $matches.Count -gt 0
}

#see https://github.com/sanderaernouts/tfs-build-tools
if((Get-Module TfsBuildTools) -ne $null) { Remove-Module TfsBuildTools}
Import-Module TfsBuildTools

Write-Host "Changing build number format to `"`$(BuildDefinitionName)_<major>.<minor>.<patch>.`$(BuildID)`" for all build definitions at: `"$CollectionUrl/$TeamProject`""

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"

Set-BuildServer -Collection $CollectionUrl

Get-BuildDefinition -TeamProject $TeamProject | %{
    Write-Host "Updating: $($_.Name)..."
    $currentFormat = Get-ProcessParameter -BuildDefinition $_ -Key "BuildNumberFormat"
    Write-Verbose "Current build number format: `"$currentFormat`""

    if(AlreadyHasNewFormat -buildNumberFormat $currentFormat) {
        Write-Warning "skipping `"$($_.Name)`", this build definition already uses the new format"
        return #could not use continue here, see http://stackoverflow.com/questions/7760013/why-does-continue-behave-like-break-in-a-foreach-object
    }

    $matches = [regex]::matches($currentFormat, $oldFormatRegex)

    if($matches.Count -eq 0) { 
        Write-Warning "skipping `"$($_.Name)`", no matches found in build number format `"$currentFormat`" for regex `"$oldFormatRegex`"."
        return #could not use continue here, see http://stackoverflow.com/questions/7760013/why-does-continue-behave-like-break-in-a-foreach-object
    }
    if($matches.Count -gt 1) { 
        Write-Warning "skipping `"$($_.Name)`", multiple matches found in build number format: `"$currentFormat`" for regex `"$oldFormatRegex`"."
        return #could not use continue here, see http://stackoverflow.com/questions/7760013/why-does-continue-behave-like-break-in-a-foreach-object
    }

    $match = $matches[0]

    $major= $match.Groups['major'].Value
    $minor= $match.Groups['minor'].Value


    $newFormat = "`$(BuildDefinitionName)_$major.$minor.0.`$(BuildID)"
    Write-Verbose "New build number format: `"$newFormat`""

    Set-ProcessParameter -BuildDefinition $_ -Key "BuildNumberFormat" -value $newFormat

    if($WhatIf) {
        Write-Warning "Would have updated buildnumber format to $newFormat"
    }else{
        Write-Verbose "Saving `"$($_.Name)`""
        Save-BuildDefinition -BuildDefinition $_ 
    }
}

$ErrorActionPreference = $oldErrorActionPreference