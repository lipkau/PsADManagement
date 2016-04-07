#Requires -Version 2.0
Function Get-Computer
{
    <#
    .Synopsis
        Retrieves all computer objects in a domain or container.
        
    .Description
        Retrieves all computer objects in a domain or container.
        
    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.3
        Date      : 2013-05-16 17:35:26

    .Inputs
        System.String
        
    .Parameter Name
        Value to search for in: sAMAccountName, cn, displayName, dNSHostName and name
        
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
        Get-Computer -Name WRK* -Enabled
        -----------
        Description
        Gets all domain enabled computers which names start with WRK
        
    .Example
        Get-Computer -SearchRoot 'CN=Computers,DC=Domain,DC=com' -Disabled
        -----------
        Description
        Gets all disabled computers from the Computers container
        
    .Example
        Get-Computer -Name "mpcc1d2c" -SearchRoot "domain.com"
        -----------
        Description
        Gets specific computer in a different domain
        
    .Example
        "mpcc1d2c" | Get-Computer -SearchRoot "domain.com"
        -----------
        Description
        Gets computer from Pipe
        
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>
    
    [CmdletBinding(DefaultParametersetName="cn")]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,Mandatory=$true,ParameterSetName='cn',Position=0)]
        [Alias("CN")]
        [string[]]$Name = "*",

        [Parameter(ValueFromPipeline = $true,Mandatory=$true,ParameterSetName='managed',Position=0)]
        [ADSI[]]$ManagedBy,
        
        [string]$SearchRoot,
        
        [ValidateNotNullOrEmpty()]
        [int]$PageSize = 1000,
        
        [ValidateNotNullOrEmpty()]
        [int]$SizeLimit = 0,
        
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Base","OneLevel","Subtree")]
        [string]$SearchScope = "SubTree",
        
        [switch]$Enabled,
        
        [switch]$Disabled
    )
    
    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        $c = 0
        
        $disableStr = "userAccountControl:1.2.840.113556.1.4.803:=2"
        $Enabledf = "(!$disableStr)"
        $Disabledf = "($disableStr)"

        $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
    }
    
    Process
    {
        switch ($PsCmdlet.ParameterSetName) { 
            "managed"  { $SearchObjects = $ManagedBy.distinguishedName; break}
            Default {$SearchObjects = $name; break} 
        }
        foreach ($n in $SearchObjects)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Searching for $n"

            if(($Enabled) -and (!($Disabled)))
                {$EnabledDisabledf = $Enabledf}
            elseif(($Disabled) -and (!($Enabled)))
                {$EnabledDisabledf = $Disabledf}
            else 
                {$EnabledDisabledf = ""}

            switch ($PsCmdlet.ParameterSetName) { 
                "managed"  { $resolve = "(managedBy=$n)"; break}
                Default {$resolve = "(|(sAMAccountName=$n)(cn=$n)(displayName=$n)(dNSHostName=$n)(name=$n))"; break} 
            }
            
      
            $filter = "(&(objectCategory=Computer)(objectClass=User)$EnabledDisabledf$resolve)"

            if (!($SearchRoot))
                {$SearchRoot=$root.defaultNamingContext}
            elseif (!($SearchRoot) -or ![ADSI]::Exists("LDAP://$SearchRoot"))
                {Write-Error "$($MyInvocation.MyCommand.Name):: '$SearchRoot' does not exist";return}
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
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Results found: $c"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    }
}