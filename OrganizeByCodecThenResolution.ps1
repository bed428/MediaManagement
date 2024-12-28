#Organizes video data by 'Video Format Video Frame Video Codec'


$TargetDirectory = "C:\Users\USERNAME\Videos\Album01"

$ExifTool = "C:\Scripts\exiftool-13.10_64\exiftool.exe"

#OPTIONAL - Remove comment on -recuse and it will dive into subfolders also.
$RefFiles = Get-ChildItem -Path $TargetDirectory -File #-Recuse

$ParsedObjects = @()
foreach($Item in $RefFiles){
    $Output = &$ExifTool $Item.FullName

    # # Split the output into lines and Parse each line and create a hashtable
    $Lines = $Output -split "`n"
    $HashTable = @{}
    foreach ($Line in $Lines) {
        # Split on the first colon and trim whitespace
        $Parts = $Line -split ":", 2
        if ($Parts.Count -eq 2) {
            $Key = $Parts[0].Trim()
            $Value = $Parts[1].Trim()
            $HashTable[$Key] = $Value
        }
    }

    # Convert the hashtable to a PSCustomObject
    $ParsedObject = [PSCustomObject]$HashTable

    $ParsedObjects += $ParsedObject
}

#Output Objects for line by line running/checking
  #$ParsedObjects | select 'File Name','Video Format Video Frame Video Codec'

#Items with a valid codec will have a folder created (if not already exists) and moved into the folder.
  $ObjectsWithCodec = $ParsedObjects | where {$null -ne $_.'Video Format Video Frame Video Codec'}
  foreach($item in $ObjectsWithCodec){
      $ItemPath = ($item.Directory + "/" + $item.'file name')
      $ItemCodec = ($Item.'Video Format Video Frame Video Codec')
      
      if( Test-Path ($TargetDirectory + '/' + $ItemCodec ){<#Do nothing#>}
      else{ New-Item ($TargetDirectory + '/' + $ItemCodec) -ItemType Directory }
      
      try{
        Move-Item -Path $ItemPath -Destination ($TargetDirectory + '\' + $Item.'Video Format Video Frame Video Codec') -ErrorAction Stop
        Write-Host "Successfully moved $($Item.'File Name')"
      }
      catch{Write-Host -ForegroundColor Red $ItemPath 'failed!`n $($_.Exception)'  }
  }

#Determine which items do not have a codec and create a simple resolution folder for them, then move them there. 
  $ObjectsWithOutCodec = $ParsedObjects | where {$null -eq $_.'Video Format Video Frame Video Codec'}
  
  foreach($Object in $ObjectsWithOutCodec){
      $Resolution = $object.'Image Width' + 'x' + $object.'Image Height'
      $ItemPath = ($Object.Directory + "/" + $Object.'file name')
      
      if(Test-Path ($TargetDirectory + '/' + $Resolution)){}
      else{ New-Item ($TargetDirectory + '/' + $Resolution) -ItemType Directory}
      
      try{
        Move-Item -Path $ItemPath -Destination ($TargetDirectory + '/' + $Resolution) -ErrorAction Stop
        Write-Host "Successfully moved $($Object.'File Name')"
      }
      catch{ Write-Host -ForegroundColor Red $ItemPath 'failed!`n $($_.Exception)' }
      
  }
