#Requires -Version 2.0
Function Get-StaleComputer
{
    <#
    .Synopsis
        Return a collection of computer accounts older than a set number of days.

    .Description
        This function can be used to get a list of computer accounts within your Active Directory that are older than a certain number of days. Typically a computer account will renew it's own password every 90 days, so any account where the 'whenChanged' attribute is older than 90 would be considered old.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2011/08/12 16:25

    .Inputs
        System.String
        System.Integer

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter SearchRoot
        A search base (the distinguished name of the search base object) defines the location in the directory from which the LDAP search begins

    .Parameter SizeLimit
        Maximum of results shown for a query

    .Parameter SearchScope
        A search scope defines how deep to search within the search base.
            Base , or zero level, indicates a search of the base object only.
            One level indicates a search of objects immediately subordinate to the base object, but does not include the base object itself.
            Subtree indicates a search of the base object and the entire subtree of which the base object distinguished name is the topmost object.

    .Parameter DayOffset
        An integer that represents the number of days in which an account is considered stale.

    .Example
        Get-StaleComputer -SearchRoot "DC=company,DC=com" -DayOffset 90

        Description
        -----------
        This is the typical usage from the command-line


    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    Param
    (
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,Mandatory=$true,HelpMessage="Name of the computer to be searched")]
        [Alias("CN")]
        [string[]]$Name = "*",

        [Parameter()]
        [string]$SearchRoot,

        [ValidateNotNullOrEmpty()]
        [Parameter()]
        [int]$PageSize = 1000,

        [Parameter()]
        [int]$SizeLimit = 0,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Base","OneLevel","Subtree")]
        [string]$SearchScope = "SubTree",

        [Parameter(Mandatory=$true,HelpMessage="Max number of inactive days for a computer to be considered stale")]
        [int]$DayOffset = 90
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-Computer))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Computer'. Please make sure it's loaded."}
    }

    Process
    {
        $PSBoundParameters.Remove("DayOffset")
        $DateOffset = (Get-Date).AddDays(-$DayOffset)
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Seaching computers older than: $DateOffset"

        Get-Computer @PSBoundParameters | Where-Object {$_.Properties.whenchanged -lt $DateOffset}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}