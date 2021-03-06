#Requires -Version 2.0
Function Enable-Account
{
    <#
    .Synopsis
        Enables a user or computer account in Active Directory.

    .Description
        Enables a user or computer account in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2010/10/13 09:22

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Object
        DN of the object (user or computer) to enable. Can be an array.

    .Example
        Get-User Test1 | Enable-Account
        Enable user Test1

    .Example
        Enable-Account "cn=admin,ou=user,dc=domain,dc=com"
        Enables Admin

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

                $null = $object.psbase.invokeSet("AccountDisabled",$false)
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving changes"
                $null = $object.SetInfo()
                #Restore current user context
                if ($Credential)
                    {$null = Pop-ImpersonationContext}
            }
        } else
            {Write-Warning "$($object.distinguishedName) is not a valid object type (only 'User' or 'Computer' objects are allowed) or could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Object: $object"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function Ended"}
}