#Requires -Version 2.0
Function Add-GroupMember
{
    <#
    .Synopsis
        Adds one or more objects to a group in Active Directory.

    .Description
        Adds one or more objects to a group in Active Directory.

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2010/10/13 09:22

    .Inputs
        System.DirectoryServices.DirectoryEntry

    .Parameter Member
        User to be added

    .Parameter AddBySID
        Will use the SID of the object to add it to the group.
        This will allows you to add users from different (but trusted) domains and forests.

    .Parameter Group
        Group to which you want to add a new member

    .Example
        (Get-Group QA).distinguishedName | Add-GroupMember -Member 'CN=Administrator,CN=Users,DC=domain,DC=com'
        -------------
        Description
        Adds the domain administrator account to the QA group

    .Example
        (Get-Group QA).distinguishedName | Add-GroupMember -Member (Get-User -Name QAUser*).distinguishedName
        -------------
        Description
        Adds multiple accounts to the QA group

    .Example
        Add-GroupMember -Member 'CN=Administrator,CN=Users,DC=domain,DC=com' -Group 'CN=Admin,OU=users,DC=domain,DC=com'

    .Link
        Get-Group
        Get-Object
        Get-objectBySID
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
        [Parameter(Mandatory=$true)]
        [ADSI[]]$Member,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
        [ADSI]$Group,

        [switch]$AddBySID,

        [System.Management.Automation.PSCredential]$Credential
    )

    Begin
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
        if ($AddBySID)
        {
            if (!(Test-Path function:Get-ObjectSID))
               {Throw "$($MyInvocation.MyCommand.Name):: This command requires the function 'Get-ObjectSID'. Please make sure it's loaded."}
        }
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
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing Group: $($Group.cn)"
        if ($Group.psbase.SchemaClassName -eq 'group' -and [ADSI]::Exists($Group.Path))
        {
            $Member | `
            Where-Object `
                {$_} | `
            ForEach-Object `
            {
                $user = $_
                if ($user.psbase.SchemaClassName -eq 'user' -and [ADSI]::Exists($user.Path))
                {
                    if ($pscmdlet.ShouldProcess($Group.cn))
                    {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding user: $($user.cn)"
                        #Load different user context if credential parameter is present
                        if ($Credential)
                            {$null = Push-ImpersonationContext $Credential}

                        if ($AddBySID)
                        {
                            Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding using SID"
                            $SID = Get-ObjectSID $user
                            $Group.add("LDAP://<SID=$SID>")
                        } else
                            {$Group.add($user.Path)}
                        #Restore current user context
                        if ($Credential)
                            {$null = Pop-ImpersonationContext}
                    }
                }
                else
                    {Write-Warning "$($MyInvocation.MyCommand.Name):: $user is not a valid object type (only User objects are allowed) or could not be found."}
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended processing user: $($user.cn)"
            }
        } else
            {Write-Warning "$($MyInvocation.MyCommand.Name):: $Group is not a valid object type (only Group objects are allowed) or object could not be found."}
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Ended processing Group: $($Group.cn)"
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}