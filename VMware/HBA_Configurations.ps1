$ErrorActionPreference = "SilentlyContinue"

#Find PowerCli initalization script
$PowerCli = (Get-ChildItem "C:\Program *" -Filter "*PowerCLIEnvironment.ps1*" -Recurse -ErrorAction SilentlyContinue).FullName
#Run Powercli initalization script
& $PowerCli
Start-Sleep 5

#change the values to suit your needs. You can remove or uncomment 
# the other vcenters too if you'd prefer. 

$vCenter_1	= "vcenter_1.domain.local"
$vCenter_2	= "vcenter_2.domain.local"
$vCenter_3	= "vcenter_3.domain.local"
$Credentials = Get-Credential -message "Enter your credentials (domain\username)"

# If you uncomment vCenters above, you would need to uncomment the 
# corresponding vCenter connections below. 

Connect-ViServer "$vCenter_1" -Credential $Credentials 
Connect-ViServer "$vCenter_2" -Credential $Credentials
Connect-ViServer "$vCenter_3" -Credential $Credentials 

# Below you will see three clusters, you may remove the clusters and 
# just use a Get-VM function or change it to a Get-Datacenter function 
# to reach a larger amount of VMs

$style = "
<title>HBA Configuration</title>

<style>
    h1, h5, h2, th { text-align: center;font-family: sans-serif; }
    table { align=`"center`"; vertical-align=`"top`"; font-family: arial; box-shadow: 10px 10px 5px #888; border: 1px solid black;}
    th { background: #000000; color: #FFF; max-width: 400px; padding: 5px 10px; }
    td { font-size: 11px; padding: 5px 15px; color: #000000; }
    tr { background: #FFFFFF; }
</style>
"

$IScsiInfo = @()
$NoHba = @()
$NoIP = @()
$ESXiHosts = Get-VMHost

ForEach ($_ in $ESXiHosts) {
           $GetIScsi = New-Object System.Object
           $GetIScsi | Add-Member -Type NoteProperty -Name "Name" -Value $_.Name

                $hba = $_ | Get-VMHostHba -Type iScsi | Where-Object {$_.Model -eq "iSCSI Software Adapter"} 

                    if ($hba -eq $null) 
                        {       
                            $NoHba+=$_ 
                        }Else{

                    $TargetIP = $_ | Get-VMHostHba -Type iScsi | Where-Object {$_.Model -eq "iSCSI Software Adapter"} | Get-IscsihbaTarget -Type "Send" | select-object -ExpandProperty Address
               
                    if ($TargetIP -eq $null) 
                        { 
                        $NoTargetIP = New-Object System.Object
                        $NoTargetIP | Add-Member -Type NoteProperty -Name "Name" -Value ($_.Name)
                        $NoTargetIP | Add-Member -Type NoteProperty -Name "HBA" -Value $Hba.IScsiName
                        $NoIP+=$NoTargetIP
                        }else{

            $GetIScsi | Add-Member -Type NoteProperty -Name "HBA" -Value $Hba.IScsiName
            $GetIScsi | Add-Member -Type NoteProperty -Name "IP1" -Value ($TargetIP).get(0)
            $GetIScsi | Add-Member -Type NoteProperty -Name "IP2" -Value ($TargetIP).get(1)
            
            #Uncomment the below for all the IPs you have, or add additional lines if you have more configured, incrementing the numbers
            
            # $GetIScsi | Add-Member -Type NoteProperty -Name "IP3" -Value ($TargetIP).get(2)
            # $GetIScsi | Add-Member -Type NoteProperty -Name "IP4" -Value ($TargetIP).get(3)
            # $GetIScsi | Add-Member -Type NoteProperty -Name "IP5" -Value ($TargetIP).get(4)
            # $GetIScsi | Add-Member -Type NoteProperty -Name "IP6" -Value ($TargetIP).get(5)
            # $GetIScsi | Add-Member -Type NoteProperty -Name "IP7" -Value ($TargetIP).get(6)
            # $GetIScsi | Add-Member -Type NoteProperty -Name "IP8" -Value ($TargetIP).get(7)
            $IScsiInfo += $GetIScsi
            
        } 
    }
}   

$body = ""
$body += "<center>"
$body += "<h2>The following have iSCSI HBA's configured</h2>"
$body += $IScsiInfo | Sort-Object -Property Name | ConvertTo-Html -As Table
$body += "<h2>The following have iSCSI HBA's but NO IPs configured</h2>"
$body += $NoIP  | Sort-Object -Property Name | ConvertTo-Html -As Table
$body += "<h2>The following have NO iSCSI HBA's configured</h2>"
$body += $NoHba | Sort-Object -Property Name | Select-Object Name,PowerState  | ConvertTo-Html 
$body += "</center>"
$html = $style + $body

#Outputs to file
#ConvertTo-Html -Head $style -Body $body | Out-File C:\temp\test.html

#Email config
$From = "<HBAConfigurations@domain.com>"
$To = @("Firstname LastName<Firstname.LastName@domain.com>")
$Subject = "HBA Configurations"
$SMTPServer = "smtp.domain.com"

#Send email
Send-MailMessage -From $From -To $To -Subject $Subject -SmtpServer $SMTPServer -BodyAsHtml $html