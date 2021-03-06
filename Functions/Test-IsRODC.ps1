#Requires -Version 2.0
Function Test-IsRODC
{
<#
    .Synopsis
        Tests if a Domain Controller is Read-Only

    .Description
        Tests if a Domain Controller is Read-Only

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:49

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter InputObject
        ADSI object of the server you want tested

    .Outputs
        System.Boolean

    .Example
        Test-IsRODC "cn=dc1,ou=domain controllers,dc=domain,dc=com"

    .Example
        Test-IsRODC (Get-NearestDC)

    .Link
        Get-Computer
        Get-object
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="ADSI object of the server you want tested")]
        [ADSI[]]$InputObject
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        foreach ($Object in $InputObject)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($Object.cn)"
            if ($Object.psbase.SchemaClassName -eq 'computer' -and [ADSI]::Exists($Object.Path))
            {
                $Object.GetInfoEx(@("msDS-IsRODC"),0)
                if (!($Object."msDS-IsRODC"))
                    {return $false}
                else
                    {return $ObjectDN."msDS-IsRODC"}
            } else
                {Write-Warning "`$Object is not a valid object type (only 'Computer' objects are allowed) or could not be found."}
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Object: $($Object.cn)"
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}