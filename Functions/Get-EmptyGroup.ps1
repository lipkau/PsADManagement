#Requires -Version 2.0
Function Get-EmptyGroup
{
    <#
    .Synopsis
        Retrieves all groups without members in a domain or container.

    .Description
        Retrieves all groups without members in a domain or container.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:18

    .Inputs
        System.String, System.Integer

    .Parameter SearchRoot
        A search base (the distinguished name of the search base object) defines the location in the directory from which the LDAP search begins

    .Parameter SizeLimit
        Maximum of results shown for a query

    .Parameter SearchScope
        A search scope defines how deep to search within the search base.
            Base , or zero level, indicates a search of the base object only.
            One level indicates a search of objects immediately subordinate to the base object, but does not include the base object itself.
            Subtree indicates a search of the base object and the entire subtree of which the base object distinguished name is the topmost object.

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-EmptyGroup

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [string]$SearchRoot,

        [ValidateNotNullOrEmpty()]
        [int]$PageSize = 1000,

        [int]$SizeLimit = 0,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Base","OneLevel","Subtree")]
        [string]$SearchScope = "SubTree"
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $c = 0
        $filter = "(&(objectClass=group)(!member=*))"

        $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter
    }

    Process
    {
        if (!($SearchRoot))
            {$SearchRoot=$root.defaultNamingContext}
        elseif (!($SearchRoot) -or ![ADSI]::Exists("LDAP://$SearchRoot"))
            {Write-Error "$($MyInvocation.MyCommand.Name):: SearchRoot value: '$SearchRoot' is invalid, please check value";return}
        $searcher.SearchRoot = "LDAP://$SearchRoot"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

        $searcher.SearchScope = $SearchScope
        $searcher.SizeLimit = $SizeLimit
        $searcher.PageSize = $PageSize
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