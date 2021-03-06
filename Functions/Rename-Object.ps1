#Requires -Version 2.0
Function Rename-Object
{
    <#
    .Synopsis
        Renames one or more objects.

    .Description
        Renames one or more objects.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2010/08/28 09:32

    .Inputs
        System.DirectoryServices.DirectoryEntry
        System.String

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter InputObject
        Object to be renamed

    .Example
        Get-User testuser | Rename-Object -NewName "test_user"
        -----------
        Description
        Renames the "testuser" to "test_user"

    .Link
        Get-User
        Get-Computer
        Get-Object
        Get-ObjectBySID
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Object to be renamed")]
        [ADSI]$InputObject,

        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true)]
        [string]$NewName,

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
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($InputObject.cn)"
        if ([ADSI]::Exists($InputObject.Path))
        {
            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            if ($pscmdlet.ShouldProcess($InputObject.cn))
                {$InputObject.psbase.Rename("cn=$NewName")}

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}

            return $InputObject
        } else
            {Write-Warning "$($MyInvocation.MyCommand.Name):: `$InputObject could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Object: $($InputObject.cn)"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}