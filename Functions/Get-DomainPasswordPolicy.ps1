#Requires -Version 2.0
Function Get-DomainPasswordPolicy
{
    <#
    .Synopsis
        Retrieves the domain password policy.

    .Description
        Retrieves the domain password policy.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/25 18:22

    .Inputs
        System.String

    .Parameter domain
        Target Domain

    .Outputs
        System.Management.Automation.PSCustomObject

    .Example
        Get-DomainPasswordPolicy
        -----------
        Description
        Gets Password Policies of your domain

    .Example
        Get-DomainPasswordPolicy -domain us001
        -----------
        Description
        Gets Password Policies of the US001 domain.

    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$true)]
        [string]$Domain = $env:userdomain
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        $domainObj = [ADSI]"WinNT://$domain"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Target Domain: $domain"

        $Name = @{Name="DomainName";Expression={$_.Name}}
        $MinPassLen = @{Name="Minimum Password Length (Chars)";Expression={$_.MinPasswordLength}}
        $MinPassAge = @{Name="Minimum Password Age (Days)";Expression={$_.MinPasswordAge.value/86400}}
        $MaxPassAge = @{Name="Maximum Password Age (Days)";Expression={$_.MaxPasswordAge.value/86400}}
        $PassHistory = @{Name="Enforce Password History (Passwords remembered)";Expression={$_.PasswordHistoryLength}}
        $AcctLockoutThreshold = @{Name="Account Lockout Threshold (Invalid logon attempts)";Expression={$_.MaxBadPasswordsAllowed}}
        $AcctLockoutDuration =  @{Name="Account Lockout Duration (Minutes)";Expression={if ($_.AutoUnlockInterval.value -eq -1) {'Account is locked out until administrator unlocks it.'} else {$_.AutoUnlockInterval.value/60}}}
        $ResetAcctLockoutCounter = @{Name="Reset Account Lockout Counter After (Minutes)";Expression={$_.LockoutObservationInterval.value/60}}

        $domainObj | Select-Object $Name,$MinPassLen,$MinPassAge,$MaxPassAge,$PassHistory,$AcctLockoutThreshold,$AcctLockoutDuration,$ResetAcctLockoutCounter
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}