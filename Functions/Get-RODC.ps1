#Requires -Version 2.0
Function Get-RODC
{
<#
    .Synopsis
        Gets Read-Only Domain Controller

    .Description
        Gets Read-Only Domain Controller

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 14:53

    .Inputs
        System.String

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-RODC

    .Example
        Get-RODC "dc=domain,dc=com"

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(DC=.*){2,}$')]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Distinguished name of the domain to search")]
        [string]$domain
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        $c = 0
        $filter = "(msDS-IsRODC=1)"

        $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter
    }

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing doamin: $domain"
        if (!($domain))
            {$SearchRoot=$root.defaultNamingContext}
        elseif (!($domain) -or ![ADSI]::Exists("LDAP://$domain"))
            {Write-Error "$($MyInvocation.MyCommand.Name):: SearchRoot value: '$domain' is invalid, please check value";return}
        else
            {$SearchRoot=$domain}
        $searcher.SearchRoot = "LDAP://ou=domain controllers,$SearchRoot"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

        try
        {
            $searcher.FindAll() | `
            Foreach-Object `
            {
                $c++
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Found: $($_.Properties.cn)"
                $_.GetDirectoryEntry()
            }
        }
        catch
        {
            return $false
        }

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing domain: $domain"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}