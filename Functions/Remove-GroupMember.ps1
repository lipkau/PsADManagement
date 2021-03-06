#Requires -Version 2.0
function Remove-GroupMember
{
    <#
    .Synopsis
        Removes a member from a group in Active Directory.

    .Description
        Removes a member from a group in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.0
        Date      : 2011/08/13 13:02

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Member
        Object to be removed from the group

    .Parameter Group
        Group object

    .Example
        Get-Group QA | Remove-GroupMember -MemberDN 'CN=Administrator,CN=Users,DC=domain,DC=com'
        -----------
        Description
        Removes the domain administrator account to the QA group

    .Example
        Get-Group QA | Remove-GroupMember -MemberDN (Get-User -Name QAUser* | Foreach-Object { $_.distinguishedName } )
        -----------
        Description
        Removes multiple accounts to the QA group

    .Link
        Get-Group
        Get-GroupMember
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
        [Parameter(ValueFromPipeline = $true,mandatory=$true,HelpMessage="Group object")]
        [ADSI]$Group,

        [ValidateNotNullOrEmpty()]
        [Parameter(mandatory=$true,HelpMessage="Object to be removed from the group")]
        [ADSI[]]$Member,

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
        if ($Group.psbase.SchemaClassName -eq 'group' -and [ADSI]::Exists($Group.Path))
        {
            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            $Member | Where-Object {$_} | `
            ForEach-Object `
            {
                $user = $_
                if ($user.psbase.SchemaClassName -eq 'user' -and [ADSI]::Exists($user.Path))
                {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Removing user: $($user.cn)"
                    $null = $Group.member.remove($_)
                }
                else
                    {Write-Warning "$($MyInvocation.MyCommand.Name):: `$user is not a valid object type (only User objects are allowed) or object could not be found."}
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended processing user: $($user.cn)"
            }
            if ($pscmdlet.ShouldProcess($Group.cn))
            {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Saving changes"
                $Group.psbase.commitChanges()
            }

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}
        }
        else
            {Write-Warning "$($MyInvocation.MyCommand.Name):: `$Group is not a valid object type (only Group objects are allowed) or could not be found"}
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}