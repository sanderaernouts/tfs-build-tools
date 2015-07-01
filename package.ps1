
$packageDir = "$PSScriptRoot\package"
$packagingDir = "$packageDir\TfsBuildTools"
$moduleName = "TfsBuildTools"

if(Test-Path $packageDir)
{
    Remove-Item $packageDir -Force -Recurse | Out-Null
}

New-Item -ItemType Directory $packageDir | Out-Null
New-Item -ItemType Directory $packagingDir | Out-Null
    
#gather files in the module TfsSecurityTools folder
Copy-Item $PSScriptRoot\module\*.ps*1 -Destination $packagingDir
Copy-Item $PSScriptRoot\install.ps1 -Destination $packagingDir

#create a zip package
$zipFile = "$packageDir\$($moduleName).zip"
if(Test-Path $zipFile)
{
	Get-ChildItem -File $zipFile | Remove-Item
}

Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory($packagingDir,$zipFile, $compressionLevel, $false)

#open the package directory
explorer $packageDir
