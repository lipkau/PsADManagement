#Requires -Version 2.0
function Set-DomainMode
{
    <#
    .Synopsis
        Modifies the domain functionality.

    .Discription
        Modifies the domain functionality.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:57

    .Inputs
        System.String

    .Parameter Domain
        Domain you want to change

    .Parameter Funcionality
        New Functionality Level. Options:
            Windows2000MixedDomain
            Windows2000NativeDomain
            Windows2003InterimDomain
            Windows2003Domain
            Windows2008Domain
            Windows2008R2Domain

    .Example
        Set-DomainMode "Windows2008Domain"
        -----------
        Description
        Changes the functionality of the current domain to Windows 2008 Domain

    .Link
        Get-Domain
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="New Functionality Level")]
        [ValidateSet("Windows2000MixedDomain","Windows2000NativeDomain","Windows2003InterimDomain","Windows2003Domain","Windows2008Domain","Windows2008R2Domain")]
        [string]$Funcionality,

        [ValidateNotNullOrEmpty()]
        [ValidatePattern('(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')]
        [Parameter(ValueFromPipeline = $true)]
        [string]$Domain,

        [System.Management.Automation.PSCredential]$Credential
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        if (!(Test-Path function:Get-Domain))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-Domain'. Please make sure it's loaded."}

        if ($Credential)
        {
            if (!(Test-Path function:Push-ImpersonationContext))
               {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Push-ImpersonationContext'. Please make sure it's loaded."}
            if (!(Test-Path function:Pop-ImpersonationContext))
               {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Pop-ImpersonationContext'. Please make sure it's loaded."}
        }
    }

    Process
    {
        if ($domain)
            {$d = Get-domain -domain $domain}
        else
            {$d = Get-domain}

        #Load different user context if credential parameter is present
        if ($Credential)
            {$null = Push-ImpersonationContext $Credential}

        if ($pscmdlet.ShouldProcess($d.name))
            {$d.RaiseDomainFunctionality($Funcionality)}

        #Restore current user context
        if ($Credential)
            {$null = Pop-ImpersonationContext}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function Ended"}
}