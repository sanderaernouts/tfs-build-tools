. .\TfsBuildTools.BuildServer.ps1
. .\TfsBuildTools.BuildDefinition.ps1
. .\TfsBuildTools.WorkspaceMappings.ps1
. .\TfsBuildTools.ProjectsToBuild.ps1
. .\TfsBuildTools.AdvancedBuildSettings.ps1
. .\TfsBuildTools.AdvancedTestSettings.ps1
. .\TfsBuildTools.AutomatedTestSettings.ps1

#export only the function names that contain a hyphen (and thus are cmdlets)
Export-ModuleMember -function *-*