#Requires -Version 2
Function Get-DomainControllers
{
    <#
    .Synopsis
        Retrieves all Domain Controllers objects in the domain.

    .Description
        Retrieves all Domain Controllers objects in the domain.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:22

    .Input
        System.String

    .Parameter domain
        DN of the domain you want to search for DCs

    .Outputs
        System.Array

    .Example
        Get-DomainControllers -descending
        -----------
        Description
        Retrives all DCs in the current domain

    .Link
        Get-DomainControllerInfo
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(DC=.*)*$')]
        [string]$Domain
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $c = 0

        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.filter = "objectCategory=computer"
        $searcher.sort.propertyname = "name"
    }

    Process
    {
        $domaindn = $domain
        if (!($domaindn))
            {$domaindn = ([ADSI]"").distinguishedName}
        if (!($domaindn) -or !([ADSI]::Exists("LDAP://$domaindn")))
            {Write-Error "$($MyInvocation.MyCommand.Name):: $domain could not be found";return}
        $searcher.searchroot = "LDAP://OU=Domain Controllers,$domaindn"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for: $($searcher.filter)"
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
            {return $false}
        }
    }

    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Found $c results"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}