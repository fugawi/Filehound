<#
	.SYNOPSIS
	Provides ability to search file content/name based on user supplied string(s), other options allow for listing directories/files.

	Filehound: v1.1 
	Author: Steve Motts (@fugawi72)
	License: BSD 3-Clause
	Required Dependencies: Powershell v3
	Optional Dependencies: N/A
	

	.DESCRIPTION
	Provides the capability to search file name/content based on a user supplied criteria, also has capability to list directories or files recursively.
	The search begins from a base directory of either a local or mapped drive (ex. c:\temp) provided by the user. Information found can either be displayed
	to the console or saved to a file (csv format). Options selected determine if directories/files will be listed or searched.
	
   
	.PARAMETER BaseDir
	Base directory recursive search starts from (user supplied) - required param
	Options - user supplied string containing path 

	.PARAMETER SearchType
	Type of search to be performed (user supplied) - required param
	Options - ld -> list directory, lf -> list file, sn -> search file name, sc -> search file content 

	.PARAMETER FileString
	String to be searched for in file name.  
	Options - user supplied string to be searched, option sn allows for wildcard *, highly recommend wildcard

	.PARAMETER ContentString
	String to be searched for file content. If this option is selected a 'FileString' is required
	MS Word documents can be searched, however takes a really longtime! Recommend search be very specific if including .doc filenames
	Options - user supplied content string to be searched, does not allow for wildcard *

	.PARAMETER Depth
	Control the depth of the recursive searching from the supplied base directory
	Options - user supplied integer for recursive depth *default is none so will recurse all directories
	
	.PARAMETER Outfile
	Filename to save output (user supplied)
	Options - user string containing path and filename (ex.. c:\Temp\foo.csv), output format is CSV 

	.EXAMPLE
	Filehound.ps1 -SearchType sn -BaseDir c:\temp -OutFile dirs.csv
	
	Description
	-----------
	Do a recursive directory (including hidden) listing starting at c:\temp and save all directories to dirs.csv
	
	
	Filehound.ps1 -SearchType sc -BaseDir c:\temp -FileString *.txt, *.csv -ContentString pwd, pass
	
	Description
	-----------
	Do a recursive directory (including hidden) search for all file names containing (.txt or .csv) and if found search
	contents of the file looking for strings containing (pwd or pass) and display to console.
#>

Param
(
	[Parameter(Mandatory=$false,HelpMessage="Base directory to start search from")]
	[AllowEmptyString()]
	[string]
	$BaseDir = "",
	
	[Parameter(Mandatory=$false, HelpMessage="Required ++ list dir -> ld, list file -> lf, search file name -> /sn, search file content -> /sc")]
	[string]
	$SearchType = "",
	
	[Parameter(Mandatory=$false)]
	[string[]]
	$FileString = @(''),
	
	[Parameter(Mandatory=$false,HelpMessage="path\filename to input file")]
	[string]
	$Infile = "",
	
	[Parameter(Mandatory=$false,HelpMessage="path\filename to save results")]
	[string]
	$Outfile = "",
	
	[Parameter(Mandatory=$false,HelpMessage="Depth for recursive base directory search")]
	[int]
	$Depth = "",
	
	[Parameter(Mandatory=$false,HelpMessage="content search string")]
	[string[]]
	$ContentString = @('')	
)	


function dirlist {
#array to hold directory results 
$dirtotal = @()
	if ($Depth -ne "") {
		#list all dirs based on recursive depth
		foreach ($dir in Get-ChildItem $BaseDir -Force -Recurse -Depth $Depth -Directory -ErrorAction SilentlyContinue) {
			$dirtotal += $dir | Select-Object FullName, CreationTime, LastAccessTime
		}
	} Else {
		#list all dirs including hidden
		foreach ($dir in Get-ChildItem $BaseDir -Force -Recurse -Directory -ErrorAction SilentlyContinue) {
			$dirtotal += $dir | Select-Object FullName, CreationTime, LastAccessTime
		}
	}
	if ($Outfile -ne "") {
		$dirtotal | Export-Csv -NoTypeInformation -append $OutFile
	} Else {
		$dirtotal | Format-Table 
	}	
Write-Host "Directory Count: "$dirtotal.count -Foregroundcolor Green
}

function filelist {
#array to hold file results 
$filetotal = @()
	if ($Depth -ne "") {
		#list all files based on recursive depth
		foreach ($file in Get-ChildItem $BaseDir -Force -Recurse -Depth $Depth -File -ErrorAction SilentlyContinue) {
			$filetotal += $file | Select-Object FullName, CreationTime, LastAccessTime
		}
	} Else {
		#list all files including hidden
		foreach ($file in Get-ChildItem $BaseDir -Force -Recurse -File -ErrorAction SilentlyContinue) {
			$filetotal += $file | Select-Object FullName, CreationTime, LastAccessTime
		}
	}	
	if ($Outfile -ne "") {
		$filetotal | Export-Csv -NoTypeInformation -append $OutFile
	} Else {
		$filetotal | Format-Table 
	}	
Write-Host "Directory Count: "$filetotal.count -Foregroundcolor Green
}

function searchfilename {
#array to hold file results 
$filetotal = @()
	if ($Depth -ne "") {
		#list files based on recursive depth including hidden that contain file search string(s)
		foreach ($string in $FileString) { 
			foreach ($file in Get-ChildItem $BaseDir -Force -Recurse -Depth $Depth -File -Filter $string -ErrorAction SilentlyContinue) {
				$filetotal += $file | Select-Object FullName, CreationTime, LastAccessTime
			}
		}
	} Else {
		#list files including hidden that contain file search string(s)
		foreach ($string in $FileString) { 
			foreach ($file in Get-ChildItem $BaseDir -Force -Recurse -Depth $Depth -File -Filter $string -ErrorAction SilentlyContinue) {
				$filetotal += $file | Select-Object FullName, CreationTime, LastAccessTime
			}
		}
	}	
	if ($Outfile -ne "") {
		$filetotal | Export-Csv -NoTypeInformation -append $OutFile
	} Else {
		$filetotal | Format-Table 
	}
Write-Host "File  Count: "$filetotal.count -Foregroundcolor Green
}

function contentsearch{
#array to hold file results 
$filetotal = @()
#initialize word com object if file type contains .doc/.docx
if ($FileString -match '.doc$' -or $FileString -match '.docx$'){ #-like "*.doc*") {
	$word = New-Object -comobject word.application
	$word.visible = $false
}
	#find all files including hidden based on recursive depth
	#first foreach loop could be removed, use 'Include' instead of 'Filter', however in testing the 'Filter' param was minimally faster
if ($Depth -ne "") {
	foreach ($string in $FileString) { 
		foreach ($file in Get-ChildItem $BaseDir -Force -Recurse -Depth $Depth -File -Filter $string -ErrorAction SilentlyContinue) {
			#Search each file type for content. Check if MS Word document was given and search/close as applicable
			foreach ($cstring in $ContentString) { 
				Write-Progress -Activity "Processing files" -status "Processing $($file.FullName)" -PercentComplete ($i /$file.Count * 100)
				if ($file.FullName -match '.doc$' -or $file.FullName -match '.docx$') {
					
					if ($word.Documents.Open($file.FullName).Content.Find.Execute($cstring)) {
						$word.Application.ActiveDocument.Close()
						$result = $file | Select-Object FullName, CreationTime, LastAccessTime, @{Name="Content"; Expression={$cstring}}
					}			
				} else {	
					$result = Get-Content -LiteralPath $file.FullName | Select-String -Pattern $cstring
				}	
			
				if ($result -ne $Null) {
					$filetotal += $file | Select-Object FullName, CreationTime, LastAccessTime, @{Name="Content"; Expression={$cstring}} 
				}
				$result = $Null
			}
		}
	}
} Else {
	#find all files including hidden 
	#first foreach loop could be removed, use 'Include' instead of 'Filter', however in testing the 'Filter' param was minimally faster
	foreach ($string in $FileString) { 
		foreach ($file in Get-ChildItem $BaseDir -Force -Recurse -File -Filter $string -ErrorAction SilentlyContinue) {
			#Search each file type for content. Check if MS Word document was given and search/close as applicable
			foreach ($cstring in $ContentString) { 
				Write-Progress -Activity "Processing files" -status "Processing $($file.FullName)" -PercentComplete ($i /$file.Count * 100)
				if ($file.FullName -match '.doc$' -or $file.FullName -match '.docx$') {
					
					if ($word.Documents.Open($file.FullName).Content.Find.Execute($cstring)) {
						$word.Application.ActiveDocument.Close()
						$result = $file | Select-Object FullName, CreationTime, LastAccessTime, @{Name="Content"; Expression={$cstring}}
					}			
				} else {	
					$result = Get-Content -LiteralPath $file.FullName | Select-String -Pattern $cstring
				}	
			
				if ($result -ne $Null) {
					$filetotal += $file | Select-Object FullName, CreationTime, LastAccessTime, @{Name="Content"; Expression={$cstring}} 
				}
				$result = $Null
			}
		}
	}
}
#quit MS Word	
if ($FileString -like "*.doc*") {
	$word.Quit()
}
#save to file or print
if ($Outfile -ne "") {
	$filetotal | Export-Csv -NoTypeInformation -append $OutFile
} Else {
	$filetotal | Format-Table 
}
Write-Host "File  Count: "$filetotal.count -Foregroundcolor Green
}
#gather user options 
If ($SearchType -eq "ld") {
	If([string]::IsNullOrEmpty($BaseDir)) {
		Write-Host "BaseDir parameter cannot be NULL or EMPTY!" -Foregroundcolor "Red"
		Return
	}
	If (Test-Path $BaseDir -PathType Container) {
		Write-Host "`nListing all directories starting at:" $BaseDir -Foregroundcolor "Yellow"
		$sw = [system.diagnostics.stopwatch]::startNew()
		dirlist
		$et = $sw.Elapsed
		Write-Host "Time taken" $et -Foregroundcolor "Yellow" "`n"
		$sw.Stop()
	} Else {
		Write-Host "Directory $BaseDir not found!" -Foregroundcolor "Red"
		Return
	}
}
ElseIf ($SearchType -eq "lf") {
	If([string]::IsNullOrEmpty($BaseDir)) {
		Write-Host "BaseDir parameter supplied is NULL or EMPTY!" -Foregroundcolor "Red"
		Return
	}
	If (Test-Path  $BaseDir -PathType Container){
		Write-Host "Listing all files starting at:" $BaseDir -Foregroundcolor "Yellow"
		$sw = [system.diagnostics.stopwatch]::startNew()
		filelist
		$et = $sw.Elapsed
		Write-Host "Time taken" $et -Foregroundcolor "Yellow" "`n"
		$sw.Stop()
	} Else {
		Write-Host "Directory $BaseDir not found!" -Foregroundcolor "Red"
		Return
	}
}
ElseIf ($SearchType -eq "sn") {
	If([string]::IsNullOrEmpty($BaseDir)) {
		Write-Host "BaseDir parameter supplied is NULL or EMPTY!" -Foregroundcolor "Red"
		Return
	}
	If (Test-Path  $BaseDir -PathType Container){
		If([string]::IsNullOrEmpty($FileString)) {
			Write-Host "File search parameter supplied is NULL or EMPTY!, one or the other is REQUIRED!" -Foregroundcolor "Red"
			Return
		} Else {
			
			Write-Host "Listing files starting at:" $BaseDir "containing:" $FileString -Foregroundcolor "Yellow"
			$sw = [system.diagnostics.stopwatch]::startNew()
			searchfilename
			$et = $sw.Elapsed
			Write-Host "Time taken" $et -Foregroundcolor "Yellow" "`n"
			$sw.Stop()
		}
	} Else {
		Write-Host "Directory $BaseDir not Found!" -Foregroundcolor "Red"
		Return
	}
}
ElseIf ($SearchType -eq "sc") {
If([string]::IsNullOrEmpty($BaseDir)) {
		Write-Host "BaseDir parameter supplied is NULL or EMPTY!" -Foregroundcolor "Red"
		Return
	}
	If (Test-Path  $BaseDir -PathType Container){
		If([string]::IsNullOrEmpty($FileString)) {
			Write-Host "File search parameter supplied is NULL or EMPTY!, one or the other is REQUIRED!" -Foregroundcolor "Red"
			Return
		} Else {
			Write-Host "Searching" $BaseDir "for filenames containing" $FileString "and file content containing" $ContentString -Foregroundcolor "Yellow"
			$sw = [system.diagnostics.stopwatch]::startNew()
			contentsearch
			$et = $sw.Elapsed
			Write-Host "Time taken" $et -Foregroundcolor "Yellow" "`n"
			$sw.Stop()
		}
	} Else {
		Write-Host "Directory $BaseDir not Found!" -Foregroundcolor "Red"
		Return
	}
}