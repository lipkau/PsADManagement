#Requires -Version 2.0
function Remove-Object
{
    <#
    .Synopsis
        Deletes the specified object in Active Directory.

    .Description
        Deletes the specified object in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 12:59

    .Inputs
        System.DirectoryServices.DirectoryEntry
        System.String

    .Parameter InputObject
        Object to be deleted

    .Example
        Get-User -Disabled | Remove-Object
        -----------
        Description
        Deletes all disabled domain user - no confirmation

    .Example
        Get-User -Name idera* -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Remove-Object -Confirm
        -----------
        Description
        Deletes all objects which names start with idera from the Test OU - must be confirmed

    .Link
        Get-Computer
        Get-Group
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
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Object to be deleted")]
        [ADSI[]]$InputObject,

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
        foreach ($object in $InputObject)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($Object.cn)"
            if ([ADSI]::Exists($Object.Path))
            {
                if ($pscmdlet.ShouldProcess($Object.cn))
                {
                    #Load different user context if credential parameter is present
                    if ($Credential)
                        {$null = Push-ImpersonationContext $Credential}

                    $scn = $Object.psbase.SchemaClassName
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Deleting $scn : $($Object.cn)"
                    $Object.psbase.parent.delete($scn,"CN="+$Object.cn)

                    #Restore current user context
                    if ($Credential)
                        {$null = Pop-ImpersonationContext}
                }
            } else
                {Write-Warning "$($MyInvocation.MyCommand.Name):: `$Object could not be found."}
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing Object: $($Object.cn)"
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}