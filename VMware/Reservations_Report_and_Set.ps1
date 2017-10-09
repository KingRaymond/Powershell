$ErrorActionPreference = "SilentlyContinue"

#Find PowerCli initalization script
$PowerCli = (Get-ChildItem "c:\Program *" -Filter "*PowerCLIEnvironment.ps1*" -Recurse -ErrorAction SilentlyContinue).FullName
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

$CPUCount = @()

$vm = Get-Cluster -Name "Cluster_1","Cluster_2","Cluser_3" | Get-VM # | Where-Object { $_.Name -notlike "*KSVP*"} #uncomment the Where-Object if you would like 

ForEach ($_ in $vm) {
           $SetCPU = New-Object System.Object
           $SetCPU | Add-Member -type NoteProperty -Name "VMName" -Value $_.Name
           $SetCPU | Add-Member -type NoteProperty -Name "CPU" -Value $_.NumCpu
           $SetCPU | Add-Member -type NoteProperty -Name "Memory" -Value $_.MemoryGB
              $ReservationCPU = $_ | Get-VMResourceConfiguration | Select-Object CpuReservationMhz
              $ReservationMEM = $_ | Get-VMResourceConfiguration | Select-Object MemReservationGB
           $SetCPU | Add-Member -type NoteProperty -Name "CpuReservationMhz" -Value $ReservationCPU.CpuReservationMhz
           $SetCPU | Add-Member -type NoteProperty -Name "MemReservationGB" -Value $ReservationMEM.MemReservationGB
                #Change the number after the * This is the amountof CPUMhz that you would like to reserve. 
                $CPUmhz = ([int64](($_.NumCpu)*1920))
           $CPUCount += $SetCPU 
            Get-VM $_ | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuReservationMhz "$CPUmhz" | Out-Null 
                $SetMEM = New-Object VMware.Vim.VirtualMachineConfigSpec
                $SetMEM.memoryReservationLockedToMax = $true 
                    (Get-VM $_).ExtensionData.ReconfigVM_Task($SetMEM) | Out-Null 
            }

    #$CPUCount | Format-Table | Export-Csv "C:\temp\reservations.csv" 

#Html Formating 

# The below will create a small table above the content with a 
# couple logos. I just thought it looked cool. 

$img = @"
<table>
    <tr>
        <td>
            <center><img src="https://online.com/image1.png"></center>
        </td>
        <td>
            <center><img src="https://online.com/image2.png"></center>
        </td>
    </tr>
</table>
"@

$style = "
<title>CPU and Memory Reservations</title>

<style>
    h1, h5, h2, th { text-align: center;font-family: sans-serif; }
    table { align=`"center`"; vertical-align=`"top`"; font-family: arial; border: 0px;width: 700px;max-width: 700px;text-align: center; }
    th { background: #000000; color: #FFF; max-width: 400px; padding: 5px 10px; }
    td { font-size: 11px; padding: 5px 20px; color: #000000;}
    tr { background: #FFFFFF; }
</style>
"
$body = '<center>'
$body += '<h1>CPU and Memory Reservations</h1></br>'
$body += $CPUCount | ConvertTo-Html -PreContent $img -As Table
$body +='</center>'
$html = $style + $body

#Outputs to file
#ConvertTo-Html -Head $style -Body $body | Out-File C:\temp\test.html

#Email config
$From = "<CPU_And_Memory_Reservationst@domain.com>"
$To = @("Firstname LastName<Firstname.LastName@domain.com>")
$Subject = "CPU and Memory Reservations"
$SMTPServer = "smtp.domain.com"

#Send email
Send-MailMessage -From $From -To $To -Subject $Subject -SmtpServer $SMTPServer -BodyAsHtml $html