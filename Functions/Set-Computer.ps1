#Requires -Version 2.0
Function Set-Computer
{
    <#
    .Synopsis
        Changes a Computer account in Active Directory.

    .Description
        Changes a Computer account in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:58

    .Inputs
        System.String
        System.DirectoryServices.DirectoryEntry

    .Outputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Computer
        Computer Object to be changed

    .Example
        Get-Computer -Name TestPC | Set-COmputer -description "new description" -accountExpires (Get-Date 21/12/2012)
        -----------
        Description
        Sets a new description and expiration date for TestPC

    .Link
        Get-Computer
        Get-Object
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium"
    )]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="Computer Object to be changed")]
        [ADSI]$Computer,

        [ADSI]$managedby,

        [string]$Description,

        [datetime]$accountExpires,

        [System.Management.Automation.PSCredential]$Credential
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if (!(Test-Path function:Get-DomainRoot))
            {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-DomainRoot'. Please make sure it's loaded."}

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
        #Load different user context if credential parameter is present
        if ($Credential)
            {$null = Push-ImpersonationContext $Credential}

        if ($pscmdlet.ShouldProcess($Computer.cn))
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Creating Computer: $($Computer.cn)"

            if ($Description)
                {$null = $computer.put("description",$Description)}

            if ($Managedby)
            {
                if ($Managedby.psbase.SchemaClassName -match 'User|Contact' -and [ADSI]::Exists($Managedby.Path))
                    {$null = $computer.put("managedBy","$($managedby.distinguishedName)")}
                else
                    {Write-Warning "$($MyInvocation.MyCommand.Name):: `$Manager is not a valid object type (only 'User' or 'Contact' objects are allowed) or could not be found."}
            }

            if ($accountExpires)
                {$computer.psbase.InvokeSet("accountexpires","$($accountExpires.ToFileTimeUtc())")}

            Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving Information for: $Name"
            $null = $computer.psbase.CommitChanges()
        }

        #Restore current user context
        if ($Credential)
            {$null = Pop-ImpersonationContext}

        return $computer
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}