#Requires -Version 2.0
Function Disable-Account
{
    <#
    .Synopsis
        Disable a user or computer account in Active Directory.

    .Description
        Disable a user or computer account in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2010/10/13 09:22

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Object
        Object (user or computer) to be disabled. Can be an array.

    .Example
        Get-Computer Server1 | Disable-Account
        --------------
        Description
        Disable computer Server1

    .Example
        Disable-Account "cn=Admin,cn=users,dc=domain,dc=com"
        --------------
        Description
        Disables user Admin

    .Link
        Get-Computer
        Get-Object
        Get-ObjectBySID
        Get-User
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        [ADSI]$Object,

        [System.Management.Automation.PSCredential]$Credential
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

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
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($Object.cn)"
        if ($Object.psbase.SchemaClassName -match '^(user|computer)$' -and [ADSI]::Exists($Object.Path))
        {
            if ($pscmdlet.ShouldProcess($Object.cn))
            {
                #Load different user context if credential parameter is present
                if ($Credential)
                    {$null = Push-ImpersonationContext $Credential}

                $null = $Object.psbase.invokeSet("AccountDisabled",$true)
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving changes"
                $null = $Object.SetInfo()
                #Restore current user context
                if ($Credential)
                    {$null = Pop-ImpersonationContext}
            }
        } else
            {Write-Warning "$($MyInvocation.MyCommand.Name):: $Object is not a valid object type (only 'User' or 'Computer' objects are allowed) or could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Object: $($Object.cn)"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function Ended"}
}