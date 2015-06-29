 <#
.SYNOPSIS

A script to migrate buildsettings stored in XML files (by ExportBuildDefinion.ps1) to the default RDW build template. -PassThru can be used to modify the build with team or platform specific settings after the default migration.
.DESCRIPTION

A script to migrate buildsettings stored in XML files (by ExportBuildDefinion.ps1) to the default RDW build template. -PassThru can be used to modify the build with team or platform specific settings after the default migration.

.PARAMETER TargetCollection
The url of the team project collection this script should connect to for instance "https://tfs.yourserver.com/tfs/DefaultCollection"

.PARAMETER TargetProject
The name of the team project the build definitions should be exported from

.PARAMETER TargetTeam
The name of the team the build definitions belong to, will be used to create a sub folder in de Drop location and to prefix the build name.

.PARAMETER BuildDefinitionXmlDirectory
The directory where the XML files are stored saved.

.PARAMETER MajorVersion
The major version for the builds to be used in the BUildNumberFormat

.PARAMETER MinorVersion
The minor version for the builds to be used in the BUildNumberFormat

.PARAMETER PassThru
Will return all IBuilddefition objects for further modification after initial migration NOTE: the definitions will be saved by this script before passing them thru.


#>

#SCRIPT PARAMETERS
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetCollection,
    [Parameter(Mandatory=$true)]
    [string]$TargetProject,
	[Parameter(Mandatory=$true)]
    [string]$TargetTeam="",
    [Parameter(Mandatory=$true)]
    [string]$BuildDefinitionXmlDirectory,
    [Parameter(Mandatory=$false)]
    [string]$MajorVersion=1,
    [Parameter(Mandatory=$false)]
    [string]$MinorVersion=0,
    [switch]$PassThru
);

#region SETUP

#backup the ErrorActionPreference and set it to "Stop" for this script
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

#load types
add-type -Path "$($env:VS120COMNTOOLS)..\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Build.Workflow.dll"
    
#load assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client") 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client") 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Workflow")

#endregion

#region PRIVATE FUNCTIONS

function importBuildDefinitionSettings 
{
    Param(
        [Parameter(Mandatory=$true)]
        $BuildDefinitionXmlFile
    )

    $builddef = Get-ChildItem $BuildDefinitionXmlFile


    Write-Verbose "Loading XML from `"$($builddef.FullName)`"" 
    [xml]$xml = $userfile = Get-Content $builddef.FullName

    Write-Verbose "Processing builddefinition `"$($xml.BuildDefinition.Name)`"" 

    Write-Verbose "Processing workspace mappings"
    $workspaceMappings = @()
    foreach($mapping in $xml.BuildDefinition.Workspace.Mapping){
        $workspaceMapping = [PSCustomObject]@{
            ServerItem = $mapping.ServerItem;
            LocalItem = $mapping.LocalItem;
            Type = $mapping.MappingType;
        }

        $workspaceMappings += $workspaceMapping
    }

    $proccessParameters = $xml.BuildDefinition.ProcessParameters.'#cdata-section';
    Write-Verbose "Processing projects to build"

    $projectsToBuildRegex = '(ProjectsToBuild=\"(?<projectsToBuild>.*)\")'
    $matches = [regex]::matches($proccessParameters, $projectsToBuildRegex)

    foreach($match in $matches)
    {
        $value = $match.Groups['projectsToBuild'].Value
        
        #VS2010 uses a comma seperated list of items to build
        $projectsToBuild = $value.Split(',')

        foreach($projectToBuild in $projectsToBuild)
        {
            Write-Verbose "Found project to build:  $projectToBuild"
        }
    }

    Write-Verbose "Processing configurations to build"
    $configurationsToBuildRegex = '(PlatformConfiguration\s*Configuration=\"(?<configuration>.*?)\"\s*Platform=\"(?<platform>.*?)\")'
    $matches = [regex]::matches($proccessParameters, $configurationsToBuildRegex)

    $configurations = [string[]]@();
    foreach($match in $matches)
    {
        #TFS 2013 expects configurations in the format "Any CPU|Release"
        $configuration = "$($match.Groups['platform'].Value)|$($match.Groups['configuration'].Value)"

        Write-Verbose "Adding configuration to build:`"$configuration`""
        $configurations += $configuration;
    }

    Write-Verbose "Processing Advanced Build options"

    #MSBuildPlatform
    $msBuildPlatformRegex='<mtbwa:ToolPlatform x:Key="MSBuildPlatform">(?<msBuildPlatform>.*?)<\/mtbwa:ToolPlatform>'
    $matches = [regex]::matches($proccessParameters, $msBuildPlatformRegex)

    #default value
    $msBuildPlatform = "Auto"
    foreach($match in $matches)
    {
        
        $msBuildPlatform = "$($match.Groups['msBuildPlatform'].Value)"

        Write-Verbose "Detected MSBuildPlatform:`"$msBuildPlatform`""
    }

    #MSBuildArguments
    $msBuildArgumentsRegex='<x:String x:Key="MSBuildArguments">(?<msBuildArguments>.*?)<\/x:String>'
    $matches = [regex]::matches($proccessParameters, $msBuildArgumentsRegex)

    #default value
    $msBuildArguments = [String]::Empty
    foreach($match in $matches)
    {
        $msBuildArguments = "$($match.Groups['msBuildArguments'].Value))"

        Write-Verbose "Detected MSBuildPlatform:`"$msBuildArguments`""
    }

    #RunStaticCodeAnalysis
    $runStaticCodeAnalysisRegex='<mtbwa:CodeAnalysisOption x:Key="RunCodeAnalysis">(?<runCodeAnalysis>.*?)<\/mtbwa:CodeAnalysisOption>'
    $matches = [regex]::matches($proccessParameters, $runStaticCodeAnalysisRegex)

    #Default value
    $runStaticCodeAnalysis="AsConfigured"
    foreach($match in $matches)
    {
        $runStaticCodeAnalysis = "$($match.Groups['runCodeAnalysis'].Value)"

        Write-Verbose "Detected RunStaticCodeAnalysis:`"$runStaticCodeAnalysis`""
    }

    $settings = [PSCustomObject]@{
        Name = $xml.BuildDefinition.Name;
        ProjectsToBuild = $projectsToBuild;
        ConfigurationsToBuild = $configurations;
        WorkSpaceMappings = $workspaceMappings;
        MSBuildPlatform = $msBuildPlatform;
        MSBuildArguments = $msBuildArguments;
        RunStaticCodeAnalysis = $runStaticCodeAnalysis;
    }

    return $settings
    
}

function getBuildServer
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$Collection
    )

    $uri = [URI]$Collection
    $tpc = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($uri)
    $buildServer = $tpc.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])

    return $buildServer
}

function newBuildDefinition
{
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Collection,
        [Parameter(Mandatory=$true)]
        [string] $TeamProject,
        [Parameter(Mandatory=$true)]
        [string] $Name,
        $BuildTemplate = $null,
        [Microsoft.TeamFoundation.Build.Client.IBuildController] $BuildController = $null
    );

    $BuildServer = getBuildServer -Collection $Collection

    if($BuildTemplate -eq $null)
    {
        Write-Verbose "No template was specified, using default template"
        $BuildTemplate = getDefaultBuildTemplate -BuildServer $BuildServer -TeamProject $TeamProject
    }

    if($BuildController -eq $null)
    {
        Write-Verbose "No controller was specified, using first controller"
        $BuildController = getFirstBuildController -BuildServer $BuildServer
    }

    $result = getBuildDefinitions -BuildServer $BuildServer -TeamProject $TeamProject -Name $Name
    if($result -and $result.Definitions -and $result.Definitions.Count -gt 0)
    {
        Write-Error "a build definition with the name `"$name`" already exists, remove the definition or pick a different name" -ErrorAction Stop;
    }else{
        $buildDefinition = $BuildServer.CreateBuildDefinition($TeamProject)
        $buildDefinition.Name = $Name
        $buildDefinition.Process = $BuildTemplate
        $buildDefinition.BuildController = $BuildController

        return $buildDefinition
    }
}

function getBuildDefinitions {
    Param(
        [Microsoft.TeamFoundation.Build.Client.IBuildServer] $BuildServer,
        [string] $TeamProject,
        [string] $Name
    );

    $spec = $BuildServer.CreateBuildDefinitionSpec($TeamProject, $Name);
    $result = $BuildServer.QueryBuildDefinitions($spec);
    return $result;
}

function getDefaultBuildTemplate {
    Param(
        [Microsoft.TeamFoundation.Build.Client.IBuildServer] $BuildServer,
        [string] $TeamProject
    );

    $buildTemplates = $BuildServer.QueryProcessTemplates($TeamProject);
    $defaultTemplate = $buildTemplates | where { $_.TemplateType -eq [Microsoft.TeamFoundation.Build.Client.ProcessTemplateType]::Default }

    return $defaultTemplate;
}

function getFirstBuildController {
    Param(
        [Microsoft.TeamFoundation.Build.Client.IBuildServer] $BuildServer
    );

    #create a spec to search for all controllers
    $buildControllerSpec = $BuildServer.CreateBuildControllerSpec("*","");
    $result = $BuildServer.QueryBuildControllers($false);

    if(!$result -or $result.Count -eq 0)
    {
        Write-Error "unable to find any build controllers" -ErrorAction Stop;
    } else {
        Write-Verbose "Found $($result.Count) controllers, selecting first controller in list"
        $buildController = $result[0];
        Write-Verbose "Selected $($buildController.Name)"
        return $buildController
    }
}

function setWorkSpaceMappings{
    Param(
        [Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $buildDefinition,
        [array] $mappings
    );

    Write-Verbose "Clearing workspace mappings"
    $buildDefinition.Workspace.Mappings.Clear()

    $defaultWorkspaceMapping = [PSCustomObject]@{
            ServerItem = "`$/BuildTest/Build/BuildExtensions";
            LocalItem = "`$(SourceDir)\Build";
            Type = "Map";
    }

    $workspaceMappings = @(
        $defaultWorkspaceMapping
    );

    #import the mappings from the exported build defintion
    foreach($workspaceMapping in $configoptions.WorkSpaceMappings)
    {
        #Because we are migrating to a new project we need to modify the imported mapping, in this case prefix the project name to the version control path
        $workspaceMapping.ServerItem = $workspaceMapping.ServerItem.Replace("`$/", "`$/$Project/")
        $workspaceMappings += $workspaceMapping
    }

    #add the mappings to the build definition
    foreach($mapping in $mappings)
    {
        [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType] $type = [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType]::Map;

        if($mapping.Type -eq "Cloak")
        {
            if($mapping.ServerItem.EndsWith("/Drops"))
            {
                Write-Verbose "Skipping cloacked drop folder as we are not dropping into source control"
                continue;
            }
            Write-Verbose "Cloaked workspace mapping"
            $type = [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType]::Cloak;
        }

        $buildDefinition.Workspace.AddMapping($mapping.ServerItem, $mapping.LocalItem, $type) | Out-Null
        Write-Verbose "Mapped workspace path: server:`"$($mapping.ServerItem)`" to local`"$($mapping.LocalItem)`" as: `"$($mapping.Type)`""
    };
}

function createAdvancedBuildSettings {
    Param(
        [string]$msBuildArguments = [System.String]::Empty,
        [string]$msBuildPlatform = "Auto",
        [string]$preActionScriptArguments = [System.String]::Empty,
        [string]$preActionScriptPath = [System.String]::Empty,
        [string]$postActionScriptArguments = [System.String]::Empty,
        [string]$postActionScriptPath = [System.String]::Empty,
        [string]$runCodeAnalysis = "AsConfigured"  
    );

    $params = @{
    "MSBuildArguments" = $msBuildArguments;
    "MSBuildPlatform" = $msBuildPlatform;
    "PreActionScriptArguments" = $preActionScriptArguments;
    "PreActionScriptPath" = $preActionScriptPath;
    "PostActionScriptArguments" = $postActionScriptArguments
    "PostActionScriptPath" = $postActionScriptPath;
    "RunCodeAnalysis"= $runCodeAnalysis;
   };

   $buildParameter = New-Object Microsoft.TeamFoundation.Build.Common.BuildParameter -ArgumentList @($params);
   return $buildParameter;
}

function createAdvancedTestSettings {
    Param(
        [switch]$analyzeTestImpact,
        [switch]$disableTests,
        [string]$preActionScriptArguments = [System.String]::Empty,
        [string]$preActionScriptPath = [System.String]::Empty,
        [string]$postActionScriptArguments = [System.String]::Empty,
        [string]$postActionScriptPath = [System.String]::Empty 
    );

    
    $params = @{ 
        "AnalyzeTestImpact"=if($analyzeTestImpact){$true}else{$false}; 
        "DisableTests"= if($disableTests){$true}else{$false};
        "PreActionScriptPath"= $preActionScriptPath;
        "PreActionScriptArguments"= $preActionScriptArguments;
        "PostActionScriptPath"= $postActionScriptPath; 
        "PostActionScriptArguments"= $postActionScriptArguments;
   };

   $buildParameter = New-Object Microsoft.TeamFoundation.Build.Common.BuildParameter -ArgumentList @($params);
   return $buildParameter;

}

function setProcessParameters {
    Param(
        [Microsoft.TeamFoundation.Build.Client.IBuildDefinition] $buildDefinition,
        $configOptions,
        [string] $Project,
        [int]$majorVersion,
        [int]$minorVersion
        
    );

    $processParameters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::DeserializeProcessParameters($buildDefinition.ProcessParameters)
    $advancedBuildSettings = createAdvancedBuildSettings -postActionScriptPath "$/BuildTest/Build/BuildExtensions/Scripts/Post-Build/post-build.ps1" -preActionScriptPath "$/BuildTest/Build/BuildExtensions/Scripts/Pre-build/pre-build.ps1" -msBuildArguments $configoptions.MSBuildArguments -msBuildPlatform $configoptions.MSBuildPlatform -runCodeAnalysis $configoptions.RunStaticCodeAnalysis
    $processParameters.Add("AdvancedBuildSettings", $advancedBuildSettings);

    $advancedTestSettings = createAdvancedTestSettings -analyzeTestImpact -postActionScriptPath "$/BuildTest/Build/BuildExtensions/Scripts/Post-test/post-test.ps1";
    $processParameters.Add("AdvancedTestSettings", $advancedTestSettings);

    $processParameters.Add("BuildNumberFormat", "`$(BuildDefinitionName)_$majorVersion.$minorVersion.`$(year:yy)`$(DayOfYear)`$(Rev:.r)");

    $covertedProjectsToBuild = [string[]]@()
    foreach($projectToBuild in $configoptions.ProjectsToBuild)
    {
        #Because we are migrating to a new project we need to modify the imported mapping, in this case prefix the project name to the version control path
        $projectToBuild = $projectToBuild.Replace("`$/", "`$/$Project/")
        $covertedProjectsToBuild += $projectToBuild
    }

    $processParameters.Add("ProjectsToBuild", [string[]]$covertedProjectsToBuild)


    $processParameters.Add("ConfigurationsToBuild", [string[]]$configoptions.ConfigurationsToBuild)

    $buildDefinition.ProcessParameters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::SerializeProcessParameters($processParameters);
}

#endregion

#region MIGRATION FUNCTION
function migrate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Collection,
        [Parameter(Mandatory=$true)]
        [string]$Project,
        [string]$TargetTeam,
        [Parameter(Mandatory=$true)]
        [string]$buildDefinitionXmlFile,
        [Parameter(Mandatory=$false)]
        [string]$majorVersion=1,
        [Parameter(Mandatory=$false)]
        [string]$minorVersion=0
    );

    #Read the config options form the builddefinition XML file
    $configoptions = importBuildDefinitionSettings -BuildDefinitionXmlFile $buildDefinitionXmlFile

    # $TFS_BuildServer = "Build Server"
    $dropLocation = "\\rdw.dev.infosupport.net\Public\Drop\RDW\RDW\$TargetTeam"

    $buildDefinitionName = $configoptions.Name
	# Prefix the name with a team prefix
	if([string]::IsNullOrEmpty($TargetTeam) -eq $false)
    {
	    $buildDefinitionName = "$($TargetTeam)`.$($buildDefinitionName)"
    }

    # Create Build Definition
    $buildDefinition = newBuildDefinition -Collection $Collection -TeamProject $Project -Name $buildDefinitionName

    #Set the trigger to Manual
    $buildDefinition.ContinuousIntegrationType = [Microsoft.TeamFoundation.Build.Client.ContinuousIntegrationType]::None

    #Set the drop location
    $buildDefinition.DefaultDropLocation = $dropLocation

    #Set work space mappings, including default mappings
    setWorkSpaceMappings -buildDefinition $buildDefinition -mappings $configoptions.WorkSpaceMappings

    #Set process parameters
    setProcessParameters -buildDefinition $buildDefinition -configOptions $configoptions -Project $Project -majorVersion $majorVersion -minorVersion $minorVersion

    return $buildDefinition
}
#endregion

#region SCRIPT
$buildDefXmls = gci "$BuildDefinitionXmlDirectory\*.xml"
$buildDefs = @();

foreach($buildDefXml in $buildDefXmls)
{
    Write-Host "Migrating $($buildDefXml.Name)"
    $buildDefinition = migrate -Collection $TargetCollection  -Project $TargetProject -TargetTeam $TargetTeam -buildDefinitionXmlFile $buildDefXml -majorVersion $MajorVersion -minorVersion $MinorVersion
    $buildDefs += $buildDefinition

    #Save the build definition
    $buildDefinition.Save()
}

if($PassThru) {
    return $buildDefs
}

#reset the ErrorActionPreference
$ErrorActionPreference =$oldErrorActionPreference

#endregion


