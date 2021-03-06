#Requires -Version 2.0
Function Get-Group
{
    <#
    .Synopsis
        Retrieves all groups in a domain or container that match the specified conditions.

    .Description
        Retrieves all groups in a domain or container that match the specified conditions.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2010/08/25 18:15

    .Inputs
        System.String

    .Parameter Name
        Value to search for in: sAMAccountName, cn and name

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
        Get-Group -Name test* -GroupType distribution
        -----------
        Description
        Retrieves distribution groups which name starts with 'test'

    .Example
        Get-Group -GroupType security -GroupScope universal
        -----------
        Description
        Retrieves all universal security groups

    .Example
        Get-Group -Name "test-group" -SearchRoot "domain.com"
        -----------
        Description
        Retrieves specific group in different domain

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Name = "*",

        [string]$SearchRoot,

        [ValidateNotNullOrEmpty()]
        [int]$PageSize = 1000,

        [int]$SizeLimit = 0,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Base","OneLevel","Subtree")]
        [string]$SearchScope = "SubTree",

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Security","Distribution")]
        [string]$GroupType,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Universal","Global","DomainLocal")]
        [string]$GroupScope
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $c = 0

        $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
    }

    Process
    {
        foreach ($n in $name)
        {
            $resolve = "(|(sAMAccountName=$n)(cn=$n)(name=$n))"

            $parameters = $GroupScope,$GroupType
            switch ($parameters)
            {
                @('Universal','Distribution')
                    {$filter = "(&(objectcategory=group)(sAMAccountType=268435457)(grouptype:1.2.840.113556.1.4.804:=8)$resolve)"}
                @('Universal','Security')
                    {$filter = "(&(objectcategory=group)(sAMAccountType=268435456)(grouptype:1.2.840.113556.1.4.804:=-2147483640)$resolve)"}
                @('Global','Distribution')
                    {$filter = "(&(objectcategory=group)(sAMAccountType=268435457)(grouptype:1.2.840.113556.1.4.804:=2)$resolve)"}
                @('Global','Security')
                    {$filter = "(&(objectcategory=group)(sAMAccountType=268435456)(grouptype:1.2.840.113556.1.4.803:=-2147483646)$resolve)"}
                @('DomainLocal','Distribution')
                    {$filter = "(&(objectcategory=group)(sAMAccountType=536870913)(grouptype:1.2.840.113556.1.4.804:=4)$resolve)"}
                @('DomainLocal','Security')
                    {$filter = "(&(objectcategory=group)(sAMAccountType=536870912)(grouptype:1.2.840.113556.1.4.804:=-2147483644)$resolve)"}
                @('Global','')
                    {$filter = "(&(objectcategory=group)(grouptype:1.2.840.113556.1.4.804:=2)$resolve)"}
                @('DomainLocal','')
                    {$filter = "(&(objectcategory=group)(grouptype:1.2.840.113556.1.4.804:=4)$resolve)"}
                @('Universal','')
                    {$filter = "(&(objectcategory=group)(grouptype:1.2.840.113556.1.4.804:=8)$resolve)"}
                @('','Distribution')
                    {$filter = "(&(objectCategory=group)(!groupType:1.2.840.113556.1.4.803:=2147483648)$resolve)"}
                @('','Security')
                    {$filter = "(&(objectcategory=group)(groupType:1.2.840.113556.1.4.803:=2147483648)$resolve)"}
                default
                    {$filter = "(&(objectcategory=group)$resolve)"}
            }

            if (!($SearchRoot))
                {$SearchRoot=$root.defaultNamingContext}
            elseif (!($SearchRoot) -or ![ADSI]::Exists("LDAP://$SearchRoot"))
                {Write-Error "$($MyInvocation.MyCommand.Name):: `$SearchRoot does not exist";return}
            $searcher.SearchRoot = "LDAP://$SearchRoot"
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

            $searcher.SearchScope = $SearchScope
            $searcher.SizeLimit = $SizeLimit
            $searcher.PageSize = $PageSize
            $searcher.filter = $filter
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
    }

    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Found $c results"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}