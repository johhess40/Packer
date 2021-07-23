[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file -Verbose

##Set up WinRm listener for future use

Write-Host "Create a new WinRM listener and configure"


Enable-PSremoting

winrm create winrm/config/listener?Address=*+Transport=HTTP

winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'

winrm set winrm/config '@{MaxTimeoutms="7200000"}'

winrm set winrm/config/service '@{AllowUnencrypted="true"}'

winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'

winrm set winrm/config/service/auth '@{Basic="true"}'

winrm set winrm/config/client/auth '@{Basic="true"}'

Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -RemoteAddress Any -Action Allow -Direction Inbound 

Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any -Action Allow -Direction Inbound 

Set-Item -Force WSMan:\localhost\Service\AllowUnencrypted $true

Set-Item -Force WSMan:\localhost\Client\AllowUnencrypted $true

Set-Item -Force WSMan:\localhost\Service\Auth\Basic $true

Set-NetFirewallProfile -Profile Private,Domain,Public -Enabled False

$FirewallParam = @{
     DisplayName = 'Custom WinRM Port Rule'
     Direction = 'Inbound'
     LocalPort = 5985
     Protocol = 'TCP'
     Action = 'Allow'
     Program = 'System'
 }
 New-NetFirewallRule @FirewallParam

(Get-Service -Name winrm).Status



