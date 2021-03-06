#Requires -Version 2.0
Function Test-SameSubnet
{
    <#
    .Synopsis
        Tests if two IPs are in the same subnet.

    .Description
        Tests if two IPs are in the same subnet.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:47

    .Inputs
        System.String

    .Parameter IP1
        First IP address to compare

    .Parameter IP2
        Secound IP address to compare

    .Parameter SubnetMask
        Subnet mask (both IPs need to have the same subnet mask)

    .Example
        Test-SameSubnet -ip1 129.214.31.241 -ip2 129.214.31.111 -mask 255.255.252.0

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true,HelpMessage="First IP address to compare")]
        [Net.IPAddress]$IP1,

        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true,HelpMessage="Secound IP address to compare")]
        [Net.IPAddress]$IP2,

        [ValidateNotNullOrEmpty()]
        [alias("Mask")]
        [Net.IPAddress]$SubnetMask ="255.255.255.0"
    )

    Process
        {(($ip1.address -band $SubnetMask.address) -eq ($ip2.address -band $SubnetMask.address))}
}