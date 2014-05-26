# foo.li systeme + software 2014
##############################################################################
#
# NAME: 	check_file_age.ps1
#
# AUTHOR:   Peter Beck, foo.li systeme + software
# EMAIL: 	peter.beck@foo.li
#
# COMMENT:  Script to check windows file age with Nagios + NRPE/NSClient++
#           currently calculating with days only
#
#           configuration in NSClient++ ini:
#           check_file_age=cmd /c echo scripts/check_file_age.ps1 -path $ARG1$ -warn \
#           $ARG2$ -crit $ARG3$; exit($lastexitcode) | powershell.exe -command -
#
#           ensure nasty_meta_chars are allowed and 
#           backslashes in paths via nrpe are escaped (\\)
#
# CHANGELOG:
# 1.0 2014-03-21 - initial version
#
##############################################################################

Param (
 [Parameter(Mandatory = $true)]  #this value has to be set
 [string]$path,
 [Parameter()]                   #these values have defaults
 [int32]$warn = "7",
 [int32]$crit = "14"
)

if ($warn -ge $crit) {
    Write-Host "warn threshold has to be lower than critical threshold"
    exit 3
}
if(!(Test-Path -Path $path)) { 
    Write-Host "UNKNOWN script state: File not found"
    Write-Host "Hint: ensure backslashes in paths are escaped."
    exit 3
}

$now = (Get-Date)
$lim_warn = (Get-Date).AddDays(-$warn)
$lim_crit = (Get-Date).AddDays(-$crit)
$age = [datetime](Get-ItemProperty -Path $path).LastWriteTime
$days = [int](New-TimeSpan -Start $age -End $now).days   #this will return positive values
$filename = $path.split("\")[-1]

if ($days -lt $warn) {
    Write-Host "OK: File $filename is $days days old"
    exit 0
}
elseif ($days -ge $crit) {
    Write-Host "CRITICAL: File $filename is $days days old"
    exit 2
} 
elseif ($days -ge $warn ) {
    Write-Host "WARNING: File $filename is $days days old"
    exit 1 
} 
else {
    Write-Host "UNKNOWN script state"
    exit 3
}
