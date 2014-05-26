# DHCP Leases Exportieren
#
# foo.li systeme + software 2014
#
# neuere win-versionen haben das in der powershell integriert, bei 2003 waere mir das jedoch
# nicht bekannt, deshalb das ganze via netsh-Umweg. 
#
# 29.3.2014/pvb
# nur mit englischem Server 2003 getestet
#
# Originalskript:
# http://theadminguy.com/2009/10/14/export-dhcp-leases-to-html-using-powershell/
# musste jedoch einiges ergaenzen/anpassen und parameter fuer fuer scope, pfad und server hinzugefuegt

Param (
 [Parameter(Mandatory = $true)]  #this value has to be set
 [string]$scope,
 [Parameter()]                   #these values have defaults
 [string]$out_path = "\\unxfsv001\transfer\it",
 [string]$out_file = "dhcp_leases",
 [string]$server = $env:computername #in my tests it's working more reliable with ip address
)

$out_csv = $out_path + "\" + $out_file + ".csv"
$out_html = $out_path + "\" + $out_file + ".html"

# "1" on show clients will also show the hostnames
$a = (netsh dhcp server $server scope $scope show clients 1)

$lines = @()
#start by looking for lines where there is both IP and MAC present:
foreach ($i in $a){
    if ($i -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){
        If ($i -match "[0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}"){    
            $lines += $i.Trim()
        }
    }
}
$csvfile = @()
#Trim the lines for uneeded stuff, leaving only IP, Subnet mask, hostname and MAC
foreach ($l in $lines){
    $Row = "" | select Hostname,IP,Subnet,Mac
    #$l = $l -replace '[0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}', ''
    $l = $l -replace '-D-',',' #nix nur zum testen, kann leer bleiben
    $l = $l -replace '-N-',','
    $l = $l -replace '- NEVER EXPIRES',''   
    $l = $l -replace '- INACTIVE',''  
    $l = $l -replace '[-]{1}\d{2}[/]\d{2}[/]\d{4}','' #amidatum (notime nur zum testen, kann leer sein)
    $l = $l -replace '[-]{1}\d{2}[.]\d{2}[.]\d{4}','' #eurodatum
    $l = $l -replace '\d{1,2}[:]\d{2}[:]\d{2}',''     #zeit       
    $l = $l -replace ' - ',','
    $l = $l -replace '- ',','
    $l = $l -replace ' -',',' 
    $l = $l -replace '\s{4,}','' # ?
    $l = $l -replace '--','-'    # ?
    $l = $l -replace 'AM',''
    $l = $l -replace 'PM',''
    $l = $l -replace '\s{1}','' # ?
    if ($l -match "[0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}[:-][0-9a-f]{2}") {
        $l = $l -replace '-',''
        $Row.Mac = ($l.Split(","))[2]
    }
    $l = $l + "`n"
    $Row.IP = ($l.Split(","))[0]
    $Row.Hostname = ($l.Split(","))[3] 
    $Row.Subnet = ($l.Split(","))[1] 
    $Row.Mac = ($l.Split(","))[2] 
    $csvfile += $Row
}

#create csv file
$csvfile | sort-object IP | Export-Csv "$out_csv"

#create HTML formating
$date = Get-Date
$a = "<style>"
$a = $a + "body {margin: 10px; width: 600px; font-family:arial; font-size: 12px;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color: rgb(179,179,179);align='left';}"
$a = $a + "TD{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color: white;}"
$a = $a + "</style>"
$a = $a + "<title>foo.li DHCP Leases from " + $server + " (" + $date + ") </title>"

#create HTML file...
Write-Host leases exported to $out_html | Out-File $out_html
$csvfile | sort-object Hostname | ConvertTo-HTML -head $a | Out-File -Append "$out_html"
