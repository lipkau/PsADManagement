#Requires -Version 2.0
Function Get-IPSite
{
    <#
    .Synopsis
        Gets site that contains a given IP

    .Description
        Gets site that contains a given IP

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/28 10:35

    .Inputs
        Net.IPAddress,
        System.String

    .Example
        Get-IPSite -ip 129.214.31.241 -mask 255.255.252.0
        -----------
        Description
        Returns the site that contains that IP address

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true)]
        [Net.IPAddress]$IP,

        [ValidateNotNullOrEmpty()]
        [alias("SubnetMask")]
        [Net.IPAddress]$mask ="255.255.255.0",

        [string]$forest
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-Forest))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Forest'. Please make sure it's loaded."}

        function ConvertTo-MaskLength
        {
            #.Synopsis
            # Convert from a netmask to the masklength
            #.Example
            # ConvertTo-MaskLength -Mask 255.255.255.0
            # AUTHOR:    Glenn Sizemore
            # Website:   http://get-admin.com
            Param(
                [ValidateNotNullOrEmpty()]
                [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
                [string]$mask
            )

            process
            {
                $out = 0
                foreach ($octet in $Mask.split('.'))
                {
                    0..7 | ForEach-Object `
                    {
                        if (($octet - [math]::pow(2,(7-$_)))-ge 0)
                        {
                            $octet = $octet - [math]::pow(2,(7-$_))
                            $out++
                        }
                    }
                }
                return $out
            }
        }
    }

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Getting forest"
        if ($forest)
            {$f = Get-Forest -forest $forest}
        else
            {$f = Get-Forest}

        $result = $ip.address -band $mask.address
        $search = ([Net.IPAddress]$result).IPAddressToString + "/" + (ConvertTo-MaskLength $mask)

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Querying Sites"
        $f.get_Sites() | Where-Object {$_.Subnets -like $search}
    }


    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}