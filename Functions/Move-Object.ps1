#Requires -Version 2.0
Function Move-Object
{
    <#
    .Synopsis
        Moves one or more objects to a different container in Active Directory.

    .Description
        Moves one or more objects to a different container in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/16 18:38

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Object
        Object to be moved.

    .Parameter NewLocation
        Place the object should be moved to.

    .Example
        Get-User test* | Move-Object -NewLocationDN "OU=TEST,DC=domain,DC=com"
        -----------
        Description
        Gets all users which names start with Test and move them to the Test OU

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
        [Parameter(ValueFromPipeline = $true,mandatory=$true)]
        [ADSI[]]$Object,

        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true)]
        [ADSI]$NewLocation,

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
        if (![ADSI]::Exists($NewLocation.Path))
            {Write-Error "$($MyInvocation.MyCommand.Name):: `$NewLocation doesn't exist, please check the value.";return}

        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Object: $($Object.cn)"
        if ([ADSI]::Exists($Object.Path))
        {
            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            if ($pscmdlet.ShouldProcess($Object.cn))
                {$Object.psbase.MoveTo($NewLocation)}

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}

            return $object
        } else
            {Write-Warning "$($MyInvocation.MyCommand.Name):: `$Object could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended Processing Object: $($Object.cn)"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}