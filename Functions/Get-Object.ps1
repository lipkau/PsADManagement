#Requires -Version 2.0
Function Get-Object
{
    <#
    .Synopsis
        Retrieves an object from AD.

    .Description
        Retrieves an object from AD.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.2
        Date      : 2013-05-16 17:35:40

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

    .Parameter Path
        DistinguishedName of the object.

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Example
        Get-Object -Name test*
        -----------
        Description
        Retrieves all object starting with test

    .Example
        Get-Object -Path "cn=users,dc=domain,dc=com"
        -----------
        Description
        Retrieves the AD object "cn=users,dc=domain,dc=com"

    .Example
        Get-Object -Path "cn=users,dc=domain,dc=com" -recurse
        -----------
        Description
        Retrieves the AD object "cn=users,dc=domain,dc=com" and child objects (OU members)

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,Mandatory=$true,ParameterSetName='search')]
        [Alias("CN")]
        [string[]]$Name = "*",

        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName='search')]
        [ValidateSet("organizationalUnit","user","contact","group","computer","volume","printQueue","*")]
        [string[]]$type = "*",

        [Parameter(ParameterSetName='search')]
        [string]$SearchRoot,

        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName='search')]
        [int]$PageSize = 1000,

        [Parameter(ParameterSetName='search')]
        [int]$SizeLimit = 0,

        [Parameter(ParameterSetName='search')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Base","OneLevel","Subtree")]
        [string]$SearchScope = "SubTree",

        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName='search')]
        [ValidateSet("Security","Distribution")]
        [string]$GroupType,

        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName='search')]
        [ValidateSet("Universal","Global","DomainLocal")]
        [string]$GroupScope,

        [Parameter(ValueFromPipelineByPropertyName = $true,mandatory=$false,ParameterSetName='path')]
        [ValidatePattern('^((CN|OU)=.*)*(DC=.*)*$')]
        [Alias("DN","DistinguishedName")]
        [string[]]$path,

        [Parameter(ParameterSetName='path')]
        [switch]$recurse
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
        if ($path)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Using ADSI path"
            foreach ($item in $path)
            {
                if ([ADSI]::Exists("LDAP://$item"))
                {
                    [adsi]"LDAP://$item"
                    if ($recurse)
                        {([adsi]"LDAP://$item").Child | Foreach-Object {Get-Object -path $_.distinguishname}}
                } else {

                }
            }
        } else {
            foreach ($n in $name)
            {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for $n"
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Using filters"
                $class = "(&"
                foreach ($t in $type)
                    {$class = "(objectCategory=$t)"}
                $class += ")"
                $resolve = "(&$class(|(sAMAccountName=$n)(cn=$n)(name=$n)))"

                if (!($SearchRoot))
                    {$SearchRoot=$root.defaultNamingContext}
                elseif (!($SearchRoot) -or ![ADSI]::Exists("LDAP://$SearchRoot"))
                    {Write-Error "$($MyInvocation.MyCommand.Name):: `$SearchRoot does not exist";return}
                $searcher.SearchRoot = "LDAP://$SearchRoot"
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

                $searcher.SearchScope = $SearchScope
                $searcher.SizeLimit = $SizeLimit
                $searcher.PageSize = $PageSize
                $searcher.filter = $resolve
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for: $($searcher.filter)"
                try
                {
                    $searcher.FindAll() | `
                    Foreach-Object `
                    {
                        $c++
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Found: $($_.Properties.cn)"
                        $_.GetDirectoryEntry()
                        if ($recurse)
                            {([adsi]$_.Path).Child | Foreach-Object {Get-Object -path $_.distinguishname}}
                    }
                }
                catch
                    {$false}
            }
        }
    }

    End
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Found $c results"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}