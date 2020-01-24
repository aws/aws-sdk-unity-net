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

function Edit-ProjectFileUnityPath($projectFile)
{
    $projectFileDestination = Get-Destination $projectFile
    Write-Host "=== Writing $($projectFile.Name) to $projectFileDestination"
    [Xml]$xmlDoc = Get-Content $projectFile.Name
    $chooseFragment = $xmlDoc.CreateDocumentFragment()
    if($projectFile.Name -eq 'AWSSDK.Core.Unity.csproj')
    {
        $chooseFragment.InnerXml = @'

  <Choose>
    <When Condition=" '$(UnityDataPath)' == '' ">
      <ItemGroup>
        <Reference Include="UnityEngine, Version=0.0.0.0, Culture=neutral, processorArchitecture=MSIL">
          <HintPath>C:\Program Files\Unity\Editor\Data\Managed\UnityEngine.dll</HintPath>
        </Reference>
      </ItemGroup>
    </When>
    <Otherwise>
      <ItemGroup>
        <Reference Include="UnityEngine, Version=0.0.0.0, Culture=neutral, processorArchitecture=MSIL">
          <HintPath>$(UnityDataPath)\Managed\UnityEngine.dll</HintPath>
        </Reference>
      </ItemGroup>
    </Otherwise>
  </Choose>

'@
    }
    else
    {
        $chooseFragment.InnerXml = @'

  <Choose>
    <When Condition=" '$(UnityDataPath)' == '' ">
      <ItemGroup>
        <Reference Include="UnityEngine, Version=0.0.0.0, Culture=neutral, processorArchitecture=MSIL">
          <HintPath>C:\Program Files\Unity\Editor\Data\Managed\UnityEngine.dll</HintPath>
        </Reference>
        <Reference Include="System.Data">
          <HintPath>C:\Program Files\Unity\Editor\Data\Mono\lib\mono\2.0\System.Data.dll</HintPath>
          <Private>True</Private>
        </Reference>
        <Reference Include="Mono.Data.SQLite">
          <HintPath>C:\Program Files\Unity\Editor\Data\Mono\lib\mono\2.0\Mono.Data.SQLite.dll</HintPath>
          <Private>True</Private>
        </Reference>
      </ItemGroup>
    </When>
    <Otherwise>
      <ItemGroup>
        <Reference Include="UnityEngine, Version=0.0.0.0, Culture=neutral, processorArchitecture=MSIL">
          <HintPath>$(UnityDataPath)\Managed\UnityEngine.dll</HintPath>
        </Reference>
        <Reference Include="System.Data">
          <HintPath>$(UnityDataPath)\Mono\lib\mono\2.0\System.Data.dll</HintPath>
          <Private>True</Private>
        </Reference>
        <Reference Include="Mono.Data.SQLite">
          <HintPath>$(UnityDataPath)\Mono\lib\mono\2.0\Mono.Data.SQLite.dll</HintPath>
          <Private>True</Private>
        </Reference>        
      </ItemGroup>
    </Otherwise>
  </Choose>

'@
    }
    $xmlDoc.Project.AppendChild($chooseFragment)

    $xmlDoc.Project.ItemGroup.Reference |
     Where-Object { $_ } |
     Where-Object { $_.Include.StartsWith('UnityEngine') -or $_ -eq 'System.Data' -or $_ -eq 'Mono.Data.SQLite' } |
     ForEach-Object { $_.ParentNode.RemoveChild($_) }

    $projectFileDestination = Get-Destination $projectFile

    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.IndentChars = '  '

    # Yes, writing this to a string just to remove xmlns. I could not find a better way to do it.
    $stringHold = New-Object System.Text.StringBuilder
    $xmlWriter = [System.Xml.XmlWriter]::Create($stringHold, $xmlWriterSettings)
    $xmlDoc.Save($xmlWriter)
    $stringHold.ToString().Replace(' xmlns=""', '') > $projectFileDestination
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

    Edit-ProjectFileUnityPath $projectFile
}

Set-Location $destinationRoot