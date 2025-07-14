# Install the DHCP Server feature and management tools
Install-WindowsFeature -Name 'DHCP' -IncludeManagementTools

# Import the DHCP Server module
Import-Module DhcpServer

# Prompt for DHCP scope settings
$ScopeName   = Read-Host "Enter a name for the DHCP scope"
$StartRange  = Read-Host "Enter the start IP address (e.g., 192.168.1.100)"
$EndRange    = Read-Host "Enter the end IP address (e.g., 192.168.1.200)"
$SubnetMask  = Read-Host "Enter the subnet mask (e.g., 255.255.255.0)"
$Gateway     = Read-Host "Enter the default gateway IP address (e.g., 192.168.1.1)"
$DnsServer   = Read-Host "Enter the DNS server IP address (e.g., 192.168.1.10)"

# Exclude specified IPs or ranges
$ExcludeIPs = Read-Host "Enter IPs to exclude (comma-separated, e.g. 10.46.41.1-10.46.41.99,10.46.41.150)"

if ($ExcludeIPs -ne "") {
    $ExclusionItems = $ExcludeIPs -split "," | ForEach-Object { $_.Trim() }

    foreach ($item in $ExclusionItems) {
        if ($item -match "-") {
            # Range exclusion
            $range = $item -split "-"
            if ($range.Count -eq 2) {
                $startIP = $range[0].Trim()
                $endIP = $range[1].Trim()
                Add-DhcpServerv4ExclusionRange -ScopeId $StartRange -StartRange $startIP -EndRange $endIP
                Write-Host "Excluded range: $startIP - $endIP"
            } else {
                Write-Host "Invalid range format: $item" -ForegroundColor Yellow
            }
        } else {
            # Single IP exclusion
            Add-DhcpServerv4ExclusionRange -ScopeId $StartRange -StartRange $item -EndRange $item
            Write-Host "Excluded single IP: $item"
        }
    }
}

# Create the DHCP scope
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask
Write-Host "`nDHCP scope '$ScopeName' created from $StartRange to $EndRange."

# Apply scope options (Gateway and DNS)
Set-DhcpServerv4OptionValue -ScopeId $StartRange -Router $Gateway -DnsServer $DnsServer
Write-Host "Set Gateway ($Gateway) and DNS Server ($DnsServer) for scope."

# Exclude specified IPs (if any)
foreach ($ip in $ExcludeList) {
    Add-DhcpServerv4ExclusionRange -ScopeId $StartRange -StartRange $ip -EndRange $ip
    Write-Host "Excluded IP: $ip"
}
# Get the server's primary IP explicitly (you can even hardcode if needed)
$ServerIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "10.46.*" }).IPAddress

Add-DhcpServerInDC -DnsName $env:COMPUTERNAME -IPAddress $ServerIP
Write-Host "`n✅ DHCP server authorized in Active Directory as $env:COMPUTERNAME ($ServerIP)"


Write-Host "`n✅ DHCP Server installed and fully configured."
