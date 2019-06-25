$ErrorActionPreference = "Stop"

Add-Type -Path ([System.IO.Path]::Combine($PSScriptRoot, 'HidSharp', 'HidSharp.dll'))
$script:COMMAND_INDEXES = @{
	Left  = 2
	Right = 3
	Up    = 4
	Down  = 5
	Fire  = 6
}

$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

foreach($Import in @($Public + $Private)){
	Write-Verbose "Loading $($Import.FullName)"
	try {
		. $Import.FullName
	} catch {
		Write-Error -Message "Failed to import function $($Import.FullName): $_"
	}
}
Export-ModuleMember -Function $Public.Basename