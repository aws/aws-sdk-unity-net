param (
    [string]$SdkRepo
)
$originalLocationLength
$destinationRoot

# We need to keep the directory nesting that's different between just changing root destinations
function Get-Destination($file)
{
    $fileTail = $file.FullName.Substring($originalLocationLength)
    Join-Path -Path $destinationRoot -ChildPath $fileTail
}

function Copy-SrcToNewLocation($file)
{
    $destination = Get-Destination $file
    Write-Host "Copying $file to $destination"
    $destinationDirectoryPath = ([System.IO.FileInfo]$destination).DirectoryName
    # Create the directory if it does not exist
    if(-not (Test-Path $destinationDirectoryPath))
    {
        New-Item $destinationDirectoryPath -ItemType Directory
    }
    Copy-Item $file.FullName -Destination $destination
}

# Check to ensure we are using a valid sdk root
$sdkRepoSrcLocation = Join-Path -Path $SdkRepo -ChildPath 'sdk'
$unitySln = Get-Item (Join-Path $sdkRepoSrcLocation -ChildPath 'AWSSDK.Unity.sln')
if(-not $unitySln)
{
    throw 'Not able to find Unity solution. Please set the SdkRepo parameter to the root of an AWS SDK for .NET repo clone.'
}

$destinationRoot = Get-Location
$originalLocationLength = $sdkRepoSrcLocation.ToString().Length

Set-Location $sdkRepoSrcLocation
Write-Host '=== Copying Unity solution ==='
Copy-SrcToNewLocation $unitySln
Write-Host 'Starting deep copy'
$projectFiles = Get-ChildItem '*.Unity.csproj' -Recurse
foreach($projectFile in $projectFiles)
{
    Write-Host "=== Processing $projectFile ==="
    Write-Host "=== Copying $projectFile ==="
    Copy-SrcToNewLocation $projectFile
    Set-Location $projectFile.Directory
    [Xml]$fileContent = Get-Content $projectFile.Name
    $itemGroups = $fileContent.Project.ItemGroup
    $sourceIncludes = $itemGroups.Compile.Include
    $noneIncludes = $itemGroups.None.Include
    $embeddedIncludes = $itemGroups.EmbeddedResource.Include
    $allIncludes = $sourceIncludes + $noneIncludes + $embeddedIncludes | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    Write-Host "=== Copying includes for $projectFile ==="
    foreach($include in $allIncludes)
    {
        Write-Host "Executing Get-ChildItem against include path $include"
        Get-ChildItem $include -File | ForEach-Object { Copy-SrcToNewLocation $_ }
    }
}

Set-Location $destinationRoot