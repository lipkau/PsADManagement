#Requires -Version 2.0
Function Get-DomainControllerInfo
{
    <#
    .Synopsis
        Retrieves information from all domain controller in the domain.

    .Description
        Retrieves information from all domain controller in the domain.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:25

    .Outputs
        System.Array

    .Example
        Get-DomainControllerInfo

    .Link
        Get-DomainControllers
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')]
        [Parameter(ValueFromPipeline = $true)]
        [string]$domain
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-Domain))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Domain'. Please make sure it's loaded."}
    }

    Process
    {
        if (!($Domain))
            {(Get-Domain).DomainControllers}
        else
            {(Get-Domain $domain).DomainControllers}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}