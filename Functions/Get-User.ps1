#Requires -Version 2.0
Function Get-User
{
    <#
    .Synopsis
        Retrieves users in a domain or container.

    .Description
        Retrieves users in a domain or container.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.3
        Date      : 2011/08/10 05:08

    .Inputs
        System.String

    .Parameter Name
        Value to search for in: sAMAccountName, cn, displayName and givenName

    .Parameter SearchRoot
        Root in which to search. Can be a OU or another domain in the forrest.

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
        Get-User
        -----------
        Description
        Gets all user objects from the domain

    .Example
        Get-User -Name J* -Disabled
        -----------
        Description
        Gets all disabled users which names start with J

    .Example
        Get-User -SizeLimit 10 -SearchRoot 'OU=Developers,DC=domain,DC=com'
        -----------
        Description
        Gets 10 user accounts from the Developers OU

    .Example
        Get-User -Enabled  -PasswordNeverExpires
        -----------
        Description
        Gets all enabled users with non-expiring passwords

    .Example
        "mpccn1c0" | Get-User -Enabled
        -----------
        Description
        Gets specific User from pipe

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$true)]
        [Alias("CN")]
        [string[]]$Name = "*",

        [string]$SearchRoot,

        [ValidateNotNullOrEmpty()]
        [int]$PageSize = 1000,

        [int]$SizeLimit = 0,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Base","OneLevel","Subtree")]
        [string]$SearchScope = "SubTree",

        [switch]$Enabled,

        [switch]$Disabled,

        [switch]$AccountNeverExpires,

        [switch]$PasswordNeverExpires
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $c = 0

        $disableStr = "userAccountControl:1.2.840.113556.1.4.803:=2"
        $Enabledf = "(!$disableStr)"
        $Disabledf = "($disableStr)"

        $accountNe = "(|(accountExpires=9223372036854775807)(accountExpires=0))"
        $pwNe = "(userAccountControl:1.2.840.113556.1.4.803:=65536)"

        $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
    }

    Process
    {
        foreach ($n in $name)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for $n"
            # for domain\user format:
            if ($n -match "\\")
                # get only the user:
                {$Partial = $n.split("\")[-1]}
            $resolve = "(|(sAMAccountName=$n)(sAMAccountName=$(if ($Partial) {$Partial} else {$n}))(cn=$n)(displayName=$n)(givenName=$n))"
            $filter = "(&(objectCategory=Person)(objectClass=User)$EnabledDisabledf$AccountNeverExpiresf$PasswordNeverExpiresf$resolve)"

            if (!($SearchRoot))
                {$SearchRoot=$root.defaultNamingContext}
            elseif (!($SearchRoot) -or ![ADSI]::Exists("LDAP://$SearchRoot"))
                {Write-Error "SearchRoot value: '$SearchRoot' is invalid, please check value";return}
            $searcher.SearchRoot = "LDAP://$SearchRoot"
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching in: $($searcher.SearchRoot)"

            if (($Enabled) -and (!($Disabled)))
                {$EnabledDisabledf = $Enabledf}
            elseif (($Disabled) -and (!($Enabled)))
                {$EnabledDisabledf = $Disabledf}
            else
                {$EnabledDisabledf = ""}

            if ($AccountNeverExpires)
                {$AccountNeverExpiresf = $accountNe}
            if ($PasswordNeverExpires)
                {$PasswordNeverExpiresf = $pwNe}


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
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Results found: $c"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}