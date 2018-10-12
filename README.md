# Filehound
Filehound is a penetration testing tool for searching file name/content based on user supplied criteria, also has capability to list directories or files recursively. Created to assist with MITRE ATT&CK ID T1083 (File and Directory Discovery)

# PARAMETERS
	BaseDir - Base directory recursive search starts from (user supplied)
	Options - user supplied string containing path 

	SearchType - Type of search to be performed (user supplied) - required param
	Options - ld -> list directory, lf -> list file, sn -> search file name, sc -> search file content 

	Depth - Recursive search depth
	Options - Integer specifying  how deep to conduct recursive search

	FileString
	String to be searched for in filename  
	Options - user supplied filename string to be searched, allows for wildcard *highly recommend wildcard*

	ContentString
	String to be searched for in file content. MS Word documents can be searched, however takes a really longtime! 
	Recommend search be very specific if including .doc filenames
	Options - user supplied content string to be searched, does not allow for wildcard *

	Outfile
	Filename to save output
	Options - user string containing path and filename (ex.. c:\Temp\foo.csv), output format is CSV 

# EXAMPLES
	Filehound.ps1 -SearchType sn -BaseDir c:\temp -OutFile dirs.csv
	
	Description
	-----------
	Do a recursive directory (including hidden) listing starting at c:\temp and save all directories to dirs.csv
	
	
	Filehound.ps1 -SearchType sc -BaseDir c:\temp -FileString *.txt, *.csv -ContentString pwd, pass
	
	Description
	-----------
	Do a recursive directory (including hidden) search for all file names containing (.txt or .csv) and if found search
	contents of the file looking for strings containing (pwd or pass) and display to console.
