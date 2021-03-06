#Requires -Version 2.0
Function Get-Domain
{
    <#
    .Synopsis
        Retrieve domain information like Domain Controllers, DomainMode, Domain Masters, and Forest Root.

    .Description
        Retrieve domain information like Domain Controllers, DomainMode, Domain Masters, and Forest Root.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:27

    .Inputs
        System.String

    .Parameter domain
        FQDN of the target domain

    .Outputs
        System.DirectoryServices.ActiveDirectory.Domain

    .Example
        Get-CurrentDomain | Select-Object *owner
        -----------
        Description
        Retrieves domain FSMO roles holders

    .Example
        Get-Domain | Select-Object -ExpandProperty DomainControllers
        -----------
        Description
        Retrieves domain controllers for the current domain

    .Example
        Get-Domain "domain.forest.com"

    .Link
        Get-Forest
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')]
        [Parameter(ValueFromPipeline = $true)]
        [string]$domain
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        if (!($domain))
            {[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()}
        else
        {
            $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
            [system.directoryservices.activedirectory.domain]::GetDomain($context)
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}