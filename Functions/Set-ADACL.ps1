#Requires -Version 2.0
function Set-ADACL
{
    <#
    .Synopsis
        Sets the AD Object ACL to ‘ACL Object’ or ‘SDDL’ String

    .Description
        Sets the AD Object ACL to ‘ACL Object’ or ‘SDDL’ String

    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Version   : v1.1
        Date      : 2011/08/13 11:59

        Original  : YetiCentral\bshell <www.bsonposh.com>

    .Inputs
        System.DirectoryServices.DirectoryEntry
        System.DirectoryServices.ActiveDirectoryAccessRule
        System.String

    .Parameter InputObject
        Object to Set the ACL

    .Parameter ACL
        ACL Object to Apply

    .Parameter SDDL
        SDDL string to Apply

    .Example
        Set-ADACL (Get-User "Joe") -ACL (Get-ADACL (Get-Object "cn=users,dc=domain,dc=com"))
        -----------
        Description
        Set ACL on Get-User results using ACL Object

    .Example
        Set-ADACL ([adsi]"LDAP://cn=users,dc=corp,dc=lab") -sddl $mysddl
        -----------
        Description
        Set ACL on ‘cn=users,dc=corp,dc=lab’ using SDDL

    .Example
        Get-Object -SeacrhRoot ‘cn=users,dc=corp,dc=lab’ -recurse | Set-ADACL -sddl $mysddl
        -----------
        Description
        Set ACL for all objects in ‘cn=users,dc=corp,dc=lab’ using SDDL

    .Link
        Get-ADACL
        Get-Computer
        Get-OU
        Get-Object
        Get-User
    .Link
        http://oliver.lipkau.net/blog/category/powershell/admanagement/
    #>

    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$true,Mandatory=$True,HelpMessage="Object to Set the ACL")]
        [ADSI[]]$InputObject,

        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName="ACL",mandatory=$true)]
        [System.DirectoryServices.ActiveDirectoryAccessRule]$ACL,

        [Parameter(ParameterSetName="SDDL",mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SDDL,

        [switch]$Replace,

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
        foreach ($Object in $InputObject)
        {
            Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing $($Object.DistinguishedName)"

            #Load different user context if credential parameter is present
            if ($Credential)
                {$null = Push-ImpersonationContext $Credential}

            if($sddl)
            {
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Setting ACL using SDDL"
                $Object.psbase.ObjectSecurity.SetSecurityDescriptorSddlForm($sddl)
            } else {
                foreach($ace in $acl)
                {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Adding Permission [$($ace.ActiveDirectoryRights)] to [$($ace.IdentityReference)]"
                    if($Replace)
                        {$Object.psbase.ObjectSecurity.SetAccessRule($ace)}
                    else
                        {$Object.psbase.ObjectSecurity.AddAccessRule($ace)}
                }
            }
            $Object.psbase.commitchanges()

            #Restore current user context
            if ($Credential)
                {$null = Pop-ImpersonationContext}
        }
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}