# Install AD DS and DNS Server roles 
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
# Import the AD DS module 
Import-Module ADDSDeployment
# Install a new forest "Vestkommune" 
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "vestkommune.ad" `
-DomainNetbiosName "VEST" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
