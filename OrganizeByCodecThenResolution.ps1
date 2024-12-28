#↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓EDIT THESE↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    $TargetDirectory = "C:\Users\USERNAME\Videos\Folder01"
    $ExifTool = "C:\Scripts\exiftool-13.10_64\exiftool.exe"

    $VideoExtensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.mpeg')
    $RefFiles = Get-ChildItem -Path $TargetDirectory -File -Recurse | Where-Object { $VideoExtensions -contains $_.Extension }

#↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑EDIT THESE↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑


#↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓No need to modify anything below↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

#By Default, ExifTool doesn't return a workable object, so we need to parse the output into a hashtable and then convert that to a PSCustomObject.
  $ParsedObjects = @()
  foreach($Item in $RefFiles){
      $Output = &$ExifTool $Item.FullName

      # #Split the output into lines and Parse each line and create a hashtable
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

#Items with a valid codec will have a folder created (if not already exists) and moved into the folder.
  foreach($Object in $ParsedObjects){
      $DeviceModelName = 
            if($Object.'Samsung Model'){$Object.'Samsung Model'} #Samsung devices. Tested with S21 Ultra
            elseif($Object.'Device Model Name'){$Object.'Device Model Name'} #Sony devices. (Tested with A7C & A7IV)
      $ObjectCodec = ($Object.'Video Format Video Frame Video Codec')
      $Resolution = $Object.'Image Width' + 'x' + $Object.'Image Height'
      $ObjectPath = ($Object.Directory + "/" + $Object.'file name')
      $FrameRate = $Object.'Video Frame Rate'
      $MajorBrand = 
            if($object.'Major Brand' -like "*Sony*") {$Object.'Major Brand'} #AKA Like "Sony XAVC"
            else{""} #For samsung devices it's an ISO# so we just want to ignore this. 
      
      $ItemNewDirectoryName = $TargetDirectory + '\' + `
        ($DeviceModelName + "_" -replace '^\s*_\s*', '') + `
        ($MajorBrand + "_" -replace '^\s*_\s*', '') + `
        ($ObjectCodec + "_" -replace '^\s*_\s*', '') + `
        $Resolution + "_" + `
        $FrameRate + "fps"

      if( !(Test-Path $ItemNewDirectoryName) ){New-Item $ItemNewDirectoryName -ItemType Directory }
      try{
        Move-Item -Path $ObjectPath -Destination $ItemNewDirectoryName -ErrorAction Stop
        Write-Host "Successfully moved $($Item.'File Name')"
      }
      catch{Write-Host -ForegroundColor Red $ObjectPath 'failed!`n $($_.Exception)'  }
  }
