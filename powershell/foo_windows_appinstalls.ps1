
Function QueryProgramFiles
{
	Function BuildArray
	{	#if 64bit system
		if (!([Diagnostics.Process]::GetCurrentProcess().Path -match '\\syswow64\\'))
		{
			$unistallPath = "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
			$unistallWow6432Path = "\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
			$Array = @(
			if (Test-Path "HKLM:$unistallWow6432Path" ) { Get-ChildItem "HKLM:$unistallWow6432Path"}
			if (Test-Path "HKLM:$unistallPath" ) { Get-ChildItem "HKLM:$unistallPath" }
			if (Test-Path "HKCU:$unistallWow6432Path") { Get-ChildItem "HKCU:$unistallWow6432Path"}
			if (Test-Path "HKCU:$unistallPath" ) { Get-ChildItem "HKCU:$unistallPath" }
			)
			return $Array
		}
		else #32bit system
		{
			$unistallPath = "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
			$Array = @( if (Test-Path "HKLM:$unistallPath" ) { Get-ChildItem "HKLM:$unistallPath" }
					if (Test-Path "HKCU:$unistallPath" ) { Get-ChildItem "HKCU:$unistallPath" } )
			return $Array
		}
	}

	$data = BuildArray
	$test = $data | ForEach-Object { Get-ItemProperty $_.PSPath } `
			| Where-Object { $_.DisplayName -and !$_.SystemComponent -and !$_.ReleaseType -and !$_.ParentKeyName -and ($_.UninstallString -or $_.NoRemove) } `
			| Sort-Object DisplayName | Select-Object DisplayName
			
	return $test
}

#create Baseline if none exists
Function CreateBasline
{
	if (!(Test-Path .\ProgramList.tmp))
		{ QueryProgramFiles | Out-File .\ProgramList.tmp}
;}

#function for parsing information from array to display
Function WriteList {
	param([string[]]$ProgLst, [int]$len)
	for ($i = 3; $i -lt $len; $i++)
		{ $elem = $ProgLst[$i] -replace '\s+', ''
		  $elem = $elem -replace '=>', ' installed'
		  $elem = $elem -replace '<=', ' uninstalled'
		  Write-Host $elem
		}
}

#tests if change has been detected, and display the correct message
Function Delta
{
	QueryProgramFiles | Out-File .\ProgramList2.tmp
	
	$BaseLine = $(Get-Content .\ProgramList.tmp)
	$Current = $(Get-Content .\ProgramList2.tmp)
	$Delta = Compare-Object $BaseLine $Current

	if (!$Delta)
		{ Write-Host "Program Files Counted: " -nonewline
		  $Total = $BaseLine.Length - 5
		  Write-Host $Total
		  Write-Host "\n"
		  WriteList $Current ($Current.length - 2)
		  exit 0}
	else
	{	
		echo $Delta > Delta.tmp
		Write-Host "Program(s) Added/Removed:"
		$Delta = $(Get-Content Delta.tmp)
		WriteList $Delta $Delta.length		
		rm ProgramList.tmp
		rm ProgramList2.tmp
		exit 2
	}
}

CreateBasline
Delta

#check_windows_app_installs V1.1
#Developed by: Yancy Ribbens (yribbens@nagios.com)
#Copyright (c) 2010-2011 Nagios Enterprises, LLC.
