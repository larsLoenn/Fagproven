# Install AD DS and DNS Server roles 
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
# Import the AD DS module 
Import-Module ADDSDeployment
# Install a new forest "sjobris" 
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "sjobris.ad" `
-DomainNetbiosName "SJOBRIS" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true


# DC02 replikering av DC01

#
# Windows PowerShell script for AD DS Deployment
#
# Install AD DS and DNS Server roles 
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
# Import the AD DS module 
Import-Module ADDSDeployment
Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-Credential (Get-Credential) `
-CriticalReplicationOnly:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainName "sjobris.ad" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-ReplicationSourceDC "DC01.sjobris.ad" `
-SiteName "Default-First-Site-Name" `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
