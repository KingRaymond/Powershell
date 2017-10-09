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